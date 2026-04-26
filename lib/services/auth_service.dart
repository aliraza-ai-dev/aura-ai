import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Admin emails
  static const List<String> adminEmails = [
    'admin@auraai.com',
    // Add your admin emails here
  ];

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user == null) return null;

      await cred.user!.updateDisplayName(displayName);

      final user = UserModel(
        uid: cred.user!.uid,
        email: email,
        displayName: displayName,
        plan: 'free',
        createdAt: DateTime.now(),
        isAdmin: adminEmails.contains(email.toLowerCase()),
      );

      await _db.collection('users').doc(user.uid).set(user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user == null) return null;
      return await getUserData(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUserPlan(String uid, String plan) async {
    await _db.collection('users').doc(uid).update({'plan': plan});
  }

  Future<void> incrementMessageCount(String uid) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final userDoc = await _db.collection('users').doc(uid).get();
    final data = userDoc.data()!;
    final lastDate = data['lastMessageDate'] != null
        ? (data['lastMessageDate'] as Timestamp).toDate()
        : null;
    final lastDay = lastDate != null
        ? DateTime(lastDate.year, lastDate.month, lastDate.day)
        : null;

    if (lastDay == null || lastDay.isBefore(today)) {
      await _db.collection('users').doc(uid).update({
        'dailyMessagesUsed': 1,
        'lastMessageDate': Timestamp.fromDate(now),
      });
    } else {
      await _db.collection('users').doc(uid).update({
        'dailyMessagesUsed': FieldValue.increment(1),
        'lastMessageDate': Timestamp.fromDate(now),
      });
    }
  }

  Stream<UserModel?> userStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'Authentication failed: ${e.message}';
    }
  }
}
