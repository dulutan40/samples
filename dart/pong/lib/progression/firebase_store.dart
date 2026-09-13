import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'badges.dart';
import 'streaks.dart';

class FirebaseProgressStore {
  FirebaseProgressStore({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, Object?>> _doc() {
    final uid = _auth.currentUser?.uid ?? (throw StateError('Not authed'));
    return _firestore.collection('users').doc(uid).collection('progress').doc('v1');
  }

  Future<void> syncUp({
    required Set<BadgeId> badges,
    required Streaks streaks,
  }) async {
    await _doc().set({
      'badges': badges.map((b) => b.name).toList(),
      'streaks': {
        'dailyPlay': streaks.dailyPlay,
        'winCpu': streaks.winCpu,
        'winOnline': streaks.winOnline,
        'bestRally': streaks.bestRally,
      },
      'updatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }
}

