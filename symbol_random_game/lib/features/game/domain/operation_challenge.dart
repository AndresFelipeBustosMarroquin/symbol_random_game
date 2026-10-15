import 'dart:math';

enum OperationDifficulty {
  basic('BÁSICO', 1, 1),
  medium('MEDIO', 2, 3),
  advanced('AVANZADO', 3, 5);

  const OperationDifficulty(this.label, this.scoreLevel, this.pointsPerAnswer);

  final String label;
  final int scoreLevel;
  final int pointsPerAnswer;

  static OperationDifficulty forRound(int round) {
    if (round <= 4) return OperationDifficulty.basic;
    if (round <= 8) return OperationDifficulty.medium;
    return OperationDifficulty.advanced;
  }
}

class OperationChallenge {
  const OperationChallenge({required this.expression, required this.answer});

  final String expression;
  final int answer;

  static OperationChallenge generate({
    required Random random,
    required OperationDifficulty difficulty,
  }) {
    return switch (difficulty) {
      OperationDifficulty.basic => _basic(random),
      OperationDifficulty.medium => _medium(random),
      OperationDifficulty.advanced => _advanced(random),
    };
  }

  static OperationChallenge _basic(Random random) {
    final left = random.nextInt(20) + 1;
    final right = random.nextInt(20) + 1;

    if (random.nextBool()) {
      return OperationChallenge(
        expression: '$left + $right',
        answer: left + right,
      );
    }

    final larger = max(left, right);
    final smaller = min(left, right);
    return OperationChallenge(
      expression: '$larger - $smaller',
      answer: larger - smaller,
    );
  }

  static OperationChallenge _medium(Random random) {
    if (random.nextBool()) {
      final left = random.nextInt(11) + 2;
      final right = random.nextInt(11) + 2;
      return OperationChallenge(
        expression: '$left × $right',
        answer: left * right,
      );
    }

    final divisor = random.nextInt(11) + 2;
    final answer = random.nextInt(11) + 2;
    return OperationChallenge(
      expression: '${divisor * answer} ÷ $divisor',
      answer: answer,
    );
  }

  static OperationChallenge _advanced(Random random) {
    final left = random.nextInt(19) + 2;
    final middle = random.nextInt(19) + 2;
    final right = random.nextInt(10) + 2;

    if (random.nextBool()) {
      return OperationChallenge(
        expression: '($left + $middle) × $right',
        answer: (left + middle) * right,
      );
    }

    return OperationChallenge(
      expression: '$left × $middle + $right',
      answer: left * middle + right,
    );
  }
}
