import 'dart:math';

import 'package:flutter/widgets.dart';

import 'active_effect.dart';
import 'bonus_item.dart';
import 'bonus_type.dart';

class BonusPickupEvent {
  const BonusPickupEvent({
    required this.type,
    required this.position,
    required this.message,
  });

  final BonusType type;
  final Offset position;
  final String message;
}

class BonusManagerState {
  const BonusManagerState({
    required this.totalHits,
    required this.item,
    required this.effects,
    required this.lastPickup,
  });

  final int totalHits;
  final BonusItem? item;
  final List<ActiveEffect> effects;
  final BonusPickupEvent? lastPickup;

  BonusManagerState copyWith({
    int? totalHits,
    BonusItem? item,
    List<ActiveEffect>? effects,
    BonusPickupEvent? lastPickup,
  }) {
    return BonusManagerState(
      totalHits: totalHits ?? this.totalHits,
      item: item,
      effects: effects ?? this.effects,
      lastPickup: lastPickup,
    );
  }
}

class BonusManager {
  BonusManager({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  BonusManagerState _state =
      const BonusManagerState(totalHits: 0, item: null, effects: [], lastPickup: null);
  BonusManagerState get state => _state;

  void reset() {
    _state = const BonusManagerState(totalHits: 0, item: null, effects: [], lastPickup: null);
  }

  /// Call when a paddle hit happens (either side).
  void onHit({
    required Size fieldSize,
    required String lastHitterSide, // "left" | "right"
  }) {
    final nextHits = _state.totalHits + 1;

    // Tick item TTL and active effects.
    final nextItem = _state.item?.copyWith(ttlHits: _state.item!.ttlHits - 1);
    final nextEffects = _state.effects
        .map((e) => e.tickHit())
        .where((e) => e.remainingHits > 0)
        .toList(growable: false);

    var s = _state.copyWith(
      totalHits: nextHits,
      effects: nextEffects,
      item: nextItem,
    );

    // Despawn item if TTL elapsed.
    if (s.item != null && s.item!.ttlHits <= 0) {
      s = s.copyWith(item: null);
    }

    // Spawn process: expected 1 per 10 hits, only if no item is present.
    if (s.item == null && _rng.nextDouble() < 0.1) {
      s = s.copyWith(item: _spawnItem(fieldSize));
    }

    _state = s;
  }

  /// Returns true if consumed.
  bool tryConsumeIfBallOverlaps({
    required Offset ballPos,
    required double ballRadius,
    required String lastHitterSide,
  }) {
    final item = _state.item;
    if (item == null) return false;

    final dx = ballPos.dx - item.position.dx;
    final dy = ballPos.dy - item.position.dy;
    final r = ballRadius + item.radius;
    if (dx * dx + dy * dy > r * r) return false;

    final durationHits = 4 + _rng.nextInt(11); // [4,14]
    final effect = ActiveEffect(
      type: item.type,
      remainingHits: durationHits,
      targetSide: lastHitterSide,
    );

    _state = _state.copyWith(
      item: null,
      effects: [..._state.effects, effect],
      lastPickup: BonusPickupEvent(
        type: item.type,
        position: item.position,
        message: _messageFor(item.type, lastHitterSide),
      ),
    );
    return true;
  }

  BonusItem _spawnItem(Size field) {
    final type = BonusType.values[_rng.nextInt(BonusType.values.length)];
    final radius = 30.0; // 3x diameter vs before

    // Lifetime: expected ~4 hits, min 2.
    final ttlHits = max(2, (2 + _exp(mean: 2)).floor());

    final margin = 40.0;
    final x = margin + _rng.nextDouble() * max(1.0, field.width - 2 * margin);
    final y = margin + _rng.nextDouble() * max(1.0, field.height - 2 * margin);

    return BonusItem(
      type: type,
      position: Offset(x, y),
      radius: radius,
      ttlHits: ttlHits,
    );
  }

  double _exp({required double mean}) {
    final u = (_rng.nextDouble()).clamp(1e-9, 1 - 1e-9);
    return -mean * log(u);
  }

  String _messageFor(BonusType type, String side) {
    final who = side == 'left' ? 'You' : 'Opponent';
    return switch (type) {
      BonusType.paddleEnlarge => '$who: Paddle enlarged',
      BonusType.paddleShorten => '$who: Paddle shortened',
      BonusType.ballSpeedUp => 'Ball speed up',
      BonusType.ballSlowDown => 'Ball slow down',
      BonusType.doublePaddle => '$who: Double paddle',
    };
  }
}

