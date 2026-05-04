// MusicService - background music playback with foreground-service notification.
// Uses just_audio_background under the hood: lock-screen controls, system
// notification with play/pause/stop, and guaranteed playback when the device
// is locked or the app is minimized (Spotify-style).
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../features/music/models/music_track.dart';
import 'shared_audio_player.dart';

class MusicService extends ChangeNotifier {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal() {
    _stateSub = _player.playerStateStream.listen((_) => notifyListeners());
    _posSub = _player.positionStream.listen((_) {
      // Throttle position-driven rebuilds (positionStream emits very frequently)
      final now = DateTime.now();
      if (_lastPosNotify == null ||
          now.difference(_lastPosNotify!).inMilliseconds >= 500) {
        _lastPosNotify = now;
        notifyListeners();
      }
    });
  }

  final AudioPlayer _player = SharedAudioPlayer().player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  DateTime? _lastPosNotify;
  final SharedAudioPlayer _sharedAudio = SharedAudioPlayer();

  MusicTrack? _currentTrack;
  Duration? _sessionDuration; // null = until manually stopped
  Duration? _remainingWhenPaused;
  Timer? _autoStopTimer;
  DateTime? _playStartedAt;
  double _volume = 0.7;

  MusicTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  double get volume => _volume;
  Duration? get sessionDuration => _sessionDuration;
  bool get hasActiveSession => _currentTrack != null;

  Duration? get sessionRemaining {
    if (_currentTrack == null || _sessionDuration == null) return null;
    final remaining = _currentRemaining;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Progress through the session (0.0 - 1.0). Null when there's no fixed duration.
  double? get sessionProgress {
    final totalDuration = _sessionDuration;
    if (_currentTrack == null || totalDuration == null) return null;
    final total = totalDuration.inMilliseconds;
    if (total == 0) return 0;
    final elapsed = total - _currentRemaining.inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Duration get _currentRemaining {
    final remaining = _remainingWhenPaused ?? Duration.zero;
    final startedAt = _playStartedAt;
    if (!_player.playing || startedAt == null) return remaining;
    return remaining - DateTime.now().difference(startedAt);
  }

  Future<void> play(MusicTrack track, {Duration? duration}) async {
    try {
      _currentTrack = track;
      _sessionDuration = duration;
      _remainingWhenPaused = duration;
      _playStartedAt = null;
      _sharedAudio.claimPlayback();
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      // AudioSource with MediaItem tag — drives the system notification + lock-screen controls
      final source = AudioSource.asset(
        track.assetPath,
        tag: MediaItem(
          id: track.id,
          title: track.title,
          album: 'Stillspace',
          artist: track.category,
          duration: duration,
        ),
      );
      await _player.setAudioSource(source);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_volume);
      await _player.seek(Duration.zero);
      _playStartedAt = DateTime.now();
      _startAutoStopTimer(duration);
      unawaited(_player.play());
      notifyListeners();
    } catch (e) {
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      _sessionDuration = null;
      _remainingWhenPaused = null;
      _playStartedAt = null;
      _currentTrack = null;
      debugPrint('MusicService: failed to play ${track.id} - $e');
    }
  }

  Future<void> releaseForMeditationPlayback() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _sessionDuration = null;
    _remainingWhenPaused = null;
    _playStartedAt = null;
    _currentTrack = null;
    notifyListeners();
    return Future.value();
  }

  Future<void> pause() async {
    _remainingWhenPaused = sessionRemaining;
    _playStartedAt = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    _playStartedAt = DateTime.now();
    _startAutoStopTimer(_remainingWhenPaused);
    unawaited(_player.play());
    notifyListeners();
  }

  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _sessionDuration = null;
    _remainingWhenPaused = null;
    _playStartedAt = null;
    _currentTrack = null;
    _sharedAudio.claimPlayback();
    await _player.stop();
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  void _startAutoStopTimer(Duration? remaining) {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    if (remaining == null || remaining <= Duration.zero) return;
    _autoStopTimer = Timer(remaining, () => stop());
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _autoStopTimer?.cancel();
    super.dispose();
  }
}
