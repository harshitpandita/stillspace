// Session screen - meditation timer with breathing animation
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/streak_provider.dart';
import '../../../widgets/primary_action_button.dart';

class SessionScreen extends StatefulWidget {
  final int duration;

  const SessionScreen({super.key, required this.duration});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isComplete = false;
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration * 60;
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breathController.dispose();
    super.dispose();
  }

  void _startSession() {
    setState(() => _isRunning = true);
    _breathController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _completeSession();
      }
    });
  }

  void _pauseSession() {
    _timer?.cancel();
    _breathController.stop();
    setState(() => _isRunning = false);
  }

  Future<void> _completeSession() async {
    _timer?.cancel();
    _breathController.stop();
    setState(() {
      _isRunning = false;
      _isComplete = true;
    });
    await context.read<StreakProvider>().incrementStreak();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              if (_isComplete)
                _buildCompletionView()
              else
                _buildTimerView(),
              const Spacer(),
              if (_isComplete)
                PrimaryActionButton(
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(),
                )
              else if (_isRunning)
                PrimaryActionButton(
                  label: 'Pause',
                  onPressed: _pauseSession,
                )
              else
                PrimaryActionButton(
                  label: _remainingSeconds == widget.duration * 60 ? 'Start' : 'Resume',
                  onPressed: _startSession,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerView() {
    return Column(
      children: [
        Text(
          '${widget.duration} Minute Session',
          style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 40),
        AnimatedBuilder(
          animation: _breathAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _isRunning ? _breathAnimation.value : 0.9,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: Center(
                  child: Text(
                    _formatTime(_remainingSeconds),
                    style: AppTextStyles.headline1.copyWith(
                      fontSize: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        Text(
          _isRunning ? 'Breathe...' : 'Ready when you are',
          style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCompletionView() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.check, color: AppColors.primary, size: 64),
        ),
        const SizedBox(height: 32),
        const Text('Session Complete!', style: AppTextStyles.headline1),
        const SizedBox(height: 12),
        Text(
          'You completed ${widget.duration} minutes of mindfulness.',
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
              const Icon(Icons.local_fire_department, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Streak updated!',
                style: AppTextStyles.label.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
