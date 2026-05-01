// Onboarding flow screen - 4 steps: name, goal, notification time, welcome
import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Onboarding Screen\n(To be implemented)',
          style: AppTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
