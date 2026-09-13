import 'dart:math';

import 'package:flutter/widgets.dart';

import '../model/ball.dart';
import '../model/game_config.dart';
import '../model/paddle.dart';
import 'ai_config.dart';

class AiOpponent {
  AiOpponent({
    required this.config,
    Random? random,
  }) : _rng = random ?? Random();

  AiConfig config;
  final Random _rng;

  double _cooldown = 0;
  double _targetY = 0;

  Paddle step({
    required GameConfig game,
    required Size fieldSize,
    required Ball ball,
    required Paddle paddle,
    required double dtSeconds,
  }) {
    _cooldown -= dtSeconds;
    if (_cooldown <= 0) {
      _cooldown = config.reactionSeconds;
      _targetY = _computeTargetY(game, fieldSize, ball, paddle);
    }

    final delta = _targetY - paddle.centerY;
    final maxDelta = config.maxSpeed * dtSeconds;
    final move = delta.clamp(-maxDelta, maxDelta).toDouble();
    return paddle.copyWith(centerY: paddle.centerY + move);
  }

  double _computeTargetY(
    GameConfig game,
    Size fieldSize,
    Ball ball,
    Paddle paddle,
  ) {
    // If ball is moving away, drift toward center.
    if (ball.velocity.dx <= 0) return fieldSize.height / 2;

    final timeToReach =
        (paddle.x - ball.position.dx) / max(1e-3, ball.velocity.dx);
    final rawY = ball.position.dy + ball.velocity.dy * timeToReach;

    // Mirror-bounce prediction for top/bottom walls.
    final top = game.wallInset + ball.radius;
    final bottom = fieldSize.height - game.wallInset - ball.radius;
    final span = bottom - top;
    double y = rawY - top;

    if (span > 0) {
      final period = 2 * span;
      y = y % period;
      if (y < 0) y += period;
      if (y > span) y = period - y;
      y += top;
    }

    final error = (_rng.nextDouble() * 2 - 1) * config.aimErrorPx;
    return y + error;
  }
}

