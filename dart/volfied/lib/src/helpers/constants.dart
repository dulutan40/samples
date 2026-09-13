class GameConstants {
  static const int gridSize = 72;
  static const double winPercent = 80;
  static const double theoreticalMaxPercent = 99.9;

  static const double playerStepSeconds = 0.07;
  static const double poisonStepSeconds = 0.12;
  static const double monsterSpeed = 11;
  static const double monsterHuntSpeed = 13;
  static const double monsterSteer = 0.2;
  static const double monsterOrbitMin = 16;
  static const double monsterOrbitMax = 28;
  static const double monsterHuntOrbitMin = 10;
  static const double monsterHuntOrbitMax = 18;
  static const double monsterKeepAway = 12;
  static const double monsterHuntKeepAway = 8;
  static const double monsterTurnSeconds = 0.7;
  static const double playerHitRadius = 0.42;

  static const double bigAreaFraction = 1 / 20;
  static const double bigHeadShare = 1 / 3;
  static const double smallAreaFraction = 1 / 100;
  static const double smallHeadShare = 1 / 10;
  static const double shrinkAtPercent = 45;

  static const int startingInnerSide = gridSize - 2;
  static const int startingArea = startingInnerSide * startingInnerSide;
}
