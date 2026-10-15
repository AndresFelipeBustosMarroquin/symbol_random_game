import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/core/config/app_config.dart';
import 'package:symbol_random_game/features/game/domain/game_mode.dart';
import 'package:symbol_random_game/features/game/domain/operation_challenge.dart';
import 'package:symbol_random_game/features/game/presentation/game_mode_input.dart';
import 'package:symbol_random_game/features/settings/presentation/option_screen.dart';
import 'package:symbol_random_game/shared/pause_panel.dart';

enum _VPhase { ready, turn, showing, input, correct, wrong }

AppPalette _playerPalette(int index) => PlayerPalettes.of(index);

Color _playerColor(int index) => _playerPalette(index).primaryLight;

class _Player {
  _Player(this.name);

  final String name;

  int hearts = 0;
  int score = 0;

  void reset(int maxHearts) {
    hearts = maxHearts;
    score = 0;
  }
}

class VersusScreen extends StatefulWidget {
  const VersusScreen({super.key, required this.mode, this.userId});

  final GameMode mode;
  final int? userId;

  @override
  State<VersusScreen> createState() => _VersusScreenState();
}

class _VersusScreenState extends State<VersusScreen>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  late final AnimationController _timer;

  Timer? _delay;
  VoidCallback? _pendingAction;

  final List<_Player> _players = [_Player('JUGADOR 1'), _Player('JUGADOR 2')];

  _VPhase _phase = _VPhase.ready;

  String _sequence = '';
  int _operationAnswer = 0;

  bool _growNext = true;

  bool _paused = false;
  bool _dialogOpen = false;
  bool _exiting = false;

  int _current = 0;
  int _round = 1;

  _Player get _player => _players[_current];

  @override
  void initState() {
    super.initState();

    for (final p in _players) {
      p.reset(GameSettings.hearts);
    }

    _timer = AnimationController(
      vsync: this,
      duration: Duration(seconds: GameSettings.time),
    )..addStatusListener(_onTimerStatus);
  }

  @override
  void dispose() {
    _delay?.cancel();
    _timer.dispose();
    _textController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void _later(int milliseconds, VoidCallback action) {
    _delay?.cancel();
    _pendingAction = null;

    _delay = Timer(Duration(milliseconds: milliseconds), () {
      if (!mounted || _exiting) return;

      if (_dialogOpen) {
        _pendingAction = action;
        return;
      }

      action();
    });
  }

  void _start() {
    if (_phase != _VPhase.ready) return;

    HapticFeedback.selectionClick();

    _beginTurn();
  }

  void _beginTurn() {
    if (!mounted || _exiting) return;

    if (_growNext) {
      if (widget.mode == GameMode.operations) {
        final challenge = OperationChallenge.generate(
          random: _random,
          difficulty: OperationDifficulty.forRound(_round),
        );
        _sequence = challenge.expression;
        _operationAnswer = challenge.answer;
      } else {
        final pool = widget.mode.pool;
        _sequence += List.generate(
          GameSettings.increment,
          (_) => pool[_random.nextInt(pool.length)],
        ).join();
      }

      _growNext = false;
    }

    _textController.clear();
    _focusNode.unfocus();

    setState(() {
      _phase = _VPhase.turn;
      _paused = false;
    });

    _later(1300, _startShowing);
  }

  void _startShowing() {
    if (_phase != _VPhase.turn) return;

    setState(() {
      _phase = _VPhase.showing;
    });

    _timer.forward(from: 0);
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _phase == _VPhase.showing) {
      setState(() {
        _phase = _VPhase.input;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _phase == _VPhase.input) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _submit() {
    if (_phase != _VPhase.input) return;

    final answer = _textController.text.trim().toUpperCase();

    if (answer.isEmpty) return;

    _focusNode.unfocus();

    final p = _player;

    final isCorrect = widget.mode == GameMode.operations
        ? int.tryParse(answer) == _operationAnswer
        : answer == _sequence;

    if (isCorrect) {
      HapticFeedback.lightImpact();
      final points = widget.mode == GameMode.operations
          ? OperationDifficulty.forRound(_round).pointsPerAnswer
          : 1;

      setState(() {
        _phase = _VPhase.correct;
        p.score += points;
      });

      _growNext = true;

      _later(1000, _endTurn);
    } else {
      HapticFeedback.heavyImpact();

      setState(() {
        _phase = _VPhase.wrong;
        p.hearts--;
      });

      _growNext = false;

      _later(1600, _endTurn);
    }
  }

  void _endTurn() {
    if (!mounted || _exiting) return;

    if (_player.hearts <= 0) {
      _showResult();
      return;
    }

    setState(() {
      _current = 1 - _current;

      if (_current == 0) {
        _round++;
      }
    });

    _beginTurn();
  }

  void _restart() {
    _delay?.cancel();
    _pendingAction = null;
    _timer.value = 0;
    _textController.clear();

    setState(() {
      for (final p in _players) {
        p.reset(GameSettings.hearts);
      }

      _sequence = '';
      _operationAnswer = 0;
      _growNext = true;
      _current = 0;
      _round = 1;
      _paused = false;
      _phase = _VPhase.ready;
    });
  }

  void _exitToMenu() {
    _exiting = true;
    _delay?.cancel();

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _resume() {
    setState(() {
      _paused = false;
    });

    _timer.forward();
  }

  void _skip() {
    if (_phase != _VPhase.showing) return;

    HapticFeedback.selectionClick();

    setState(() {
      _paused = false;
    });

    _timer.value = 1.0;
  }

  Future<void> _openPauseMenu() async {
    if (_phase != _VPhase.showing || _paused) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _paused = true;
    });

    _timer.stop();

    while (true) {
      final action = await showDialog<PauseAction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PausePanel(),
      );

      if (!mounted || _exiting) return;

      if (action == PauseAction.restart) {
        _restart();
        return;
      }

      if (action == PauseAction.menu) {
        final leave = await _askLeave();

        if (!mounted) return;

        if (leave) {
          _exitToMenu();
          return;
        }

        continue;
      }

      if (action == PauseAction.options) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OptionsScreen(userId: widget.userId),
          ),
        );

        continue;
      }

      if (action == PauseAction.score) {
        await _showScoreSheet();

        continue;
      }

      _resume();

      return;
    }
  }

  Future<bool> _askLeave() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LeaveDialog(),
    );

    return result == true;
  }

  Future<void> _confirmExit() async {
    if (_dialogOpen || _exiting) return;

    final wasRunning = _phase == _VPhase.showing && !_paused;

    if (wasRunning) {
      _timer.stop();

      setState(() {
        _paused = true;
      });
    }

    _dialogOpen = true;

    final leave = await _askLeave();

    _dialogOpen = false;

    if (!mounted) return;

    if (leave) {
      _exitToMenu();
      return;
    }

    if (wasRunning) {
      _resume();
    }

    final pending = _pendingAction;

    _pendingAction = null;

    pending?.call();
  }

  Future<void> _showScoreSheet() {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 40),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: AppColors.primaryLight,
                size: 50,
              ),
              const SizedBox(height: 12),
              Text(
                'PUNTUACIÓN',
                style: AppText.title(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < _players.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _playerPalette(i).card.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _playerColor(i).withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _players[i].name,
                            style: AppText.title(
                              color: _playerColor(i),
                              fontSize: 15,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Text(
                          '${_players[i].score}',
                          style: AppText.display(fontSize: 30),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showResult() async {
    final loser = _current;

    final rematch = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ResultDialog(players: _players, winner: 1 - loser),
    );

    if (!mounted || _exiting) return;

    if (rematch == true) {
      _restart();
    } else {
      _exitToMenu();
    }
  }

  void _insertSymbol(String symbol) {
    if (_phase != _VPhase.input) return;

    HapticFeedback.selectionClick();

    final newText = _textController.text + symbol;

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _backspace() {
    if (_phase != _VPhase.input) return;

    final text = _textController.text;

    if (text.isEmpty) return;

    HapticFeedback.selectionClick();

    final newText = text.substring(0, text.length - 1);

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmExit();
        }
      },
      child: AppFontBuilder(
        builder: (context) => Scaffold(
          body: AnimatedAppBackground(
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktopLayout(context) ? 960 : 680,
                  ),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final desktop = isDesktopLayout(context);
                      final topGap = desktop
                          ? 8.0
                          : (box.maxHeight * 0.16).clamp(8.0, 150.0);
                      final bottomGap = desktop
                          ? 12.0
                          : (box.maxHeight * 0.14).clamp(16.0, 120.0);

                      final content = ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: box.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              SizedBox(height: topGap),
                              _VersusTopBar(
                                mode: widget.mode,
                                round: _round,
                                players: _players,
                                current: _current,
                                started: _phase != _VPhase.ready,
                                maxHearts: GameSettings.hearts,
                                onBack: _confirmExit,
                              ),
                              Expanded(child: Center(child: _buildStage())),
                              _buildInput(),
                              SizedBox(height: bottomGap),
                            ],
                          ),
                        ),
                      );

                      return desktop
                          ? content
                          : SingleChildScrollView(child: content);
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    final p = _player;
    final color = _playerColor(_current);

    final Widget child = switch (_phase) {
      _VPhase.ready => _ReadyView(
        key: const ValueKey('ready'),
        onStart: _start,
        isOperation: widget.mode == GameMode.operations,
      ),
      _VPhase.turn => _TurnView(
        key: ValueKey('turn-$_round-$_current'),
        playerName: p.name,
        color: color,
        length: _sequence.length,
        isOperation: widget.mode == GameMode.operations,
        operationDifficulty: OperationDifficulty.forRound(_round),
      ),
      _VPhase.showing => _ShowingView(
        key: const ValueKey('showing'),
        playerName: p.name,
        color: color,
        sequence: _sequence,
        isOperation: widget.mode == GameMode.operations,
        operationDifficulty: OperationDifficulty.forRound(_round),
        animation: _timer,
        palette: _playerPalette(_current),
        paused: _paused,
        onPause: _openPauseMenu,
        onSkip: _skip,
      ),
      _VPhase.input => _MessageView(
        key: const ValueKey('input'),
        tag: p.name,
        tagColor: color,
        icon: Icons.psychology_alt_rounded,
        color: color,
        title: widget.mode.question,
        subtitle: widget.mode == GameMode.operations
            ? OperationDifficulty.forRound(_round).label
            : '${_sequence.length} en total',
      ),
      _VPhase.correct => _MessageView(
        key: const ValueKey('correct'),
        tag: p.name,
        tagColor: color,
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        title: widget.mode == GameMode.operations
            ? '¡CORRECTO! +${OperationDifficulty.forRound(_round).pointsPerAnswer} PTS'
            : '¡CORRECTO!',
        subtitle: _sequence,
        subtitleBig: true,
      ),
      _VPhase.wrong => _MessageView(
        key: const ValueKey('wrong'),
        tag: p.name,
        tagColor: color,
        icon: Icons.cancel_rounded,
        color: Colors.redAccent,
        title: 'INCORRECTO  −1 ♥',
        subtitle: _sequence,
        subtitleBig: true,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: child,
    );
  }

  Widget _buildInput() {
    final active = _phase == _VPhase.input;

    final palette = _playerPalette(_current);

    final color = palette.primaryLight;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: active ? 1 : 0.35,
      child: IgnorePointer(
        ignoring: !active,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                enabled: active,
                keyboardType: widget.mode.keyboard,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                inputFormatters: [
                  if (widget.mode == GameMode.numbers ||
                      widget.mode == GameMode.operations)
                    FilteringTextInputFormatter.digitsOnly,
                ],
                style: AppText.display(fontSize: 28, letterSpacing: 6),
                cursorColor: color,
                decoration: InputDecoration(
                  hintText: '· · ·',
                  hintStyle: AppText.display(
                    color: Colors.white24,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: palette.card.withValues(alpha: 0.78),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: color.withValues(alpha: 0.58),
                      width: 1.4,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: color, width: 2),
                  ),
                ),
              ),
              if (widget.mode == GameMode.symbols) ...[
                const SizedBox(height: 12),
                _SymbolKeyboard(
                  palette: palette,
                  symbols: widget.mode.pool.split(''),
                  onSymbol: _insertSymbol,
                  onBackspace: _backspace,
                ),
              ],
              const SizedBox(height: 14),
              PressableScale(
                onTap: _submit,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: palette.gradient,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    active ? 'COMPROBAR · ${_player.name}' : 'COMPROBAR',
                    style: AppText.title(fontSize: 17, letterSpacing: 1.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersusTopBar extends StatelessWidget {
  const _VersusTopBar({
    required this.mode,
    required this.round,
    required this.players,
    required this.current,
    required this.started,
    required this.maxHearts,
    required this.onBack,
  });

  final GameMode mode;
  final int round;
  final List<_Player> players;
  final int current;
  final bool started;
  final int maxHearts;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.white,
                iconSize: 22,
                tooltip: 'Volver',
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${mode.title} · DUELO',
                      style: AppText.label(
                        color: AppColors.primaryLight,
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RONDA $round',
                      style: AppText.display(fontSize: 18, letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
          child: Row(
            children: [
              for (var i = 0; i < players.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _PlayerChip(
                    player: players[i],
                    palette: _playerPalette(i),
                    maxHearts: maxHearts,
                    active: started && current == i,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.player,
    required this.palette,
    required this.maxHearts,
    required this.active,
  });

  final _Player player;
  final AppPalette palette;
  final int maxHearts;
  final bool active;

  Color get color => palette.primaryLight;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.primary.withValues(alpha: active ? 0.34 : 0.14),
            palette.card.withValues(alpha: active ? 0.92 : 0.55),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? color : color.withValues(alpha: 0.35),
          width: active ? 2 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(
                    color: active ? color : color.withValues(alpha: 0.6),
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Icon(
                Icons.check_circle_outline_rounded,
                size: 14,
                color: active ? color : color.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text('${player.score}', style: AppText.display(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                for (var i = 0; i < maxHearts; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      i < player.hearts
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: i < player.hearts
                          ? Colors.redAccent
                          : Colors.white30,
                      size: 18,
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

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    super.key,
    required this.onStart,
    required this.isOperation,
  });

  final VoidCallback onStart;
  final bool isOperation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_rounded, color: _playerColor(0), size: 52),
              const SizedBox(width: 10),
              const Icon(Icons.bolt_rounded, color: Colors.white54, size: 36),
              const SizedBox(width: 10),
              Icon(Icons.person_rounded, color: _playerColor(1), size: 52),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '¿LISTOS?',
            style: AppText.display(fontSize: 26, letterSpacing: 4),
          ),
          const SizedBox(height: 10),
          Text(
            isOperation
                ? 'Resuelvan operaciones por turnos. Cada respuesta correcta '
                      'vale más puntos al subir de nivel.\n'
                      'Quien se quede sin corazones primero pierde.'
                : 'Una sola secuencia para los dos.\n'
                      'Cada turno se le suma algo nuevo.\n'
                      'Quien falle pierde un corazón; el primero que se quede '
                      'sin ellos pierde.',
            textAlign: TextAlign.center,
            style: AppText.label(
              color: Colors.white60,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          PressableScale(
            onTap: onStart,
            child: Container(
              width: 220,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Text(
                'COMENZAR',
                style: AppText.title(fontSize: 17, letterSpacing: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TurnView extends StatelessWidget {
  const _TurnView({
    super.key,
    required this.playerName,
    required this.color,
    required this.length,
    required this.isOperation,
    required this.operationDifficulty,
  });

  final String playerName;
  final Color color;
  final int length;
  final bool isOperation;
  final OperationDifficulty operationDifficulty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'TURNO DE',
            style: AppText.label(
              color: Colors.white60,
              fontSize: 14,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              playerName,
              style: AppText.display(
                color: color,
                fontSize: 38,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isOperation
                ? 'Nivel ${operationDifficulty.label.toLowerCase()}'
                : 'Secuencia de $length',
            style: AppText.label(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowingView extends StatelessWidget {
  const _ShowingView({
    super.key,
    required this.playerName,
    required this.color,
    required this.sequence,
    required this.isOperation,
    required this.operationDifficulty,
    required this.animation,
    required this.palette,
    required this.paused,
    required this.onPause,
    required this.onSkip,
  });

  final String playerName;
  final Color color;
  final String sequence;
  final bool isOperation;
  final OperationDifficulty operationDifficulty;
  final Animation<double> animation;
  final AppPalette palette;
  final bool paused;
  final VoidCallback onPause;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            playerName,
            style: AppText.title(color: color, fontSize: 14, letterSpacing: 3),
          ),
          const SizedBox(height: 6),
          Text(
            paused
                ? 'EN PAUSA'
                : isOperation
                ? 'RESUELVE · ${operationDifficulty.label}'
                : 'MEMORIZA',
            style: AppText.label(
              color: Colors.white60,
              fontSize: 14,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          if (paused)
            const SizedBox(
              height: 87,
              child: Icon(
                Icons.pause_circle_rounded,
                color: Colors.white38,
                size: 72,
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              child: GradientText(
                sequence,
                gradient: palette.gradient,
                style: AppText.display(
                  fontSize: isOperation ? 54 : 72,
                  letterSpacing: isOperation ? 2 : 8,
                ),
              ),
            ),
          const SizedBox(height: 32),
          AnimatedBuilder(
            animation: animation,
            builder: (_, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 1 - animation.value,
                  minHeight: 8,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ControlButton(
                icon: Icons.pause_rounded,
                label: 'PAUSA',
                palette: palette,
                onTap: onPause,
              ),
              const SizedBox(width: 14),
              _ControlButton(
                icon: Icons.fast_forward_rounded,
                label: 'OMITIR',
                palette: palette,
                onTap: onSkip,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.tag,
    this.tagColor,
    this.subtitle,
    this.subtitleBig = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? tag;
  final Color? tagColor;
  final String? subtitle;
  final bool subtitleBig;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tag != null) ...[
            Text(
              tag!,
              style: AppText.title(
                color: tagColor ?? Colors.white60,
                fontSize: 14,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Icon(icon, color: color, size: 72),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.title(fontSize: 26, letterSpacing: 2),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                subtitle!,
                style: subtitleBig
                    ? AppText.display(
                        color: color,
                        fontSize: 48,
                        letterSpacing: 6,
                      )
                    : AppText.label(
                        color: Colors.white60,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveDialog extends StatelessWidget {
  const _LeaveDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        '¿SALIR DEL DUELO?',
        textAlign: TextAlign.center,
        style: AppText.title(fontSize: 19, letterSpacing: 2),
      ),
      content: Text(
        'Se perderá la partida actual.',
        textAlign: TextAlign.center,
        style: AppText.label(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'SEGUIR',
            style: AppText.title(
              color: AppColors.primaryLight,
              letterSpacing: 1.4,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'SALIR',
            style: AppText.title(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({required this.players, required this.winner});

  final List<_Player> players;
  final int winner;

  @override
  Widget build(BuildContext context) {
    final color = _playerColor(winner);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: color.withValues(alpha: 0.7), width: 2),
        ),
        title: Text(
          '¡GANA ${players[winner].name}!',
          textAlign: TextAlign.center,
          style: AppText.title(color: color, fontSize: 20, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: color, size: 56),
            const SizedBox(height: 16),
            for (var i = 0; i < players.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        players[i].name,
                        style: AppText.title(
                          color: _playerColor(i),
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      '${players[i].score} aciertos · ${players[i].hearts} ♥',
                      style: AppText.label(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'SALIR',
              style: AppText.title(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'REVANCHA',
              style: AppText.title(
                color: AppColors.primaryLight,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: palette.card.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: palette.primary.withValues(alpha: 0.58),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: palette.primaryLight, size: 22),
            const SizedBox(width: 8),
            Text(label, style: AppText.title(fontSize: 14, letterSpacing: 1.6)),
          ],
        ),
      ),
    );
  }
}

class _SymbolKeyboard extends StatelessWidget {
  const _SymbolKeyboard({
    required this.palette,
    required this.symbols,
    required this.onSymbol,
    required this.onBackspace,
  });

  final AppPalette palette;
  final List<String> symbols;
  final ValueChanged<String> onSymbol;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keyStyle = AppText.display(fontSize: 20);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in symbols)
          _Key(
            palette: palette,
            onTap: () => onSymbol(s),
            child: Text(s, style: keyStyle),
          ),
        _Key(
          palette: palette,
          onTap: onBackspace,
          child: const Icon(
            Icons.backspace_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.palette, required this.onTap, required this.child});

  final AppPalette palette;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.card.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.primary.withValues(alpha: 0.45)),
          ),
          child: child,
        ),
      ),
    );
  }
}
