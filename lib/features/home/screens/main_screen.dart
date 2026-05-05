// MainScreen - bottom navigation shell with Home, Journal, Profile tabs
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/mood_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/background_sync_service.dart';
import '../../../services/notification_service.dart';
import '../../mood/screens/mood_checkin_screen.dart';
import '../../music/widgets/mini_player.dart';
import 'home_screen.dart';
import '../../journal/screens/journal_screen.dart';
import '../../profile/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    JournalListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StreakProvider>().checkAndUpdateStreak();
      _scheduleNotifications();
      _maybePromptMoodCheckIn();
      // Fallback for missed midnight sync — fires once per calendar day
      BackgroundSyncService().syncIfNeeded();
    });
  }

  Future<void> _maybePromptMoodCheckIn() async {
    if (!mounted) return;
    final moodProvider = context.read<MoodProvider>();
    if (!moodProvider.shouldShowMoodCheckIn) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (_, _, _) => const MoodCheckinScreen(),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _scheduleNotifications() async {
    final userProvider = context.read<UserProvider>();
    final streakProvider = context.read<StreakProvider>();

    if (!userProvider.notificationsEnabled) {
      await NotificationService().cancelReminderNotifications();
      return;
    }

    await NotificationService().scheduleDailyReminder(
      time: userProvider.notificationTime,
      currentStreak: streakProvider.currentStreak,
      daysLeftToGoal: streakProvider.daysLeftToGoal,
      missedYesterday: streakProvider.missedYesterday,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.surface, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
