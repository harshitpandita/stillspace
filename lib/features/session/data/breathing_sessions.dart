// Catalog of available breathing sessions - add new sessions here as they're built
import 'package:flutter/material.dart';
import '../models/breathing_session.dart';

class BreathingSessions {
  static const wimHof = BreathingSession(
    id: 'wim_hof',
    title: 'Wim Hof Breathing',
    shortLabel: 'Wim Hof',
    description: 'Guided power breathing for energy and stress relief',
    audioAsset: 'assets/audio/wim-hof.mp3',
    durationSeconds: 630, // 10 minutes 30 seconds
    streakMinutes: 10,
    icon: Icons.air,
    emoji: '🌬️',
  );

  static const List<BreathingSession> all = [wimHof];

  static BreathingSession? byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}
