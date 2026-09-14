import 'dart:math' as math;

import '../models/grid_point.dart';

double distance(math.Point<double> a, math.Point<double> b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return math.sqrt(dx * dx + dy * dy);
}

math.Point<double> cellCenter(GridPoint point) {
  return math.Point(point.x + 0.5, point.y + 0.5);
}

double distanceToSegment(
  math.Point<double> point,
  math.Point<double> a,
  math.Point<double> b,
) {
  final vx = b.x - a.x;
  final vy = b.y - a.y;
  final length2 = vx * vx + vy * vy;
  if (length2 == 0) return distance(point, a);
  var t = ((point.x - a.x) * vx + (point.y - a.y) * vy) / length2;
  t = t.clamp(0.0, 1.0);
  return distance(point, math.Point(a.x + t * vx, a.y + t * vy));
}
