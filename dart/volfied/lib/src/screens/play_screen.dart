import 'package:flutter/material.dart';

import '../containers/play_stage.dart';
import '../game/world.dart';
import '../helpers/colors.dart';
import '../models/game_status.dart';
import '../services/game_loop_service.dart';
import '../services/input_service.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key, required this.onFinished});

  final void Function(GameResult result) onFinished;

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final World world = World();
  final InputService input = InputService();
  late final GameLoopService loop;
  final FocusNode focus = FocusNode();

  @override
  void initState() {
    super.initState();
    loop = GameLoopService(
      world: world,
      input: input,
      onTick: _onTick,
    )..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => focus.requestFocus());
  }

  void _onTick() {
    if (!mounted) return;
    setState(() {});
    if (world.status != GameStatus.playing) {
      loop.stop();
      final result = GameResult(status: world.status, percent: world.percent);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished(result);
      });
    }
  }

  @override
  void dispose() {
    loop.dispose();
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final touch = shortest < 760;

    return Focus(
      focusNode: focus,
      autofocus: true,
      onKeyEvent: (_, event) => input.onKey(event),
      child: Scaffold(
        backgroundColor: GameColors.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: PlayStage(
              world: world,
              showTouchControls: touch,
              drawHeld: input.space,
              onDirectionStart: input.setPointerDirection,
              onDirectionEnd: () => input.setPointerDirection(null),
              onDrawChanged: input.setDrawHeld,
            ),
          ),
        ),
      ),
    );
  }
}
