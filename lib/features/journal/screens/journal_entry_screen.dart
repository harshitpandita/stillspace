// Journal entry screen - create new journal entry with optional prompt
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/journal_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/primary_action_button.dart';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _contentController = TextEditingController();
  late String _suggestedPrompt;
  bool _usePrompt = true;
  int? _selectedMood;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _suggestedPrompt = _getRandomPrompt();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String _getRandomPrompt() {
    final random = Random();
    return AppConstants.defaultJournalPrompts[
        random.nextInt(AppConstants.defaultJournalPrompts.length)];
  }

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
        title: const Text('New Entry', style: AppTextStyles.headline3),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPromptSection(),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _contentController,
                        style: AppTextStyles.body1,
                        maxLines: null,
                        minLines: 8,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: _usePrompt
                              ? 'Write your thoughts...'
                              : 'What\'s on your mind?',
                          hintStyle: AppTextStyles.body2,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 24),
                      Text('How are you feeling?', style: AppTextStyles.label),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(5, (index) {
                          final moodScore = index + 1;
                          final isSelected = _selectedMood == moodScore;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedMood = isSelected ? null : moodScore;
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 52 : 44,
                              height: isSelected ? 52 : 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  AppConstants.moodEmojis[index],
                                  style: TextStyle(fontSize: isSelected ? 24 : 20),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      PrimaryActionButton(
                        label: 'Save Entry',
                        onPressed: _contentController.text.trim().isNotEmpty ? _saveEntry : null,
                        isLoading: _isSaving,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPromptSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Suggested prompt',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _usePrompt = !_usePrompt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _usePrompt ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _usePrompt ? 'On' : 'Off',
                  style: AppTextStyles.caption.copyWith(
                    color: _usePrompt ? AppColors.background : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_usePrompt) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _suggestedPrompt = _getRandomPrompt()),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _suggestedPrompt,
                      style: AppTextStyles.body1.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.shuffle, color: AppColors.primary, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveEntry() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);

    final journalProvider = context.read<JournalProvider>();
    final streakProvider = context.read<StreakProvider>();
    final navigator = Navigator.of(context);

    await journalProvider.addEntry(
      prompt: _usePrompt ? _suggestedPrompt : 'Free write',
      content: _contentController.text.trim(),
      moodScore: _selectedMood,
    );

    await streakProvider.incrementStreak();
    await NotificationService().cancelFollowUpNotifications();

    if (mounted) {
      navigator.pop();
    }
  }
}
