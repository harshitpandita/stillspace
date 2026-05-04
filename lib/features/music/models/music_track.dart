// MusicTrack - data model for in-app background music selections
import 'package:flutter/material.dart';

class MusicTrack {
  final String id;
  final String title;
  final String description;
  final String assetPath;
  final IconData icon;
  final String category;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.description,
    required this.assetPath,
    required this.icon,
    required this.category,
  });
}
