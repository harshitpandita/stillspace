// Session screen - meditation timer with breathing animation and ambient audio
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/streak_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/notification_service.dart';
import '../../../services/audio_service.dart';
import '../../../widgets/primary_action_button.dart';

class SessionScreen extends StatefulWidget {
  final int duration;
  final MeditationSound sound;
  final String meditationType;

  const SessionScreen({
    super.key,
    required this.duration,
    this.sound = MeditationSound.none,
    this.meditationType = 'Meditation',
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> with TickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _isComplete = false;
  bool _quietModeActive = false;
  late AnimationController _breathController;

  double _volume = 0.5;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.duration * 60;
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _stopTimer();
    if (_quietModeActive) {
      unawaited(_restoreNotifications());
    }
    _breathController.dispose();
    _audioService.stopAll();
    super.dispose();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _restoreNotifications() async {
    if (!_quietModeActive) return;

    final userProvider = context.read<UserProvider>();
    final streakProvider = context.read<StreakProvider>();

    await NotificationService().exitQuietMode(
      notificationsEnabled: userProvider.notificationsEnabled,
      time: userProvider.notificationTime,
      currentStreak: streakProvider.currentStreak,
      daysLeftToGoal: streakProvider.daysLeftToGoal,
      missedYesterday: streakProvider.missedYesterday,
    );

    _quietModeActive = false;
  }

  void _tick() {
    if (!mounted || !_isRunning) return;

    if (_remainingSeconds > 0) {
      setState(() => _remainingSeconds--);
    } else {
      _completeSession();
    }
  }

  Future<void> _startSession() async {
    _stopTimer();

    await NotificationService().enterQuietMode();
    _quietModeActive = true;

    setState(() => _isRunning = true);
    _breathController.repeat(reverse: true);

    // Start timer immediately
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());

    // Play the start bell first; ambient begins after the bell finishes.
    unawaited(
      _audioService.startSessionAudio(
        sound: widget.sound,
        volume: _volume,
      ),
    );
  }

  void _pauseSession() {
    _stopTimer();
    _breathController.stop();
    _audioService.pause();
    setState(() => _isRunning = false);
  }

  void _resumeSession() {
    setState(() => _isRunning = true);
    _breathController.repeat(reverse: true);
    _audioService.resume();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _completeSession() async {
    _stopTimer();
    _breathController.stop();
    await _audioService.stop();

    if (!mounted) return;

    // Play completion bell
    _audioService.playBell();

    setState(() {
      _isRunning = false;
      _isComplete = true;
    });

    await context.read<StreakProvider>().incrementStreak(sessionMinutes: widget.duration);
    await NotificationService().cancelFollowUpNotifications();
    await _restoreNotifications();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  bool get _hasStarted => _remainingSeconds != widget.duration * 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () async {
            _stopTimer();
            _breathController.stop();
            await _audioService.stopAll();
            await _restoreNotifications();
            if (mounted) Navigator.of(context).pop();
          },
        ),
        title: Text(
          widget.meditationType,
          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
        ),
        centerTitle: true,
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

              // Volume slider - only when sound is selected and session started
              if (!_isComplete && widget.sound != MeditationSound.none && _hasStarted) ...[
                _buildVolumeSlider(),
                const SizedBox(height: 16),
              ],

              if (!_isComplete) ...[
                _buildQuietModeNote(),
                const SizedBox(height: 16),
              ],

              // Action button
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
                  label: _hasStarted ? 'Resume' : 'Start',
                  onPressed: _hasStarted ? _resumeSession : _startSession,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuietModeNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.do_not_disturb_on, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiet session mode',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'During your session, Stillspace keeps distractions quiet on Android and reminds you when the session ends.',
                  style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_down, color: AppColors.textSecondary, size: 20),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.background,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _volume,
                onChanged: (value) {
                  setState(() => _volume = value);
                  _audioService.setVolume(value);
                },
              ),
            ),
          ),
          const Icon(Icons.volume_up, color: AppColors.textSecondary, size: 20),
        ],
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
          animation: _breathController,
          builder: (context, child) {
            final scale = _isRunning
                ? 0.8 + (0.2 * _breathController.value)
                : 0.9;
            return Transform.scale(
              scale: scale,
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
        if (_isRunning && widget.sound != MeditationSound.none)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AudioService.getSoundEmoji(widget.sound),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                AudioService.getSoundName(widget.sound),
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          )
        else
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
          'You completed ${widget.duration} minutes of ${widget.meditationType.toLowerCase()}.',
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
