import 'dart:async';

import 'package:flutter/material.dart';

import '../../game/engine/game_controller.dart';
import '../../game/model/game_config.dart';
import '../../game/render/pong_painter.dart';
import '../../i18n/app_strings.dart';
import '../../i18n/keys.dart';
import '../../multiplayer/room_models.dart';
import '../../multiplayer/sync/realtime_sync_service.dart';
import '../widgets/keyboard_paddle_handler.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({
    super.key,
    required this.room,
    required this.myUid,
  });

  final Room room;
  final String myUid;

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  final _sync = RealtimeSyncService();
  late final GameController _controller;
  final _config = GameConfig.classic;

  StreamSubscription<double?>? _remotePaddleSub;
  StreamSubscription<BallSnapshot?>? _ballSub;
  Timer? _hostBallTicker;

  bool get _isHost => widget.room.hostUid == widget.myUid;
  String get _otherUid =>
      widget.room.players.keys.firstWhere((k) => k != widget.myUid);

  @override
  void initState() {
    super.initState();
    _controller = GameController(
      config: _config,
      aiRightPaddle: null,
    );
    _controller.addListener(_onTick);

    _remotePaddleSub = _sync.watchPaddleY(widget.room.id, _otherUid).listen((y) {
      if (y == null) return;
      if (!mounted) return;
      if (widget.room.players[widget.myUid]?.side == 'left') {
        _controller.moveRightPaddleTo(y);
      } else {
        _controller.moveLeftPaddleTo(y);
      }
    });

    _ballSub = _sync.watchBallSnapshot(widget.room.id).listen((snap) {
      if (snap == null) return;
      if (!mounted) return;
      if (_isHost) return;
      _controller.setBallFromNetwork(position: snap.position, velocity: snap.velocity);
    });

    if (_isHost) {
      _hostBallTicker = Timer.periodic(const Duration(milliseconds: 90), (_) {
        final s = _controller.state;
        _sync.sendBallSnapshot(
          widget.room.id,
          position: s.ball.position,
          velocity: s.ball.velocity,
        );
      });
    }
  }

  @override
  void dispose() {
    _remotePaddleSub?.cancel();
    _ballSub?.cancel();
    _hostBallTicker?.cancel();
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  void _onTick() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t(I18nKeys.onlineMatchTitle))),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            _controller.setFieldSize(size);
            final state = _controller.state;

            return KeyboardPaddleHandler(
              onMoveUp: () => _nudgeLocal(-18),
              onMoveDown: () => _nudgeLocal(18),
              child: Listener(
                onPointerDown: (e) async {
                  _controller.start();
                  await _applyLocalInput(e.localPosition, size);
                },
                onPointerMove: (e) async =>
                    _applyLocalInput(e.localPosition, size),
                child: Stack(
                  children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: PongPainter(
                        state: state,
                        config: _config,
                        colorScheme: Theme.of(context).colorScheme,
                        bonusItem: _controller.bonusState.item,
                      ),
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

  void _nudgeLocal(double deltaY) {
    final mySide = widget.room.players[widget.myUid]?.side ?? 'left';
    if (mySide == 'left') {
      final y = _controller.state.leftPaddle.centerY + deltaY;
      _controller.moveLeftPaddleTo(y);
      _sync.sendPaddleY(widget.room.id, _controller.state.leftPaddle.centerY);
    } else {
      final y = _controller.state.rightPaddle.centerY + deltaY;
      _controller.moveRightPaddleTo(y);
      _sync.sendPaddleY(widget.room.id, _controller.state.rightPaddle.centerY);
    }
  }

  Future<void> _applyLocalInput(Offset pos, Size size) async {
    final mySide = widget.room.players[widget.myUid]?.side ?? 'left';
    if (mySide == 'left') {
      _controller.moveLeftPaddleTo(pos.dy);
      await _sync.sendPaddleY(widget.room.id, _controller.state.leftPaddle.centerY);
    } else {
      _controller.moveRightPaddleTo(pos.dy);
      await _sync.sendPaddleY(widget.room.id, _controller.state.rightPaddle.centerY);
    }
  }
}

