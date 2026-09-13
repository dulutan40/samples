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

  double _moveAcc = 0;
  double _poisonAcc = 0;

  double get percent => field.claimedPercent();

  bool get onPath => drawing && path.isNotEmpty;

  void reset() {
    field.reset();
    player = GridPoint(0, field.size ~/ 2);
    path.clear();
    drawing = false;
    poison = null;
    status = GameStatus.playing;
    _moveAcc = 0;
    _poisonAcc = 0;
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

    monster.update(dt, shouldBeBig: percent < GameConstants.shrinkAtPercent);
    _resolveMonsterTouch();

    if (status != GameStatus.playing) return;

    _poisonAcc += dt;
    while (poison != null && _poisonAcc >= GameConstants.poisonStepSeconds) {
      _poisonAcc -= GameConstants.poisonStepSeconds;
      poison!.stepTowardUser();
      if (poison!.reachedUser && drawing) {
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
      if (field.at(next) == Cell.computer && !path.contains(next)) {
        path.add(next);
        player = next;
      }
      return;
    }

    if (spaceHeld && field.at(next) == Cell.computer) {
      drawing = true;
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

  void _closeClaim() {
    final complete = path.isNotEmpty &&
        _isContinuous(path) &&
        touches(field, path.first, Cell.player) &&
        touches(field, path.last, Cell.player);
    for (final cell in path) {
      field.set(cell, Cell.player);
    }
    if (complete) {
      claimPartitionedRegions(field, monster.occupiedCells());
    }
    path.clear();
    drawing = false;
    poison = null;
    if (field.isShore(player) || field.at(player) == Cell.player) {
      // stay put; snap to nearest shore if we landed inside claimed land
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
    if (!drawing) return;
    if (_monsterHitsPlayer()) {
      status = GameStatus.lost;
      return;
    }
    if (path.isEmpty || poison != null) return;
    final hit = _monsterHitsPath();
    if (hit != null) {
      poison = Poison(path: path, index: hit);
    }
  }

  bool _monsterHitsPlayer() {
    return _overlapsMonster(cellCenter(player));
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
    for (var i = 0; i < path.length; i += 1) {
      if (_overlapsMonster(cellCenter(path[i]))) return i;
    }
    return null;
  }

  bool _overlapsMonster(math.Point<double> point) {
    if (distance(point, monster.head) <= monster.headRadius + 0.35) {
      return true;
    }
    for (var i = 0; i < monster.body.length - 1; i += 1) {
      final gap = distanceToSegment(point, monster.body[i], monster.body[i + 1]);
      if (gap <= monster.bodyWidth * 0.55) return true;
    }
    return false;
  }
}
