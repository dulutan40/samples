import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../game/world.dart';
import '../../helpers/colors.dart';
import '../../models/cell.dart';

class PlayfieldView extends StatelessWidget {
  const PlayfieldView({super.key, required this.world});

  final World world;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GameColors.computer,
      child: CustomPaint(
        painter: _PlayfieldPainter(
          world,
          MediaQuery.devicePixelRatioOf(context),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PlayfieldPainter extends CustomPainter {
  _PlayfieldPainter(this.world, this.devicePixelRatio);

  final World world;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final n = world.field.size;
    final board = math.min(size.width, size.height);
    final snappedBoard = (board * devicePixelRatio).floor() / devicePixelRatio;
    final cell = snappedBoard / n;
    final origin = Offset(
      ((size.width - snappedBoard) / 2 * devicePixelRatio).round() / devicePixelRatio,
      ((size.height - snappedBoard) / 2 * devicePixelRatio).round() / devicePixelRatio,
    );

    final claimed = Paint()
      ..color = GameColors.claimed
      ..isAntiAlias = false;
    final computer = Paint()
      ..color = GameColors.computer
      ..isAntiAlias = false;
    final trailFill = Paint()
      ..color = GameColors.trail
      ..isAntiAlias = false;
    final edge = Paint()
      ..color = GameColors.claimedEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..isAntiAlias = false;

    for (var y = 0; y < n; y += 1) {
      for (var x = 0; x < n; x += 1) {
        final paint = world.field.cells[y][x] == Cell.player ? claimed : computer;
        canvas.drawRect(_cellRect(origin, cell, x, y), paint);
      }
    }

    for (final point in world.path) {
      canvas.drawRect(_cellRect(origin, cell, point.x, point.y), trailFill);
    }

    final poison = world.poison;
    if (poison != null && poison.alive && world.path.isNotEmpty) {
      final stain = Paint()
        ..color = GameColors.poison.withValues(alpha: 0.55)
        ..isAntiAlias = false;
      final last = poison.index.clamp(0, world.path.length - 1);
      for (var i = 0; i <= last; i += 1) {
        final point = world.path[i];
        canvas.drawRect(_cellRect(origin, cell, point.x, point.y), stain);
      }
    }

    canvas.drawRect(Rect.fromLTWH(origin.dx, origin.dy, cell * n, cell * n), edge);

    final body = Paint()
      ..color = GameColors.monster
      ..strokeWidth = math.max(2, world.monster.bodyWidth * cell)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final bodyPoints = [
      for (final p in world.monster.body)
        Offset(origin.dx + p.x * cell, origin.dy + p.y * cell),
    ];
    if (bodyPoints.length > 1) {
      final bodyPath = Path()..moveTo(bodyPoints.first.dx, bodyPoints.first.dy);
      for (final point in bodyPoints.skip(1)) {
        bodyPath.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(bodyPath, body);
    }

    final head = world.monster.head;
    canvas.drawCircle(
      Offset(origin.dx + head.x * cell, origin.dy + head.y * cell),
      world.monster.headRadius * cell,
      Paint()..color = GameColors.monsterHead,
    );

    if (poison != null && poison.alive && world.path.isNotEmpty) {
      final at = poison.visualCenter;
      final center = Offset(origin.dx + at.x * cell, origin.dy + at.y * cell);
      canvas.drawCircle(center, cell * 0.72, Paint()..color = GameColors.poison);
      canvas.drawCircle(center, cell * 0.38, Paint()..color = GameColors.poisonCore);
    }

    canvas.drawCircle(
      Offset(
        origin.dx + (world.player.x + 0.5) * cell,
        origin.dy + (world.player.y + 0.5) * cell,
      ),
      cell * 0.42,
      Paint()..color = GameColors.player,
    );
  }

  Rect _cellRect(Offset origin, double cell, int x, int y) {
    final pad = 0.5 / devicePixelRatio;
    return Rect.fromLTWH(
      origin.dx + x * cell - pad,
      origin.dy + y * cell - pad,
      cell + pad * 2,
      cell + pad * 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
