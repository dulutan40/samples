import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:monster_hunt/src/game/playfield.dart';
import 'package:monster_hunt/src/helpers/constants.dart';
import 'package:monster_hunt/src/helpers/geometry.dart';
import 'package:monster_hunt/src/models/cell.dart';
import 'package:monster_hunt/src/models/grid_point.dart';
import 'package:monster_hunt/src/scripts/monster_ai.dart';
import 'package:monster_hunt/src/scripts/monster_cycle.dart';

void main() {
  test('large-head bursts shrink by one after each tiny cycle', () {
    final cycle = MonsterCycle(largeBurst: 6);
    final sizes = <bool>[];

    void runBurst() {
      while (!cycle.tiny) {
        expect(cycle.big, isTrue);
        sizes.add(true);
        cycle.finishCycle();
      }
      expect(cycle.big, isFalse);
      sizes.add(false);
      cycle.finishCycle();
    }

    runBurst();
    expect(sizes.where((big) => big).length, 6);
    expect(sizes.last, isFalse);

    sizes.clear();
    runBurst();
    expect(sizes.where((big) => big).length, 5);

    sizes.clear();
    runBurst();
    expect(sizes.where((big) => big).length, 4);
  });

  test('after the last large burst only the tiny head remains', () {
    final cycle = MonsterCycle(largeBurst: 1);
    expect(cycle.big, isTrue);
    cycle.finishCycle();
    expect(cycle.big, isFalse);
    cycle.finishCycle();
    expect(cycle.big, isFalse);
    cycle.finishCycle();
    expect(cycle.big, isFalse);
  });

  test('a large head cannot pass a one-cell outlet', () {
    final field = Playfield(size: 16);
    for (var x = 1; x <= 14; x += 1) {
      if (x == 8) continue;
      field.set(GridPoint(x, 8), Cell.player);
    }

    const radius = 2.2;
    expect(headFits(field, const math.Point(8.5, 4.5), radius), isTrue);
    expect(headFits(field, const math.Point(8.5, 8.5), radius), isFalse);
    expect(headFits(field, const math.Point(8.5, 8.5), 0.4), isTrue);
  });

  test('a head overlapping a new wall is pushed back into open land', () {
    final field = Playfield(size: 20);
    for (var y = 1; y <= 6; y += 1) {
      for (var x = 1; x <= 8; x += 1) {
        field.set(GridPoint(x, y), Cell.player);
      }
    }
    final monster = Monster(field, math.Random(0));
    monster.head = const math.Point(8.2, 3.5);
    monster.body
      ..clear()
      ..add(monster.head);
    expect(headFits(field, monster.head, monster.headRadius), isFalse);

    monster.freeFromWalls();

    expect(headFits(field, monster.head, monster.headRadius), isTrue);
    expect(monster.head.x, greaterThan(8.2));
  });

  test('a locked cycle never returns to the large head', () {
    final cycle = MonsterCycle(largeBurst: 4);
    cycle.lockTiny();
    expect(cycle.big, isFalse);
    cycle.finishCycle();
    expect(cycle.big, isFalse);
    cycle.finishCycle();
    expect(cycle.big, isFalse);
  });

  test('growing near a shore sidesteps instead of overlapping the rim', () {
    final field = Playfield();
    final monster = Monster(field, math.Random(1));
    final start = math.Point(2.0, field.size / 2);
    monster.head = start;
    monster.body
      ..clear()
      ..add(start);
    monster.tryResizeForPatrol();

    expect(monster.big, isTrue);
    expect(headFits(field, monster.head, monster.headRadius), isTrue);
    expect(distance(start, monster.head), lessThan(GameConstants.monsterGrowNudge + 0.01));
  });

  test('if a large head cannot sidestep it stays small forever', () {
    final field = Playfield();
    for (var y = 1; y < field.size - 1; y += 1) {
      for (var x = 1; x < field.size - 1; x += 1) {
        if (x >= 34 && x <= 36 && y >= 34 && y <= 36) continue;
        field.set(GridPoint(x, y), Cell.player);
      }
    }
    final monster = Monster(field, math.Random(2));
    monster.head = const math.Point(35.5, 35.5);
    monster.body
      ..clear()
      ..add(monster.head);
    monster.tryResizeForPatrol();

    expect(monster.big, isFalse);
    expect(monster.cycle.big, isFalse);
    monster.cycle.finishCycle();
    expect(monster.cycle.big, isFalse);
  });
}
