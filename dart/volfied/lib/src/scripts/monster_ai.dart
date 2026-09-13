import 'dart:math' as math;

import '../game/playfield.dart';
import '../helpers/constants.dart';
import '../helpers/geometry.dart';
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
  double _untilJitter = GameConstants.monsterTurnSeconds;
  double _orbitAngle = 0;
  double _orbitRadius = GameConstants.monsterOrbitMax;
  double _orbitSign = 1;

  void reset({required bool big}) {
    _applySize(big: big);
    head = math.Point(field.size / 2, field.size / 2);
    body
      ..clear()
      ..addAll(List.generate(bodyLength, (_) => head));
    velocity = const math.Point(0, 0);
    _untilJitter = GameConstants.monsterTurnSeconds;
    _orbitAngle = _random.nextDouble() * math.pi * 2;
    _orbitRadius = GameConstants.monsterOrbitMax;
    _orbitSign = _random.nextBool() ? 1 : -1;
  }

  GridPoint get occupiedCell {
    final x = head.x.floor().clamp(1, field.size - 2);
    final y = head.y.floor().clamp(1, field.size - 2);
    return GridPoint(x, y);
  }

  Iterable<GridPoint> occupiedCells() sync* {
    final seen = <GridPoint>{};
    void add(math.Point<double> point, double radius) {
      final minX = (point.x - radius).floor();
      final maxX = (point.x + radius).ceil();
      final minY = (point.y - radius).floor();
      final maxY = (point.y + radius).ceil();
      for (var y = minY; y <= maxY; y += 1) {
        for (var x = minX; x <= maxX; x += 1) {
          final cell = GridPoint(x, y);
          if (!field.inBounds(cell) || seen.contains(cell)) continue;
          final cx = x + 0.5;
          final cy = y + 0.5;
          final dx = cx - point.x;
          final dy = cy - point.y;
          if (dx * dx + dy * dy <= radius * radius) {
            seen.add(cell);
          }
        }
      }
    }

    add(head, headRadius + 0.6);
    for (final point in body) {
      add(point, bodyWidth * 0.6);
    }
    yield* seen;
  }

  void update(
    double dt, {
    required bool shouldBeBig,
    required math.Point<double> prey,
    bool hunt = false,
  }) {
    if (shouldBeBig != big) {
      _applySize(big: shouldBeBig);
    }

    final speed = hunt ? GameConstants.monsterHuntSpeed : GameConstants.monsterSpeed;
    final minR = hunt ? GameConstants.monsterHuntOrbitMin : GameConstants.monsterOrbitMin;
    final maxR = hunt ? GameConstants.monsterHuntOrbitMax : GameConstants.monsterOrbitMax;
    final keepAway = hunt ? GameConstants.monsterHuntKeepAway : GameConstants.monsterKeepAway;
    _orbitRadius = _orbitRadius.clamp(minR, maxR);

    _untilJitter -= dt;
    if (_untilJitter <= 0) {
      if (_random.nextDouble() < 0.3) _orbitSign *= -1;
      _orbitRadius = minR + _random.nextDouble() * (maxR - minR);
      _untilJitter = GameConstants.monsterTurnSeconds * (0.7 + _random.nextDouble());
    }

    final spin = (hunt ? 1.8 : 1.15) * _orbitSign;
    _orbitAngle += spin * dt;

    final zone = _zoneCenter(prey);
    final orbit = math.Point(
      zone.x + math.cos(_orbitAngle) * _orbitRadius,
      zone.y + math.sin(_orbitAngle) * _orbitRadius,
    );

    var desired = _toward(orbit, speed);
    final gap = distance(head, prey);
    if (gap < keepAway) {
      desired = _away(prey, speed);
    }

    velocity = math.Point(
      velocity.x + (desired.x - velocity.x) * GameConstants.monsterSteer,
      velocity.y + (desired.y - velocity.y) * GameConstants.monsterSteer,
    );

    if (!_tryMove(dt)) {
      _orbitAngle += _orbitSign * 0.7;
      velocity = _nudge(_toward(orbit, speed), speed * 0.35);
      _tryMove(dt);
    }
  }

  math.Point<double> _zoneCenter(math.Point<double> prey) {
    final mid = field.size / 2;
    return math.Point(
      prey.x + (mid - prey.x) * 0.18,
      prey.y + (mid - prey.y) * 0.18,
    );
  }

  void _applySize({required bool big}) {
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
    if (body.isEmpty) return;
    while (body.length > bodyLength) {
      body.removeLast();
    }
    while (body.length < bodyLength) {
      body.add(body.last);
    }
  }

  math.Point<double> _toward(math.Point<double> target, double speed) {
    final gap = distance(head, target);
    if (gap < 0.001) return velocity;
    return math.Point(
      (target.x - head.x) / gap * speed,
      (target.y - head.y) / gap * speed,
    );
  }

  math.Point<double> _away(math.Point<double> target, double speed) {
    final gap = distance(head, target);
    if (gap < 0.001) {
      return math.Point(math.cos(_orbitAngle) * speed, math.sin(_orbitAngle) * speed);
    }
    return math.Point(
      (head.x - target.x) / gap * speed,
      (head.y - target.y) / gap * speed,
    );
  }

  math.Point<double> _nudge(math.Point<double> base, double amount) {
    final angle = _random.nextDouble() * math.pi * 2;
    return math.Point(
      base.x + math.cos(angle) * amount,
      base.y + math.sin(angle) * amount,
    );
  }

  bool _tryMove(double dt) {
    final full = math.Point(head.x + velocity.x * dt, head.y + velocity.y * dt);
    if (_commit(full)) return true;
    final slideX = math.Point(head.x + velocity.x * dt, head.y);
    if (_commit(slideX)) return true;
    final slideY = math.Point(head.x, head.y + velocity.y * dt);
    return _commit(slideY);
  }

  bool _commit(math.Point<double> next) {
    if (!_isOpen(next)) return false;
    head = next;
    body.insert(0, head);
    while (body.length > bodyLength) {
      body.removeLast();
    }
    return true;
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
