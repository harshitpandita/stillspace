// Mood check-in screen - full screen emoji-based mood selector
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/mood_provider.dart';
import '../../../widgets/primary_action_button.dart';

class MoodCheckinScreen extends StatefulWidget {
  const MoodCheckinScreen({super.key});

  @override
  State<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends State<MoodCheckinScreen> {
  int? _selectedMood;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('How are you feeling?', style: AppTextStyles.headline3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              Text(
                'Select your current mood',
                style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(5, (index) {
                  final moodScore = index + 1;
                  final isSelected = _selectedMood == moodScore;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = moodScore),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 64 : 56,
                      height: isSelected ? 64 : 56,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AppConstants.moodEmojis[index],
                          style: TextStyle(fontSize: isSelected ? 32 : 28),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              if (_selectedMood != null)
                Text(
                  _getMoodLabel(_selectedMood!),
                  style: AppTextStyles.headline3.copyWith(color: AppColors.primary),
                ),
              const Spacer(),
              PrimaryActionButton(
                label: 'Save',
                onPressed: _selectedMood != null ? _saveMood : null,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodLabel(int score) {
    switch (score) {
      case 1: return 'Very Low';
      case 2: return 'Low';
      case 3: return 'Neutral';
      case 4: return 'Good';
      case 5: return 'Great';
      default: return '';
    }
  }

  Future<void> _saveMood() async {
    if (_selectedMood == null) return;
    await context.read<MoodProvider>().logMood(_selectedMood!);
    if (mounted) Navigator.of(context).pop();
  }
}
