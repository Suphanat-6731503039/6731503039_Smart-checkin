import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email/password and save profile to Firestore
  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
    required String studentId,
    String role = 'student', // 'student' | 'instructor'
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    await _db.collection('users').doc(cred.user!.uid).set({
      'displayName': displayName,
      'email': email,
      'studentId': studentId,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  /// Sign in
  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Sign out
  static Future<void> signOut() => _auth.signOut();

  /// Get user profile from Firestore
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  /// Check if current user is instructor
  static Future<bool> isInstructor() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final profile = await getUserProfile(user.uid);
    return profile?['role'] == 'instructor';
  }
}
