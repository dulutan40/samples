import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef PaddleMoveCallback = void Function(double deltaY);

class KeyboardPaddleHandler extends StatelessWidget {
  const KeyboardPaddleHandler({
    required this.child,
    required this.onMoveUp,
    required this.onMoveDown,
    super.key,
  });

  final Widget child;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    // On mobile we still keep focusable wrapper harmlessly.
    return Focus(
      autofocus: kIsWeb || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
          onMoveUp();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
          onMoveDown();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

