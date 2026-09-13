import 'package:flutter_test/flutter_test.dart';
import 'package:volfied/src/game/playfield.dart';
import 'package:volfied/src/models/cell.dart';
import 'package:volfied/src/models/grid_point.dart';

void main() {
  test('the outer corners are shore, so the four rims are one loop', () {
    final field = Playfield(size: 8);
    const corners = [
      GridPoint(0, 0),
      GridPoint(0, 7),
      GridPoint(7, 0),
      GridPoint(7, 7),
    ];
    for (final corner in corners) {
      expect(field.isShore(corner), isTrue, reason: '$corner should be walkable');
    }

    expect(_shoreReachable(field, const GridPoint(0, 3), const GridPoint(3, 0)), isTrue);
    expect(_shoreReachable(field, const GridPoint(0, 3), const GridPoint(7, 3)), isTrue);
  });

  test('claimed-coast corners stay walkable', () {
    final field = Playfield(size: 8);
    for (var y = 1; y <= 3; y += 1) {
      for (var x = 1; x <= 3; x += 1) {
        field.set(GridPoint(x, y), Cell.player);
      }
    }

    expect(field.isShore(const GridPoint(3, 3)), isTrue);
    expect(_shoreReachable(field, const GridPoint(0, 4), const GridPoint(4, 0)), isTrue);
  });
}

bool _shoreReachable(Playfield field, GridPoint from, GridPoint to) {
  final seen = <GridPoint>{from};
  final queue = <GridPoint>[from];
  const step = [
    GridPoint(-1, 0),
    GridPoint(1, 0),
    GridPoint(0, -1),
    GridPoint(0, 1),
  ];
  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    if (current == to) return true;
    for (final delta in step) {
      final next = current + delta;
      if (seen.contains(next) || !field.isShore(next)) continue;
      seen.add(next);
      queue.add(next);
    }
  }
  return false;
}
