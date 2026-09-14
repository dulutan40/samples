import 'dart:math';

final _rng = Random();

/// Default display name: `Player_` + six digits (000000–999999).
String randomPlayerName([Random? rng]) {
  final n = (rng ?? _rng).nextInt(1000000).toString().padLeft(6, '0');
  return 'Player_$n';
}

List<String> uniqueRandomPlayerNames(int count, [Random? rng]) {
  final r = rng ?? _rng;
  final used = <String>{};
  final out = <String>[];
  while (out.length < count) {
    final name = randomPlayerName(r);
    if (used.add(name.toLowerCase())) out.add(name);
  }
  return out;
}

String normalizePlayerName(String raw) => raw.trim();

/// Case-insensitive duplicate check. [exceptIndex] skips that slot (local edit).
bool isPlayerNameTaken(
  String candidate,
  Iterable<String> existing, {
  int? exceptIndex,
}) {
  final key = normalizePlayerName(candidate).toLowerCase();
  if (key.isEmpty) return false;
  var i = 0;
  for (final name in existing) {
    if (exceptIndex != null && i == exceptIndex) {
      i++;
      continue;
    }
    if (normalizePlayerName(name).toLowerCase() == key) return true;
    i++;
  }
  return false;
}
