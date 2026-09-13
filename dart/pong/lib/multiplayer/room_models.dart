import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { waiting, playing, ended }

class RoomPlayer {
  const RoomPlayer({
    required this.uid,
    required this.side,
    required this.ready,
    required this.lastSeen,
  });

  final String uid;
  final String side; // "left" | "right"
  final bool ready;
  final DateTime? lastSeen;

  Map<String, Object?> toJson() => {
        'side': side,
        'ready': ready,
        'lastSeen': lastSeen == null ? null : Timestamp.fromDate(lastSeen!),
      };

  static RoomPlayer fromJson(String uid, Map<String, Object?> json) {
    final ts = json['lastSeen'];
    return RoomPlayer(
      uid: uid,
      side: (json['side'] as String?) ?? 'left',
      ready: (json['ready'] as bool?) ?? false,
      lastSeen: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class Room {
  const Room({
    required this.id,
    required this.status,
    required this.hostUid,
    required this.seed,
    required this.players,
  });

  final String id;
  final RoomStatus status;
  final String hostUid;
  final int seed;
  final Map<String, RoomPlayer> players;

  static RoomStatus _parseStatus(String? raw) {
    return switch (raw) {
      'playing' => RoomStatus.playing,
      'ended' => RoomStatus.ended,
      _ => RoomStatus.waiting,
    };
  }

  static Room fromDoc(DocumentSnapshot<Map<String, Object?>> doc) {
    final data = doc.data() ?? const {};
    final playersRaw = (data['players'] as Map?)?.cast<String, Object?>() ?? {};
    final players = <String, RoomPlayer>{};
    for (final entry in playersRaw.entries) {
      final value = entry.value;
      if (value is Map) {
        players[entry.key] =
            RoomPlayer.fromJson(entry.key, value.cast<String, Object?>());
      }
    }

    return Room(
      id: doc.id,
      status: _parseStatus(data['status'] as String?),
      hostUid: (data['hostUid'] as String?) ?? '',
      seed: (data['seed'] as num?)?.toInt() ?? 0,
      players: players,
    );
  }
}

