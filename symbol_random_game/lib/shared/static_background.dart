import 'package:flutter/material.dart';
import 'package:symbol_random_game/core/app_theme.dart';

/// Fondo estático: degradado + dos brillos suaves, igual que el animado
/// pero sin ningún controlador ni animación.
///
/// - Se dibuja una sola vez (RepaintBoundary): lo que pasa encima
///   (timer, teclado, etc.) no lo vuelve a pintar.
/// - Los brillos son RadialGradient, sin blur ni filtros costosos.
/// - Sigue la paleta elegida en Opciones.
class StaticAppBackground extends StatelessWidget {
  const StaticAppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppColors.paletteNotifier,
      // El `child` pasa por aquí para no reconstruir la pantalla entera
      // cuando cambia la paleta: solo se repinta el fondo.
      child: child,
      builder: (context, _, child) {
        final bgTop = AppColors.palettes[AppColors.selectedIndex].bgTop;

        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bgTop, AppColors.bgBottom],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Brillo arriba a la izquierda
                    _Glow(
                      alignment: const Alignment(-1, -0.57),
                      shift: const Offset(-140, 0),
                      size: 360,
                      color: AppColors.primary.withValues(alpha: 0.30),
                    ),
                    // Brillo abajo a la derecha
                    _Glow(
                      alignment: const Alignment(1, 0.67),
                      shift: const Offset(160, 0),
                      size: 480,
                      color: AppColors.primary.withValues(alpha: 0.16),
                    ),
                  ],
                ),
              ),
            ),
            child!,
          ],
        );
      },
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.alignment,
    required this.shift,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final Offset shift;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: alignment,
        child: Transform.translate(
          offset: shift,
          child: SizedBox(
            width: size,
            height: size,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color, color.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
