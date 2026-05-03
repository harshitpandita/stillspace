// Firebase service - handles authentication and Firestore sync
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  bool get isSignedIn => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> syncAllDataToCloud() async {
    if (!isSignedIn) return;
    final uid = currentUser!.uid;

    try {
      await _syncUserProfile(uid);
      await _syncStreakData(uid);
      await _syncMoodLogs(uid);
      await _syncJournalEntries(uid);
    } catch (e) {
      // Firestore may not be available - data stays local
    }
  }

  Future<void> syncAllDataFromCloud() async {
    if (!isSignedIn) return;
    final uid = currentUser!.uid;

    try {
      await _fetchUserProfile(uid);
      await _fetchStreakData(uid);
      await _fetchMoodLogs(uid);
      await _fetchJournalEntries(uid);
    } catch (e) {
      // Firestore may not be available - continue with local data
    }
  }

  Future<void> _syncUserProfile(String uid) async {
    final box = Hive.box(AppConstants.hiveBoxUserProfile);
    final data = {
      'userName': box.get('userName'),
      'goalDays': box.get('goalDays'),
      'notificationTime': box.get('notificationTime'),
      'notificationsEnabled': box.get('notificationsEnabled'),
      'isOnboardingComplete': box.get('isOnboardingComplete'),
      'lastSyncedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> _fetchUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return;

    final data = doc.data()!;
    final box = Hive.box(AppConstants.hiveBoxUserProfile);

    if (data['userName'] != null) await box.put('userName', data['userName']);
    if (data['goalDays'] != null) await box.put('goalDays', data['goalDays']);
    if (data['notificationTime'] != null) await box.put('notificationTime', data['notificationTime']);
    if (data['notificationsEnabled'] != null) await box.put('notificationsEnabled', data['notificationsEnabled']);
    if (data['isOnboardingComplete'] != null) await box.put('isOnboardingComplete', data['isOnboardingComplete']);
  }

  Future<void> _syncStreakData(String uid) async {
    final box = Hive.box(AppConstants.hiveBoxStreakData);
    final completedDates = box.get('completedDates', defaultValue: <String>[]);

    final data = {
      'currentStreak': box.get('currentStreak', defaultValue: 0),
      'longestStreak': box.get('longestStreak', defaultValue: 0),
      'lastCompletedDate': box.get('lastCompletedDate'),
      'completedDates': completedDates,
      'lastSyncedAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(uid).collection('streak_data').doc('current').set(data);
  }

  Future<void> _fetchStreakData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).collection('streak_data').doc('current').get();
    if (!doc.exists) return;

    final cloudData = doc.data()!;
    final box = Hive.box(AppConstants.hiveBoxStreakData);

    // Merge: take higher streak values, union completed dates — never reset local progress
    final localCurrent = (box.get('currentStreak', defaultValue: 0) as num).toInt();
    final localLongest = (box.get('longestStreak', defaultValue: 0) as num).toInt();
    final localDates = Set<String>.from(
      box.get('completedDates', defaultValue: <String>[]) as List,
    );
    final localLastCompleted = box.get('lastCompletedDate') as String?;

    final cloudCurrent = (cloudData['currentStreak'] as num?)?.toInt() ?? 0;
    final cloudLongest = (cloudData['longestStreak'] as num?)?.toInt() ?? 0;
    final cloudDates = cloudData['completedDates'] != null
        ? Set<String>.from(cloudData['completedDates'] as List)
        : <String>{};
    final cloudLastCompleted = cloudData['lastCompletedDate'] as String?;

    final mergedDates = {...localDates, ...cloudDates}.toList();
    String? mergedLastCompleted;
    if (localLastCompleted != null && cloudLastCompleted != null) {
      mergedLastCompleted = localLastCompleted.compareTo(cloudLastCompleted) >= 0
          ? localLastCompleted
          : cloudLastCompleted;
    } else {
      mergedLastCompleted = localLastCompleted ?? cloudLastCompleted;
    }

    await box.put('currentStreak', localCurrent > cloudCurrent ? localCurrent : cloudCurrent);
    await box.put('longestStreak', localLongest > cloudLongest ? localLongest : cloudLongest);
    await box.put('completedDates', mergedDates);
    if (mergedLastCompleted != null) {
      await box.put('lastCompletedDate', mergedLastCompleted);
    }
  }

  Future<void> _syncMoodLogs(String uid) async {
    final box = Hive.box(AppConstants.hiveBoxMoodLogs);
    final logs = box.get('logs', defaultValue: <Map>[]);

    final batch = _firestore.batch();
    final collectionRef = _firestore.collection('users').doc(uid).collection('mood_logs');

    for (final log in logs) {
      final logMap = Map<String, dynamic>.from(log);
      final docRef = collectionRef.doc(logMap['id']);
      batch.set(docRef, logMap);
    }

    await batch.commit();
  }

  Future<void> _fetchMoodLogs(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('mood_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    if (snapshot.docs.isEmpty) return;

    final logs = snapshot.docs.map((doc) => doc.data()).toList();
    final box = Hive.box(AppConstants.hiveBoxMoodLogs);
    await box.put('logs', logs);
  }

  Future<void> _syncJournalEntries(String uid) async {
    final box = Hive.box(AppConstants.hiveBoxJournalEntries);
    final entries = box.get('entries', defaultValue: <Map>[]);

    final batch = _firestore.batch();
    final collectionRef = _firestore.collection('users').doc(uid).collection('journal_entries');

    for (final entry in entries) {
      final entryMap = Map<String, dynamic>.from(entry);
      final docRef = collectionRef.doc(entryMap['id']);
      batch.set(docRef, entryMap);
    }

    await batch.commit();
  }

  Future<void> _fetchJournalEntries(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('journal_entries')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    if (snapshot.docs.isEmpty) return;

    final entries = snapshot.docs.map((doc) => doc.data()).toList();
    final box = Hive.box(AppConstants.hiveBoxJournalEntries);
    await box.put('entries', entries);
  }

  void syncOnChange() {
    if (!isSignedIn) return;
    syncAllDataToCloud();
  }
}
