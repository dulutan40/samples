import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

import '../bonus/bonus_item.dart';
import '../bonus/bonus_manager.dart';
import '../bonus/bonus_type.dart';
import '../model/game_config.dart';
import '../model/game_state.dart';

class PongPainter extends CustomPainter {
  PongPainter({
    required this.state,
    required this.config,
    required this.colorScheme,
    this.bonusItem,
    this.pickup,
    this.pickupT,
  });

  final GameState state;
  final GameConfig config;
  final ColorScheme colorScheme;
  final BonusItem? bonusItem;
  final BonusPickupEvent? pickup;
  final double? pickupT; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = colorScheme.surface;
    canvas.drawRect(Offset.zero & size, bg);

    final midLine = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.15)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(size.width / 2, config.wallInset),
      Offset(size.width / 2, size.height - config.wallInset),
      midLine,
    );

    final wall = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, config.wallInset),
      Offset(size.width, config.wallInset),
      wall,
    );
    canvas.drawLine(
      Offset(0, size.height - config.wallInset),
      Offset(size.width, size.height - config.wallInset),
      wall,
    );

    final paddlePaint = Paint()..color = colorScheme.onSurface;
    canvas.drawRRect(
      RRect.fromRectAndRadius(state.leftPaddle.rect, const Radius.circular(8)),
      paddlePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(state.rightPaddle.rect, const Radius.circular(8)),
      paddlePaint,
    );

    final ballPaint = Paint()..color = colorScheme.primary;
    canvas.drawCircle(state.ball.position, state.ball.radius, ballPaint);

    final p = pickup;
    final t = pickupT;
    if (p != null && t != null) {
      final base = _bonusColor(p.type, colorScheme);
      final alpha = (1.0 - t).clamp(0.0, 1.0);
      final ring = Paint()
        ..color = base.withValues(alpha: 0.65 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      final glow = Paint()
        ..color = base.withValues(alpha: 0.18 * alpha)
        ..style = PaintingStyle.fill;

      final r = lerpDouble(10, 44, Curves.easeOut.transform(t))!;
      canvas.drawCircle(p.position, r, glow);
      canvas.drawCircle(p.position, r, ring);
    }

    final item = bonusItem;
    if (item != null) {
      final paint = Paint()
        ..color = _bonusColor(item.type, colorScheme)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(item.position, item.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PongPainter oldDelegate) => true;
}

Color _bonusColor(BonusType t, ColorScheme cs) {
  return switch (t) {
    BonusType.paddleEnlarge => Colors.greenAccent.shade400,
    BonusType.paddleShorten => Colors.redAccent.shade200,
    BonusType.ballSpeedUp => Colors.orangeAccent.shade400,
    BonusType.ballSlowDown => Colors.blueAccent.shade200,
    BonusType.doublePaddle => Colors.purpleAccent.shade200,
  };
}

