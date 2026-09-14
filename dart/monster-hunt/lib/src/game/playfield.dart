import '../helpers/constants.dart';
import '../models/cell.dart';
import '../models/grid_point.dart';

class Playfield {
  Playfield({this.size = GameConstants.gridSize}) {
    reset();
  }

  final int size;
  late List<List<Cell>> cells;
  late int startingInner;

  void reset() {
    cells = List.generate(size, (y) {
      return List.generate(size, (x) {
        final edge = x == 0 || y == 0 || x == size - 1 || y == size - 1;
        return edge ? Cell.player : Cell.computer;
      });
    });
    startingInner = (size - 2) * (size - 2);
  }

  bool inBounds(GridPoint point) {
    return point.x >= 0 && point.y >= 0 && point.x < size && point.y < size;
  }

  Cell at(GridPoint point) => cells[point.y][point.x];

  void set(GridPoint point, Cell cell) {
    cells[point.y][point.x] = cell;
  }

  bool isShore(GridPoint point) {
    if (!inBounds(point) || at(point) != Cell.player) return false;
    // Corners only touch computer land diagonally. 4-neighbors left the four
    // rims (and later claimed coastlines) disconnected at those corners.
    const neighbors = [
      GridPoint(-1, 0),
      GridPoint(1, 0),
      GridPoint(0, -1),
      GridPoint(0, 1),
      GridPoint(-1, -1),
      GridPoint(-1, 1),
      GridPoint(1, -1),
      GridPoint(1, 1),
    ];
    for (final delta in neighbors) {
      final next = point + delta;
      if (inBounds(next) && at(next) == Cell.computer) return true;
    }
    return false;
  }

  double claimedPercent() {
    var claimed = 0;
    for (var y = 1; y < size - 1; y += 1) {
      for (var x = 1; x < size - 1; x += 1) {
        if (cells[y][x] == Cell.player) claimed += 1;
      }
    }
    return claimed / startingInner * 100;
  }
}
