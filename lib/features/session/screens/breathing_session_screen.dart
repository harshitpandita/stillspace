// Generic guided breathing session player — drives countdown from the audio's actual position
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/session_provider.dart';
import '../../../providers/streak_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/notification_service.dart';
import '../../../widgets/primary_action_button.dart';
import '../models/breathing_session.dart';

class BreathingSessionScreen extends StatefulWidget {
  final BreathingSession session;

  const BreathingSessionScreen({super.key, required this.session});

  @override
  State<BreathingSessionScreen> createState() => _BreathingSessionScreenState();
}

class _BreathingSessionScreenState extends State<BreathingSessionScreen>
    with TickerProviderStateMixin {
  final AudioService _audio = AudioService();

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;
  Timer? _fallbackTimer;
  final Stopwatch _fallbackClock = Stopwatch();

  Duration _elapsed = Duration.zero;
  DateTime? _lastAudioPositionAt;
  bool _isRunning = false;
  bool _isComplete = false;
  bool _isPaused = false;
  bool _quietModeActive = false;
  late AnimationController _breathController;
  late UserProvider _userProvider;
  late StreakProvider _streakProvider;
  late SessionProvider _sessionProvider;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
    _streakProvider = context.read<StreakProvider>();
    _sessionProvider = context.read<SessionProvider>();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _stateSub?.cancel();
    _stopFallbackTimer();
    _sessionProvider.resetSession();
    if (_quietModeActive) {
      unawaited(_restoreNotifications());
    }
    _breathController.dispose();
    _audio.stopGuided();
    super.dispose();
  }

  Future<void> _start() async {
    _elapsed = Duration.zero;
    _fallbackClock
      ..reset()
      ..start();
    _lastAudioPositionAt = DateTime.now();
    _sessionProvider.startSession();

    if (_userProvider.quietModeEnabled) {
      await NotificationService().enterQuietMode();
      if (!mounted) {
        _sessionProvider.resetSession();
        return;
      }
      _quietModeActive = true;
    }

    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _breathController.repeat(reverse: true);
    _startFallbackTimer();

    // Subscribe BEFORE play() so we don't miss the early position updates
    _posSub = _audio.guidedPositionStream.listen((pos) {
      if (!mounted) return;
      _lastAudioPositionAt = DateTime.now();
      setState(() => _elapsed = pos);
    });

    _stateSub = _audio.guidedStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed && !_isComplete) {
        unawaited(_completeSession());
      }
    });

    await _audio.playGuided(widget.session.audioAsset);
  }

  Future<void> _pause() async {
    await _audio.pauseGuided();
    _fallbackClock.stop();
    _stopFallbackTimer();
    _breathController.stop();
    setState(() {
      _isRunning = false;
      _isPaused = true;
    });
  }

  Future<void> _resume() async {
    await _audio.resumeGuided();
    _fallbackClock.start();
    _lastAudioPositionAt = DateTime.now();
    _startFallbackTimer();
    _breathController.repeat(reverse: true);
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
  }

  Future<void> _completeSession() async {
    _breathController.stop();
    _fallbackClock.stop();
    _stopFallbackTimer();
    await _audio.stopGuided();

    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _isComplete = true;
    });

    await _streakProvider.incrementStreak(sessionMinutes: widget.session.streakMinutes);
    _sessionProvider.endSession();
    await NotificationService().cancelFollowUpNotifications();
    await _restoreNotifications();
  }

  String _formatTime(Duration d) {
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Duration get _remaining {
    final total = Duration(seconds: widget.session.durationSeconds);
    final remaining = total - _elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double get _progress {
    if (widget.session.durationSeconds == 0) return 0;
    return (_elapsed.inMilliseconds / (widget.session.durationSeconds * 1000)).clamp(0.0, 1.0);
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRunning || _isComplete) return;

      final lastPositionAt = _lastAudioPositionAt;
      final positionIsStale = lastPositionAt == null ||
          DateTime.now().difference(lastPositionAt) > const Duration(seconds: 2);

      if (!positionIsStale) return;

      final total = Duration(seconds: widget.session.durationSeconds);
      final fallbackElapsed = _fallbackClock.elapsed;
      final nextElapsed = fallbackElapsed > total ? total : fallbackElapsed;
      setState(() => _elapsed = nextElapsed);

      if (nextElapsed >= total) {
        unawaited(_completeSession());
      }
    });
  }

  void _stopFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  Future<void> _restoreNotifications() async {
    if (!_quietModeActive) return;

    await NotificationService().exitQuietMode(
      notificationsEnabled: _userProvider.notificationsEnabled,
      time: _userProvider.notificationTime,
      currentStreak: _streakProvider.currentStreak,
      daysLeftToGoal: _streakProvider.daysLeftToGoal,
      missedYesterday: _streakProvider.missedYesterday,
    );

    _quietModeActive = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () async {
            await _audio.stopGuided();
            _sessionProvider.resetSession();
            await _restoreNotifications();
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        title: Text(
          widget.session.shortLabel,
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
              if (_isComplete) _buildComplete() else _buildPlayer(),
              const Spacer(),
              if (_isComplete)
                PrimaryActionButton(
                  label: 'Done',
                  onPressed: () => Navigator.of(context).pop(),
                )
              else if (_isRunning)
                PrimaryActionButton(label: 'Pause', onPressed: _pause)
              else
                PrimaryActionButton(
                  label: _isPaused ? 'Resume' : 'Start Session',
                  onPressed: _isPaused ? _resume : _start,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final hasStarted = _isRunning || _isPaused;
    return Column(
      children: [
        Text(widget.session.title, style: AppTextStyles.headline2),
        const SizedBox(height: 8),
        Text(
          widget.session.description,
          style: AppTextStyles.body2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        AnimatedBuilder(
          animation: _breathController,
          builder: (context, child) {
            final scale = _isRunning ? 0.85 + (0.15 * _breathController.value) : 0.9;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.primary, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        hasStarted
                            ? _formatTime(_remaining)
                            : _formatTime(Duration(seconds: widget.session.durationSeconds)),
                        style: AppTextStyles.headline1.copyWith(
                          fontSize: 44,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasStarted ? 'remaining' : 'total',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        if (hasStarted)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 4,
              backgroundColor: AppColors.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          )
        else
          Text(
            'Find a quiet space. Sit or lie down comfortably.',
            style: AppTextStyles.body2,
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildComplete() {
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
          'You completed ${widget.session.title.toLowerCase()}.',
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
