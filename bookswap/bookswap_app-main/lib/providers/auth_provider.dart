import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  UserProfile? _userProfile;
  bool _loading = false;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get loading => _loading;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      await _fetchUserProfile();
    } else {
      _userProfile = null;
    }
    notifyListeners();
  }

  Future<void> _fetchUserProfile() async {
    if (_user == null) return;

    final doc = await _firestore.collection('users').doc(_user!.uid).get();
    if (doc.exists) {
      _userProfile = UserProfile.fromMap(_user!.uid, doc.data()!);
    } else {
      // Create profile if it doesn't exist
      final userProfile = UserProfile(
        uid: _user!.uid,
        email: _user!.email ?? '',
        displayName:
            _user!.displayName ?? _user!.email?.split('@')[0] ?? 'User',
        createdAt: DateTime.now(),
        emailVerified: _user!.emailVerified,
      );

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .set(userProfile.toMap());

      _userProfile = userProfile;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _loading = true;
      notifyListeners();

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.sendEmailVerification();

      final userProfile = UserProfile(
        uid: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userProfile.toMap());

      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      _loading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _loading = false;
      notifyListeners();
    } catch (e) {
      _loading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateNotificationPreferences(bool enabled) async {
    if (_user == null || _userProfile == null) return;

    await _firestore.collection('users').doc(_user!.uid).update({
      'notificationsEnabled': enabled,
    });

    _userProfile = _userProfile!.copyWith(notificationsEnabled: enabled);
    notifyListeners();
  }
}
