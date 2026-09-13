import 'bonus_type.dart';

class ActiveEffect {
  const ActiveEffect({
    required this.type,
    required this.remainingHits,
    required this.targetSide,
  });

  final BonusType type;
  final int remainingHits; // decremented on each paddle hit (total hits)
  final String targetSide; // "left" | "right"

  ActiveEffect tickHit() =>
      ActiveEffect(type: type, remainingHits: remainingHits - 1, targetSide: targetSide);
}

