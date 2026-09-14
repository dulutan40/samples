import 'package:flutter_test/flutter_test.dart';
import 'package:monster_hunt/src/models/grid_point.dart';
import 'package:monster_hunt/src/scripts/poison_travel.dart';

void main() {
  test('poison walks the trail toward the player and can be outrun', () {
    final path = [
      const GridPoint(1, 1),
      const GridPoint(1, 2),
      const GridPoint(1, 3),
      const GridPoint(1, 4),
      const GridPoint(1, 5),
    ];
    final poison = Poison(path: path, index: 0);

    poison.stepTowardUser();
    poison.stepTowardUser();
    expect(poison.cell, const GridPoint(1, 3));
    expect(poison.reachedUser, isFalse);

    path.add(const GridPoint(1, 6));
    path.add(const GridPoint(1, 7));
    poison.stepTowardUser();
    expect(poison.reachedUser, isFalse);
    expect(poison.cell, const GridPoint(1, 4));
  });

  test('poison reaches the player at the tip of the trail', () {
    final path = [
      const GridPoint(2, 2),
      const GridPoint(2, 3),
      const GridPoint(2, 4),
    ];
    final poison = Poison(path: path, index: 1);
    poison.stepTowardUser();
    expect(poison.reachedUser, isTrue);
    expect(poison.cell, const GridPoint(2, 4));
  });

  test('poison advances along the trail without jumping to the tip', () {
    final path = [
      const GridPoint(1, 1),
      const GridPoint(1, 2),
      const GridPoint(1, 3),
      const GridPoint(1, 4),
      const GridPoint(1, 5),
    ];
    final poison = Poison(path: path, index: 0);
    poison.advance(0.035, 0.035);
    expect(poison.index, 1);
    expect(poison.reachedUser, isFalse);
    poison.advance(0.035, 0.035);
    expect(poison.index, 2);
    expect(poison.reachedUser, isFalse);
  });
}
