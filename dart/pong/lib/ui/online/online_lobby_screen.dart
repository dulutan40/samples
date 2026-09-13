import 'package:flutter/material.dart';

import '../../i18n/app_strings.dart';
import '../../i18n/keys.dart';
import '../../multiplayer/multiplayer_service.dart';
import '../../multiplayer/room_models.dart';
import 'online_game_screen.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final _service = MultiplayerService();
  final _joinController = TextEditingController();

  String? _roomId;
  Object? _error;

  @override
  void dispose() {
    _joinController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _error = null);
    try {
      final id = await _service.createRoom();
      if (!mounted) return;
      setState(() => _roomId = id);
    } catch (e) {
      setState(() => _error = e);
    }
  }

  Future<void> _join() async {
    setState(() => _error = null);
    try {
      final id = _joinController.text.trim().toUpperCase();
      await _service.joinRoom(id);
      if (!mounted) return;
      setState(() => _roomId = id);
    } catch (e) {
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomId = _roomId;
    return Scaffold(
      appBar: AppBar(title: Text(context.t(I18nKeys.homePlayOnline))),
      body: roomId == null ? _buildChooser() : _buildRoom(roomId),
    );
  }

  Widget _buildChooser() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FilledButton(
          onPressed: _create,
          child: Builder(
            builder: (context) => Text(context.t(I18nKeys.onlineCreateRoom)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _joinController,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: context.t(I18nKeys.onlineRoomCode),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _join,
          child: Builder(
            builder: (context) => Text(context.t(I18nKeys.onlineJoinRoom)),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error.toString()),
        ],
      ],
    );
  }

  Widget _buildRoom(String roomId) {
    return StreamBuilder<Room>(
      stream: _service.watchRoom(roomId),
      builder: (context, snap) {
        final room = snap.data;
        if (room == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final me = _service.uid;
        final myPlayer = room.players[me];

        if (room.status == RoomStatus.playing && room.players.length == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OnlineGameScreen(room: room, myUid: me),
              ),
            );
          });
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SelectableText('${context.t(I18nKeys.onlineRoomLabel)}: $roomId'),
            const SizedBox(height: 12),
            Text(
              '${context.t(I18nKeys.onlinePlayersLabel)}: ${room.players.length}/2',
            ),
            const SizedBox(height: 12),
            for (final p in room.players.values)
              ListTile(
                title: Text(
                  p.uid == me
                      ? context.t(I18nKeys.onlineYou)
                      : context.t(I18nKeys.onlineOpponent),
                ),
                subtitle: Text(
                  '${p.side} • ${p.ready ? context.t(I18nKeys.onlineReady) : context.t(I18nKeys.onlineNotReady)}',
                ),
              ),
            const SizedBox(height: 16),
            if (myPlayer != null)
              FilledButton(
                onPressed: () async {
                  final next = !myPlayer.ready;
                  await _service.setReady(roomId, next);
                  await _service.maybeStartIfReady(roomId);
                },
                child: Text(
                  myPlayer.ready
                      ? context.t(I18nKeys.onlineUnready)
                      : context.t(I18nKeys.onlineReady),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await _service.leaveRoom(roomId);
                if (!mounted) return;
                setState(() => _roomId = null);
              },
              child: Text(context.t(I18nKeys.onlineLeave)),
            ),
            const SizedBox(height: 12),
            if (room.status == RoomStatus.playing)
              Text(context.t(I18nKeys.onlineStarting)),
          ],
        );
      },
    );
  }
}

