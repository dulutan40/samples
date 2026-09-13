import 'dart:math';

import 'modifier_type.dart';

class ModifierManagerState {
  const ModifierManagerState({
    required this.active,
    required this.remainingHits,
  });

  final ModifierType? active;
  final int remainingHits;
}

class ModifierManager {
  ModifierManager({Random? random}) : _rng = random ?? Random();

  final Random _rng;

  ModifierManagerState _state =
      const ModifierManagerState(active: null, remainingHits: 0);
  ModifierManagerState get state => _state;

  void reset() {
    _state = const ModifierManagerState(active: null, remainingHits: 0);
  }

  void onHit() {
    if (_state.active != null) {
      final next = _state.remainingHits - 1;
      if (next <= 0) {
        _state = const ModifierManagerState(active: null, remainingHits: 0);
      } else {
        _state = ModifierManagerState(active: _state.active, remainingHits: next);
      }
      return;
    }

    // Simple timed event chance: 1% per hit to enable portals for 6-12 hits.
    if (_rng.nextDouble() < 0.01) {
      final hits = 6 + _rng.nextInt(7);
      _state = ModifierManagerState(active: ModifierType.portalWalls, remainingHits: hits);
    }
  }
}

