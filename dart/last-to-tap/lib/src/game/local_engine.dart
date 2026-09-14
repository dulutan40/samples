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
  static const minRound = Duration(seconds: 15);
  static const maxRound = Duration(seconds: 20);

  LocalPhase phase = LocalPhase.lobby;
  final Map<int, DateTime?> lastTap = {};
  final Map<int, DateTime> cooldownUntil = {};
  int? winnerIndex;
  Timer? _endTimer;

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

  void start() {
    if (names.length < 2) return;
    ensurePlayers();
    _endTimer?.cancel();
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

  void tap(int i) {
    if (phase != LocalPhase.playing) return;
    final now = DateTime.now();
    if (now.isBefore(cooldownUntil[i]!)) return;
    lastTap[i] = now;
    cooldownUntil[i] = now.add(cooldown);
    notifyListeners();
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
    super.dispose();
  }
}

enum LocalPhase { lobby, playing, results }
