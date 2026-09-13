import 'package:flutter_test/flutter_test.dart';
import 'package:volfied/src/game/playfield.dart';
import 'package:volfied/src/models/cell.dart';
import 'package:volfied/src/models/grid_point.dart';
import 'package:volfied/src/scripts/claim_region.dart';

void main() {
  test('a closed trail claims every cell cut off from the monster', () {
    final field = Playfield(size: 8);
    const trail = [
      GridPoint(2, 1),
      GridPoint(2, 2),
      GridPoint(2, 3),
      GridPoint(3, 3),
      GridPoint(4, 3),
      GridPoint(5, 3),
      GridPoint(5, 2),
      GridPoint(5, 1),
    ];
    for (final cell in trail) {
      field.set(cell, Cell.player);
    }

    claimPartitionedRegions(field, const [GridPoint(6, 6)]);

    expect(field.at(const GridPoint(3, 2)), Cell.player);
    expect(field.at(const GridPoint(4, 2)), Cell.player);
    expect(field.at(const GridPoint(3, 1)), Cell.player);
    expect(field.at(const GridPoint(4, 1)), Cell.player);
    expect(field.at(const GridPoint(6, 6)), Cell.computer);
    expect(field.at(const GridPoint(1, 1)), Cell.computer);
  });

  test('a walked loop fills every interior cell, not just a flood pocket', () {
    final field = Playfield(size: 8);
    const trail = [
      GridPoint(2, 1),
      GridPoint(2, 2),
      GridPoint(2, 3),
      GridPoint(3, 3),
      GridPoint(4, 3),
      GridPoint(5, 3),
      GridPoint(5, 2),
      GridPoint(5, 1),
    ];

    claimClosedLoop(
      field: field,
      trail: trail,
      origin: const GridPoint(2, 0),
      close: const GridPoint(5, 0),
      monsterCells: const [GridPoint(6, 6)],
    );

    expect(field.at(const GridPoint(3, 2)), Cell.player);
    expect(field.at(const GridPoint(4, 2)), Cell.player);
    expect(field.at(const GridPoint(3, 1)), Cell.player);
    expect(field.at(const GridPoint(4, 1)), Cell.player);
    expect(field.at(const GridPoint(2, 2)), Cell.player);
    expect(field.at(const GridPoint(6, 6)), Cell.computer);
    expect(field.at(const GridPoint(1, 1)), Cell.computer);
  });

  test('a larger rectangle claims the whole interior with no holes', () {
    final field = Playfield(size: 12);
    final trail = <GridPoint>[
      for (var y = 1; y <= 6; y += 1) GridPoint(2, y),
      for (var x = 3; x <= 8; x += 1) GridPoint(x, 6),
      for (var y = 5; y >= 1; y -= 1) GridPoint(8, y),
    ];

    claimClosedLoop(
      field: field,
      trail: trail,
      origin: const GridPoint(2, 0),
      close: const GridPoint(8, 0),
      monsterCells: const [GridPoint(10, 10)],
    );

    for (var y = 1; y <= 5; y += 1) {
      for (var x = 3; x <= 7; x += 1) {
        expect(field.at(GridPoint(x, y)), Cell.player, reason: 'hole at ($x,$y)');
      }
    }
    expect(field.at(const GridPoint(10, 10)), Cell.computer);
    expect(field.at(const GridPoint(1, 1)), Cell.computer);
  });

  test('touching the trail does not lock the monster inside the pocket', () {
    final field = Playfield(size: 8);
    const trail = [
      GridPoint(2, 1),
      GridPoint(2, 2),
      GridPoint(2, 3),
      GridPoint(3, 3),
      GridPoint(4, 3),
      GridPoint(5, 3),
      GridPoint(5, 2),
      GridPoint(5, 1),
    ];

    claimClosedLoop(
      field: field,
      trail: trail,
      origin: const GridPoint(2, 0),
      close: const GridPoint(5, 0),
      monsterCells: const [
        GridPoint(6, 3),
        GridPoint(3, 2),
        GridPoint(4, 2),
        GridPoint(5, 2),
      ],
    );

    expect(field.at(const GridPoint(3, 2)), Cell.player);
    expect(field.at(const GridPoint(4, 2)), Cell.player);
    expect(field.at(const GridPoint(6, 3)), Cell.computer);
    expect(field.at(const GridPoint(6, 6)), Cell.computer);
  });
}
