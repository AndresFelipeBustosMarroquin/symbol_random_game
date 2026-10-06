import 'package:flutter/material.dart';
import 'package:symbol_random_game/core/app_fonts.dart';

/// Tipografía centralizada del juego.
///
/// Todos los estilos usan la fuente seleccionada en [AppFonts].
/// Cada rol mantiene su tamaño, peso y color por defecto:
/// - [display] -> secuencias, puntajes, rondas, input (cifras tabulares).
/// - [title]   -> títulos, botones, mensajes.
/// - [label]   -> etiquetas pequeñas y subtítulos (cifras tabulares).
abstract final class AppText {
  static const _tabular = [FontFeature.tabularFigures()];

  static TextStyle display({
    Color color = Colors.white,
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w800,
    double? letterSpacing,
    double? height,
  }) {
    return AppFonts.style(
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontFeatures: _tabular,
      ),
    );
  }

  static TextStyle title({
    Color color = Colors.white,
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w800,
    double? letterSpacing,
    double? height,
  }) {
    return AppFonts.style(
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      ),
    );
  }

  static TextStyle label({
    Color color = Colors.white70,
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    double? letterSpacing,
    double? height,
  }) {
    return AppFonts.style(
      TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        fontFeatures: _tabular,
      ),
    );
  }
}
