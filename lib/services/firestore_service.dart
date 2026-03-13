import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  String get _displayName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';

  // ──────────────────────────────────────────────────────────
  //  Check-in / Check-out
  // ──────────────────────────────────────────────────────────

  Future<void> saveCheckIn(Map<String, dynamic> data) async {
    await _db.collection('checkins').add({
      ...data,
      'uid': _uid,
      'displayName': _displayName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveCheckOut(Map<String, dynamic> data) async {
    await _db.collection('checkouts').add({
      ...data,
      'uid': _uid,
      'displayName': _displayName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ──────────────────────────────────────────────────────────
  //  QR Session management (Instructor creates, students read)
  // ──────────────────────────────────────────────────────────

  /// Instructor: create a new QR session
  Future<String> createQrSession({
    required String className,
    required double latitude,
    required double longitude,
    int radiusMeters = 100,
    int validMinutes = 15,
  }) async {
    final doc = await _db.collection('qr_sessions').add({
      'className': className,
      'createdBy': _uid,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'expiresAt': Timestamp.fromDate(
          DateTime.now().add(Duration(minutes: validMinutes))),
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id; // This is the QR payload
  }

  /// Get a QR session document
  Future<DocumentSnapshot> getQrSession(String sessionId) =>
      _db.collection('qr_sessions').doc(sessionId).get();

  /// Student: check-in via QR session ID
  Future<void> qrCheckIn({
    required String sessionId,
    required double latitude,
    required double longitude,
    required int mood,
    required String previousTopic,
    required String expectedTopic,
  }) async {
    // Verify session is still valid
    final session = await getQrSession(sessionId);
    if (!session.exists) throw Exception('Session not found.');
    final data = session.data() as Map<String, dynamic>;
    final expires = (data['expiresAt'] as Timestamp).toDate();
    if (DateTime.now().isAfter(expires)) throw Exception('QR code has expired.');
    if (!(data['active'] as bool)) throw Exception('Session is no longer active.');

    await saveCheckIn({
      'sessionId': sessionId,
      'className': data['className'] ?? '',
      'previousTopic': previousTopic,
      'expectedTopic': expectedTopic,
      'mood': mood,
      'latitude': latitude,
      'longitude': longitude,
      'method': 'qr',
    });
  }

  // ──────────────────────────────────────────────────────────
  //  Analytics helpers
  // ──────────────────────────────────────────────────────────

  Stream<QuerySnapshot> streamCheckIns({int limit = 50}) => _db
      .collection('checkins')
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots();

  Stream<QuerySnapshot> streamCheckOuts({int limit = 50}) => _db
      .collection('checkouts')
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .snapshots();

  /// Returns check-in counts grouped by day (last 7 days)
  Future<Map<String, int>> getWeeklyCheckInCounts() async {
    final since = Timestamp.fromDate(
        DateTime.now().subtract(const Duration(days: 7)));
    final snap = await _db
        .collection('checkins')
        .where('timestamp', isGreaterThan: since)
        .get();
    final Map<String, int> counts = {};
    for (final d in snap.docs) {
      final ts = (d['timestamp'] as Timestamp?)?.toDate();
      if (ts == null) continue;
      final key =
          '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}
