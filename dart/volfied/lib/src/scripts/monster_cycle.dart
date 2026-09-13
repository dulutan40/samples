/// Large-head bursts shrink by one after each tiny-head cycle, until only
/// the tiny head remains.
class MonsterCycle {
  MonsterCycle({this.largeBurst = 6}) : remainingLarge = largeBurst;

  int largeBurst;
  int remainingLarge;
  bool tiny = false;

  bool get big => !tiny;

  void lockTiny() {
    tiny = true;
    largeBurst = 0;
    remainingLarge = 0;
  }

  void finishCycle() {
    if (tiny) {
      if (largeBurst > 1) {
        largeBurst -= 1;
        remainingLarge = largeBurst;
        tiny = false;
      }
      return;
    }
    remainingLarge -= 1;
    if (remainingLarge <= 0) {
      tiny = true;
    }
  }
}
