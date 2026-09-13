import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/ai/difficulty.dart';
import '../i18n/app_strings.dart';
import '../i18n/keys.dart';
import 'game_screen.dart';
import 'online/online_lobby_screen.dart';
import 'settings_screen.dart';
import 'widgets/pong_logo.dart';
import 'profile/profile_screen.dart';
import '../store/store_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const PongLogo(size: 120),
                    const SizedBox(height: 24),
                    Text(
                      context.t(I18nKeys.appTitle),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GameScreen(
                              vsCpu: true,
                              difficulty: _difficulty,
                            ),
                          ),
                        );
                      },
                      child: Text(context.t(I18nKeys.homePlayCpu)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OnlineLobbyScreen(),
                          ),
                        );
                      },
                      child: Text(context.t(I18nKeys.homePlayOnline)),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                        await _load();
                      },
                      child: Text(context.t(I18nKeys.navSettings)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Text(context.t(I18nKeys.navProfile)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StoreScreen()),
                        );
                      },
                      child: Text(context.t(I18nKeys.navStore)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

