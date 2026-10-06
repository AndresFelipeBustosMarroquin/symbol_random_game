import 'package:flutter/material.dart';
import 'package:symbol_random_game/core/app_theme.dart';

enum PauseAction { resume, restart, menu, options, score }

class PausePanel extends StatelessWidget {
  const PausePanel({
    super.key,
    this.gameOver = false,
    this.score,
    this.saveError,
  });

  final bool gameOver;
  final int? score;
  final String? saveError;

  @override
  Widget build(BuildContext context) {
    void pick(PauseAction action) {
      Navigator.of(context).pop(action);
    }

    return AlertDialog(
      scrollable: true,
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        gameOver ? 'GAME OVER' : 'PAUSA',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 3,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (gameOver && score != null) ...[
            Text(
              'RONDAS SUPERADAS: $score',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (saveError != null) ...[
            Text(
              'No se pudo guardar el resultado.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
            Text(
              saveError!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            const SizedBox(height: 8),
          ],
          if (!gameOver) ...[
            _PauseOption(
              icon: Icons.play_arrow_rounded,
              label: 'REANUDAR',
              filled: true,
              onTap: () => pick(PauseAction.resume),
            ),
            const SizedBox(height: 10),
          ],
          _PauseOption(
            icon: Icons.refresh_rounded,
            label: 'REINICIAR',
            onTap: () => pick(PauseAction.restart),
          ),
          const SizedBox(height: 10),
          _PauseOption(
            icon: Icons.home_rounded,
            label: 'MENÚ',
            onTap: () => pick(PauseAction.menu),
          ),
          const SizedBox(height: 10),
          _PauseOption(
            icon: Icons.settings_rounded,
            label: 'OPCIONES',
            onTap: () => pick(PauseAction.options),
          ),
          const SizedBox(height: 10),
          _PauseOption(
            icon: Icons.emoji_events_rounded,
            label: 'PUNTUACIÓN',
            onTap: () => pick(PauseAction.score),
          ),
        ],
      ),
    );
  }
}

class _PauseOption extends StatelessWidget {
  const _PauseOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? AppColors.primaryGradient : null,
          color: filled ? null : AppColors.bgBottom.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(15),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.primary.withValues(alpha: 0.58),
                  width: 1.4,
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : AppColors.primaryLight,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
