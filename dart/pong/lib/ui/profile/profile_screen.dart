import 'package:flutter/material.dart';

import '../../i18n/app_strings.dart';
import '../../i18n/keys.dart';
import '../../progression/progression_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProgressionService();
  ProgressionSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _service.load();
    if (!mounted) return;
    setState(() => _snapshot = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _snapshot;
    return Scaffold(
      appBar: AppBar(title: Text(context.t(I18nKeys.navProfile))),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${context.t(I18nKeys.profileBadges)}: ${s.badges.length}'),
                const SizedBox(height: 12),
                Text('Daily streak: ${s.streaks.dailyPlay}'),
                Text('Win streak (CPU): ${s.streaks.winCpu}'),
                Text('Win streak (Online): ${s.streaks.winOnline}'),
                Text('Best rally: ${s.streaks.bestRally}'),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    await _service.recordDailyPlay();
                    await _load();
                  },
                  child: const Text('Record daily play (test)'),
                ),
              ],
            ),
    );
  }
}

