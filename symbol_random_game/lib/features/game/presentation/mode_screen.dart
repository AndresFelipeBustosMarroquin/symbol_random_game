import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/features/game/domain/game_mode.dart';
import 'package:symbol_random_game/features/game/presentation/game_screen.dart';
import 'package:symbol_random_game/features/game/presentation/versus_screen.dart';
import 'package:symbol_random_game/shared/static_background.dart';

class _ModeData {
  const _ModeData(
    this.mode,
    this.icon,
    this.title,
    this.description,
    this.difficulty,
  );

  final GameMode mode;
  final IconData icon;
  final String title;
  final String description;
  final int difficulty;
}

const _modes = [
  _ModeData(
    GameMode.numbers,
    Icons.pin_rounded,
    'NÚMEROS',
    'Secuencias numéricas',
    1,
  ),
  _ModeData(
    GameMode.characters,
    Icons.text_fields_rounded,
    'CARACTERES',
    'Letras y números',
    2,
  ),
  _ModeData(
    GameMode.symbols,
    Icons.tag_rounded,
    'SÍMBOLOS',
    'Diferentes símbolos',
    3,
  ),
  _ModeData(
    GameMode.operations,
    Icons.calculate_rounded,
    'OPERACIONES',
    'Cálculo de básico a avanzado',
    3,
  ),
];

const _pagePadding = 28.0;
const _sidePadding = _pagePadding - 12;
const _gap = 12.0;
const _maxContentWidth = 680.0;

const _arrowSlot = 48.0;

class ModeScreen extends StatefulWidget {
  const ModeScreen({super.key, this.versus = false, this.userId});

  final bool versus;
  final int? userId;

  @override
  State<ModeScreen> createState() => _ModeScreenState();
}

class _ModeScreenState extends State<ModeScreen> {
  int? _selected;

  void _select(int index) {
    HapticFeedback.selectionClick();

    setState(() {
      _selected = _selected == index ? null : index;
    });
  }

  void _continue(int? index) {
    if (index == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          final mode = _modes[index].mode;

          if (widget.versus) {
            return VersusScreen(mode: mode, userId: widget.userId);
          }

          final userId = widget.userId;
          if (userId == null) {
            throw StateError(
              'No hay una cuenta activa para guardar la partida.',
            );
          }

          return GameScreen(mode: mode, userId: userId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFontBuilder(
      builder: (context) => Scaffold(
        body: StaticAppBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktopLayout(context) ? 960 : _maxContentWidth,
                ),
                child: LayoutBuilder(
                  builder: (context, box) => _buildContent(box),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BoxConstraints box) {
    final versus = widget.versus;

    const outerSide = 12.0;
    const sectionGap = 20.0;
    const headerGap = 12.0;
    final desktop = isDesktopLayout(context);
    final breathing = desktop ? 12.0 : (versus ? 20.0 : 28.0);

    final side = versus ? _sidePadding + 12 : _sidePadding;

    final headerHeight = versus ? 56.0 : 112.0;
    final paletteHeight = versus ? 80.0 : 0.0;
    final buttonHeight = versus ? 48.0 : 58.0;

    final tileRatio = versus ? 0.68 : 0.85;
    final minTileHeight = versus ? 80.0 : (desktop ? 110.0 : 175.0);

    final tileWidth = (box.maxWidth - outerSide * 2 - side * 2 - _gap) / 2;

    final reserved =
        headerHeight +
        headerGap +
        sectionGap +
        buttonHeight +
        (versus ? paletteHeight + sectionGap : 0) +
        breathing * 2;
    final maxByScreen = math.max(
      0.0,
      (box.maxHeight - reserved - _gap - 16) / 2,
    );
    final preferredTileHeight = math.min(tileWidth * tileRatio, maxByScreen);
    final tileHeight = preferredTileHeight >= minTileHeight
        ? preferredTileHeight
        : maxByScreen;
    final cardsHeight = tileHeight * 2 + _gap;

    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: outerSide, vertical: breathing),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ModeHeader(versus: versus),
            const SizedBox(height: headerGap),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: side),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: cardsHeight,
                    child: _buildCards(compact: versus),
                  ),
                  if (versus) ...[
                    const SizedBox(height: sectionGap),
                    SizedBox(
                      height: paletteHeight,
                      child: _PlayerPalettes(
                        compact: true,
                        onSelect: (player, index) {
                          HapticFeedback.selectionClick();
                          setState(() => PlayerPalettes.select(player, index));
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: sectionGap),
                  _ContinueButton(
                    enabled: _selected != null,
                    compact: versus,
                    onTap: () => _continue(_selected),
                  ),
                ],
              ),
            ),
          ],
        ),
    );

    return Center(
      child: versus || desktop
          ? content
          : SingleChildScrollView(
              child: content,
            ),
    );
  }

  Widget _buildCards({required bool compact}) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final tileWidth = (constraints.maxWidth - _gap) / 2;
        final tileHeight = (constraints.maxHeight - _gap) / 2;
        final aspectRatio = tileWidth / tileHeight;
        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: _gap,
          mainAxisSpacing: _gap,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: [
            for (final (index, mode) in _modes.indexed)
              _ModeCard(
                data: mode,
                isSelected: _selected == index,
                compact: compact,
                onTap: () => _select(index),
              ),
          ],
        );
      },
    );
  }
}

class _ModeHeader extends StatelessWidget {
  const _ModeHeader({required this.versus});

  final bool versus;

  @override
  Widget build(BuildContext context) {
    return AppFontBuilder(
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const _BackArrow(),

                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: GradientText(
                        versus ? 'ELIGE EL DUELO' : 'ELIGE TU DESAFÍO',
                        style: AppText.display(
                          fontSize: 40,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: _arrowSlot),
              ],
            ),
          ),

          if (!versus) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
              child: Text(
                'Selecciona el tipo de elementos que aparecerán en el juego',
                textAlign: TextAlign.center,
                style: AppText.label(
                  color: Colors.white60,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BackArrow extends StatelessWidget {
  const _BackArrow();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).maybePop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: Colors.white,
      iconSize: 22,
      tooltip: 'Volver',
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.onTap,
    required this.enabled,
    required this.compact,
  });

  final VoidCallback onTap;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: compact ? 48 : 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.primaryGradient : null,
        color: enabled ? null : AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: enabled
              ? Colors.transparent
              : AppColors.primary.withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 200),
        style: AppText.title(
          color: enabled ? Colors.white : Colors.white30,
          fontSize: 17,
          letterSpacing: 2,
        ),
        child: const Text('CONTINUAR'),
      ),
    );

    if (!enabled) {
      return button;
    }

    return PressableScale(onTap: onTap, child: button);
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.data,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  final _ModeData data;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(compact ? 18 : 24),
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.34),
                    AppColors.primary.withValues(alpha: 0.12),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.card.withValues(alpha: 0.78),
          border: Border.all(
            color: isSelected
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.58),
            width: isSelected ? 2.2 : 1.4,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: compact ? 6 : 12,
                right: compact ? 6 : 12,
                child: Container(
                  width: compact ? 22 : 28,
                  height: compact ? 22 : 28,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.primary,
                    size: compact ? 15 : 18,
                  ),
                ),
              ),

            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 6 : (isSelected ? 12 : 8),
                  vertical: compact ? 4 : 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: compact ? 42 : (isSelected ? 72 : 60),
                      height: compact ? 42 : (isSelected ? 72 : 60),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.13)
                            : AppColors.primary.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(
                          compact ? 13 : (isSelected ? 20 : 17),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        data.icon,
                        size: compact ? 25 : (isSelected ? 40 : 32),
                        color: isSelected
                            ? Colors.white
                            : AppColors.primaryLight,
                      ),
                    ),

                    SizedBox(height: compact ? 4 : 12),

                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title(
                        fontSize: compact ? 13 : (isSelected ? 19 : 16),
                        letterSpacing: 0.6,
                      ),
                    ),

                    if (!compact) ...[
                      const SizedBox(height: 7),
                      Text(
                        data.description,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.80)
                              : Colors.white.withValues(alpha: 0.55),
                          fontSize: isSelected ? 12 : 10,
                          height: 1.25,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else
                      const SizedBox(height: 5),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (index) {
                        final active = index < data.difficulty;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Container(
                            width: compact ? 7 : (isSelected ? 10 : 9),
                            height: compact ? 7 : (isSelected ? 10 : 9),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: active
                                  ? AppColors.primaryLight
                                  : Colors.white24,
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerPalettes extends StatelessWidget {
  const _PlayerPalettes({required this.onSelect, required this.compact});

  final void Function(int player, int index) onSelect;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: _gap,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var player = 0; player < 2; player++)
          Expanded(
            child: _PlayerPaletteTile(
              player: player,
              compact: compact,
              onChanged: (index) => onSelect(player, index),
            ),
          ),
      ],
    );
  }
}

class _PlayerPaletteTile extends StatelessWidget {
  const _PlayerPaletteTile({
    required this.player,
    required this.compact,
    required this.onChanged,
  });

  final int player;
  final bool compact;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = PlayerPalettes.indexOf(player);

    final palette = PlayerPalettes.of(player);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(compact ? 7 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withValues(alpha: 0.30),
            palette.card.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(
          color: palette.primaryLight.withValues(alpha: 0.7),
          width: 1.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 24 : 30,
                height: compact ? 24 : 30,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: compact ? 15 : 18,
                  color: palette.primaryLight,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  'Jugador ${player + 1}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(
                    fontSize: compact ? 12 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 6 : 10),

          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedIndex,
              isExpanded: true,
              isDense: true,
              dropdownColor: palette.card,
              borderRadius: BorderRadius.circular(16),
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: palette.primaryLight,
              ),
              style: AppText.label(
                color: Colors.white,
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
              selectedItemBuilder: (context) {
                return AppColors.palettes.map((item) {
                  return Row(
                    children: [
                      _PaletteSwatches(palette: item),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(item.name, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  );
                }).toList();
              },
              items: List.generate(AppColors.palettes.length, (index) {
                final item = AppColors.palettes[index];

                final taken = PlayerPalettes.isTaken(player, index);

                return DropdownMenuItem<int>(
                  value: index,
                  enabled: !taken,
                  child: Opacity(
                    opacity: taken ? 0.35 : 1,
                    child: Row(
                      children: [
                        _PaletteSwatches(palette: item),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item.name)),
                        if (selectedIndex == index)
                          Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: palette.primaryLight,
                          ),
                      ],
                    ),
                  ),
                );
              }),
              onChanged: (index) {
                if (index != null) {
                  onChanged(index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteSwatches extends StatelessWidget {
  const _PaletteSwatches({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Swatch(color: palette.bgTop),
        _Swatch(color: palette.primary),
        _Swatch(color: palette.primaryLight),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 11,
      height: 18,
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.top = 8, this.left = 8});

  final double top;
  final double left;

  @override
  Widget build(BuildContext context) {
    return Positioned(top: top, left: left, child: const _BackArrow());
  }
}