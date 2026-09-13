import 'package:flutter/widgets.dart';

class Ball {
  const Ball({
    required this.position,
    required this.velocity,
    required this.radius,
  });

  final Offset position;
  final Offset velocity; // logical units per second
  final double radius;

  Ball copyWith({
    Offset? position,
    Offset? velocity,
    double? radius,
  }) {
    return Ball(
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      radius: radius ?? this.radius,
    );
  }
}

