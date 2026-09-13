import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'badges.dart';
import 'streaks.dart';

class LocalProgressStore {
  static const _badgesKey = 'progress.badges';
  static const _streaksKey = 'progress.streaks';
  static const _lastPlayDayKey = 'progress.lastPlayDay';

  Future<Set<BadgeId>> loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_badgesKey) ?? const <String>[];
    return raw
        .map((s) => BadgeId.values.where((b) => b.name == s).cast<BadgeId?>().firstOrNull)
        .whereType<BadgeId>()
        .toSet();
  }

  Future<void> saveBadges(Set<BadgeId> badges) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_badgesKey, badges.map((b) => b.name).toList());
  }

  Future<Streaks> loadStreaks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_streaksKey);
    if (raw == null) return Streaks.empty;
    final json = jsonDecode(raw);
    if (json is! Map) return Streaks.empty;
    return Streaks(
      dailyPlay: (json['dailyPlay'] as num?)?.toInt() ?? 0,
      winCpu: (json['winCpu'] as num?)?.toInt() ?? 0,
      winOnline: (json['winOnline'] as num?)?.toInt() ?? 0,
      bestRally: (json['bestRally'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> saveStreaks(Streaks streaks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _streaksKey,
      jsonEncode({
        'dailyPlay': streaks.dailyPlay,
        'winCpu': streaks.winCpu,
        'winOnline': streaks.winOnline,
        'bestRally': streaks.bestRally,
      }),
    );
  }

  Future<DateTime?> loadLastPlayDay() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastPlayDayKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveLastPlayDay(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayDayKey, _dayKey(day));
  }

  static String _dayKey(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day).toIso8601String();
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

