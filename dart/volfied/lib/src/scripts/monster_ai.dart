import 'dart:collection';
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

double radiusFor(Playfield field, {required bool big}) {
  final playArea = field.startingInner.toDouble();
  final area = playArea *
      (big ? GameConstants.bigAreaFraction : GameConstants.smallAreaFraction);
  final headArea =
      area * (big ? GameConstants.bigHeadShare : GameConstants.smallHeadShare);
  return math.sqrt(headArea / math.pi) * 0.5;
}

math.Point<double>? nearbyFit(
  Playfield field,
  math.Point<double> origin,
  double radius, {
  double maxShift = GameConstants.monsterGrowNudge,
}) {
  if (headFits(field, origin, radius)) return origin;
  math.Point<double>? best;
  var bestScore = double.infinity;
  final mid = field.size / 2;
  for (var step = 0.5; step <= maxShift + 0.001; step += 0.5) {
    const samples = 16;
    for (var i = 0; i < samples; i += 1) {
      final angle = i * math.pi * 2 / samples;
      final point = math.Point(
        origin.x + math.cos(angle) * step,
        origin.y + math.sin(angle) * step,
      );
      if (!headFits(field, point, radius)) continue;
      final inward = (point.x - mid) * (point.x - mid) + (point.y - mid) * (point.y - mid);
      final score = step * 20 + inward * 0.01;
      if (score < bestScore) {
        bestScore = score;
        best = point;
      }
    }
  }
  return best;
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
  double _stuckHeat = 0;

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
    _stuckHeat = 0;
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
        _beginPatrol();
      }
      return;
    }

    _cycleAcc += dt;
    if (_cycleAcc >= GameConstants.monsterCycleSeconds) {
      _beginCollect();
      return;
    }

    final panic = _refreshPanic();
    final speed =
        (hunt ? GameConstants.monsterHuntSpeed : GameConstants.monsterSpeed) *
            (1 + panic * 0.55);
    final minR = hunt ? GameConstants.monsterHuntOrbitMin : GameConstants.monsterOrbitMin;
    final maxR = hunt ? GameConstants.monsterHuntOrbitMax : GameConstants.monsterOrbitMax;
    final keepAway = hunt ? GameConstants.monsterHuntKeepAway : GameConstants.monsterKeepAway;
    _orbitRadius = _orbitRadius.clamp(minR, maxR);

    _untilJitter -= dt;
    if (_untilJitter <= 0) {
      if (_random.nextDouble() < 0.55 + panic * 0.35) _orbitSign *= -1;
      _orbitRadius = minR + _random.nextDouble() * (maxR - minR);
      _orbitAngle += (_random.nextDouble() - 0.5) * (1.8 + panic * 2.4);
      _untilJitter =
          GameConstants.monsterTurnSeconds * (0.35 + _random.nextDouble()) / (1 + panic * 2);
    }

    final spin = (hunt ? 2.4 : 1.7) * _orbitSign * (1 + panic * 1.6);
    _orbitAngle += spin * dt;

    final zone = _zoneCenter(prey);
    final orbit = math.Point(
      zone.x + math.cos(_orbitAngle) * _orbitRadius,
      zone.y + math.sin(_orbitAngle) * _orbitRadius,
    );

    var desired = _nudge(_toward(orbit, speed), speed * (0.28 + panic * 0.45));
    final gap = distance(head, prey);
    if (gap < keepAway) {
      desired = _nudge(_away(prey, speed), speed * 0.18);
    }

    final steer = (GameConstants.monsterSteer * (1 + panic * 0.9)).clamp(0.1, 0.95);
    velocity = math.Point(
      velocity.x + (desired.x - velocity.x) * steer,
      velocity.y + (desired.y - velocity.y) * steer,
    );

    if (!_tryMove(dt)) {
      _stuckHeat = (_stuckHeat + dt * 2).clamp(0, 1);
      _orbitAngle += _orbitSign * (0.7 + panic);
      velocity = _nudge(_toward(orbit, speed), speed * (0.35 + panic * 0.5));
      _tryMove(dt);
    } else {
      _stuckHeat = math.max(0, _stuckHeat - dt * 0.35);
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
    phase = MonsterPhase.rest;
    _restAcc = 0;
    _cycleAcc = 0;
  }

  void tryResizeForPatrol() => _applyPlannedSize();

  void _beginPatrol() {
    _applyPlannedSize();
    phase = MonsterPhase.charge;
    _cycleAcc = 0;
    _stuckHeat = 0;
  }

  void _applyPlannedSize() {
    if (!cycle.big) {
      _applySize(big: false);
      return;
    }
    final largeRadius = radiusFor(field, big: true);
    if (headFits(field, head, largeRadius)) {
      _applySize(big: true);
      return;
    }
    final shift = nearbyFit(
      field,
      head,
      largeRadius,
      maxShift: GameConstants.monsterGrowNudge,
    );
    if (shift != null) {
      _placeHead(shift);
      _applySize(big: true);
      return;
    }
    cycle.lockTiny();
    _applySize(big: false);
  }

  double _refreshPanic() {
    final room = _homeArea();
    final comfort = math.max(80, math.pi * math.pow(headRadius * 5, 2));
    final cramped = (1 - room / comfort).clamp(0.0, 1.0);
    return (cramped * 0.75 + _stuckHeat * 0.55).clamp(0.0, 1.0);
  }

  int _homeArea() {
    final start = sideCell;
    if (!field.inBounds(start) || field.at(start) != Cell.computer) return 0;
    final seen = <GridPoint>{start};
    final queue = Queue<GridPoint>()..add(start);
    var count = 0;
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      count += 1;
      for (final delta in neighbors4) {
        final next = current + delta;
        if (seen.contains(next) ||
            !field.inBounds(next) ||
            field.at(next) != Cell.computer) {
          continue;
        }
        seen.add(next);
        queue.add(next);
      }
    }
    return count;
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
    headRadius = radiusFor(field, big: big);
    final bodyArea = area - headArea;
    bodyWidth = math.max(0.7, headRadius * 2 * (big ? 0.55 : 0.45));
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
