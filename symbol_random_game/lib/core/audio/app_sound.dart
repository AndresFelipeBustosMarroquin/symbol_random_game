import 'package:flutter/material.dart';

class AppSound {
  const AppSound({
    required this.name,
    required this.asset,
    this.icon = Icons.music_note_rounded,
  });

  final String name;

  final String asset;
  final IconData icon;
}