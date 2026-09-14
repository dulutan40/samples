import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OnlineSession extends ChangeNotifier {
  OnlineSession({required this.serverUrl});

  final String serverUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _cooldownTimer;
  String? playerId;
  String? room;
  bool isHost = false;
  String phase = 'lobby';
  String? winnerId;
  String? lastTapPlayerId;
  String? error;
  bool connected = false;
  Map<String, dynamic> you = {};
  List<Map<String, dynamic>> players = [];

  /// Absolute local time when your tap cooldown ends (null if idle).
  DateTime? cooldownUntil;

  bool get onCooldown =>
      cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!);

  Future<void> create({required String name}) async {
    await _connect();
    _send({'type': 'create', 'name': name});
  }

  Future<void> join({required String name, required String roomCode}) async {
    await _connect();
    _send({'type': 'join', 'name': name, 'room': roomCode.trim().toUpperCase()});
  }

  void start() => _send({'type': 'start'});

  void again() => _send({'type': 'again'});

  void tap() {
    // Optimistic 1s lock so the pad re-enables even if no further WS states arrive.
    cooldownUntil = DateTime.now().add(const Duration(seconds: 1));
    _armCooldownTimer();
    notifyListeners();
    _send({'type': 'tap'});
  }

  void rename(String name) {
    error = null;
    _send({'type': 'rename', 'name': name});
  }

  Future<void> _connect() async {
    await disposeSocket();
    error = null;
    final uri = Uri.parse(serverUrl);
    final channel = WebSocketChannel.connect(uri);
    _channel = channel;

    // Wait until the socket is actually up (or fail fast with a clear error).
    try {
      await channel.ready.timeout(const Duration(seconds: 4));
    } on TimeoutException {
      await disposeSocket();
      throw Exception(
        'Timed out connecting to $serverUrl. Is the Last to Tap server running?\n'
        'cd dart/last-to-tap/server && dart run bin/server.dart',
      );
    } catch (e) {
      await disposeSocket();
      final msg = e.toString();
      if (msg.contains('Connection refused') ||
          msg.contains('Failed to connect') ||
          msg.contains('SocketException')) {
        throw Exception(
          'Cannot reach $serverUrl (connection refused).\n'
          'Start the server first:\n'
          'cd dart/last-to-tap/server && dart run bin/server.dart',
        );
      }
      throw Exception('WebSocket failed: $msg');
    }

    connected = true;
    notifyListeners();
    _sub = channel.stream.listen(
      _onMessage,
      onDone: () {
        connected = false;
        error ??= 'Disconnected';
        notifyListeners();
      },
      onError: (Object e) {
        connected = false;
        error = e.toString();
        notifyListeners();
      },
    );
  }

  void _onMessage(dynamic raw) {
    final msg = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'welcome':
        playerId = msg['playerId'] as String?;
        room = msg['room'] as String?;
        isHost = msg['isHost'] == true;
        error = null;
      case 'state':
        error = null;
        phase = msg['phase'] as String? ?? phase;
        room = msg['room'] as String? ?? room;
        winnerId = msg['winnerId'] as String?;
        lastTapPlayerId = msg['lastTapPlayerId'] as String?;
        you = Map<String, dynamic>.from(msg['you'] as Map? ?? {});
        isHost = you['isHost'] == true;
        players = (msg['players'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _syncCooldownFromState();
      case 'error':
        error = msg['message'] as String? ?? 'Error';
    }
    notifyListeners();
  }

  void _syncCooldownFromState() {
    final remaining = (you['cooldownRemainingMs'] as num?)?.toInt() ?? 0;
    if (remaining > 0) {
      final serverUntil = DateTime.now().add(Duration(milliseconds: remaining));
      // Keep the later of optimistic local lock and server remaining.
      if (cooldownUntil == null || serverUntil.isAfter(cooldownUntil!)) {
        cooldownUntil = serverUntil;
      }
      _armCooldownTimer();
    } else if (you['onCooldown'] != true) {
      // Only clear if our optimistic timer already elapsed.
      if (cooldownUntil != null && !DateTime.now().isBefore(cooldownUntil!)) {
        cooldownUntil = null;
        _cooldownTimer?.cancel();
        _cooldownTimer = null;
      }
    }
  }

  void _armCooldownTimer() {
    _cooldownTimer?.cancel();
    final until = cooldownUntil;
    if (until == null) return;
    final wait = until.difference(DateTime.now());
    if (wait <= Duration.zero) {
      cooldownUntil = null;
      notifyListeners();
      return;
    }
    _cooldownTimer = Timer(wait + const Duration(milliseconds: 16), () {
      cooldownUntil = null;
      notifyListeners();
    });
  }

  void _send(Map<String, Object?> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  Future<void> disposeSocket() async {
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    await _sub?.cancel();
    _sub = null;
    await _channel?.sink.close();
    _channel = null;
    connected = false;
  }

  @override
  void dispose() {
    unawaited(disposeSocket());
    super.dispose();
  }
}

String defaultServerUrl() {
  const fromEnv = String.fromEnvironment('LTT_SERVER', defaultValue: '');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kIsWeb) return 'ws://127.0.0.1:3471';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'ws://10.0.2.2:3471';
    default:
      return 'ws://127.0.0.1:3471';
  }
}
