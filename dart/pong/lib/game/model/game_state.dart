import 'ball.dart';
import 'paddle.dart';

class GameScore {
  const GameScore({required this.left, required this.right});

  final int left;
  final int right;

  GameScore copyWith({int? left, int? right}) =>
      GameScore(left: left ?? this.left, right: right ?? this.right);
}

enum GamePhase { ready, playing, paused, pointScored }

class GameState {
  const GameState({
    required this.ball,
    required this.leftPaddle,
    required this.rightPaddle,
    required this.score,
    required this.phase,
  });

  final Ball ball;
  final Paddle leftPaddle;
  final Paddle rightPaddle;
  final GameScore score;
  final GamePhase phase;

  GameState copyWith({
    Ball? ball,
    Paddle? leftPaddle,
    Paddle? rightPaddle,
    GameScore? score,
    GamePhase? phase,
  }) {
    return GameState(
      ball: ball ?? this.ball,
      leftPaddle: leftPaddle ?? this.leftPaddle,
      rightPaddle: rightPaddle ?? this.rightPaddle,
      score: score ?? this.score,
      phase: phase ?? this.phase,
    );
  }
}

