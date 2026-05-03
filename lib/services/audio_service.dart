// Audio service - manages ambient sounds and bell for meditation sessions
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

enum MeditationSound {
  none,
  focus,
  relax,
}

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _ambientPlayer = AudioPlayer();
  final AudioPlayer _bellPlayer = AudioPlayer();
  final AudioPlayer _guidedPlayer = AudioPlayer();
  MeditationSound _currentSound = MeditationSound.none;
  double _volume = 0.5;

  MeditationSound get currentSound => _currentSound;
  double get volume => _volume;
  bool get isPlaying => _ambientPlayer.playing;

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

  Future<void> playBell() async {
    try {
      await _bellPlayer.setAsset(_bellAsset);
      await _bellPlayer.setLoopMode(LoopMode.off);
      await _bellPlayer.setVolume(0.8);
      await _bellPlayer.seek(Duration.zero);
      await _bellPlayer.play();
      debugPrint('AudioService: Playing bell');
    } catch (e) {
      debugPrint('AudioService: Error playing bell - $e');
    }
  }

  Future<void> stopBell() async {
    await _bellPlayer.stop();
  }

  Future<void> playSound(MeditationSound sound) async {
    _currentSound = sound;

    if (sound == MeditationSound.none) {
      await stop();
      return;
    }

    final assetPath = _soundAssets[sound];
    if (assetPath == null) return;

    try {
      debugPrint('AudioService: Loading $sound from $assetPath');
      await _ambientPlayer.setAsset(assetPath);
      await _ambientPlayer.setLoopMode(LoopMode.one);
      await _ambientPlayer.setVolume(_volume);
      debugPrint('AudioService: Playing $sound at volume $_volume');
      await _ambientPlayer.play();
    } catch (e) {
      debugPrint('AudioService: Error playing $sound - $e');
      _currentSound = MeditationSound.none;
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _ambientPlayer.setVolume(_volume);
  }

  Future<void> pause() async {
    await _ambientPlayer.pause();
  }

  Future<void> resume() async {
    if (_currentSound != MeditationSound.none) {
      await _ambientPlayer.play();
    }
  }

  Future<void> stop() async {
    await _ambientPlayer.stop();
    _currentSound = MeditationSound.none;
  }

  Future<void> stopAll() async {
    await _ambientPlayer.stop();
    await _bellPlayer.stop();
    await _guidedPlayer.stop();
    _currentSound = MeditationSound.none;
  }

  // Plays a one-shot guided audio file (e.g. Wim Hof). Note: just_audio's play()
  // future only resolves when playback ENDS, so we deliberately do not await it.
  Future<void> playGuided(String assetPath) async {
    try {
      await _guidedPlayer.setAsset(assetPath);
      await _guidedPlayer.setLoopMode(LoopMode.off);
      await _guidedPlayer.setVolume(1.0);
      await _guidedPlayer.seek(Duration.zero);
      unawaited(_guidedPlayer.play());
    } catch (e) {
      debugPrint('AudioService: Error playing guided $assetPath - $e');
    }
  }

  Future<void> pauseGuided() async {
    await _guidedPlayer.pause();
  }

  Future<void> resumeGuided() async {
    await _guidedPlayer.play();
  }

  Future<void> stopGuided() async {
    await _guidedPlayer.stop();
  }

  Stream<Duration> get guidedPositionStream => _guidedPlayer.positionStream;
  Stream<PlayerState> get guidedStateStream => _guidedPlayer.playerStateStream;

  void dispose() {
    _ambientPlayer.dispose();
    _bellPlayer.dispose();
    _guidedPlayer.dispose();
  }
}
