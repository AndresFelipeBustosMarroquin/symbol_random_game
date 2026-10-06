import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:symbol_random_game/features/game/operation_challenge.dart';
import 'package:symbol_random_game/features/game/game_screen.dart';
import 'package:symbol_random_game/features/leaderboard/score_screen.dart';

void main() {
  test('operation difficulty progresses from basic through advanced', () {
    expect(OperationDifficulty.forRound(1), OperationDifficulty.basic);
    expect(OperationDifficulty.forRound(4), OperationDifficulty.basic);
    expect(OperationDifficulty.forRound(5), OperationDifficulty.medium);
    expect(OperationDifficulty.forRound(8), OperationDifficulty.medium);
    expect(OperationDifficulty.forRound(9), OperationDifficulty.advanced);
  });

  test('higher operation levels award noticeably more points', () {
    expect(OperationDifficulty.basic.pointsPerAnswer, 1);
    expect(OperationDifficulty.medium.pointsPerAnswer, 3);
    expect(OperationDifficulty.advanced.pointsPerAnswer, 5);
  });

  test('generated challenges have a correct positive answer', () {
    for (final difficulty in OperationDifficulty.values) {
      final random = Random(difficulty.scoreLevel);
      for (var i = 0; i < 50; i++) {
        final challenge = OperationChallenge.generate(
          random: random,
          difficulty: difficulty,
        );
        expect(_evaluate(challenge.expression), challenge.answer);
        expect(challenge.answer, greaterThanOrEqualTo(0));
      }
    }
  });

  test('score entries recognize the operations mode returned by the API', () {
    final score = ScoreEntry.fromJson({
      'jugador': 'Jugador',
      'modo': 'OPERACIONES',
      'incremento': 2,
      'vidas': 3,
      'tiempoPregunta': 5,
      'tiempoTotal': 45,
      'resultado': 8,
      'edad': 20,
    });

    expect(score.modo, GameMode.operations);
  });
}

int _evaluate(String expression) {
  final basic = RegExp(r'^(\d+) ([+-]) (\d+)$').firstMatch(expression);
  if (basic != null) {
    final left = int.parse(basic.group(1)!);
    final right = int.parse(basic.group(3)!);
    return basic.group(2) == '+' ? left + right : left - right;
  }

  final medium = RegExp(r'^(\d+) ([×÷]) (\d+)$').firstMatch(expression);
  if (medium != null) {
    final left = int.parse(medium.group(1)!);
    final right = int.parse(medium.group(3)!);
    return medium.group(2) == '×' ? left * right : left ~/ right;
  }

  final grouped = RegExp(r'^\((\d+) \+ (\d+)\) × (\d+)$')
      .firstMatch(expression);
  if (grouped != null) {
    return (int.parse(grouped.group(1)!) + int.parse(grouped.group(2)!)) *
        int.parse(grouped.group(3)!);
  }

  final precedence = RegExp(r'^(\d+) × (\d+) \+ (\d+)$')
      .firstMatch(expression)!;
  return int.parse(precedence.group(1)!) * int.parse(precedence.group(2)!) +
      int.parse(precedence.group(3)!);
}
