import 'package:flutter/material.dart';

/// Un sonido que el usuario puede elegir.
class AppSound {
  const AppSound({
    required this.name,
    required this.asset,
    this.icon = Icons.music_note_rounded,
  });

  final String name;

  /// Ruta relativa a assets/ (ej: 'audio/classic.wav').
  final String asset;
  final IconData icon;
}