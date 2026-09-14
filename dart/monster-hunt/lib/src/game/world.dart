import 'dart:math' as math;

import '../helpers/constants.dart';
import '../helpers/geometry.dart';
import '../models/cell.dart';
import '../models/direction.dart';
import '../models/game_status.dart';
import '../models/grid_point.dart';
import '../scripts/claim_region.dart';
import '../scripts/monster_ai.dart';
import '../scripts/poison_travel.dart';
import 'playfield.dart';

class World {
  World({math.Random? random}) : _random = random ?? math.Random() {
    reset();
  }

  final math.Random _random;
  final Playfield field = Playfield();
  late Monster monster;
  late GridPoint player;
  final List<GridPoint> path = [];
  Poison? poison;
  GameStatus status = GameStatus.playing;
  bool drawing = false;
  bool spaceHeld = false;
  Direction? heldDirection;
  GridPoint? pathOrigin;

  double _moveAcc = 0;

  double get percent => field.claimedPercent();

  bool get onPath => drawing && path.isNotEmpty;

  void reset() {
    field.reset();
    player = GridPoint(0, field.size ~/ 2);
    path.clear();
    pathOrigin = null;
    drawing = false;
    poison = null;
    status = GameStatus.playing;
    _moveAcc = 0;
    monster = Monster(field, _random);
  }

  void setSpace(bool held) {
    spaceHeld = held;
  }

  void setDirection(Direction? direction) {
    heldDirection = direction;
  }

  void update(double dt) {
    if (status != GameStatus.playing) return;

    monster.update(
      dt,
      prey: cellCenter(player),
      hunt: drawing,
    );
    _resolveMonsterTouch();

    if (status != GameStatus.playing) return;

    if (poison != null) {
      poison!.advance(dt, GameConstants.poisonStepSeconds);
      if (drawing && (poison!.reachedUser || poison!.overranRetreat)) {
        status = GameStatus.lost;
        return;
      }
    }

    _moveAcc += dt;
    while (_moveAcc >= GameConstants.playerStepSeconds) {
      _moveAcc -= GameConstants.playerStepSeconds;
      if (heldDirection != null) {
        _step(heldDirection!);
      }
    }
  }

  void _step(Direction direction) {
    if (status != GameStatus.playing) return;
    final next = player + direction.delta;
    if (!field.inBounds(next)) return;

    if (drawing) {
      if (field.at(next) == Cell.player) {
        player = next;
        _closeClaim();
        return;
      }
      if (spaceHeld && field.at(next) == Cell.computer && !path.contains(next)) {
        path.add(next);
        player = next;
        return;
      }
      if (!spaceHeld) {
        _retreat(next);
      }
      return;
    }

    if (spaceHeld && field.at(next) == Cell.computer) {
      drawing = true;
      pathOrigin = player;
      path
        ..clear()
        ..add(next);
      player = next;
      return;
    }

    if (field.at(next) == Cell.player && field.isShore(next)) {
      player = next;
    }
  }

  void _retreat(GridPoint next) {
    if (path.length >= 2 && next == path[path.length - 2]) {
      path.removeLast();
      player = next;
      if (poison != null && poison!.index >= path.length) {
        status = GameStatus.lost;
      }
      return;
    }
    if (path.length == 1 && pathOrigin != null && next == pathOrigin) {
      player = pathOrigin!;
      path.clear();
      pathOrigin = null;
      drawing = false;
      poison = null;
    }
  }

  void _closeClaim() {
    final origin = pathOrigin;
    final trail = List<GridPoint>.from(path);
    final complete = trail.isNotEmpty &&
        origin != null &&
        _isContinuous(trail) &&
        touches(field, trail.first, Cell.player) &&
        touches(field, trail.last, Cell.player);

    if (complete) {
      claimClosedLoop(
        field: field,
        trail: trail,
        origin: origin,
        close: player,
        monsterCells: [monster.sideCell],
      );
    } else {
      for (final cell in trail) {
        field.set(cell, Cell.player);
      }
    }
    monster.freeFromWalls();

    path.clear();
    pathOrigin = null;
    drawing = false;
    poison = null;
    if (field.isShore(player) || field.at(player) == Cell.player) {
      if (!field.isShore(player)) {
        player = _nearestShore(player);
      }
    }
    if (percent >= GameConstants.winPercent) {
      status = GameStatus.won;
    }
  }

  GridPoint _nearestShore(GridPoint from) {
    GridPoint best = from;
    var bestDist = 1 << 20;
    for (var y = 0; y < field.size; y += 1) {
      for (var x = 0; x < field.size; x += 1) {
        final point = GridPoint(x, y);
        if (!field.isShore(point)) continue;
        final dist = (point.x - from.x).abs() + (point.y - from.y).abs();
        if (dist < bestDist) {
          bestDist = dist;
          best = point;
        }
      }
    }
    return best;
  }

  void _resolveMonsterTouch() {
    if (!drawing || path.isEmpty) return;
    final hit = _monsterHitsPath();
    if (hit != null) {
      poison ??= Poison(path: path, index: hit);
      return;
    }
    if (poison == null && _monsterHitsPlayer()) {
      status = GameStatus.lost;
    }
  }

  bool _monsterHitsPlayer() {
    return distance(cellCenter(player), monster.head) <= monster.headRadius;
  }

  bool _isContinuous(List<GridPoint> cells) {
    for (var i = 1; i < cells.length; i += 1) {
      final gap =
          (cells[i].x - cells[i - 1].x).abs() + (cells[i].y - cells[i - 1].y).abs();
      if (gap != 1) return false;
    }
    return true;
  }

  int? _monsterHitsPath() {
    final last = path.length - 1;
    int? best;
    var bestDist = double.infinity;
    for (var i = 0; i < last; i += 1) {
      final center = cellCenter(path[i]);
      if (!_overlapsMonster(center)) continue;
      final gap = distance(center, monster.head);
      if (gap < bestDist) {
        bestDist = gap;
        best = i;
      }
    }
    return best;
  }

  bool _overlapsMonster(math.Point<double> point) {
    if (distance(point, monster.head) <= monster.headRadius + 0.2) {
      return true;
    }
    for (var i = 0; i < monster.body.length - 1; i += 1) {
      final gap = distanceToSegment(point, monster.body[i], monster.body[i + 1]);
      if (gap <= monster.bodyWidth * 0.45) return true;
    }
    return false;
  }
}
