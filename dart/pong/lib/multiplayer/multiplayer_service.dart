import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'room_models.dart';

class MultiplayerService {
  MultiplayerService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, Object?>> get _rooms =>
      _firestore.collection('rooms');

  String get uid {
    final u = _auth.currentUser;
    if (u == null) throw StateError('Not authenticated');
    return u.uid;
  }

  Future<String> createRoom() async {
    final id = _randomRoomCode();
    final seed = Random().nextInt(1 << 31);
    final now = DateTime.now();

    await _rooms.doc(id).set({
      'status': 'waiting',
      'hostUid': uid,
      'seed': seed,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'players': {
        uid: {
          'side': 'left',
          'ready': false,
          'lastSeen': Timestamp.fromDate(now),
        }
      }
    });

    return id;
  }

  Future<void> joinRoom(String roomId) async {
    final ref = _rooms.doc(roomId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('Room not found');
    }
    final now = DateTime.now();

    await ref.set({
      'updatedAt': Timestamp.fromDate(now),
      'players': {
        uid: {
          'side': 'right',
          'ready': false,
          'lastSeen': Timestamp.fromDate(now),
        }
      }
    }, SetOptions(merge: true));
  }

  Stream<Room> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().map(Room.fromDoc);
  }

  Future<void> setReady(String roomId, bool ready) async {
    final ref = _rooms.doc(roomId);
    final now = DateTime.now();
    await ref.set({
      'updatedAt': Timestamp.fromDate(now),
      'players': {
        uid: {
          'ready': ready,
          'lastSeen': Timestamp.fromDate(now),
        }
      }
    }, SetOptions(merge: true));
  }

  Future<void> maybeStartIfReady(String roomId) async {
    final ref = _rooms.doc(roomId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final room = Room.fromDoc(snap);
      if (room.status != RoomStatus.waiting) return;
      if (room.players.length < 2) return;
      final allReady = room.players.values.every((p) => p.ready);
      if (!allReady) return;
      tx.set(ref, {
        'status': 'playing',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    });
  }

  Future<void> leaveRoom(String roomId) async {
    final ref = _rooms.doc(roomId);
    await ref.set({
      'players': {uid: FieldValue.delete()},
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    }, SetOptions(merge: true));
  }

  String _randomRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}

