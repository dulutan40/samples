class Streaks {
  const Streaks({
    required this.dailyPlay,
    required this.winCpu,
    required this.winOnline,
    required this.bestRally,
  });

  final int dailyPlay;
  final int winCpu;
  final int winOnline;
  final int bestRally;

  Streaks copyWith({
    int? dailyPlay,
    int? winCpu,
    int? winOnline,
    int? bestRally,
  }) {
    return Streaks(
      dailyPlay: dailyPlay ?? this.dailyPlay,
      winCpu: winCpu ?? this.winCpu,
      winOnline: winOnline ?? this.winOnline,
      bestRally: bestRally ?? this.bestRally,
    );
  }

  static const empty = Streaks(dailyPlay: 0, winCpu: 0, winOnline: 0, bestRally: 0);
}

