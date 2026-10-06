import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/core/config/app_config.dart';
import 'package:symbol_random_game/features/game/game_screen.dart'
    show GameMode, GameModeX;
import 'package:symbol_random_game/features/leaderboard/score_service.dart';
import 'package:symbol_random_game/features/profile/profile_screen.dart';
import 'package:symbol_random_game/shared/static_background.dart';

const _maxContentWidth = 760.0;
const _pagePadding = 28.0;
const _tableMinWidth = 640.0;
const _rowHeight = 44.0;
const _headerHeight = 44.0;
const _rankWidth = 38.0;
const _visibleRows = 10.5;
const _tableHeight = _headerHeight + _rowHeight * _visibleRows + 3;
const _allIncremento = 0;

const _gold = Color(0xFFFFC94D);
const _silver = Color(0xFFC0C7D1);
const _bronze = Color(0xFFD08A55);

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

class ScoreEntry {
  const ScoreEntry({
    this.idUsuario = 0,
    required this.jugador,
    required this.modo,
    required this.incremento,
    required this.vidas,
    required this.tiempoPregunta,
    required this.tiempoTotal,
    required this.resultado,
    required this.edad,
  });

  final int idUsuario;
  final String jugador;
  final GameMode modo;
  final int incremento;
  final int vidas;
  final int tiempoPregunta;
  final int tiempoTotal;
  final int resultado;
  final int edad;

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    final modeName = (json['modo'] as String).trim().toUpperCase();
    final mode = switch (modeName) {
      'NÚMEROS' || 'NUMEROS' => GameMode.numbers,
      'CARACTERES' => GameMode.characters,
      'SÍMBOLOS' || 'SIMBOLOS' => GameMode.symbols,
      'OPERACIONES' => GameMode.operations,
      _ => throw FormatException('Modo de juego desconocido: $modeName'),
    };
    return ScoreEntry(
      idUsuario: (json['idUsuario'] as num?)?.toInt() ?? 0,
      jugador: json['jugador'] as String,
      modo: mode,
      incremento: (json['incremento'] as num).toInt(),
      vidas: (json['vidas'] as num).toInt(),
      tiempoPregunta: (json['tiempoPregunta'] as num).toInt(),
      tiempoTotal: (json['tiempoTotal'] as num).toInt(),
      resultado: (json['resultado'] as num).toInt(),
      edad: (json['edad'] as num).toInt(),
    );
  }
}

enum _SortBy { resultado, tiempoPregunta, incremento, vidas }

extension _SortByX on _SortBy {
  String get label => switch (this) {
    _SortBy.resultado => 'Mayor resultado',
    _SortBy.tiempoPregunta => 'Menos tiempo/preg.',
    _SortBy.incremento => 'Mayor incremento',
    _SortBy.vidas => 'Menos vidas',
  };
}

IconData _modeIcon(GameMode mode) => switch (mode) {
  GameMode.numbers => Icons.pin_rounded,
  GameMode.characters => Icons.text_fields_rounded,
  GameMode.symbols => Icons.tag_rounded,
  GameMode.operations => Icons.calculate_rounded,
};

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key, this.scores, this.viewerId});

  /// Permite inyectar filas para previews y pruebas; normalmente se cargan
  /// desde el endpoint real del backend.
  final List<ScoreEntry>? scores;
  final int? viewerId;

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  final ScoreService _scoreService = ScoreService();
  final Listenable _appearance = Listenable.merge([
    AppColors.paletteNotifier,
    AppFonts.notifier,
  ]);

  late Future<List<ScoreEntry>> _scoresFuture;
  GameMode? _modo;
  int _incremento = _allIncremento;
  _SortBy _sort = _SortBy.resultado;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  void _loadScores() {
    _scoresFuture = widget.scores == null
        ? _scoreService.obtenerTodas().then(
            (rows) => rows.map(ScoreEntry.fromJson).toList(),
          )
        : Future.value(widget.scores);
  }

  Future<void> _retry() async {
    HapticFeedback.selectionClick();
    setState(_loadScores);
  }

  bool get _hasFilters =>
      _modo != null ||
      _incremento != _allIncremento ||
      _sort != _SortBy.resultado;

  List<ScoreEntry> _visible(List<ScoreEntry> scores) {
    final rows = scores.where((score) {
      if (_modo != null && score.modo != _modo) return false;
      if (_incremento != _allIncremento && score.incremento != _incremento) {
        return false;
      }
      return true;
    }).toList();

    rows.sort((a, b) {
      final comparison = switch (_sort) {
        _SortBy.resultado => b.resultado.compareTo(a.resultado),
        _SortBy.tiempoPregunta => a.tiempoPregunta.compareTo(b.tiempoPregunta),
        _SortBy.incremento => b.incremento.compareTo(a.incremento),
        _SortBy.vidas => a.vidas.compareTo(b.vidas),
      };
      return comparison != 0 ? comparison : b.resultado.compareTo(a.resultado);
    });
    return rows;
  }

  void _resetFilters() {
    HapticFeedback.selectionClick();
    setState(() {
      _modo = null;
      _incremento = _allIncremento;
      _sort = _SortBy.resultado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appearance,
      builder: (context, _) {
        return Scaffold(
          body: StaticAppBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >=
                      desktopLayoutBreakpoint;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: desktop ? 1200 : _maxContentWidth,
                      ),
                      child: desktop
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                              child: Column(
                                children: [
                                  const _ScoreHeader(),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: _buildScoreResults(desktop: true),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const _ScoreHeader(),
                                  const SizedBox(height: 22),
                                  _buildScoreResults(desktop: false),
                                ],
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreResults({required bool desktop}) {
    return FutureBuilder<List<ScoreEntry>>(
      future: _scoresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return desktop
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryLight,
                  ),
                )
              : const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(error: snapshot.error!, onRetry: _retry);
        }

        final rows = _visible(snapshot.data ?? const []);
        final results = Column(
          mainAxisSize: desktop ? MainAxisSize.max : MainAxisSize.min,
          children: [
            _buildFilters(),
            SizedBox(height: desktop ? 8 : 14),
            _buildCounter(rows.length),
            SizedBox(height: desktop ? 6 : 10),
            if (desktop)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
                  child: _ScoreTable(
                    rows: rows,
                    showMedals: _sort == _SortBy.resultado,
                    viewerId: widget.viewerId,
                    expand: true,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
                child: _ScoreTable(
                  rows: rows,
                  showMedals: _sort == _SortBy.resultado,
                  viewerId: widget.viewerId,
                ),
              ),
          ],
        );
        return results;
      },
    );
  }

  Widget _buildFilters() {
    final modes = <GameMode?>[null, ...GameMode.values];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final mode in modes)
                _ModeChip(
                  label: mode == null ? 'TODOS' : mode.title,
                  icon: mode == null ? null : _modeIcon(mode),
                  selected: _modo == mode,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _modo = mode);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _pagePadding),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                flex: 2,
                child: _FilterDropdown<int>(
                  label: 'INCREMENTO',
                  icon: Icons.add_circle_outline_rounded,
                  value: _incremento,
                  items: [
                    (_allIncremento, 'Todos'),
                    for (
                      var value = GameSettings.minValue;
                      value <= GameSettings.maxValue;
                      value++
                    )
                      (value, '$value'),
                  ],
                  onChanged: (value) => setState(() => _incremento = value),
                ),
              ),
              Expanded(
                flex: 3,
                child: _FilterDropdown<_SortBy>(
                  label: 'ORDENAR POR',
                  icon: Icons.swap_vert_rounded,
                  value: _sort,
                  items: [
                    for (final sort in _SortBy.values) (sort, sort.label),
                  ],
                  onChanged: (value) => setState(() => _sort = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _pagePadding + 4),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            Text(
              count == 1 ? '1 REGISTRO' : '$count REGISTROS',
              style: AppText.label(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (_hasFilters)
              PressableScale(
                onTap: _resetFilters,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_off_rounded,
                      size: 16,
                      color: AppColors.primaryLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIMPIAR',
                      style: AppText.title(
                        color: AppColors.primaryLight,
                        fontSize: 13,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader();

  @override
  Widget build(BuildContext context) {
    return AppFontBuilder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: Colors.white,
              iconSize: 22,
              tooltip: 'Volver',
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: AppColors.primaryLight,
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      GradientText(
                        'PUNTUACIÓN',
                        style: AppText.display(fontSize: 32, letterSpacing: 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.card.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.45),
            width: 1.3,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.primaryLight,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: AppText.title(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.58),
          width: 1.4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.primaryLight),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label(
                    color: Colors.white54,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
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
              items: [
                for (final (itemValue, text) in items)
                  DropdownMenuItem<T>(
                    value: itemValue,
                    child: Text(text, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (newValue) {
                if (newValue == null) return;
                HapticFeedback.selectionClick();
                onChanged(newValue);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreTable extends StatelessWidget {
  const _ScoreTable({
    required this.rows,
    required this.showMedals,
    required this.viewerId,
    this.expand = false,
  });

  final List<ScoreEntry> rows;
  final bool showMedals;
  final int? viewerId;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: expand ? double.infinity : _tableHeight,
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.3,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth < _tableMinWidth
              ? _tableMinWidth
              : box.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              height: box.maxHeight,
              child: Column(
                children: [
                  const _TableHeader(),
                  Expanded(
                    child: rows.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemExtent: _rowHeight,
                            itemCount: rows.length,
                            itemBuilder: (_, index) => _ScoreRow(
                              rank: index + 1,
                              entry: rows[index],
                              showMedals: showMedals,
                              viewerId: viewerId,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return AppFontBuilder(
      builder: (context) {
        final style = AppText.label(
          color: Colors.white60,
          fontSize: 10.5,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w700,
        );
        return Container(
          height: _headerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.18),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: _rankWidth,
                child: Text('#', textAlign: TextAlign.center, style: style),
              ),
              Expanded(flex: 3, child: Text('NOMBRE', style: style)),
              Expanded(
                flex: 2,
                child: Text('EDAD', textAlign: TextAlign.center, style: style),
              ),
              Expanded(flex: 4, child: Text('MODO', style: style)),
              Expanded(
                flex: 2,
                child: Text('INCR.', textAlign: TextAlign.center, style: style),
              ),
              Expanded(
                flex: 2,
                child: Text('VIDAS', textAlign: TextAlign.center, style: style),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'T. PREG.',
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'T. TOTAL',
                  textAlign: TextAlign.center,
                  style: style,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'RESULT.',
                  textAlign: TextAlign.right,
                  style: style,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.rank,
    required this.entry,
    required this.showMedals,
    required this.viewerId,
  });

  final int rank;
  final ScoreEntry entry;
  final bool showMedals;
  final int? viewerId;

  void _openProfile(BuildContext context) {
    if (entry.idUsuario <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfileScreen(userId: entry.idUsuario, viewerId: viewerId),
      ),
    );
  }

  Color? get _medal {
    if (!showMedals) return null;
    return switch (rank) {
      1 => _gold,
      2 => _silver,
      3 => _bronze,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cell = AppText.label(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final medal = _medal;

    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: medal?.withValues(alpha: 0.07),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _rankWidth,
            child: Center(
              child: medal == null
                  ? Text(
                      '$rank',
                      style: AppText.label(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: medal.withValues(alpha: 0.18),
                        border: Border.all(color: medal, width: 1.6),
                      ),
                      child: Text(
                        '$rank',
                        style: AppText.display(color: medal, fontSize: 12),
                      ),
                    ),
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () => _openProfile(context),
              borderRadius: BorderRadius.circular(6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  entry.jugador,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: cell.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primaryLight.withValues(
                      alpha: .55,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${entry.edad}',
              textAlign: TextAlign.center,
              style: cell.copyWith(color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(
                  _modeIcon(entry.modo),
                  size: 16,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.modo.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: cell.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${entry.incremento}',
              textAlign: TextAlign.center,
              style: cell,
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text('${entry.vidas}', style: cell),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${entry.tiempoPregunta}s',
              textAlign: TextAlign.center,
              style: cell.copyWith(color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatTime(entry.tiempoTotal),
              textAlign: TextAlign.center,
              style: cell.copyWith(color: Colors.white70),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${entry.resultado}',
              textAlign: TextAlign.right,
              style: AppText.display(
                color: medal ?? AppColors.primaryLight,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tableHeight,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _tableHeight,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                'NO SE PUDIERON CARGAR LAS PUNTUACIONES',
                textAlign: TextAlign.center,
                style: AppText.title(
                  color: Colors.white,
                  fontSize: 15,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppText.label(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('REINTENTAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return AppFontBuilder(
      builder: (context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Colors.white38,
              size: 54,
            ),
            const SizedBox(height: 12),
            Text(
              'SIN PUNTUACIONES',
              style: AppText.title(
                color: Colors.white60,
                fontSize: 15,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Todavía no hay resultados guardados',
              style: AppText.label(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
