// Onboarding flow - 4 steps: name, goal, notification time, welcome
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/user_provider.dart';
import '../../../widgets/primary_action_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  int _currentStep = 0;
  int _selectedGoalDays = 21;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);

    final timeString = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    await context.read<UserProvider>().completeOnboarding(
      name: _nameController.text.trim(),
      goalDays: _selectedGoalDays,
      notificationTime: timeString,
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 0) {
          _previousStep();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentStep = index),
                  children: [
                    _buildNameStep(),
                    _buildGoalStep(),
                    _buildTimeStep(),
                    _buildWelcomeStep(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
      child: Row(
        children: [
          if (_currentStep > 0)
            IconButton(
              onPressed: _previousStep,
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            )
          else
            const SizedBox(width: 40),
          const SizedBox(width: 8),
          ...List.generate(4, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                decoration: BoxDecoration(
                  color: index <= _currentStep
                      ? AppColors.primary
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text("What's your name?", style: AppTextStyles.headline1),
                  const SizedBox(height: 12),
                  Text(
                    "We'll use this to personalize your experience.",
                    style: AppTextStyles.body2,
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _nameController,
                    style: AppTextStyles.body1,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
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
                  const Spacer(),
                  PrimaryActionButton(
                    label: 'Continue',
                    onPressed: _nameController.text.trim().isNotEmpty ? _nextStep : null,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text('Set your goal', style: AppTextStyles.headline1),
                  const SizedBox(height: 12),
                  Text(
                    'How many consecutive days do you want to commit to?',
                    style: AppTextStyles.body2,
                  ),
                  const SizedBox(height: 40),
                  ...List.generate(4, (index) {
                    final days = [7, 14, 21, 30][index];
                    final labels = ['1 Week', '2 Weeks', '3 Weeks', '1 Month'];
                    final isSelected = _selectedGoalDays == days;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGoalDays = days),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '$days days',
                                style: AppTextStyles.headline3.copyWith(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(labels[index], style: AppTextStyles.body2),
                              const Spacer(),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 16, color: AppColors.background)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  PrimaryActionButton(label: 'Continue', onPressed: _nextStep),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text('Daily reminder', style: AppTextStyles.headline1),
          const SizedBox(height: 12),
          Text(
            "We'll remind you to practice mindfulness at this time.",
            style: AppTextStyles.body2,
          ),
          const SizedBox(height: 60),
          Center(
            child: GestureDetector(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          surface: AppColors.surface,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedTime.format(context),
                      style: AppTextStyles.headline1.copyWith(
                        fontSize: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tap to change', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          PrimaryActionButton(label: 'Continue', onPressed: _nextStep),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.self_improvement,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Welcome, ${_nameController.text.trim()}!',
            style: AppTextStyles.headline1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "You've committed to $_selectedGoalDays days of mindfulness.\nLet's begin your journey to inner peace.",
            style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Daily reminder at ${_selectedTime.format(context)}',
                  style: AppTextStyles.label,
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryActionButton(
            label: "Let's Go",
            onPressed: _completeOnboarding,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
