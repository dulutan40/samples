import '../game/world.dart';
import '../hooks/ticker_hook.dart';
import 'input_service.dart';

class GameLoopService {
  GameLoopService({required this.world, required this.input, required this.onTick});

  final World world;
  final InputService input;
  final void Function() onTick;

  late final TickerHook ticker = TickerHook(_step);

  void start() => ticker.start();

  void stop() => ticker.stop();

  void dispose() => ticker.dispose();

  void _step(Duration elapsed) {
    final dt = elapsed.inMicroseconds / 1e6;
    input.tick();
    world.setSpace(input.space);
    world.setDirection(input.direction);
    world.update(dt.clamp(0, 0.05));
    onTick();
  }
}
