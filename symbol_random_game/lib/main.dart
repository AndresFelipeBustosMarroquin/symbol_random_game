import 'package:flutter/material.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/features/auth/presentation/login_screen.dart';

void main() {
  runApp(const RandomGameApp());
}

class RandomGameApp extends StatelessWidget {
  const RandomGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppColors.paletteNotifier,
      builder: (context, paletteIndex, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.bgBottom,
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.primaryLight,
              surface: AppColors.card,
            ),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}
