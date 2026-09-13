import 'dart:collection';
import 'dart:math' as math;

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

/// Fills the polygon the player actually walked (trail + shortest rim walk),
/// then claims any leftover pockets that are cut off from the monster.
void claimClosedLoop({
  required Playfield field,
  required List<GridPoint> trail,
  required GridPoint origin,
  required GridPoint close,
  required Iterable<GridPoint> monsterCells,
}) {
  final rim = shortestPlayerPath(field, close, origin);
  for (final cell in trail) {
    field.set(cell, Cell.player);
  }

  final polygon = _loopVertices(origin, trail, close, rim);
  if (polygon.length >= 3) {
    final interior = _cellsInside(field, polygon);
    final monsterSet = monsterCells.toSet();
    final monsterInside = interior.any(monsterSet.contains);
    if (!monsterInside) {
      for (final cell in interior) {
        field.set(cell, Cell.player);
      }
    }
  }

  claimPartitionedRegions(field, monsterCells);
}

List<GridPoint>? shortestPlayerPath(Playfield field, GridPoint from, GridPoint to) {
  if (!field.inBounds(from) || !field.inBounds(to)) return null;
  if (field.at(from) != Cell.player || field.at(to) != Cell.player) return null;
  if (from == to) return [from];

  final parent = <GridPoint, GridPoint>{};
  final queue = Queue<GridPoint>()..add(from);
  parent[from] = from;

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    if (current == to) break;
    for (final delta in neighbors4) {
      final next = current + delta;
      if (!field.inBounds(next) ||
          field.at(next) != Cell.player ||
          parent.containsKey(next)) {
        continue;
      }
      parent[next] = current;
      queue.add(next);
    }
  }

  if (!parent.containsKey(to)) return null;
  final path = <GridPoint>[];
  var cursor = to;
  while (true) {
    path.add(cursor);
    if (cursor == from) break;
    cursor = parent[cursor]!;
  }
  return path.reversed.toList();
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

List<math.Point<double>> _loopVertices(
  GridPoint origin,
  List<GridPoint> trail,
  GridPoint close,
  List<GridPoint>? rim,
) {
  final cells = <GridPoint>[];
  void add(GridPoint cell) {
    if (cells.isEmpty || cells.last != cell) cells.add(cell);
  }

  add(origin);
  for (final cell in trail) {
    add(cell);
  }
  add(close);
  if (rim != null) {
    for (var i = 1; i < rim.length; i += 1) {
      add(rim[i]);
    }
  }

  return [
    for (final cell in cells) math.Point(cell.x + 0.5, cell.y + 0.5),
  ];
}

Set<GridPoint> _cellsInside(Playfield field, List<math.Point<double>> polygon) {
  final inside = <GridPoint>{};
  for (var y = 0; y < field.size; y += 1) {
    for (var x = 0; x < field.size; x += 1) {
      final cell = GridPoint(x, y);
      if (field.at(cell) != Cell.computer) continue;
      if (_pointInPolygon(polygon, math.Point(x + 0.5, y + 0.5))) {
        inside.add(cell);
      }
    }
  }
  return inside;
}

bool _pointInPolygon(List<math.Point<double>> polygon, math.Point<double> point) {
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i, i += 1) {
    final a = polygon[i];
    final b = polygon[j];
    final straddles = (a.y > point.y) != (b.y > point.y);
    if (!straddles) continue;
    final atX = (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x;
    if (point.x < atX) inside = !inside;
  }
  return inside;
}
