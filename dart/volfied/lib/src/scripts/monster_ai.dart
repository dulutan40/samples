import 'dart:math' as math;

import '../game/playfield.dart';
import '../helpers/constants.dart';
import '../helpers/geometry.dart';
import '../models/cell.dart';
import '../models/grid_point.dart';
import 'claim_region.dart';
import 'monster_cycle.dart';

enum MonsterPhase { charge, collect, rest }

bool headFits(Playfield field, math.Point<double> point, double radius) {
  final minX = (point.x - radius).floor();
  final maxX = (point.x + radius).ceil();
  final minY = (point.y - radius).floor();
  final maxY = (point.y + radius).ceil();
  final r2 = radius * radius;
  for (var y = minY; y <= maxY; y += 1) {
    for (var x = minX; x <= maxX; x += 1) {
      final left = x.toDouble();
      final top = y.toDouble();
      final closestX = point.x.clamp(left, left + 1);
      final closestY = point.y.clamp(top, top + 1);
      final dx = point.x - closestX;
      final dy = point.y - closestY;
      if (dx * dx + dy * dy >= r2) continue;
      final cell = GridPoint(x, y);
      if (!field.inBounds(cell) || field.at(cell) != Cell.computer) {
        return false;
      }
    }
  }
  return true;
}

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
  late MonsterCycle cycle;
  MonsterPhase phase = MonsterPhase.charge;
  double _cycleAcc = 0;
  double _collectAcc = 0;
  double _restAcc = 0;
  int _collectFrom = 1;
  double _untilJitter = GameConstants.monsterTurnSeconds;
  double _orbitAngle = 0;
  double _orbitRadius = GameConstants.monsterOrbitMax;
  double _orbitSign = 1;

  bool get collecting => phase == MonsterPhase.collect;

  void reset({required bool big}) {
    cycle = MonsterCycle(largeBurst: GameConstants.monsterStartLargeCycles);
    _applySize(big: big);
    head = math.Point(field.size / 2, field.size / 2);
    body
      ..clear()
      ..addAll(List.generate(bodyLength, (_) => head));
    velocity = const math.Point(0, 0);
    phase = MonsterPhase.charge;
    _cycleAcc = 0;
    _collectAcc = 0;
    _restAcc = 0;
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

  /// Side the monster lives on: the head center, not the fat disk.
  /// Touching a trail must not count as being inside the box.
  GridPoint get sideCell {
    final cell = occupiedCell;
    if (field.inBounds(cell) && field.at(cell) == Cell.computer) return cell;
    return _nearestComputer(head) ?? cell;
  }

  void freeFromWalls() {
    if (headFits(field, head, headRadius)) return;
    final parts = computerComponents(field);
    if (parts.isEmpty) return;

    Set<GridPoint>? home;
    var homeScore = -1e9;
    for (final part in parts) {
      var fits = 0;
      for (final cell in part) {
        if (headFits(field, math.Point(cell.x + 0.5, cell.y + 0.5), headRadius)) {
          fits += 1;
          if (fits >= 2) break;
        }
      }
      if (fits == 0) continue;
      var cx = 0.0;
      var cy = 0.0;
      for (final cell in part) {
        cx += cell.x + 0.5;
        cy += cell.y + 0.5;
      }
      cx /= part.length;
      cy /= part.length;
      final score = part.length - distance(head, math.Point(cx, cy)) * 0.25;
      if (score > homeScore) {
        homeScore = score;
        home = part;
      }
    }
    if (home == null) return;

    math.Point<double>? best;
    var bestDist = double.infinity;
    for (final cell in home) {
      final point = math.Point(cell.x + 0.5, cell.y + 0.5);
      if (!headFits(field, point, headRadius)) continue;
      final gap = distance(head, point);
      if (gap < bestDist) {
        bestDist = gap;
        best = point;
      }
    }
    if (best != null) _placeHead(best);
  }

  GridPoint? _nearestComputer(math.Point<double> from) {
    GridPoint? best;
    var bestDist = double.infinity;
    for (var y = 1; y < field.size - 1; y += 1) {
      for (var x = 1; x < field.size - 1; x += 1) {
        final cell = GridPoint(x, y);
        if (field.at(cell) != Cell.computer) continue;
        final dx = from.x - (x + 0.5);
        final dy = from.y - (y + 0.5);
        final dist = dx * dx + dy * dy;
        if (dist < bestDist) {
          bestDist = dist;
          best = cell;
        }
      }
    }
    return best;
  }

  void _placeHead(math.Point<double> next) {
    final dx = next.x - head.x;
    final dy = next.y - head.y;
    head = next;
    for (var i = 0; i < body.length; i += 1) {
      body[i] = math.Point(body[i].x + dx, body[i].y + dy);
    }
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

    add(head, headRadius);
    for (final point in body) {
      add(point, bodyWidth * 0.5);
    }
    yield* seen;
  }

  void update(
    double dt, {
    required math.Point<double> prey,
    bool hunt = false,
  }) {
    if (phase == MonsterPhase.collect) {
      _collectTail(dt);
      return;
    }
    if (phase == MonsterPhase.rest) {
      _restAcc += dt;
      velocity = const math.Point(0, 0);
      if (_restAcc >= GameConstants.monsterRestSeconds) {
        phase = MonsterPhase.charge;
        _cycleAcc = 0;
      }
      return;
    }

    _cycleAcc += dt;
    if (_cycleAcc >= GameConstants.monsterCycleSeconds) {
      _beginCollect();
      return;
    }

    final speed = hunt ? GameConstants.monsterHuntSpeed : GameConstants.monsterSpeed;
    final minR = hunt ? GameConstants.monsterHuntOrbitMin : GameConstants.monsterOrbitMin;
    final maxR = hunt ? GameConstants.monsterHuntOrbitMax : GameConstants.monsterOrbitMax;
    final keepAway = hunt ? GameConstants.monsterHuntKeepAway : GameConstants.monsterKeepAway;
    _orbitRadius = _orbitRadius.clamp(minR, maxR);

    _untilJitter -= dt;
    if (_untilJitter <= 0) {
      if (_random.nextDouble() < 0.55) _orbitSign *= -1;
      _orbitRadius = minR + _random.nextDouble() * (maxR - minR);
      _orbitAngle += (_random.nextDouble() - 0.5) * 1.8;
      _untilJitter = GameConstants.monsterTurnSeconds * (0.35 + _random.nextDouble());
    }

    final spin = (hunt ? 2.4 : 1.7) * _orbitSign;
    _orbitAngle += spin * dt;

    final zone = _zoneCenter(prey);
    final orbit = math.Point(
      zone.x + math.cos(_orbitAngle) * _orbitRadius,
      zone.y + math.sin(_orbitAngle) * _orbitRadius,
    );

    var desired = _nudge(_toward(orbit, speed), speed * 0.28);
    final gap = distance(head, prey);
    if (gap < keepAway) {
      desired = _nudge(_away(prey, speed), speed * 0.18);
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

  void _beginCollect() {
    phase = MonsterPhase.collect;
    _collectAcc = 0;
    _collectFrom = math.max(1, body.length);
    velocity = const math.Point(0, 0);
  }

  void _collectTail(double dt) {
    _collectAcc += dt;
    final t = (_collectAcc / GameConstants.monsterCollectSeconds).clamp(0.0, 1.0);
    final target = math.max(1, (_collectFrom * (1 - t)).ceil());
    while (body.length > target) {
      body.removeLast();
    }
    if (t < 1 && body.length > 1) return;
    body
      ..clear()
      ..add(head);
    cycle.finishCycle();
    _applySize(big: cycle.big);
    phase = MonsterPhase.rest;
    _restAcc = 0;
    _cycleAcc = 0;
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
    while (body.length < bodyLength && phase == MonsterPhase.charge) {
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
    if (!headFits(field, next, headRadius)) return false;
    head = next;
    body.insert(0, head);
    while (body.length > bodyLength) {
      body.removeLast();
    }
    return true;
  }
}
