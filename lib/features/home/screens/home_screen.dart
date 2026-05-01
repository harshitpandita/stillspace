// Home screen - main dashboard with session cards and mood check-in trigger
import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Home Screen\n(To be implemented)',
          style: AppTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
