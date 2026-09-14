import 'dart:math' as math;

import '../models/grid_point.dart';

class Poison {
  Poison({required this.path, required this.index});

  final List<GridPoint> path;
  int index;
  double offset = 0;
  bool alive = true;

  GridPoint get cell => path[index.clamp(0, path.length - 1)];

  bool get reachedUser => path.isEmpty || index >= path.length - 1;

  bool get overranRetreat => path.isNotEmpty && index >= path.length;

  math.Point<double> get visualCenter {
    if (path.isEmpty) return const math.Point(0, 0);
    final i = index.clamp(0, path.length - 1);
    final a = path[i];
    if (i >= path.length - 1) {
      return math.Point(a.x + 0.5, a.y + 0.5);
    }
    final b = path[i + 1];
    return math.Point(
      a.x + 0.5 + (b.x - a.x) * offset,
      a.y + 0.5 + (b.y - a.y) * offset,
    );
  }

  void stepTowardUser() {
    if (!alive || path.isEmpty) return;
    if (index < path.length - 1) {
      index += 1;
    }
  }

  void advance(double dt, double stepSeconds) {
    if (!alive || path.isEmpty) return;
    offset += dt / stepSeconds;
    while (offset >= 1 && index < path.length - 1) {
      offset -= 1;
      index += 1;
    }
    if (index >= path.length - 1) {
      offset = 0;
    }
  }
}
