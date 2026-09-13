import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../models/direction.dart';

class KeyboardHook {
  bool _space = false;
  bool _requireFreshDown = false;
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

  void clearUntilNextPress() {
    _space = false;
    _requireFreshDown = true;
  }

  KeyEventResult handle(KeyEvent event) {
    final key = event.logicalKey;
    if (!_isGameKey(key)) return KeyEventResult.ignored;

    if (key != LogicalKeyboardKey.space) {
      if (event is KeyUpEvent) {
        _heldMoves.remove(key);
      } else {
        _heldMoves.add(key);
      }
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent) {
      _requireFreshDown = false;
      _space = true;
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) {
      if (!_requireFreshDown) {
        _space = true;
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      _space = false;
      _requireFreshDown = false;
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
