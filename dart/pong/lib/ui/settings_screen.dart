import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/app_strings.dart';
import '../i18n/keys.dart';
import '../game/ai/difficulty.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  static const difficultyKey = 'settings.difficulty';

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Difficulty _difficulty = Difficulty.normal;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(SettingsScreen.difficultyKey);
    final parsed = Difficulty.values
        .where((d) => d.name == raw)
        .cast<Difficulty?>()
        .firstOrNull;
    if (!mounted) return;
    setState(() => _difficulty = parsed ?? Difficulty.normal);
  }

  Future<void> _save(Difficulty d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsScreen.difficultyKey, d.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t(I18nKeys.navSettings))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.t(I18nKeys.settingsCpuDifficulty)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Difficulty>(
            initialValue: _difficulty,
            items: [
              for (final d in Difficulty.values)
                DropdownMenuItem(value: d, child: Text(d.name)),
            ],
            onChanged: (d) async {
              if (d == null) return;
              setState(() => _difficulty = d);
              await _save(d);
            },
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

