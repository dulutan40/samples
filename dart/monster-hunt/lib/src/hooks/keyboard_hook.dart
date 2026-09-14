import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/direction.dart';

/// Space + arrows is a chord. On macOS and web, pressing an arrow while Space
/// is held often synthesizes a Space KeyUp even though the key is still down.
/// Those ghost releases are ignored while a move key is held, then Space is
/// reconciled when the arrows come up.
class KeyboardHook {
  KeyboardHook({this.releaseSettleMs = 140});

  final int releaseSettleMs;

  bool _space = false;
  bool _spaceUpWhileMoving = false;
  bool _pendingRelease = false;
  bool _spaceEventSincePending = false;
  int _releaseAtMs = 0;
  final Set<LogicalKeyboardKey> _heldMoves = {};

  bool get space => _space;

  Direction? get direction {
    if (_heldMoves.contains(LogicalKeyboardKey.arrowLeft) ||
        _heldMoves.contains(LogicalKeyboardKey.keyA)) {
      return Direction.left;
    }
    if (_heldMoves.contains(LogicalKeyboardKey.arrowRight) ||
        _heldMoves.contains(LogicalKeyboardKey.keyD)) {
      return Direction.right;
    }
    if (_heldMoves.contains(LogicalKeyboardKey.arrowUp) ||
        _heldMoves.contains(LogicalKeyboardKey.keyW)) {
      return Direction.up;
    }
    if (_heldMoves.contains(LogicalKeyboardKey.arrowDown) ||
        _heldMoves.contains(LogicalKeyboardKey.keyS)) {
      return Direction.down;
    }
    return null;
  }

  void tick() {
    if (!_pendingRelease) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < _releaseAtMs) return;
    _pendingRelease = false;
    if (!_spaceEventSincePending) {
      _space = false;
    }
    _spaceUpWhileMoving = false;
  }

  KeyEventResult handle(KeyEvent event) {
    final key = event.logicalKey;
    if (!_isGameKey(key)) return KeyEventResult.ignored;

    if (key != LogicalKeyboardKey.space) {
      if (event is KeyUpEvent) {
        _heldMoves.remove(key);
        if (_heldMoves.isEmpty && (_spaceUpWhileMoving || _pendingRelease)) {
          _beginReleaseCheck();
        }
      } else {
        _heldMoves.add(key);
      }
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _markSpaceDown();
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      _handleSpaceUp();
    }
    return KeyEventResult.handled;
  }

  void _markSpaceDown() {
    _space = true;
    _spaceUpWhileMoving = false;
    _pendingRelease = false;
    _spaceEventSincePending = true;
  }

  void _handleSpaceUp() {
    if (_heldMoves.isNotEmpty) {
      _spaceUpWhileMoving = true;
      return;
    }
    _space = false;
    _spaceUpWhileMoving = false;
    _pendingRelease = false;
  }

  void _beginReleaseCheck() {
    _pendingRelease = true;
    _spaceEventSincePending = false;
    _releaseAtMs = DateTime.now().millisecondsSinceEpoch + releaseSettleMs;
  }

  bool _isGameKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.keyA ||
        key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.keyS;
  }
}
