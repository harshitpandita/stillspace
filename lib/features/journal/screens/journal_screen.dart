// Journal screen - list of journal entries with add button
import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';

class JournalListScreen extends StatelessWidget {
  const JournalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Journal Screen\n(To be implemented)',
          style: AppTextStyles.headline2,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
