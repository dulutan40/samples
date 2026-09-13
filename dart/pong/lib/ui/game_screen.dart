import 'package:flutter/material.dart';

import '../game/ai/ai_config.dart';
import '../game/ai/ai_opponent.dart';
import '../game/ai/difficulty.dart';
import '../game/bonus/bonus_manager.dart';
import '../game/engine/game_controller.dart';
import '../game/model/game_config.dart';
import '../game/render/pong_painter.dart';
import 'widgets/keyboard_paddle_handler.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.vsCpu,
    required this.difficulty,
  });

  final bool vsCpu;
  final Difficulty difficulty;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller;
  final _config = GameConfig.classic;

  BonusPickupEvent? _pickup;
  DateTime? _pickupAt;

  @override
  void initState() {
    super.initState();
    final ai = widget.vsCpu
        ? AiOpponent(config: AiConfig.forDifficulty(widget.difficulty))
        : null;
    _controller = GameController(config: _config, aiRightPaddle: ai);
    _controller.addListener(_onTick);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _onTick() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _controller.setFieldSize(size);

            final state = _controller.state;
            final lastPickup = _controller.bonusState.lastPickup;
            if (lastPickup != null &&
                (_pickupAt == null || lastPickup != _pickup)) {
              _pickup = lastPickup;
              _pickupAt = DateTime.now();
            }
            final t = _pickupAt == null
                ? null
                : DateTime.now()
                    .difference(_pickupAt!)
                    .inMilliseconds
                    .clamp(0, 1200) /
                    1200.0;
            final showPickup = _pickup != null && (t ?? 1.0) < 1.0;

            return KeyboardPaddleHandler(
              onMoveUp: () => _controller.moveLeftPaddleTo(
                _controller.state.leftPaddle.centerY - 18,
              ),
              onMoveDown: () => _controller.moveLeftPaddleTo(
                _controller.state.leftPaddle.centerY + 18,
              ),
              child: Listener(
                onPointerDown: (e) {
                  _controller.start();
                  final isRight = e.localPosition.dx > size.width / 2;
                  if (isRight && !widget.vsCpu) {
                    _controller.moveRightPaddleTo(e.localPosition.dy);
                  } else {
                    _controller.moveLeftPaddleTo(e.localPosition.dy);
                  }
                },
                onPointerMove: (e) {
                  final isRight = e.localPosition.dx > size.width / 2;
                  if (isRight && !widget.vsCpu) {
                    _controller.moveRightPaddleTo(e.localPosition.dy);
                  } else {
                    _controller.moveLeftPaddleTo(e.localPosition.dy);
                  }
                },
                child: Stack(
                  children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PongPainter(
                        state: state,
                        config: _config,
                        colorScheme: Theme.of(context).colorScheme,
                        bonusItem: _controller.bonusState.item,
                        pickup: showPickup ? _pickup : null,
                        pickupT: showPickup ? t : null,
                      ),
                    ),
                  ),
                  if (showPickup && _pickup != null && t != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: Opacity(
                        opacity: (1.0 - (t * 1.15)).clamp(0.0, 1.0),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withValues(alpha: 0.65),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Text(
                                _pickup!.message,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ScoreChip(value: state.score.left),
                        const SizedBox(width: 16),
                        _ScoreChip(value: state.score.right),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      onPressed: _controller.pause,
                      icon: const Icon(Icons.pause),
                    ),
                  ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(
          '$value',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

