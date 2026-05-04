// SharedAudioPlayer - owns the single just_audio player used by background audio.
import 'package:just_audio/just_audio.dart';

class SharedAudioPlayer {
  static final SharedAudioPlayer _instance = SharedAudioPlayer._internal();
  factory SharedAudioPlayer() => _instance;
  SharedAudioPlayer._internal();

  final AudioPlayer player = AudioPlayer();
  int _playbackToken = 0;

  int claimPlayback() => ++_playbackToken;

  bool ownsPlayback(int token) => token == _playbackToken;
}
