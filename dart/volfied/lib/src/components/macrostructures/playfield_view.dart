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
        painter: _PlayfieldPainter(world),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PlayfieldPainter extends CustomPainter {
  _PlayfieldPainter(this.world);

  final World world;

  @override
  void paint(Canvas canvas, Size size) {
    final n = world.field.size;
    final cell = math.min(size.width, size.height) / n;
    final origin = Offset(
      (size.width - cell * n) / 2,
      (size.height - cell * n) / 2,
    );

    final claimed = Paint()..color = GameColors.claimed;
    final computer = Paint()..color = GameColors.computer;
    final edge = Paint()
      ..color = GameColors.claimedEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var y = 0; y < n; y += 1) {
      for (var x = 0; x < n; x += 1) {
        final rect = Rect.fromLTWH(origin.dx + x * cell, origin.dy + y * cell, cell + 0.4, cell + 0.4);
        canvas.drawRect(rect, world.field.cells[y][x] == Cell.player ? claimed : computer);
      }
    }
    canvas.drawRect(Rect.fromLTWH(origin.dx, origin.dy, cell * n, cell * n), edge);

    if (world.path.isNotEmpty) {
      final trail = Paint()
        ..color = GameColors.trail
        ..strokeWidth = math.max(2, cell * 0.7)
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.stroke;
      final points = [
        for (final p in world.path)
          Offset(origin.dx + (p.x + 0.5) * cell, origin.dy + (p.y + 0.5) * cell),
      ];
      final trailPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        trailPath.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(trailPath, trail);
    }

    if (world.poison != null && world.poison!.alive) {
      final p = world.poison!.cell;
      canvas.drawCircle(
        Offset(origin.dx + (p.x + 0.5) * cell, origin.dy + (p.y + 0.5) * cell),
        cell * 0.7,
        Paint()..color = GameColors.poison,
      );
    }

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

    canvas.drawCircle(
      Offset(origin.dx + (world.player.x + 0.5) * cell, origin.dy + (world.player.y + 0.5) * cell),
      cell * 0.55,
      Paint()..color = GameColors.player,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
