import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class BallSnapshot {
  const BallSnapshot({
    required this.position,
    required this.velocity,
    required this.sentAt,
  });

  final Offset position;
  final Offset velocity;
  final DateTime sentAt;
}

class RealtimeSyncService {
  RealtimeSyncService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String get uid => _auth.currentUser?.uid ?? (throw StateError('Not authed'));

  DocumentReference<Map<String, Object?>> _paddleDoc(String roomId, String uid) =>
      _firestore.collection('rooms').doc(roomId).collection('signals').doc(uid);

  DocumentReference<Map<String, Object?>> _ballDoc(String roomId) =>
      _firestore.collection('rooms').doc(roomId).collection('snapshots').doc('ball');

  Future<void> sendPaddleY(String roomId, double y) async {
    await _paddleDoc(roomId, uid).set({
      'y': y,
      'clientTs': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Stream<double?> watchPaddleY(String roomId, String otherUid) {
    return _paddleDoc(roomId, otherUid).snapshots().map((doc) {
      final data = doc.data();
      final y = data?['y'];
      return y is num ? y.toDouble() : null;
    });
  }

  Future<void> sendBallSnapshot(
    String roomId, {
    required Offset position,
    required Offset velocity,
  }) async {
    await _ballDoc(roomId).set({
      'x': position.dx,
      'y': position.dy,
      'vx': velocity.dx,
      'vy': velocity.dy,
      'sentAt': Timestamp.now(),
      'hostUid': uid,
    }, SetOptions(merge: true));
  }

  Stream<BallSnapshot?> watchBallSnapshot(String roomId) {
    return _ballDoc(roomId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final x = data['x'];
      final y = data['y'];
      final vx = data['vx'];
      final vy = data['vy'];
      final sentAt = data['sentAt'];
      if (x is! num || y is! num || vx is! num || vy is! num) return null;
      return BallSnapshot(
        position: Offset(x.toDouble(), y.toDouble()),
        velocity: Offset(vx.toDouble(), vy.toDouble()),
        sentAt: sentAt is Timestamp ? sentAt.toDate() : DateTime.now(),
      );
    });
  }

  StreamSubscription<T> throttle<T>(
    Stream<T> stream,
    Duration minInterval,
    void Function(T event) onEvent,
  ) {
    DateTime last = DateTime.fromMillisecondsSinceEpoch(0);
    return stream.listen((event) {
      final now = DateTime.now();
      if (now.difference(last) < minInterval) return;
      last = now;
      onEvent(event);
    });
  }
}

