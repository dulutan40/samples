import 'difficulty.dart';

class AiConfig {
  const AiConfig({
    required this.maxSpeed,
    required this.reactionSeconds,
    required this.aimErrorPx,
  });

  final double maxSpeed; // px/sec
  final double reactionSeconds;
  final double aimErrorPx;

  static AiConfig forDifficulty(Difficulty d) {
    return switch (d) {
      Difficulty.easy =>
        const AiConfig(maxSpeed: 260, reactionSeconds: 0.20, aimErrorPx: 28),
      Difficulty.normal =>
        const AiConfig(maxSpeed: 360, reactionSeconds: 0.14, aimErrorPx: 18),
      Difficulty.hard =>
        const AiConfig(maxSpeed: 520, reactionSeconds: 0.09, aimErrorPx: 10),
      Difficulty.insane =>
        const AiConfig(maxSpeed: 900, reactionSeconds: 0.05, aimErrorPx: 4),
    };
  }
}

