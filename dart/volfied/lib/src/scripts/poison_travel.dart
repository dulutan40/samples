import '../models/grid_point.dart';

class Poison {
  Poison({required this.path, required this.index});

  final List<GridPoint> path;
  int index;
  bool alive = true;

  GridPoint get cell => path[index.clamp(0, path.length - 1)];

  bool get reachedUser => path.isEmpty || index >= path.length - 1;

  bool get overranRetreat => path.isNotEmpty && index >= path.length;

  void stepTowardUser() {
    if (!alive || path.isEmpty) return;
    if (index < path.length - 1) {
      index += 1;
    }
  }
}
