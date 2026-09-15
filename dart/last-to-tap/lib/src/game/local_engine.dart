import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

/// Shared rules for local party mode (mirrors the online server).
class LocalRoundEngine extends ChangeNotifier {
  LocalRoundEngine({required this.names}) {
    ensurePlayers();
  }

  final List<String> names;
  final _rng = Random();

  static const cooldown = Duration(seconds: 1);
  static const minRound = Duration(seconds: 10);
  static const maxRound = Duration(seconds: 25);

  LocalPhase phase = LocalPhase.lobby;
  final Map<int, DateTime?> lastTap = {};
  final Map<int, DateTime> cooldownUntil = {};
  int? winnerIndex;
  Timer? _endTimer;
  final Map<int, Timer> _cooldownTimers = {};

  void ensurePlayers() {
    for (var i = 0; i < names.length; i++) {
      lastTap.putIfAbsent(i, () => null);
      cooldownUntil.putIfAbsent(
        i,
        () => DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
  }

  bool onCooldown(int i) => DateTime.now().isBefore(cooldownUntil[i]!);

  int? get latestTapIndex {
    int? best;
    DateTime? bestTime;
    lastTap.forEach((i, t) {
      if (t == null) return;
      if (bestTime == null || t.isAfter(bestTime!)) {
        bestTime = t;
        best = i;
      }
    });
    return best;
  }

  void start() {
    if (names.length < 2) return;
    ensurePlayers();
    _endTimer?.cancel();
    for (final t in _cooldownTimers.values) {
      t.cancel();
    }
    _cooldownTimers.clear();
    winnerIndex = null;
    for (final i in lastTap.keys) {
      lastTap[i] = null;
      cooldownUntil[i] = DateTime.fromMillisecondsSinceEpoch(0);
    }
    final span = maxRound.inMilliseconds - minRound.inMilliseconds;
    final ms = minRound.inMilliseconds + _rng.nextInt(span + 1);
    phase = LocalPhase.playing;
    notifyListeners();
    _endTimer = Timer(Duration(milliseconds: ms), end);
  }

  /// Returns true when the tap was accepted (not on cooldown / wrong phase).
  bool tap(int i) {
    if (phase != LocalPhase.playing) return false;
    final now = DateTime.now();
    if (now.isBefore(cooldownUntil[i]!)) return false;
    lastTap[i] = now;
    cooldownUntil[i] = now.add(cooldown);
    notifyListeners();
    _cooldownTimers[i]?.cancel();
    _cooldownTimers[i] = Timer(cooldown, () {
      if (hasListeners) notifyListeners();
    });
    return true;
  }

  void end() {
    if (phase != LocalPhase.playing) return;
    _endTimer?.cancel();
    phase = LocalPhase.results;
    int? best;
    DateTime? bestTime;
    lastTap.forEach((i, t) {
      if (t == null) return;
      if (bestTime == null || t.isAfter(bestTime!)) {
        bestTime = t;
        best = i;
      }
    });
    winnerIndex = best;
    notifyListeners();
  }

  @override
  void dispose() {
    _endTimer?.cancel();
    for (final t in _cooldownTimers.values) {
      t.cancel();
    }
    super.dispose();
  }
}

enum LocalPhase { lobby, playing, results }
