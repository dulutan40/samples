class GameConfig {
  const GameConfig({
    required this.ballRadius,
    required this.ballSpeed,
    required this.paddleHalfHeight,
    required this.paddleHalfWidth,
    required this.wallInset,
  });

  final double ballRadius;
  final double ballSpeed;
  final double paddleHalfHeight;
  final double paddleHalfWidth;
  final double wallInset;

  static const classic = GameConfig(
    ballRadius: 8,
    ballSpeed: 480,
    paddleHalfHeight: 48,
    paddleHalfWidth: 6,
    wallInset: 12,
  );
}

