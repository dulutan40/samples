enum GameStatus { playing, won, lost }

class GameResult {
  const GameResult({required this.status, required this.percent});

  final GameStatus status;
  final double percent;
}
