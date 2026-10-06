import 'dart:async';

import 'package:flutter/material.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/audio/audio_manager.dart';
import 'package:symbol_random_game/core/config/app_config.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/features/settings/configuracion_model.dart';
import 'package:symbol_random_game/features/settings/configuracion_service.dart';
import 'package:symbol_random_game/shared/app_snack.dart';
import 'package:symbol_random_game/shared/static_background.dart';

class OptionsScreen extends StatefulWidget {
  final bool preGame;
  final int? userId;

  const OptionsScreen({super.key, this.preGame = false, this.userId});

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

class _OptionsScreenState extends State<OptionsScreen> {
  static const double _maxContentWidth = 520;
  static const double _gap = 14;
  static const double _headerTopGap = 64;

  final _configuracionService = ConfiguracionService();
  late double _volume;
  late int _selectedPalette;
  late int _selectedSound;
  Timer? _volumeSaveTimer;
  Future<void> _saveQueue = Future<void>.value();

  @override
  void dispose() {
    if (_volumeSaveTimer?.isActive ?? false) {
      _volumeSaveTimer!.cancel();
      _persistSettings();
    }
    super.dispose();
  }

  void _persistSettings({bool debounce = false}) {
    final userId = widget.userId;
    if (userId == null) return;

    _volumeSaveTimer?.cancel();
    if (debounce) {
      _volumeSaveTimer = Timer(
        const Duration(milliseconds: 400),
        _persistSettings,
      );
      return;
    }

    final config = ConfiguracionUsuario.actual();
    final save = _saveQueue.then(
      (_) => _configuracionService.guardar(userId, config),
    );
    _saveQueue = save.catchError((Object error) {
      debugPrint('No se pudieron guardar las preferencias: $error');
      if (mounted) {
        AppSnack.error(
          context,
          title: 'PREFERENCIAS NO GUARDADAS',
          message: 'No se pudieron sincronizar tus opciones con la cuenta.',
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _volume = GameSettings.volume * 100;
    _selectedPalette = AppColors.selectedIndex;
    _selectedSound = AudioManager.selectedIndex;
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
                  maxWidth: isDesktopLayout(context) ? 760 : _maxContentWidth,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: isDesktopLayout(context) ? 12 : _headerTopGap,
                      ),

                      const _OptionsHeader(),

                      SizedBox(height: isDesktopLayout(context) ? 12 : 26),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 600
                                    ? 3
                                    : 2;
                                final tileWidth =
                                    (constraints.maxWidth -
                                        _gap * (columns - 1)) /
                                    columns;
                                return Wrap(
                                  spacing: _gap,
                                  runSpacing: _gap,
                                  children: [
                                    SizedBox(
                                      width: tileWidth,
                                      child: _StepperTile(
                                        icon: Icons.add_circle_outline_rounded,
                                        title: 'Incremento',
                                        value: GameSettings.increment,
                                        min: GameSettings.minValue,
                                        max: GameSettings.maxValue,
                                        onChanged: (v) {
                                          setState(() {
                                            GameSettings.increment = v;
                                          });
                                          _persistSettings();
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: tileWidth,
                                      child: _StepperTile(
                                        icon: Icons.favorite_rounded,
                                        title: 'Vidas',
                                        value: GameSettings.hearts,
                                        min: GameSettings.minValue,
                                        max: GameSettings.maxValue,
                                        onChanged: (v) {
                                          setState(() {
                                            GameSettings.hearts = v;
                                          });
                                          _persistSettings();
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: tileWidth,
                                      child: _StepperTile(
                                        icon: Icons.timer_rounded,
                                        title: 'Tiempo',
                                        suffix: 's',
                                        value: GameSettings.time,
                                        min: GameSettings.minTime,
                                        max: GameSettings.maxTime,
                                        onChanged: (v) {
                                          setState(() {
                                            GameSettings.time = v;
                                          });
                                          _persistSettings();
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: _gap),

                            Row(
                              spacing: _gap,
                              children: [
                                Expanded(
                                  child: _PaletteTile(
                                    selectedIndex: _selectedPalette,
                                    onChanged: (index) {
                                      setState(() {
                                        _selectedPalette = index;
                                      });

                                      AppColors.selectPalette(index);
                                      _persistSettings();
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _SoundTile(
                                    selectedIndex: _selectedSound,
                                    onChanged: (index) {
                                      setState(() {
                                        _selectedSound = index;
                                      });

                                      AudioManager.select(index);
                                      AudioManager.play();
                                      _persistSettings();
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: _gap),

                            SizedBox(
                              width: double.infinity,
                              child: _VolumeTile(
                                value: _volume,
                                onChanged: (v) {
                                  setState(() {
                                    _volume = v;
                                  });

                                  GameSettings.setVolume(v / 100);
                                  _persistSettings(debounce: true);
                                },
                              ),
                            ),

                            const SizedBox(height: _gap),

                            SizedBox(
                              width: double.infinity,
                              child: _FontTile(
                                selectedIndex: AppFonts.selectedIndex,
                                onChanged: (index) {
                                  AppFonts.select(index);
                                  _persistSettings();
                                },
                              ),
                            ),

                            if (widget.preGame) ...[
                              const SizedBox(height: _gap + 6),

                              SizedBox(
                                width: double.infinity,
                                child: _PlayButton(
                                  onTap: () {
                                    Navigator.of(context).pop<bool>(true);
                                  },
                                ),
                              ),
                            ],

                            SizedBox(
                              height: isDesktopLayout(context) ? 12 : 40,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Encabezado
// ─────────────────────────────────────────────────────────────────────────

const double _arrowSlot = 48;

class _OptionsHeader extends StatelessWidget {
  const _OptionsHeader();

  @override
  Widget build(BuildContext context) {
    // Escucha la fuente por su cuenta: al ser `const`, el padre no lo
    // reconstruiría cuando cambie la tipografía.
    return AppFontBuilder(
      builder: (context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const _BackArrow(),

                Expanded(
                  child: Text(
                    'OPCIONES',
                    textAlign: TextAlign.center,
                    style: AppText.display(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(width: _arrowSlot),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Personaliza tu experiencia de juego',
              textAlign: TextAlign.center,
              style: AppText.label(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ),
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
      onPressed: () {
        Navigator.of(context).maybePop();
      },
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: Colors.white,
      iconSize: 22,
      tooltip: 'Volver',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Decoración
// ─────────────────────────────────────────────────────────────────────────

BoxDecoration _tileDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primary.withValues(alpha: 0.30),
        AppColors.card.withValues(alpha: 0.92),
      ],
    ),
    border: Border.all(
      color: AppColors.primaryLight.withValues(alpha: 0.35),
      width: 1.2,
    ),
  );
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;

  const _IconBadge({required this.icon})
    : radius = 13,
      size = 38,
      iconSize = 21;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: AppColors.primaryLight),
    );
  }
}

class _TileShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final double height;

  const _TileShell({
    required this.icon,
    required this.title,
    required this.child,
  }) : height = 140;

  @override
  Widget build(BuildContext context) {
    final tileHeight = MediaQuery.sizeOf(context).width < 600 ? 156.0 : height;
    return Container(
      height: tileHeight,
      padding: const EdgeInsets.all(14),
      decoration: _tileDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconBadge(icon: icon),

          const Spacer(),

          Text(
            title,
            style: AppText.title(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),

          const SizedBox(height: 8),

          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Stepper
// ─────────────────────────────────────────────────────────────────────────

class _StepperTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String suffix;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepperTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return _TileShell(
      icon: icon,
      title: title,
      child: Row(
        children: [
          _RoundButton(
            icon: Icons.remove_rounded,
            enabled: value > min,
            onTap: () {
              onChanged(value - 1);
            },
          ),

          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$value$suffix',
                  style: AppText.display(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),

          _RoundButton(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () {
              onChanged(value + 1);
            },
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RoundButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: enabled ? 0.12 : 0.05),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primaryLight : Colors.white24,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Paletas
// ─────────────────────────────────────────────────────────────────────────

class _PaletteTile extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _PaletteTile({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _TileShell(
      icon: Icons.palette_outlined,
      title: 'Paletas',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedIndex,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryLight,
          ),
          style: AppText.label(
            color: Colors.white,
            fontSize: 14,
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

            return DropdownMenuItem<int>(
              value: index,
              child: Row(
                children: [
                  _PaletteSwatches(palette: item),

                  const SizedBox(width: 10),

                  Expanded(child: Text(item.name)),

                  if (selectedIndex == index)
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                ],
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
    );
  }
}

class _PaletteSwatches extends StatelessWidget {
  final AppPalette palette;

  const _PaletteSwatches({required this.palette});

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
  final Color color;

  const _Swatch({required this.color});

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

// ─────────────────────────────────────────────────────────────────────────
// Sonido
// ─────────────────────────────────────────────────────────────────────────

class _SoundTile extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SoundTile({required this.selectedIndex, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const sounds = AudioManager.sounds;

    return _TileShell(
      icon: Icons.music_note_rounded,
      title: 'Sonido',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedIndex,
          isExpanded: true,
          isDense: true,
          dropdownColor: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.primaryLight,
          ),
          style: AppText.label(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          selectedItemBuilder: (context) {
            return sounds.map((item) {
              return Row(
                children: [
                  Icon(item.icon, size: 18, color: AppColors.primaryLight),

                  const SizedBox(width: 7),

                  Expanded(
                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                  ),
                ],
              );
            }).toList();
          },
          items: List.generate(sounds.length, (index) {
            final item = sounds[index];

            return DropdownMenuItem<int>(
              value: index,
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: AppColors.primaryLight),

                  const SizedBox(width: 10),

                  Expanded(child: Text(item.name)),

                  if (selectedIndex == index)
                    Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: AppColors.primaryLight,
                    ),
                ],
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Volumen
// ─────────────────────────────────────────────────────────────────────────

class _VolumeTile extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeTile({required this.value, required this.onChanged});

  IconData get _icon {
    if (value == 0) {
      return Icons.volume_off_rounded;
    }

    if (value < 50) {
      return Icons.volume_down_rounded;
    }

    return Icons.volume_up_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: _tileDecoration(),
      child: Row(
        children: [
          _IconBadge(icon: _icon),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      'Volumen',
                      style: AppText.title(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),

                    const Spacer(),

                    Text(
                      '${value.round()}%',
                      style: AppText.display(
                        color: AppColors.primaryLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                SizedBox(
                  height: 34,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: AppColors.primaryLight,
                      inactiveTrackColor: Colors.white12,
                      thumbColor: Colors.white,
                      overlayColor: AppColors.primary.withValues(alpha: 0.25),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 9,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: value.clamp(0.0, 100.0),
                      min: 0,
                      max: 100,
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Fuente
// ─────────────────────────────────────────────────────────────────────────

class _FontTile extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _FontTile({required this.selectedIndex, required this.onChanged});

  TextStyle _previewStyle(int index) {
    return AppFonts.style(
      const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      index: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    const fonts = AppFonts.options;

    return Container(
      height: 96,
      padding: const EdgeInsets.all(14),
      decoration: _tileDecoration(),
      child: Row(
        children: [
          const _IconBadge(icon: Icons.text_fields_rounded),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fuente',
                  style: AppText.title(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),

                const SizedBox(height: 6),

                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedIndex,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryLight,
                    ),
                    selectedItemBuilder: (context) {
                      return List.generate(fonts.length, (index) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            fonts[index].name,
                            overflow: TextOverflow.ellipsis,
                            style: _previewStyle(index),
                          ),
                        );
                      });
                    },
                    items: List.generate(fonts.length, (index) {
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                fonts[index].name,
                                style: _previewStyle(index),
                              ),
                            ),

                            if (selectedIndex == index)
                              Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: AppColors.primaryLight,
                              ),
                          ],
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
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Botón JUGAR
// ─────────────────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;

  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),

            const SizedBox(width: 6),

            Text('JUGAR', style: AppText.title(fontSize: 18, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }
}
