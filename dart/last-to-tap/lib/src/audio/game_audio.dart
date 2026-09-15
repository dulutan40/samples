import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

/// Short SFX + a round clock that speeds up over the first 10s, then stays fast.
class GameAudio {
  GameAudio._();
  static final GameAudio instance = GameAudio._();

  final AudioPlayer _tap = AudioPlayer();
  final AudioPlayer _tick = AudioPlayer();
  final AudioPlayer _tock = AudioPlayer();
  final AudioPlayer _timeUp = AudioPlayer();

  Timer? _clock;
  DateTime? _roundStarted;
  bool _useTick = true;

  Future<void> playTap() => _burst(_tap, 'sounds/tap.wav');

  Future<void> playTimeUp() => _burst(_timeUp, 'sounds/time_up.wav');

  Future<void> _burst(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {
      // Audio is best-effort (web autoplay / missing assets shouldn't crash).
    }
  }

  void startRoundClock() {
    stopRoundClock();
    _roundStarted = DateTime.now();
    _useTick = true;
    _scheduleNextBeat();
  }

  void stopRoundClock({bool playTimeUp = false}) {
    _clock?.cancel();
    _clock = null;
    _roundStarted = null;
    if (playTimeUp) {
      unawaited(this.playTimeUp());
    }
  }

  Duration _intervalForElapsed(Duration elapsed) {
    // Slow at round start → fast by 10s → hold that pace until the cutoff.
    const slowMs = 900.0;
    const fastMs = 180.0;
    const ramp = 10.0;
    final t = (elapsed.inMilliseconds / 1000.0 / ramp).clamp(0.0, 1.0);
    final ms = slowMs + (fastMs - slowMs) * t;
    return Duration(milliseconds: ms.round());
  }

  void _scheduleNextBeat() {
    final started = _roundStarted;
    if (started == null) return;
    final wait = _intervalForElapsed(DateTime.now().difference(started));
    _clock = Timer(wait, () async {
      if (_roundStarted == null) return;
      await _burst(_useTick ? _tick : _tock, _useTick ? 'sounds/tick.wav' : 'sounds/tock.wav');
      _useTick = !_useTick;
      _scheduleNextBeat();
    });
  }

  Future<void> dispose() async {
    stopRoundClock();
    await Future.wait([
      _tap.dispose(),
      _tick.dispose(),
      _tock.dispose(),
      _timeUp.dispose(),
    ]);
  }
}
