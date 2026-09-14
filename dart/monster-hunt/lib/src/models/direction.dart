import 'grid_point.dart';

enum Direction { left, right, up, down }

extension DirectionDelta on Direction {
  GridPoint get delta {
    return switch (this) {
      Direction.left => const GridPoint(-1, 0),
      Direction.right => const GridPoint(1, 0),
      Direction.up => const GridPoint(0, -1),
      Direction.down => const GridPoint(0, 1),
    };
  }
}
