class GameConstants {
  static const int gridSize = 72;
  static const double winPercent = 80;
  static const double theoreticalMaxPercent = 99.9;

  static const double playerStepSeconds = 0.07;
  static const double poisonStepSeconds = playerStepSeconds / 2;
  static const double monsterSpeed = 16.5;
  static const double monsterHuntSpeed = 19.5;
  static const double monsterSteer = 0.38;
  static const double monsterOrbitMin = 12;
  static const double monsterOrbitMax = 30;
  static const double monsterHuntOrbitMin = 8;
  static const double monsterHuntOrbitMax = 20;
  static const double monsterKeepAway = 12;
  static const double monsterHuntKeepAway = 8;
  static const double monsterTurnSeconds = 0.32;
  static const double monsterCycleSeconds = 10;
  static const double monsterCollectSeconds = 1.25;
  static const double monsterRestSeconds = 3;
  static const int monsterStartLargeCycles = 6;

  static const double bigAreaFraction = 1 / 20;
  static const double bigHeadShare = 1 / 3;
  static const double smallAreaFraction = 1 / 100;
  static const double smallHeadShare = 1 / 10;

  static const int startingInnerSide = gridSize - 2;
  static const int startingArea = startingInnerSide * startingInnerSide;
}
