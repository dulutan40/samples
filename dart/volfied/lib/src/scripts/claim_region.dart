import 'dart:collection';

import '../game/playfield.dart';
import '../models/cell.dart';
import '../models/grid_point.dart';

const neighbors4 = [
  GridPoint(-1, 0),
  GridPoint(1, 0),
  GridPoint(0, -1),
  GridPoint(0, 1),
];

bool touches(Playfield field, GridPoint point, Cell cell) {
  for (final delta in neighbors4) {
    final next = point + delta;
    if (field.inBounds(next) && field.at(next) == cell) return true;
  }
  return false;
}

List<Set<GridPoint>> computerComponents(Playfield field) {
  final seen = <GridPoint>{};
  final parts = <Set<GridPoint>>[];

  for (var y = 0; y < field.size; y += 1) {
    for (var x = 0; x < field.size; x += 1) {
      final start = GridPoint(x, y);
      if (field.at(start) != Cell.computer || seen.contains(start)) continue;

      final region = <GridPoint>{};
      final queue = Queue<GridPoint>()..add(start);
      seen.add(start);

      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        region.add(current);
        for (final delta in neighbors4) {
          final next = current + delta;
          if (!field.inBounds(next) ||
              field.at(next) != Cell.computer ||
              seen.contains(next)) {
            continue;
          }
          seen.add(next);
          queue.add(next);
        }
      }
      parts.add(region);
    }
  }
  return parts;
}

/// Keeps the computer region the monster still occupies and fills every
/// other cut-off region completely.
void claimPartitionedRegions(Playfield field, Iterable<GridPoint> monsterCells) {
  final parts = computerComponents(field);
  if (parts.isEmpty) return;

  final monsterSet = monsterCells.toSet();
  Set<GridPoint> keep = parts.first;
  var keepHits = -1;
  var keepSize = -1;

  for (final part in parts) {
    var hits = 0;
    for (final cell in part) {
      if (monsterSet.contains(cell)) hits += 1;
    }
    final betterHits = hits > keepHits;
    final sameHitsLarger = hits == keepHits && part.length > keepSize && hits > 0;
    final noHitsYetLargest = keepHits <= 0 && hits <= 0 && part.length > keepSize;
    if (betterHits || sameHitsLarger || noHitsYetLargest) {
      keep = part;
      keepHits = hits;
      keepSize = part.length;
    }
  }

  for (final part in parts) {
    if (identical(part, keep)) continue;
    for (final cell in part) {
      field.set(cell, Cell.player);
    }
  }
}
