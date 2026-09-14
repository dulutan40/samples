import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OnlineSession extends ChangeNotifier {
  OnlineSession({required this.serverUrl});

  final String serverUrl;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  String? playerId;
  String? room;
  bool isHost = false;
  String phase = 'lobby';
  String? winnerId;
  String? error;
  bool connected = false;
  Map<String, dynamic> you = {};
  List<Map<String, dynamic>> players = [];

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

  void tap() => _send({'type': 'tap'});

  Future<void> _connect() async {
    await disposeSocket();
    error = null;
    final uri = Uri.parse(serverUrl);
    _channel = WebSocketChannel.connect(uri);
    connected = true;
    notifyListeners();
    _sub = _channel!.stream.listen(
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
      case 'state':
        phase = msg['phase'] as String? ?? phase;
        room = msg['room'] as String? ?? room;
        winnerId = msg['winnerId'] as String?;
        you = Map<String, dynamic>.from(msg['you'] as Map? ?? {});
        isHost = you['isHost'] == true;
        players = (msg['players'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      case 'error':
        error = msg['message'] as String? ?? 'Error';
    }
    notifyListeners();
  }

  void _send(Map<String, Object?> msg) {
    _channel?.sink.add(jsonEncode(msg));
  }

  Future<void> disposeSocket() async {
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
