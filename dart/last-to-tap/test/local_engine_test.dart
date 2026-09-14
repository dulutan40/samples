import 'package:flutter_test/flutter_test.dart';
import 'package:last_to_tap/src/game/local_engine.dart';

void main() {
  test('last tap wins after cutoff', () async {
    final engine = LocalRoundEngine(names: ['A', 'B', 'C']);
    engine.phase = LocalPhase.playing;
    engine.tap(0);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    engine.tap(1);
    engine.end();
    expect(engine.winnerIndex, 1);
    engine.dispose();
  });

  test('cooldown blocks rapid taps', () {
    final engine = LocalRoundEngine(names: ['A', 'B']);
    engine.phase = LocalPhase.playing;
    engine.tap(0);
    final first = engine.lastTap[0];
    engine.tap(0);
    expect(engine.lastTap[0], first);
    engine.dispose();
  });
}
