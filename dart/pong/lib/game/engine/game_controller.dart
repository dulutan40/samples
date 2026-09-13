import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../ai/ai_opponent.dart';
import '../bonus/bonus_manager.dart';
import '../bonus/bonus_type.dart';
import '../modifiers/modifier_manager.dart';
import '../model/ball.dart';
import '../model/game_config.dart';
import '../model/game_state.dart';
import '../model/paddle.dart';
import 'physics.dart';

class GameController extends ChangeNotifier {
  GameController({
    required GameConfig config,
    AiOpponent? aiRightPaddle,
    BonusManager? bonusManager,
    ModifierManager? modifierManager,
    PongPhysics physics = const PongPhysics(),
  })  : _config = config,
        _aiRightPaddle = aiRightPaddle,
        _bonus = bonusManager ?? BonusManager(),
        _modifiers = modifierManager ?? ModifierManager(),
        _physics = physics,
        _ballSpeed = config.ballSpeed;

  final PongPhysics _physics;
  final GameConfig _config;
  final AiOpponent? _aiRightPaddle;
  final BonusManager _bonus;
  final ModifierManager _modifiers;

  String _lastHitterSide = 'left';
  double _ballSpeed;
  Timer? _pickupClearTimer;

  GameState? _state;
  GameState get state => _state!;

  Size _fieldSize = Size.zero;
  bool _running = false;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _pickupClearTimer?.cancel();
    super.dispose();
  }

  void setFieldSize(Size size) {
    if (size == _fieldSize) return;
    _fieldSize = size;
    _state ??= _initialState(size, _config);
  }

  void start() {
    if (_running) return;
    _running = true;
    _state = state.copyWith(phase: GamePhase.playing);
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (!_running) return;
    _running = false;
    _ticker?.cancel();
    _state = state.copyWith(phase: GamePhase.paused);
    notifyListeners();
  }

  void reset() {
    _running = false;
    _ticker?.cancel();
    _state = _initialState(_fieldSize, _config);
    _bonus.reset();
    _modifiers.reset();
    _ballSpeed = _config.ballSpeed;
    _pickupClearTimer?.cancel();
    notifyListeners();
  }

  void setBallFromNetwork({
    required Offset position,
    required Offset velocity,
  }) {
    if (_state == null) return;
    _state = state.copyWith(
      ball: state.ball.copyWith(position: position, velocity: velocity),
    );
    notifyListeners();
  }

  void moveLeftPaddleTo(double y) {
    if (_state == null) return;
    _state = state.copyWith(leftPaddle: _clampedPaddle(state.leftPaddle, y));
    notifyListeners();
  }

  void moveRightPaddleTo(double y) {
    if (_state == null) return;
    _state = state.copyWith(rightPaddle: _clampedPaddle(state.rightPaddle, y));
    notifyListeners();
  }

  void _startTicker() {
    const dt = Duration(milliseconds: 8); // ~125 Hz
    _ticker?.cancel();
    _ticker = Timer.periodic(dt, (_) => _tick(dt.inMicroseconds / 1e6));
  }

  void _tick(double dtSeconds) {
    if (!_running || _state == null || _fieldSize == Size.zero) return;

    var s = state;

    final ai = _aiRightPaddle;
    if (ai != null) {
      final aiPaddle = ai.step(
        game: _config,
        fieldSize: _fieldSize,
        ball: s.ball,
        paddle: s.rightPaddle,
        dtSeconds: dtSeconds,
      );
      final nextRight = _clampedPaddle(s.rightPaddle, aiPaddle.centerY);
      s = s.copyWith(rightPaddle: nextRight);
      _state = s;
    }
    final res = _physics.step(
      config: _config,
      fieldSize: _fieldSize,
      ball: s.ball,
      left: s.leftPaddle,
      right: s.rightPaddle,
      dtSeconds: dtSeconds,
      modifier: _modifiers.state.active,
    );

    var nextBall = res.ball;

    if (res.leftHit) _lastHitterSide = 'left';
    if (res.rightHit) _lastHitterSide = 'right';
    if (res.leftHit || res.rightHit) {
      _bonus.onHit(fieldSize: _fieldSize, lastHitterSide: _lastHitterSide);
      _modifiers.onHit();

      // Speed curve: accelerate faster at the beginning, slower later.
      // Start at 1.5x already (config updated), then ramp.
      final hits = _bonus.state.totalHits;
      final inc = hits < 15
          ? 24.0 // 2x-ish early accel
          : hits < 45
              ? 12.0
              : 6.0;
      _ballSpeed = (_ballSpeed + inc).clamp(_config.ballSpeed, _config.ballSpeed * 2.4);
    }

    final pickedUp = _bonus.tryConsumeIfBallOverlaps(
      ballPos: nextBall.position,
      ballRadius: nextBall.radius,
      lastHitterSide: _lastHitterSide,
    );
    if (pickedUp) {
      _pickupClearTimer?.cancel();
      _pickupClearTimer = Timer(const Duration(milliseconds: 1200), () {
        // Clear pickup so UI bubble/explosion fades naturally.
        // (BonusManager keeps only the latest pickup event.)
        if (!hasListeners) return;
        // Replace with null by re-setting state through reset-less trick:
        // easiest is to just notify; UI will time out bubble based on timestamp.
        notifyListeners();
      });
    }

    // Apply active effects (basic implementation).
    final effects = _bonus.state.effects;
    double speedMult = 1.0;
    for (final e in effects) {
      if (e.type == BonusType.ballSpeedUp) speedMult *= 1.12;
      if (e.type == BonusType.ballSlowDown) speedMult *= 0.88;
    }

    // Normalize ball velocity magnitude to target speed.
    final v = nextBall.velocity;
    final mag = v.distance;
    if (mag > 1e-3) {
      final target = _ballSpeed * speedMult;
      nextBall = nextBall.copyWith(velocity: v * (target / mag));
    }

    var next = s.copyWith(ball: nextBall);

    if (res.leftScored || res.rightScored) {
      final score = next.score.copyWith(
        left: next.score.left + (res.leftScored ? 1 : 0),
        right: next.score.right + (res.rightScored ? 1 : 0),
      );
      next = next.copyWith(
        score: score,
        phase: GamePhase.pointScored,
        ball: _serveBall(_fieldSize, _config, toLeft: res.rightScored),
      );
      _ballSpeed = _config.ballSpeed;

      // Small pause between points.
      _running = false;
      _ticker?.cancel();
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (!hasListeners) return;
        _running = true;
        _state = next.copyWith(phase: GamePhase.playing);
        _startTicker();
        notifyListeners();
      });
    } else {
      _state = next;
      notifyListeners();
    }
  }

  BonusManagerState get bonusState => _bonus.state;

  ModifierManagerState get modifierState => _modifiers.state;

  Paddle _clampedPaddle(Paddle p, double targetY) {
    final top = _config.wallInset + p.halfHeight;
    final bottom = _fieldSize.height - _config.wallInset - p.halfHeight;
    final y = targetY.clamp(top, bottom).toDouble();
    return p.copyWith(centerY: y);
  }
}

GameState _initialState(Size size, GameConfig config) {
  final centerY = size.height / 2;
  final left = Paddle(
    x: config.wallInset + config.paddleHalfWidth + 8,
    centerY: centerY,
    halfHeight: config.paddleHalfHeight,
    halfWidth: config.paddleHalfWidth,
  );
  final right = Paddle(
    x: size.width - config.wallInset - config.paddleHalfWidth - 8,
    centerY: centerY,
    halfHeight: config.paddleHalfHeight,
    halfWidth: config.paddleHalfWidth,
  );
  return GameState(
    ball: _serveBall(size, config, toLeft: false),
    leftPaddle: left,
    rightPaddle: right,
    score: const GameScore(left: 0, right: 0),
    phase: GamePhase.ready,
  );
}

Ball _serveBall(Size size, GameConfig config, {required bool toLeft}) {
  final rng = Random();
  final angle = (rng.nextDouble() * 0.6 - 0.3); // ~[-0.3, 0.3] rad
  final speed = config.ballSpeed;
  final vx = cos(angle) * speed * (toLeft ? -1 : 1);
  final vy = sin(angle) * speed;
  return Ball(
    position: Offset(size.width / 2, size.height / 2),
    velocity: Offset(vx, vy),
    radius: config.ballRadius,
  );
}

