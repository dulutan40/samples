import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/direction.dart';

class KeyboardHook {
  bool _space = false;
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

  KeyEventResult handle(KeyEvent event) {
    final key = event.logicalKey;
    if (!_isGameKey(key)) return KeyEventResult.ignored;

    final isMove = key != LogicalKeyboardKey.space;
    if (isMove) {
      if (event is KeyUpEvent) {
        _heldMoves.remove(key);
      } else {
        _heldMoves.add(key);
      }
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _space = true;
      return KeyEventResult.handled;
    }

    if (event is KeyUpEvent) {
      // Holding Space + arrows often synthesizes a Space key-up. Ignore that.
      if (_heldMoves.isEmpty) {
        _space = false;
      }
    }
    return KeyEventResult.handled;
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
