// Stillspace app entry point - initializes Firebase, Hive, providers, and routing
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/app_constants.dart';
import 'providers/user_provider.dart';
import 'providers/mood_provider.dart';
import 'providers/session_provider.dart';
import 'providers/streak_provider.dart';
import 'providers/journal_provider.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/home/screens/main_screen.dart';

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

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyCyu06SXeik4yMge3wkgfWZ5RKHgthKZ6k',
      appId: '1:706859686171:android:cf7082380ac8a62d38dbbe',
      messagingSenderId: '706859686171',
      projectId: 'stillspace-670ef',
      storageBucket: 'stillspace-670ef.firebasestorage.app',
    ),
  );

  await Hive.initFlutter();
  await Hive.openBox(AppConstants.hiveBoxUserProfile);
  await Hive.openBox(AppConstants.hiveBoxMoodLogs);
  await Hive.openBox(AppConstants.hiveBoxJournalEntries);
  await Hive.openBox(AppConstants.hiveBoxStreakData);

  // UNCOMMENT TO CLEAR ALL HIVE DATA FOR TESTING ONBOARDING:
   await Hive.box(AppConstants.hiveBoxUserProfile).clear();
   await Hive.box(AppConstants.hiveBoxMoodLogs).clear();
   await Hive.box(AppConstants.hiveBoxJournalEntries).clear();
   await Hive.box(AppConstants.hiveBoxStreakData).clear();

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

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        if (!userProvider.isOnboardingComplete) {
          return const OnboardingScreen();
        }
        return const MainScreen();
      },
    );
  }
}
