import 'dart:math' as math;

import '../game/playfield.dart';
import '../helpers/constants.dart';
import '../models/cell.dart';
import '../models/grid_point.dart';

class Monster {
  Monster(this.field, math.Random random) : _random = random {
    reset(big: true);
  }

  final Playfield field;
  final math.Random _random;

  late math.Point<double> head;
  final List<math.Point<double>> body = [];
  late math.Point<double> velocity;
  late bool big;
  late double headRadius;
  late double bodyWidth;
  late int bodyLength;
  double _untilTurn = GameConstants.monsterTurnSeconds;

  void reset({required bool big}) {
    this.big = big;
    final playArea = field.startingInner.toDouble();
    final area = playArea *
        (big ? GameConstants.bigAreaFraction : GameConstants.smallAreaFraction);
    final headArea =
        area * (big ? GameConstants.bigHeadShare : GameConstants.smallHeadShare);
    final fullHeadRadius = math.sqrt(headArea / math.pi);
    headRadius = fullHeadRadius * 0.5;
    final bodyArea = area - headArea;
    bodyWidth = math.max(0.7, fullHeadRadius * (big ? 0.55 : 0.45));
    bodyLength = math.max(8, (bodyArea / bodyWidth).round());

    head = math.Point(field.size / 2, field.size / 2);
    body
      ..clear()
      ..addAll(List.generate(bodyLength, (_) => head));
    _pickVelocity();
    _untilTurn = GameConstants.monsterTurnSeconds;
  }

  GridPoint get occupiedCell {
    final x = head.x.floor().clamp(1, field.size - 2);
    final y = head.y.floor().clamp(1, field.size - 2);
    return GridPoint(x, y);
  }

  void update(double dt, {required bool shouldBeBig}) {
    if (shouldBeBig != big) {
      reset(big: shouldBeBig);
    }

    _untilTurn -= dt;
    if (_untilTurn <= 0) {
      _pickVelocity();
      _untilTurn = GameConstants.monsterTurnSeconds * (0.6 + _random.nextDouble());
    }

    var next = math.Point(
      head.x + velocity.x * dt,
      head.y + velocity.y * dt,
    );

    if (!_isOpen(next)) {
      _pickVelocity();
      next = math.Point(
        head.x + velocity.x * dt,
        head.y + velocity.y * dt,
      );
      if (!_isOpen(next)) return;
    }

    head = next;
    body.insert(0, head);
    while (body.length > bodyLength) {
      body.removeLast();
    }
  }

  void _pickVelocity() {
    final angle = _random.nextDouble() * math.pi * 2;
    velocity = math.Point(
      math.cos(angle) * GameConstants.monsterSpeed,
      math.sin(angle) * GameConstants.monsterSpeed,
    );
  }

  bool _isOpen(math.Point<double> point) {
    final cell = GridPoint(point.x.floor(), point.y.floor());
    if (!field.inBounds(cell)) return false;
    if (field.at(cell) != Cell.computer) return false;
    final pad = headRadius + 0.35;
    if (point.x < pad ||
        point.y < pad ||
        point.x > field.size - pad ||
        point.y > field.size - pad) {
      return false;
    }
    return true;
  }
}
