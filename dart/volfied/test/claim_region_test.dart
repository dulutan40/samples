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

    claimEnclosedRegion(field, const GridPoint(6, 6));

    expect(field.at(const GridPoint(3, 2)), Cell.player);
    expect(field.at(const GridPoint(4, 2)), Cell.player);
    expect(field.at(const GridPoint(6, 6)), Cell.computer);
    expect(field.at(const GridPoint(1, 1)), Cell.computer);
  });
}
