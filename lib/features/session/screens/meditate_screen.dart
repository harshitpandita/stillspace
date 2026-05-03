// Meditate screen - select duration and optional sound before starting session
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/audio_service.dart';
import '../data/breathing_sessions.dart';
import '../models/breathing_session.dart';
import 'breathing_session_screen.dart';
import 'session_screen.dart';

class MeditateScreen extends StatefulWidget {
  const MeditateScreen({super.key});

  @override
  State<MeditateScreen> createState() => _MeditateScreenState();
}

class _MeditateScreenState extends State<MeditateScreen> {
  MeditationSound _selectedSound = MeditationSound.none;
  int _selectedDuration = 10;

  final List<int> _durations = [5, 10, 15, 20, 30];

  String get _sessionLabel {
    switch (_selectedSound) {
      case MeditationSound.focus:
        return 'Focus';
      case MeditationSound.relax:
        return 'Relax';
      case MeditationSound.none:
        return 'Timer';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Meditate', style: AppTextStyles.headline2),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Duration', style: AppTextStyles.headline3),
              const SizedBox(height: 16),
              _buildDurationSelector(),

              const SizedBox(height: 32),

              const Text('Ambient Sound', style: AppTextStyles.headline3),
              const SizedBox(height: 4),
              Text(
                'Optional - enhance your session',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildSoundSelector(),

              const SizedBox(height: 32),

              _buildStartButton(),

              const SizedBox(height: 32),

              const Text('Guided Breathing', style: AppTextStyles.headline3),
              const SizedBox(height: 4),
              Text(
                'Audio-guided breathwork sessions',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...BreathingSessions.all.map(
                (session) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildBreathingCard(session),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _durations.map((duration) {
        final isSelected = _selectedDuration == duration;
        return GestureDetector(
          onTap: () => setState(() => _selectedDuration = duration),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 58,
            height: 64,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$duration',
                  style: AppTextStyles.headline3.copyWith(
                    color: isSelected ? AppColors.background : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'min',
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? AppColors.background.withValues(alpha: 0.8) : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSoundSelector() {
    return Column(
      children: [
        _buildSoundOption(
          sound: MeditationSound.none,
          title: 'Silent',
          subtitle: 'Timer only, no sound',
          icon: Icons.timer_outlined,
        ),
        const SizedBox(height: 10),
        _buildSoundOption(
          sound: MeditationSound.focus,
          title: '2.5 Hz Binaural',
          subtitle: 'Deep focus & concentration',
          icon: Icons.psychology_outlined,
        ),
        const SizedBox(height: 10),
        _buildSoundOption(
          sound: MeditationSound.relax,
          title: 'Brown Noise',
          subtitle: 'Calm & relaxation',
          icon: Icons.nightlight_outlined,
        ),
      ],
    );
  }

  Widget _buildSoundOption({
    required MeditationSound sound,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedSound == sound;

    return GestureDetector(
      onTap: () => setState(() => _selectedSound = sound),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.background,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: AppColors.background, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startSession,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Start $_selectedDuration min $_sessionLabel',
            style: const TextStyle(
              color: AppColors.background,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _startSession() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SessionScreen(
          duration: _selectedDuration,
          sound: _selectedSound,
          meditationType: _sessionLabel,
        ),
      ),
    );
  }

  Widget _buildBreathingCard(BreathingSession session) {
    final mins = session.durationSeconds ~/ 60;
    final secs = session.durationSeconds % 60;
    final durationLabel = secs == 0 ? '$mins min' : '$mins min $secs sec';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BreathingSessionScreen(session: session),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(session.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.title, style: AppTextStyles.label),
                  const SizedBox(height: 2),
                  Text(
                    session.description,
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                durationLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
