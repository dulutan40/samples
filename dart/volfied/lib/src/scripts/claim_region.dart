import 'dart:collection';

import '../game/playfield.dart';
import '../models/cell.dart';
import '../models/grid_point.dart';

const _neighbors = [
  GridPoint(-1, 0),
  GridPoint(1, 0),
  GridPoint(0, -1),
  GridPoint(0, 1),
];

bool touches(Playfield field, GridPoint point, Cell cell) {
  for (final delta in _neighbors) {
    final next = point + delta;
    if (field.inBounds(next) && field.at(next) == cell) return true;
  }
  return false;
}

GridPoint? nearestComputerCell(Playfield field, GridPoint near) {
  if (field.inBounds(near) && field.at(near) == Cell.computer) return near;

  GridPoint? best;
  var bestDist = 1 << 20;
  for (var y = 0; y < field.size; y += 1) {
    for (var x = 0; x < field.size; x += 1) {
      final point = GridPoint(x, y);
      if (field.at(point) != Cell.computer) continue;
      final dist = (point.x - near.x).abs() + (point.y - near.y).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = point;
      }
    }
  }
  return best;
}

/// After the trail is painted as player land, keep only the computer cells
/// the monster can still walk. Everything else was fully cut off by the path.
void claimEnclosedRegion(Playfield field, GridPoint monsterHint) {
  final seed = nearestComputerCell(field, monsterHint);
  if (seed == null) return;

  final reachable = <GridPoint>{};
  final queue = Queue<GridPoint>()..add(seed);
  reachable.add(seed);

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    for (final delta in _neighbors) {
      final next = current + delta;
      if (!field.inBounds(next) ||
          field.at(next) != Cell.computer ||
          reachable.contains(next)) {
        continue;
      }
      reachable.add(next);
      queue.add(next);
    }
  }

  for (var y = 0; y < field.size; y += 1) {
    for (var x = 0; x < field.size; x += 1) {
      final point = GridPoint(x, y);
      if (field.at(point) == Cell.computer && !reachable.contains(point)) {
        field.set(point, Cell.player);
      }
    }
  }
}
