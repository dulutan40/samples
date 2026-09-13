import 'package:flutter/widgets.dart';

class Paddle {
  const Paddle({
    required this.centerY,
    required this.halfHeight,
    required this.x,
    required this.halfWidth,
  });

  final double x;
  final double centerY;
  final double halfHeight;
  final double halfWidth;

  Rect get rect => Rect.fromCenter(
        center: Offset(x, centerY),
        width: halfWidth * 2,
        height: halfHeight * 2,
      );

  Paddle copyWith({
    double? x,
    double? centerY,
    double? halfHeight,
    double? halfWidth,
  }) {
    return Paddle(
      x: x ?? this.x,
      centerY: centerY ?? this.centerY,
      halfHeight: halfHeight ?? this.halfHeight,
      halfWidth: halfWidth ?? this.halfWidth,
    );
  }
}

