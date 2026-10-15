import 'package:flutter/material.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';

enum AppSnackType { success, error, info }

abstract final class AppSnack {
  static void success(
    BuildContext context, {
    required String message,
    String title = '¡LISTO!',
  }) {
    _show(context, AppSnackType.success, title, message);
  }

  static void error(
    BuildContext context, {
    required String message,
    String title = 'ALGO SALIÓ MAL',
  }) {
    _show(context, AppSnackType.error, title, message);
  }

  static void info(
    BuildContext context, {
    required String message,
    String title = 'AVISO',
  }) {
    _show(context, AppSnackType.info, title, message);
  }

  static void _show(
    BuildContext context,
    AppSnackType type,
    String title,
    String message,
  ) {
    final messenger = ScaffoldMessenger.of(context);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          duration: const Duration(milliseconds: 3800),
          dismissDirection: DismissDirection.horizontal,
          content: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _SnackCard(type: type, title: title, message: message),
            ),
          ),
        ),
      );
  }
}

class _SnackCard extends StatelessWidget {
  const _SnackCard({
    required this.type,
    required this.title,
    required this.message,
  });

  final AppSnackType type;
  final String title;
  final String message;

  Color get _color => switch (type) {
    AppSnackType.success => AppColors.success,
    AppSnackType.error => Colors.redAccent,
    AppSnackType.info => AppColors.primaryLight,
  };

  IconData get _icon => switch (type) {
    AppSnackType.success => Icons.check_circle_rounded,
    AppSnackType.error => Icons.error_rounded,
    AppSnackType.info => Icons.info_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color.alphaBlend(color.withValues(alpha: 0.22), AppColors.card),
                AppColors.card.withValues(alpha: 0.97),
              ],
            ),
            border: Border.all(
              color: color.withValues(alpha: 0.55),
              width: 1.3,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.title(
                                  color: color,
                                  fontSize: 13,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                message,
                                style: AppText.label(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
