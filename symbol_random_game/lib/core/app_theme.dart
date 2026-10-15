import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppPalette {
  final String name;
  final Color bgTop;
  final Color bgBottom;
  final Color primary;
  final Color primaryLight;
  final Color card;
  final Color success;

  const AppPalette({
    required this.name,
    required this.bgTop,
    required this.bgBottom,
    required this.primary,
    required this.primaryLight,
    required this.card,
    required this.success,
  });
}

class AppColors {
  AppColors._();

  static const List<AppPalette> palettes = [
    AppPalette(
      name: 'Violeta',
      bgTop: Color(0xFF10152F),
      bgBottom: Color(0xFF090B18),
      primary: Color(0xFF5B5FEF),
      primaryLight: Color(0xFF8E9BFF),
      card: Color(0xFF171D3D),
      success: Color(0xFF4ADE80),
    ),
    AppPalette(
      name: 'Océano',
      bgTop: Color(0xFF082B3A),
      bgBottom: Color(0xFF04151F),
      primary: Color(0xFF0891B2),
      primaryLight: Color(0xFF67E8F9),
      card: Color(0xFF103747),
      success: Color(0xFF5EEAD4),
    ),
    AppPalette(
      name: 'Esmeralda',
      bgTop: Color(0xFF092C25),
      bgBottom: Color(0xFF041710),
      primary: Color(0xFF059669),
      primaryLight: Color(0xFF6EE7B7),
      card: Color(0xFF103A30),
      success: Color(0xFFA3E635),
    ),
    AppPalette(
      name: 'Atardecer',
      bgTop: Color(0xFF35162D),
      bgBottom: Color(0xFF170B1B),
      primary: Color(0xFFE0528A),
      primaryLight: Color(0xFFFFA3C7),
      card: Color(0xFF401D36),
      success: Color(0xFFFDA4AF),
    ),
    AppPalette(
      name: 'Ámbar',
      bgTop: Color(0xFF34220D),
      bgBottom: Color(0xFF170F07),
      primary: Color(0xFFD97706),
      primaryLight: Color(0xFFFCD34D),
      card: Color(0xFF402B15),
      success: Color(0xFFA3E635),
    ),
    AppPalette(
      name: 'Rojo',
      bgTop: Color(0xFF351416),
      bgBottom: Color(0xFF180809),
      primary: Color(0xFFDC2626),
      primaryLight: Color(0xFFFCA5A5),
      card: Color(0xFF421B20),
      success: Color(0xFFFDE047),
    ),
  ];

  static final ValueNotifier<int> paletteNotifier = ValueNotifier<int>(0);

  static int get selectedIndex => paletteNotifier.value;

  static AppPalette get current => palettes[selectedIndex];

  static void selectPalette(int index) {
    paletteNotifier.value = index.clamp(0, palettes.length - 1);
  }

  static Color get bgTop => current.bgTop;
  static Color get bgBottom => current.bgBottom;
  static Color get primary => current.primary;
  static Color get primaryLight => current.primaryLight;
  static Color get card => current.card;
  static Color get success => current.success;

  static LinearGradient get background {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [bgTop, bgBottom],
    );
  }

  static LinearGradient get primaryGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryLight, primary],
    );
  }
}

extension AppPaletteX on AppPalette {
  LinearGradient get gradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [primaryLight, primary],
    );
  }
}

class PlayerPalettes {
  PlayerPalettes._();

  static final List<int> _selected = [0, 4];

  static int indexOf(int player) => _selected[player];

  static AppPalette of(int player) => AppColors.palettes[_selected[player]];

  static bool isTaken(int player, int index) => _selected[1 - player] == index;

  static void select(int player, int index) {
    if (index < 0 || index >= AppColors.palettes.length) return;
    if (isTaken(player, index)) return;

    _selected[player] = index;
  }
}

class AnimatedAppBackground extends StatefulWidget {
  final Widget child;

  const AnimatedAppBackground({super.key, required this.child});

  @override
  State<AnimatedAppBackground> createState() => _AnimatedAppBackgroundState();
}

class _AnimatedAppBackgroundState extends State<AnimatedAppBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: AppColors.background),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value * 2 * math.pi;

              return Stack(
                children: [
                  _orb(
                    top: 70 + 25 * math.sin(t),
                    left: -70 + 35 * math.cos(t),
                    size: 230,
                    color: AppColors.primary.withValues(alpha: 0.20),
                  ),
                  _orb(
                    bottom: 30 + 30 * math.cos(t),
                    right: -80 + 25 * math.sin(t),
                    size: 270,
                    color: AppColors.primaryLight.withValues(alpha: 0.14),
                  ),
                ],
              );
            },
          ),
          Positioned.fill(child: widget.child),
        ],
      ),
    );
  }

  Widget _orb({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const PressableScale({super.key, required this.child, this.onTap});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() {
            _scale = 0.95;
          });
        },
        onTapUp: (_) {
          setState(() {
            _scale = 1;
          });
        },
        onTapCancel: () {
          setState(() {
            _scale = 1;
          });
        },
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient? gradient;

  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final currentGradient = gradient ?? AppColors.primaryGradient;

    return ShaderMask(
      shaderCallback: (bounds) {
        return currentGradient.createShader(bounds);
      },
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
