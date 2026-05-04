// Audio service - manages ambient sounds and bell for meditation sessions
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'music_service.dart';
import 'shared_audio_player.dart';

enum MeditationSound {
  none,
  focus,
  relax,
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final SharedAudioPlayer _sharedAudio = SharedAudioPlayer();
  late final AudioPlayer _player = _sharedAudio.player;
  StreamSubscription<PlayerState>? _startBellSub;
  MeditationSound _currentSound = MeditationSound.none;
  double _volume = 0.5;

  MeditationSound get currentSound => _currentSound;
  double get volume => _volume;
  bool get isPlaying => _player.playing;

  static const Map<MeditationSound, String> _soundAssets = {
    MeditationSound.focus: 'assets/audio/2.5-hz-focus.mp3',
    MeditationSound.relax: 'assets/audio/brown-noise-relaxing.mp3',
  };

  static const String _bellAsset = 'assets/audio/bell-sound.mp3';

  static String getSoundName(MeditationSound sound) {
    switch (sound) {
      case MeditationSound.none:
        return 'Silent';
      case MeditationSound.focus:
        return '2.5 Hz Binaural';
      case MeditationSound.relax:
        return 'Brown Noise';
    }
  }

  static String getSoundDescription(MeditationSound sound) {
    switch (sound) {
      case MeditationSound.none:
        return 'No ambient sound';
      case MeditationSound.focus:
        return 'Deep focus & concentration';
      case MeditationSound.relax:
        return 'Calm & relaxation';
    }
  }

  static String getSoundEmoji(MeditationSound sound) {
    switch (sound) {
      case MeditationSound.none:
        return '🔇';
      case MeditationSound.focus:
        return '🧠';
      case MeditationSound.relax:
        return '🌙';
    }
  }

  Future<void> startSessionAudio({
    required MeditationSound sound,
    required double volume,
  }) async {
    _volume = volume.clamp(0.0, 1.0);
    await MusicService().releaseForMeditationPlayback();
    await _cancelStartBellListener();

    final token = _sharedAudio.claimPlayback();
    _currentSound = sound;

    try {
      await _loadAndPlay(
        _source(
          assetPath: _bellAsset,
          id: 'meditation-bell-start',
          title: 'Session Bell',
          artist: 'Stillspace Meditation',
        ),
        label: 'start bell',
        loopMode: LoopMode.off,
        volume: 0.8,
      );

      if (sound != MeditationSound.none) {
        _startBellSub = _player.playerStateStream.listen((state) {
          if (!_sharedAudio.ownsPlayback(token)) {
            unawaited(_cancelStartBellListener());
            return;
          }
          if (state.processingState == ProcessingState.completed) {
            unawaited(_cancelStartBellListener());
            unawaited(_playAmbientForSession(sound, token));
          }
        });
      }
    } catch (e) {
      debugPrint('AudioService: Error starting session audio - $e');
      if (sound != MeditationSound.none) {
        unawaited(_playAmbientForSession(sound, token));
      }
    }
  }

  Future<void> playBell() async {
    await MusicService().releaseForMeditationPlayback();
    await _cancelStartBellListener();
    _sharedAudio.claimPlayback();

    try {
      await _loadAndPlay(
        _source(
          assetPath: _bellAsset,
          id: 'meditation-bell',
          title: 'Session Bell',
          artist: 'Stillspace Meditation',
        ),
        label: 'bell',
        loopMode: LoopMode.off,
        volume: 0.8,
      );
    } catch (e) {
      debugPrint('AudioService: Error playing bell - $e');
    }
  }

  Future<void> stopBell() async {
    await stop();
  }

  Future<void> playSound(MeditationSound sound) async {
    _currentSound = sound;

    if (sound == MeditationSound.none) {
      await stop();
      return;
    }

    final assetPath = _soundAssets[sound];
    if (assetPath == null) return;

    await MusicService().releaseForMeditationPlayback();
    await _cancelStartBellListener();
    final token = _sharedAudio.claimPlayback();
    await _playAmbientForSession(sound, token);
  }

  Future<void> _playAmbientForSession(MeditationSound sound, int token) async {
    if (!_sharedAudio.ownsPlayback(token)) return;

    final assetPath = _soundAssets[sound];
    if (assetPath == null) return;

    try {
      debugPrint('AudioService: Loading $sound from $assetPath');
      await _loadAndPlay(
        _source(
          assetPath: assetPath,
          id: 'meditation-${sound.name}',
          title: getSoundName(sound),
          artist: 'Stillspace Meditation',
        ),
        label: sound.name,
        loopMode: LoopMode.one,
        volume: _volume,
      );
    } catch (e) {
      debugPrint('AudioService: Error playing $sound - $e');
      _currentSound = MeditationSound.none;
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() {
    if (_currentSound != MeditationSound.none) {
      unawaited(_playWithoutBlocking(_player, _currentSound.name));
    }
    return Future.value();
  }

  Future<void> stop() async {
    await _cancelStartBellListener();
    _sharedAudio.claimPlayback();
    await _player.stop();
    _currentSound = MeditationSound.none;
  }

  Future<void> stopAll() async {
    await stop();
  }

  // Plays a one-shot guided audio file (e.g. Wim Hof). Note: just_audio's play()
  // future only resolves when playback ENDS, so we deliberately do not await it.
  Future<void> playGuided(String assetPath) async {
    await MusicService().releaseForMeditationPlayback();
    await _cancelStartBellListener();
    _sharedAudio.claimPlayback();
    _currentSound = MeditationSound.none;

    try {
      await _loadAndPlay(
        _source(
          assetPath: assetPath,
          id: 'meditation-guided-$assetPath',
          title: 'Guided Breathing',
          artist: 'Stillspace Meditation',
        ),
        label: 'guided $assetPath',
        loopMode: LoopMode.off,
        volume: 1.0,
      );
    } catch (e) {
      debugPrint('AudioService: Error playing guided $assetPath - $e');
    }
  }

  Future<void> pauseGuided() async {
    await _player.pause();
  }

  Future<void> resumeGuided() {
    unawaited(_playWithoutBlocking(_player, 'guided resume'));
    return Future.value();
  }

  Future<void> stopGuided() async {
    await stop();
  }

  Stream<Duration> get guidedPositionStream => _player.positionStream;
  Stream<PlayerState> get guidedStateStream => _player.playerStateStream;

  AudioSource _source({
    required String assetPath,
    required String id,
    required String title,
    required String artist,
  }) {
    return AudioSource.asset(
      assetPath,
      tag: MediaItem(
        id: id,
        title: title,
        album: 'Stillspace',
        artist: artist,
      ),
    );
  }

  Future<void> _loadAndPlay(
    AudioSource source, {
    required String label,
    required LoopMode loopMode,
    required double volume,
  }) async {
    await _player.setAudioSource(source);
    await _player.setLoopMode(loopMode);
    await _player.setVolume(volume);
    await _player.seek(Duration.zero);
    debugPrint('AudioService: Playing $label');
    unawaited(_playWithoutBlocking(_player, label));
  }

  Future<void> _playWithoutBlocking(AudioPlayer player, String label) {
    return player.play().catchError((Object e) {
      debugPrint('AudioService: Error during $label playback - $e');
    });
  }

  Future<void> _cancelStartBellListener() async {
    await _startBellSub?.cancel();
    _startBellSub = null;
  }

  void dispose() {
    _startBellSub?.cancel();
  }
}
