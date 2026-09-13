import 'dart:math';

import 'package:flutter/widgets.dart';

import '../model/ball.dart';
import '../model/game_config.dart';
import '../model/paddle.dart';
import '../modifiers/modifier_type.dart';

class PhysicsStepResult {
  const PhysicsStepResult({
    required this.ball,
    required this.leftPaddle,
    required this.rightPaddle,
    required this.leftScored,
    required this.rightScored,
    required this.leftHit,
    required this.rightHit,
  });

  final Ball ball;
  final Paddle leftPaddle;
  final Paddle rightPaddle;
  final bool leftScored;
  final bool rightScored;
  final bool leftHit;
  final bool rightHit;
}

class PongPhysics {
  const PongPhysics();

  PhysicsStepResult step({
    required GameConfig config,
    required Size fieldSize,
    required Ball ball,
    required Paddle left,
    required Paddle right,
    required double dtSeconds,
    ModifierType? modifier,
  }) {
    final top = config.wallInset;
    final bottom = fieldSize.height - config.wallInset;

    var nextBall = ball.copyWith(
      position: ball.position + ball.velocity * dtSeconds,
    );

    // Wall bounce.
    if (nextBall.position.dy - nextBall.radius < top) {
      nextBall = nextBall.copyWith(
        position: Offset(nextBall.position.dx, top + nextBall.radius),
        velocity: Offset(nextBall.velocity.dx, nextBall.velocity.dy.abs()),
      );
    } else if (nextBall.position.dy + nextBall.radius > bottom) {
      nextBall = nextBall.copyWith(
        position: Offset(nextBall.position.dx, bottom - nextBall.radius),
        velocity: Offset(nextBall.velocity.dx, -nextBall.velocity.dy.abs()),
      );
    }

    // Paddle collisions.
    final leftCol = _collideWithPaddle(nextBall, left);
    nextBall = leftCol.ball;
    final rightCol = _collideWithPaddle(nextBall, right);
    nextBall = rightCol.ball;

    // Portal walls modifier: left/right are portals rather than scoring.
    if (modifier == ModifierType.portalWalls) {
      final leftEdge = -config.wallInset;
      final rightEdge = fieldSize.width + config.wallInset;
      if (nextBall.position.dx + nextBall.radius < leftEdge) {
        nextBall = nextBall.copyWith(
          position: Offset(rightEdge + nextBall.radius, nextBall.position.dy),
        );
      } else if (nextBall.position.dx - nextBall.radius > rightEdge) {
        nextBall = nextBall.copyWith(
          position: Offset(leftEdge - nextBall.radius, nextBall.position.dy),
        );
      }
    }

    // Score conditions.
    final leftScored = modifier == ModifierType.portalWalls
        ? false
        : nextBall.position.dx - nextBall.radius >
            fieldSize.width + config.wallInset;
    final rightScored = modifier == ModifierType.portalWalls
        ? false
        : nextBall.position.dx + nextBall.radius < -config.wallInset;

    return PhysicsStepResult(
      ball: nextBall,
      leftPaddle: left,
      rightPaddle: right,
      leftScored: leftScored,
      rightScored: rightScored,
      leftHit: leftCol.hit,
      rightHit: rightCol.hit,
    );
  }

  _Collision _collideWithPaddle(Ball ball, Paddle paddle) {
    final r = paddle.rect;
    final closest = Offset(
      ball.position.dx.clamp(r.left, r.right),
      ball.position.dy.clamp(r.top, r.bottom),
    );
    final delta = ball.position - closest;
    final dist2 = delta.dx * delta.dx + delta.dy * delta.dy;
    final radius2 = ball.radius * ball.radius;
    if (dist2 > radius2) return _Collision(ball: ball, hit: false);

    // Push the ball out along the collision normal.
    final dist = max(0.0001, sqrt(dist2));
    final normal = delta / dist;
    final correctedPos = closest + normal * (ball.radius + 0.5);

    // Reflect velocity.
    final v = ball.velocity;
    final reflected = v - normal * (2 * (v.dx * normal.dx + v.dy * normal.dy));

    // Add "english" based on where it hits the paddle (classic pong feel).
    final rel =
        ((ball.position.dy - paddle.centerY) / paddle.halfHeight).clamp(-1, 1);
    final withSpin = Offset(reflected.dx, reflected.dy + rel * 140);

    // Ensure x direction goes away from paddle.
    final awayX = paddle.x < correctedPos.dx
        ? withSpin.dx.abs()
        : -withSpin.dx.abs();

    return _Collision(
      ball: ball.copyWith(
        position: correctedPos,
        velocity: Offset(awayX, withSpin.dy),
      ),
      hit: true,
    );
  }
}

class _Collision {
  const _Collision({required this.ball, required this.hit});
  final Ball ball;
  final bool hit;
}

