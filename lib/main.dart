// Stillspace app entry point - initializes Firebase, Hive, providers, and routing
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'providers/user_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/session_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/journal_provider.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home/screens/main_screen.dart';
import 'features/walkthrough/screens/walkthrough_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Guard against duplicate init on hot restart — the native FirebaseApp is
  // long-lived across Dart isolate restarts, so re-calling initializeApp throws.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyCyu06SXeik4yMge3wkgfWZ5RKHgthKZ6k',
        appId: '1:706859686171:android:cf7082380ac8a62d38dbbe',
        messagingSenderId: '706859686171',
        projectId: 'stillspace-670ef',
        storageBucket: 'stillspace-670ef.firebasestorage.app',
      ),
    );
  }

  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveBoxUserProfile);
  await Hive.openBox(AppConstants.hiveBoxMoodLogs);
  await Hive.openBox(AppConstants.hiveBoxJournalEntries);
  await Hive.openBox(AppConstants.hiveBoxStreakData);

  // UNCOMMENT TO CLEAR ALL HIVE DATA FOR TESTING ONBOARDING:
  // await Hive.box(AppConstants.hiveBoxUserProfile).clear();
  // await Hive.box(AppConstants.hiveBoxMoodLogs).clear();
  // await Hive.box(AppConstants.hiveBoxJournalEntries).clear();
  // await Hive.box(AppConstants.hiveBoxStreakData).clear();

  // If local data is empty (fresh install / app reinstall), force re-onboarding by signing out
  final isOnboardingComplete = Hive.box(AppConstants.hiveBoxUserProfile)
      .get('isOnboardingComplete', defaultValue: false);
  if (!isOnboardingComplete && FirebaseService().isSignedIn) {
    await FirebaseService().signOut();
  }

  await NotificationService().init();

  // Foreground service + lock-screen controls for the music player
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.harshitpandita.stillspace.music',
    androidNotificationChannelName: 'Stillspace Music',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  runApp(const StillspaceApp());
}

class StillspaceApp extends StatelessWidget {
  const StillspaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..init()),
        ChangeNotifierProvider(create: (_) => MoodProvider()..init()),
        ChangeNotifierProvider(create: (_) => SessionProvider()..init()),
        ChangeNotifierProvider(create: (_) => StreakProvider()..init()),
        ChangeNotifierProvider(create: (_) => JournalProvider()..init()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> with WidgetsBindingObserver {
  DateTime? _lastResumeDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastResumeDate = DateTime.now();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshIfNewDay();
    }
  }

  void _refreshIfNewDay() {
    final now = DateTime.now();
    final lastDate = _lastResumeDate;

    if (lastDate == null || now.day != lastDate.day || now.month != lastDate.month || now.year != lastDate.year) {
      _lastResumeDate = now;
      _refreshProviders();
    }
  }

  void _refreshProviders() {
    context.read<MoodProvider>().init();
    context.read<StreakProvider>().init();
    context.read<JournalProvider>().init();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (!userProvider.isOnboardingComplete) {
          return const OnboardingScreen();
        }
        if (!userProvider.hasSeenWalkthrough) {
          return WalkthroughScreen(
            showSkip: true,
            onComplete: () => userProvider.completeWalkthrough(),
          );
        }
        return const MainScreen();
      },
    );
  }
}
