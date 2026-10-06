import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:symbol_random_game/core/app_theme.dart';
import 'package:symbol_random_game/core/config/app_config.dart';
import 'package:symbol_random_game/core/responsive_layout.dart';
import 'package:symbol_random_game/features/settings/option_screen.dart';
import 'package:symbol_random_game/features/leaderboard/score_screen.dart';
import 'package:symbol_random_game/features/leaderboard/score_service.dart';
import 'package:symbol_random_game/features/game/operation_challenge.dart';
import 'package:symbol_random_game/core/app_text.dart';
import 'package:symbol_random_game/core/app_fonts.dart';
import 'package:symbol_random_game/shared/pause_panel.dart';

enum GameMode { numbers, characters, symbols, operations }

extension GameModeX on GameMode {
  String get title => switch (this) {
    GameMode.numbers => 'NÚMEROS',
    GameMode.symbols => 'SÍMBOLOS',
    GameMode.characters => 'CARACTERES',
    GameMode.operations => 'OPERACIONES',
  };

  String get question => switch (this) {
    GameMode.numbers => '¿Qué número era?',
    GameMode.symbols => '¿Qué símbolos eran?',
    GameMode.characters => '¿Qué caracteres eran?',
    GameMode.operations => '¿Cuánto es?',
  };

  String get pool => switch (this) {
    GameMode.numbers => '0123456789',
    GameMode.symbols => '!@#\$%&*?+=-_/()<>',
    GameMode.characters => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789',
    GameMode.operations => '',
  };

  TextInputType get keyboard => switch (this) {
    GameMode.numbers => TextInputType.number,
    GameMode.symbols => TextInputType.none,
    GameMode.operations => TextInputType.number,
    _ => TextInputType.text,
  };
}

enum _Phase { showing, input, correct, wrong }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.mode, required this.userId});

  final GameMode mode;
  final int userId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final _random = math.Random();
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _scoreService = ScoreService();

  late final AnimationController _timer;

  Timer? _delay;

  _Phase _phase = _Phase.showing;

  bool _paused = false;

  String _sequence = '';
  int _operationAnswer = 0;

  int _round = 1;
  int _score = 0;
  int _lastPointsAwarded = 0;
  DateTime _startedAt = DateTime.now();
  bool _savingScore = false;
  String? _scoreSaveError;

  late int _hearts;

  @override
  void initState() {
    super.initState();

    _hearts = GameSettings.hearts;

    _timer = AnimationController(
      vsync: this,
      duration: Duration(seconds: GameSettings.time),
    )..addStatusListener(_onTimerStatus);

    _startGame();
  }

  @override
  void dispose() {
    _delay?.cancel();
    _timer.dispose();
    _textController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  void _startGame() {
    _sequence = '';
    _round = 1;
    _score = 0;
    _lastPointsAwarded = 0;
    _hearts = GameSettings.hearts;
    _startedAt = DateTime.now();
    _scoreSaveError = null;

    _nextRound();
  }

  void _nextRound() {
    _textController.clear();

    if (widget.mode == GameMode.operations) {
      final difficulty = OperationDifficulty.forRound(_round);
      final challenge = OperationChallenge.generate(
        random: _random,
        difficulty: difficulty,
      );
      _sequence = challenge.expression;
      _operationAnswer = challenge.answer;
    } else {
      final pool = widget.mode.pool;
      final newCharacters = List.generate(
        GameSettings.increment,
        (_) => pool[_random.nextInt(pool.length)],
      ).join();
      _sequence += newCharacters;
    }

    setState(() {
      _phase = _Phase.showing;
      _paused = false;
    });

    _focusNode.unfocus();

    _timer.forward(from: 0);
  }

  Future<void> _openPauseMenu() async {
    if (_phase != _Phase.showing || _paused) return;

    HapticFeedback.selectionClick();

    setState(() {
      _paused = true;
    });

    _timer.stop();

    while (mounted) {
      final action = await showDialog<PauseAction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PausePanel(),
      );

      if (!mounted) return;

      if (action == PauseAction.restart) {
        _restart();
        return;
      }

      if (action == PauseAction.menu) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      if (action == PauseAction.options) {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const OptionsScreen()));

        continue;
      }

      if (action == PauseAction.score) {
        if (_hearts <= 0) {
          await Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => ScoreScreen(viewerId: widget.userId),
                ),
              );
        } else {
          await _showScoreSheet();
        }
        continue;
      }

      _resume();
      return;
    }
  }

  void _resume() {
    setState(() {
      _paused = false;
    });

    _timer.forward();
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.bgBottom,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Text(
                      'RONDAS SUPERADAS',
                      style: AppText.label(fontSize: 12, letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    Text('$_score', style: AppText.display(fontSize: 40)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _skip() {
    if (_phase != _Phase.showing) return;

    HapticFeedback.selectionClick();

    setState(() {
      _paused = false;
    });

    _timer.value = 1.0;
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _phase == _Phase.showing) {
      setState(() {
        _phase = _Phase.input;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _submit() {
    if (_phase != _Phase.input) return;

    final answer = _textController.text.trim().toUpperCase();

    if (answer.isEmpty) return;

    final isCorrect = widget.mode == GameMode.operations
        ? int.tryParse(answer) == _operationAnswer
        : answer == _sequence;

    if (isCorrect) {
      HapticFeedback.lightImpact();

      _focusNode.unfocus();
      final points = widget.mode == GameMode.operations
          ? OperationDifficulty.forRound(_round).pointsPerAnswer
          : 1;

      setState(() {
        _phase = _Phase.correct;
        _score += points;
        _lastPointsAwarded = points;
      });

      _delay?.cancel();

      _delay = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;

        _round++;

        _nextRound();
      });
    } else {
      HapticFeedback.heavyImpact();

      _focusNode.unfocus();

      setState(() {
        _phase = _Phase.wrong;
        _hearts--;
      });

      if (_hearts <= 0) {
        _showGameOver();
        return;
      }

      _delay?.cancel();

      _delay = Timer(const Duration(milliseconds: 1000), () {
        if (!mounted) return;

        _textController.clear();

        setState(() {
          _phase = _Phase.input;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      });
    }
  }

  void _insertSymbol(String symbol) {
    if (_phase != _Phase.input) return;

    HapticFeedback.selectionClick();

    final newText = _textController.text + symbol;

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _backspace() {
    if (_phase != _Phase.input) return;

    final text = _textController.text;

    if (text.isEmpty) return;

    HapticFeedback.selectionClick();

    final newText = text.substring(0, text.length - 1);

    _textController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }

  void _restart() {
    _delay?.cancel();

    setState(() {
      _sequence = '';
      _round = 1;
      _score = 0;
      _lastPointsAwarded = 0;
      _hearts = GameSettings.hearts;
      _startedAt = DateTime.now();
      _scoreSaveError = null;
    });

    _nextRound();
  }

  Future<void> _showGameOver() async {
    if (_savingScore) return;

    _delay?.cancel();
    _timer.stop();

    setState(() {
      _savingScore = true;
      _scoreSaveError = null;
    });

    try {
      await _scoreService.guardarResultado(
        idUsuario: widget.userId,
        modo: widget.mode.title,
        digitos: widget.mode == GameMode.operations
            ? OperationDifficulty.forRound(_round).scoreLevel
            : GameSettings.increment,
        vidas: GameSettings.hearts,
        tiempoPregunta: GameSettings.time,
        tiempoTotal: DateTime.now().difference(_startedAt).inSeconds,
        resultado: _score,
      );
    } catch (error) {
      _scoreSaveError = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _savingScore = false;
        });
      }
    }

    if (!mounted) return;

    while (mounted) {
      final action = await showDialog<PauseAction>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PausePanel(
          gameOver: true,
          score: _score,
          saveError: _scoreSaveError,
        ),
      );

      if (!mounted) return;

      if (action == PauseAction.restart) {
        _restart();
        return;
      }

      if (action == PauseAction.menu) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
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

      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppFontBuilder(
      builder: (context) => Scaffold(
        body: AnimatedAppBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight <= 900 ||
                        isDesktopLayout(context);
                    return Column(
                      children: [
                        _TopBar(
                          mode: widget.mode,
                          round: _round,
                          hearts: _hearts,
                          maxHearts: GameSettings.hearts,
                          score: _score,
                          topPadding: compact ? 12 : 200,
                          onBack: () {
                            Navigator.of(context).maybePop();
                          },
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, stageConstraints) => Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: stageConstraints.maxWidth,
                                  child: _buildStage(),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildInput(compact: compact),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    final Widget child = switch (_phase) {
      _Phase.showing => _ShowingView(
        key: const ValueKey('showing'),
        sequence: _sequence,
        isOperation: widget.mode == GameMode.operations,
        operationDifficulty: OperationDifficulty.forRound(_round),
        animation: _timer,
        paused: _paused,
        onPause: _openPauseMenu,
        onSkip: _skip,
      ),
      _Phase.input => _MessageView(
        key: const ValueKey('input'),
        icon: Icons.psychology_alt_rounded,
        color: AppColors.primaryLight,
        title: widget.mode.question,
        subtitle: widget.mode == GameMode.operations
            ? OperationDifficulty.forRound(_round).label
            : '${_sequence.length} en total',
      ),
      _Phase.correct => _MessageView(
        key: const ValueKey('correct'),
        icon: Icons.check_circle_rounded,
        color: AppColors.success,
        title: widget.mode == GameMode.operations
            ? '¡CORRECTO! +$_lastPointsAwarded PTS'
            : '¡CORRECTO!',
        subtitle: _sequence,
        subtitleBig: true,
      ),
      _Phase.wrong => _MessageView(
        key: const ValueKey('wrong'),
        icon: Icons.cancel_rounded,
        color: Colors.redAccent,
        title: 'INCORRECTO',
        subtitle: _sequence,
        subtitleBig: true,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: child,
    );
  }

  Widget _buildInput({required bool compact}) {
    final active = _phase == _Phase.input;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: active ? 1 : 0.35,
      child: IgnorePointer(
        ignoring: !active,
        child: Padding(
          padding: EdgeInsets.fromLTRB(28, 8, 28, compact ? 8 : 150),
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
                cursorColor: AppColors.primaryLight,
                decoration: InputDecoration(
                  hintText: '· · ·',
                  hintStyle: AppText.display(
                    color: Colors.white24,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: AppColors.card.withValues(alpha: 0.78),
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.58),
                      width: 1.4,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: AppColors.primaryLight,
                      width: 2,
                    ),
                  ),
                ),
              ),
              if (widget.mode == GameMode.symbols) ...[
                const SizedBox(height: 12),
                _SymbolKeyboard(
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
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Text(
                    'COMPROBAR',
                    style: AppText.title(fontSize: 17, letterSpacing: 2),
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

class _SymbolKeyboard extends StatelessWidget {
  const _SymbolKeyboard({
    required this.symbols,
    required this.onSymbol,
    required this.onBackspace,
  });

  final List<String> symbols;
  final ValueChanged<String> onSymbol;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final s in symbols)
          _Key(
            onTap: () => onSymbol(s),
            child: Text(s, style: AppText.display(fontSize: 20)),
          ),
        _Key(
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
  const _Key({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withValues(alpha: 0.78),
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
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.45),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.mode,
    required this.round,
    required this.hearts,
    required this.maxHearts,
    required this.score,
    required this.topPadding,
    required this.onBack,
  });

  final GameMode mode;
  final int round;
  final int hearts;
  final int maxHearts;
  final int score;
  final double topPadding;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8, topPadding, 20, 0),
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
                  mode.title,
                  style: AppText.label(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'RONDA $round',
                  style: AppText.display(fontSize: 18, letterSpacing: 2),
                ),
                if (mode == GameMode.operations) ...[
                  const SizedBox(height: 2),
                  Text(
                    'TOTAL $score PTS',
                    style: AppText.label(
                      color: AppColors.primaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < maxHearts; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Icon(
                      i < hearts
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(i < hearts),
                      color: i < hearts ? Colors.redAccent : Colors.white30,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShowingView extends StatelessWidget {
  const _ShowingView({
    super.key,
    required this.sequence,
    required this.isOperation,
    required this.operationDifficulty,
    required this.animation,
    required this.paused,
    required this.onPause,
    required this.onSkip,
  });

  final String sequence;
  final bool isOperation;
  final OperationDifficulty operationDifficulty;
  final Animation<double> animation;
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
            paused
                ? 'EN PAUSA'
                : isOperation
                ? '${operationDifficulty.label} · '
                      '+${operationDifficulty.pointsPerAnswer} PTS'
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
                  valueColor: AlwaysStoppedAnimation(AppColors.primaryLight),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              _ControlButton(
                icon: Icons.pause_rounded,
                label: 'PAUSA',
                onTap: onPause,
              ),
              _ControlButton(
                icon: Icons.fast_forward_rounded,
                label: 'OMITIR',
                onTap: onSkip,
              ),
            ],
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
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.58),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryLight, size: 22),
            const SizedBox(width: 8),
            Text(label, style: AppText.title(fontSize: 14, letterSpacing: 1.6)),
          ],
        ),
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
    this.subtitle,
    this.subtitleBig = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final bool subtitleBig;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 72),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppText.title(fontSize: 26, letterSpacing: 2),
            ),
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
