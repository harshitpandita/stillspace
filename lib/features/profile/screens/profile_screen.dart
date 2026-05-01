// Profile screen - user stats, streak calendar, mood chart
import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Profile Screen\n(To be implemented)',
          style: AppTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
