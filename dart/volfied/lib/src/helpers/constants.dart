class GameConstants {
  static const int gridSize = 72;
  static const double winPercent = 80;
  static const double theoreticalMaxPercent = 99.9;

  static const double playerStepSeconds = 0.07;
  static const double poisonStepSeconds = 0.028;
  static const double monsterSpeed = 11;
  static const double monsterTurnSeconds = 0.45;

  static const double bigAreaFraction = 1 / 20;
  static const double bigHeadShare = 1 / 3;
  static const double smallAreaFraction = 1 / 100;
  static const double smallHeadShare = 1 / 10;
  static const double shrinkAtPercent = 45;

  static const int startingInnerSide = gridSize - 2;
  static const int startingArea = startingInnerSide * startingInnerSide;
}
