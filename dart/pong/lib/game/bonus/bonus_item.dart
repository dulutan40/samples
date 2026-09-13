import 'package:flutter/widgets.dart';

import 'bonus_type.dart';

class BonusItem {
  const BonusItem({
    required this.type,
    required this.position,
    required this.radius,
    required this.ttlHits,
  });

  final BonusType type;
  final Offset position;
  final double radius;
  final int ttlHits; // decremented on each paddle hit

  BonusItem copyWith({
    BonusType? type,
    Offset? position,
    double? radius,
    int? ttlHits,
  }) {
    return BonusItem(
      type: type ?? this.type,
      position: position ?? this.position,
      radius: radius ?? this.radius,
      ttlHits: ttlHits ?? this.ttlHits,
    );
  }
}

