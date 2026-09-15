import 'package:flutter/services.dart';

/// One key per local-party seat (spread across the keyboard).
const List<LogicalKeyboardKey> localPartyKeys = [
  LogicalKeyboardKey.keyA,
  LogicalKeyboardKey.keyS,
  LogicalKeyboardKey.keyD,
  LogicalKeyboardKey.keyF,
  LogicalKeyboardKey.keyJ,
  LogicalKeyboardKey.keyK,
  LogicalKeyboardKey.keyL,
  LogicalKeyboardKey.semicolon,
];

String localPartyKeyLabel(int index) {
  if (index < 0 || index >= localPartyKeys.length) return '?';
  final key = localPartyKeys[index];
  if (key == LogicalKeyboardKey.semicolon) return ';';
  final label = key.keyLabel;
  return label.isEmpty ? '?' : label.toUpperCase();
}

int? localPartyIndexForKey(LogicalKeyboardKey key) {
  final i = localPartyKeys.indexOf(key);
  return i < 0 ? null : i;
}
