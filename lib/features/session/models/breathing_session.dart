// BreathingSession - data model for guided breathing exercises (e.g. Wim Hof)
import 'package:flutter/material.dart';

class BreathingSession {
  final String id;
  final String title;
  final String shortLabel;
  final String description;
  final String audioAsset;
  final int durationSeconds;
  final int streakMinutes;
  final IconData icon;
  final String emoji;

  const BreathingSession({
    required this.id,
    required this.title,
    required this.shortLabel,
    required this.description,
    required this.audioAsset,
    required this.durationSeconds,
    required this.streakMinutes,
    required this.icon,
    required this.emoji,
  });
}
