import 'dart:collection';

import '../game/playfield.dart';
import '../models/cell.dart';
import '../models/grid_point.dart';

/// Claims every computer region that does not contain the monster.
void claimSafeRegions(Playfield field, GridPoint monsterCell) {
  final seen = <GridPoint>{};
  const neighbors = [
    GridPoint(-1, 0),
    GridPoint(1, 0),
    GridPoint(0, -1),
    GridPoint(0, 1),
  ];

  for (var y = 0; y < field.size; y += 1) {
    for (var x = 0; x < field.size; x += 1) {
      final start = GridPoint(x, y);
      if (field.at(start) != Cell.computer || seen.contains(start)) continue;

      final region = <GridPoint>[];
      final queue = Queue<GridPoint>()..add(start);
      seen.add(start);
      var holdsMonster = false;

      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        region.add(current);
        if (current == monsterCell) holdsMonster = true;
        for (final delta in neighbors) {
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

      if (!holdsMonster) {
        for (final cell in region) {
          field.set(cell, Cell.player);
        }
      }
    }
  }
}
