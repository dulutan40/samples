import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

const cooldownMs = 1000;
const minRoundMs = 10000;
const maxRoundMs = 25000;

final _rng = Random.secure();

String _roomCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return List.generate(4, (_) => alphabet[_rng.nextInt(alphabet.length)]).join();
}

String _id() =>
    DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
    _rng.nextInt(1 << 20).toRadixString(36);

enum Phase { lobby, playing, results }

class Player {
  Player({required this.id, required this.name, required this.sink});

  final String id;
  String name;
  WebSocketChannel sink;
  bool connected = true;
  int? lastTapAt;
  int cooldownUntil = 0;

  Map<String, Object?> publicJson(int now) => {
        'id': id,
        'name': name,
        'connected': connected,
        'hasTapped': lastTapAt != null,
        'onCooldown': now < cooldownUntil,
      };
}

class Room {
  Room({required this.code, required this.hostId});

  final String code;
  String hostId;
  Phase phase = Phase.lobby;
  final Map<String, Player> players = {};
  int? endsAt;
  String? winnerId;
  Timer? _endTimer;

  void send(Player p, Map<String, Object?> msg) {
    try {
      p.sink.sink.add(jsonEncode(msg));
    } catch (_) {}
  }

  void broadcast(Map<String, Object?> msg) {
    final raw = jsonEncode(msg);
    for (final p in players.values) {
      if (!p.connected) continue;
      try {
        p.sink.sink.add(raw);
      } catch (_) {}
    }
  }

  Map<String, Object?> stateFor(Player viewer) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'type': 'state',
      'room': code,
      'phase': phase.name,
      'hostId': hostId,
      'endsAtHidden': true,
      'winnerId': winnerId,
      'lastTapPlayerId': phase == Phase.playing ? latestTapPlayerId : null,
      'you': {
        'id': viewer.id,
        'isHost': viewer.id == hostId,
        'onCooldown': now < viewer.cooldownUntil,
        'cooldownRemainingMs': (viewer.cooldownUntil - now).clamp(0, cooldownMs),
        'hasTapped': viewer.lastTapAt != null,
      },
      'players': players.values.map((p) => p.publicJson(now)).toList(),
    };
  }

  String? get latestTapPlayerId {
    Player? best;
    for (final p in players.values) {
      final t = p.lastTapAt;
      if (t == null) continue;
      if (best == null || t > best.lastTapAt!) best = p;
    }
    return best?.id;
  }

  void pushAll() {
    for (final p in players.values) {
      if (p.connected) send(p, stateFor(p));
    }
  }

  void startRound() {
    if (phase == Phase.playing) return;
    if (players.values.where((p) => p.connected).length < 2) {
      return;
    }
    _endTimer?.cancel();
    winnerId = null;
    final span = maxRoundMs - minRoundMs;
    final duration = minRoundMs + _rng.nextInt(span + 1);
    final now = DateTime.now().millisecondsSinceEpoch;
    endsAt = now + duration;
    phase = Phase.playing;
    for (final p in players.values) {
      p.lastTapAt = null;
      p.cooldownUntil = 0;
    }
    pushAll();
    _endTimer = Timer(Duration(milliseconds: duration), endRound);
  }

  void endRound() {
    if (phase != Phase.playing) return;
    _endTimer?.cancel();
    _endTimer = null;
    phase = Phase.results;
    Player? best;
    for (final p in players.values) {
      final t = p.lastTapAt;
      if (t == null) continue;
      if (best == null || t > best.lastTapAt!) best = p;
    }
    winnerId = best?.id;
    endsAt = null;
    pushAll();
  }

  void tap(Player p) {
    if (phase != Phase.playing) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < p.cooldownUntil) return;
    p.lastTapAt = now;
    p.cooldownUntil = now + cooldownMs;
    send(p, stateFor(p));
    // Others only need hasTapped flags, not timing.
    for (final other in players.values) {
      if (other.id == p.id || !other.connected) continue;
      send(other, stateFor(other));
    }
  }

  bool isNameTaken(String name, {String? exceptId}) {
    final key = name.toLowerCase();
    for (final p in players.values) {
      if (exceptId != null && p.id == exceptId) continue;
      if (p.name.toLowerCase() == key) return true;
    }
    return false;
  }
}

class GameHub {
  final Map<String, Room> rooms = {};

  void attach(WebSocketChannel channel) {
    String? playerId;
    String? roomCode;

    channel.stream.listen(
      (raw) {
        Map<String, dynamic> msg;
        try {
          msg = jsonDecode(raw as String) as Map<String, dynamic>;
        } catch (_) {
          channel.sink.add(jsonEncode({'type': 'error', 'message': 'bad json'}));
          return;
        }
        final type = msg['type'] as String? ?? '';
        try {
          switch (type) {
            case 'create':
              final name = _cleanName(msg['name']);
              if (name == null) {
                channel.sink.add(jsonEncode({
                  'type': 'error',
                  'message': 'Enter a player name',
                }));
                return;
              }
              final code = _uniqueCode();
              final id = _id();
              final room = Room(code: code, hostId: id);
              final player = Player(id: id, name: name, sink: channel);
              room.players[id] = player;
              rooms[code] = room;
              playerId = id;
              roomCode = code;
              room.send(player, {
                'type': 'welcome',
                'playerId': id,
                'room': code,
                'isHost': true,
              });
              room.pushAll();
            case 'join':
              final name = _cleanName(msg['name']);
              if (name == null) {
                channel.sink.add(jsonEncode({
                  'type': 'error',
                  'message': 'Enter a player name',
                }));
                return;
              }
              final code = (msg['room'] as String? ?? '').trim().toUpperCase();
              final room = rooms[code];
              if (room == null) {
                channel.sink.add(jsonEncode({
                  'type': 'error',
                  'message': 'Room not found',
                }));
                return;
              }
              if (room.phase == Phase.playing) {
                channel.sink.add(jsonEncode({
                  'type': 'error',
                  'message': 'Round in progress — try again after results',
                }));
                return;
              }
              if (room.isNameTaken(name)) {
                channel.sink.add(jsonEncode({
                  'type': 'error',
                  'message': 'That name is already taken',
                }));
                return;
              }
              final id = _id();
              final player = Player(id: id, name: name, sink: channel);
              room.players[id] = player;
              playerId = id;
              roomCode = code;
              room.send(player, {
                'type': 'welcome',
                'playerId': id,
                'room': code,
                'isHost': id == room.hostId,
              });
              room.pushAll();
            case 'rename':
              final room = _room(roomCode);
              final player = _player(room, playerId);
              if (player == null || room == null) return;
              if (room.phase == Phase.playing) {
                room.send(player, {
                  'type': 'error',
                  'message': 'Cannot rename during a round',
                });
                return;
              }
              final name = _cleanName(msg['name']);
              if (name == null) {
                room.send(player, {
                  'type': 'error',
                  'message': 'Enter a player name',
                });
                return;
              }
              if (room.isNameTaken(name, exceptId: player.id)) {
                room.send(player, {
                  'type': 'error',
                  'message': 'That name is already taken',
                });
                return;
              }
              player.name = name;
              room.pushAll();
            case 'start':
            case 'again':
              final room = _room(roomCode);
              final player = _player(room, playerId);
              if (player == null || room == null) return;
              if (player.id != room.hostId) {
                room.send(player, {
                  'type': 'error',
                  'message': 'Only the host can start',
                });
                return;
              }
              room.startRound();
              if (room.phase != Phase.playing) {
                room.send(player, {
                  'type': 'error',
                  'message': 'Need at least 2 connected players',
                });
              }
            case 'tap':
              final room = _room(roomCode);
              final player = _player(room, playerId);
              if (player == null || room == null) return;
              room.tap(player);
            default:
              channel.sink.add(jsonEncode({
                'type': 'error',
                'message': 'Unknown message',
              }));
          }
        } catch (e) {
          channel.sink.add(jsonEncode({
            'type': 'error',
            'message': e.toString(),
          }));
        }
      },
      onDone: () => _disconnect(roomCode, playerId),
      onError: (_) => _disconnect(roomCode, playerId),
      cancelOnError: true,
    );
  }

  Room? _room(String? code) => code == null ? null : rooms[code];

  Player? _player(Room? room, String? id) {
    if (room == null || id == null) return null;
    return room.players[id];
  }

  void _disconnect(String? roomCode, String? playerId) {
    if (roomCode == null || playerId == null) return;
    final room = rooms[roomCode];
    if (room == null) return;
    final player = room.players[playerId];
    if (player == null) return;
    player.connected = false;
    if (room.hostId == playerId) {
      final next = room.players.values.firstWhere(
        (p) => p.connected && p.id != playerId,
        orElse: () => player,
      );
      if (next.connected) room.hostId = next.id;
    }
    room.pushAll();
    if (room.players.values.every((p) => !p.connected)) {
      room._endTimer?.cancel();
      rooms.remove(roomCode);
    }
  }

  String _uniqueCode() {
    for (var i = 0; i < 20; i++) {
      final c = _roomCode();
      if (!rooms.containsKey(c)) return c;
    }
    return _roomCode() + _rng.nextInt(9).toString();
  }

  /// Returns cleaned name, or null if empty/invalid.
  String? _cleanName(dynamic raw) {
    var s = (raw as String? ?? '').trim();
    if (s.isEmpty) return null;
    if (s.length > 24) s = s.substring(0, 24);
    return s;
  }
}
