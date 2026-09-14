import '../game/world.dart';
import '../models/game_status.dart';

class CollisionService {
  bool isOver(World world) => world.status != GameStatus.playing;
}
