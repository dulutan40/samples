import 'package:shared_preferences/shared_preferences.dart';

import '../game/player_names.dart';

const _onlineNameKey = 'last_to_tap_online_name';

/// Stable display name for this install / browser profile.
class PlayerNameStore {
  static Future<String> loadOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_onlineNameKey)?.trim();
    if (existing != null && existing.isNotEmpty) return existing;
    final name = randomPlayerName();
    await prefs.setString(_onlineNameKey, name);
    return name;
  }

  static Future<void> save(String name) async {
    final cleaned = normalizePlayerName(name);
    if (cleaned.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_onlineNameKey, cleaned);
  }
}
