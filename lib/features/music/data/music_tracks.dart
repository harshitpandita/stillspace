// Music catalog - reuses existing audio assets, designed so adding new tracks
// (piano, additional frequencies) is just a matter of dropping a file in
// assets/audio/ and appending an entry to `all`.
import 'package:flutter/material.dart';
import '../models/music_track.dart';

class MusicTracks {
  static const brownNoise = MusicTrack(
    id: 'brown_noise',
    title: 'Brown Noise',
    description: 'Deep ambient noise for relaxation and sleep',
    assetPath: 'assets/audio/brown-noise-relaxing.mp3',
    icon: Icons.nightlight_outlined,
    category: 'Ambient',
  );

  static const focus25Hz = MusicTrack(
    id: 'focus_2_5_hz',
    title: '2.5 Hz Binaural',
    description: 'Low-frequency binaural beats for deep focus',
    assetPath: 'assets/audio/2.5-hz-focus.mp3',
    icon: Icons.psychology_outlined,
    category: 'Frequencies',
  );

  static const List<MusicTrack> all = [brownNoise, focus25Hz];

  static List<String> get categories =>
      all.map((t) => t.category).toSet().toList();

  static List<MusicTrack> byCategory(String category) =>
      all.where((t) => t.category == category).toList();
}
