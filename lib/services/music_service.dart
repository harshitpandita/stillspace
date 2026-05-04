// MusicService - background music playback with foreground-service notification.
// Uses just_audio_background under the hood: lock-screen controls, system
// notification with play/pause/stop, and guaranteed playback when the device
// is locked or the app is minimized (Spotify-style).
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../features/music/models/music_track.dart';

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

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _posSub;
  DateTime? _lastPosNotify;

  MusicTrack? _currentTrack;
  Duration? _sessionDuration; // null = until manually stopped
  Timer? _autoStopTimer;
  DateTime? _sessionStartedAt;
  double _volume = 0.7;

  MusicTrack? get currentTrack => _currentTrack;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  double get volume => _volume;
  Duration? get sessionDuration => _sessionDuration;
  bool get hasActiveSession => _currentTrack != null;

  Duration? get sessionRemaining {
    if (_sessionDuration == null || _sessionStartedAt == null) return null;
    final elapsed = DateTime.now().difference(_sessionStartedAt!);
    final remaining = _sessionDuration! - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Progress through the session (0.0 - 1.0). Null when there's no fixed duration.
  double? get sessionProgress {
    if (_sessionDuration == null || _sessionStartedAt == null) return null;
    final elapsed = DateTime.now().difference(_sessionStartedAt!).inMilliseconds;
    final total = _sessionDuration!.inMilliseconds;
    if (total == 0) return 0;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Future<void> play(MusicTrack track, {Duration? duration}) async {
    try {
      _currentTrack = track;
      _sessionDuration = duration;
      _sessionStartedAt = DateTime.now();

      _autoStopTimer?.cancel();
      if (duration != null) {
        _autoStopTimer = Timer(duration, () => stop());
      }

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
      unawaited(_player.play());
      notifyListeners();
    } catch (e) {
      debugPrint('MusicService: failed to play ${track.id} - $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    unawaited(_player.play());
    notifyListeners();
  }

  Future<void> stop() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _sessionDuration = null;
    _sessionStartedAt = null;
    _currentTrack = null;
    await _player.stop();
    notifyListeners();
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _posSub?.cancel();
    _autoStopTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
