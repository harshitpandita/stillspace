// Audio service - manages ambient sounds for meditation sessions using local assets
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

  final AudioPlayer _player = AudioPlayer();
  MeditationSound _currentSound = MeditationSound.none;
  double _volume = 0.5;

  MeditationSound get currentSound => _currentSound;
  double get volume => _volume;
  bool get isPlaying => _player.playing;

  static const Map<MeditationSound, String> _soundAssets = {
    MeditationSound.focus: 'assets/audio/2.5-hz-focus.mp3',
    MeditationSound.relax: 'assets/audio/brown-noise-relaxing.mp3',
  };

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
      await _player.setAsset(assetPath);
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_volume);
      debugPrint('AudioService: Playing $sound at volume $_volume');
      await _player.play();
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

  Future<void> resume() async {
    if (_currentSound != MeditationSound.none) {
      await _player.play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSound = MeditationSound.none;
  }

  void dispose() {
    _player.dispose();
  }
}
