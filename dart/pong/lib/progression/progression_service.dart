import 'badges.dart';
import 'firebase_store.dart';
import 'local_store.dart';
import 'streaks.dart';

class ProgressionSnapshot {
  const ProgressionSnapshot({
    required this.badges,
    required this.streaks,
  });

  final Set<BadgeId> badges;
  final Streaks streaks;
}

class ProgressionService {
  ProgressionService({
    LocalProgressStore? local,
    FirebaseProgressStore? remote,
  })  : _local = local ?? LocalProgressStore(),
        _remote = remote ?? FirebaseProgressStore();

  final LocalProgressStore _local;
  final FirebaseProgressStore _remote;

  Future<ProgressionSnapshot> load() async {
    final badges = await _local.loadBadges();
    final streaks = await _local.loadStreaks();
    return ProgressionSnapshot(badges: badges, streaks: streaks);
  }

  Future<void> recordDailyPlay() async {
    final last = await _local.loadLastPlayDay();
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    final streaks = await _local.loadStreaks();
    final next = (last == null)
        ? streaks.copyWith(dailyPlay: 1)
        : _nextDaily(streaks, last, todayKey);

    await _local.saveStreaks(next);
    await _local.saveLastPlayDay(todayKey);
    await _remote.syncUp(badges: await _local.loadBadges(), streaks: next);
  }

  Future<void> unlock(BadgeId badge) async {
    final badges = await _local.loadBadges();
    if (badges.contains(badge)) return;
    final next = {...badges, badge};
    await _local.saveBadges(next);
    await _remote.syncUp(badges: next, streaks: await _local.loadStreaks());
  }

  Streaks _nextDaily(Streaks s, DateTime last, DateTime todayKey) {
    final lastKey = DateTime(last.year, last.month, last.day);
    final diff = todayKey.difference(lastKey).inDays;
    if (diff == 0) return s; // already counted today
    if (diff == 1) return s.copyWith(dailyPlay: s.dailyPlay + 1);
    return s.copyWith(dailyPlay: 1);
  }
}

