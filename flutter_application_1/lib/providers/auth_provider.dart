import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService() {
    _initUser();
  }

  final AuthService _authService;

  FirebaseFirestore get firestore => _authService.firestore;

  void refreshCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> _initUser() async {
    try {
      final fbUser = _authService.getCurrentUser();
      if (fbUser != null) {
        final uid = fbUser.uid;
        final doc = await _authService.firestore.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          _currentUser = User.fromDocument(uid, doc.data()!);
          await NotificationService().saveFcmToken(uid);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error initializing user: $e');
    }
  }

  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool get isBuyer => _currentUser?.role == UserRole.buyer;
  bool get isSeller => _currentUser?.role == UserRole.seller;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<void> login(String email, String password) async {
    try {
      final userCredential = await _authService.loginWithEmailPassword(email, password);
      await _authService.createOrUpdateUserInFirestore(userCredential);

      final fbUser = userCredential.user;
      final uid = fbUser?.uid;
      if (uid == null) {
        throw StateError('FirebaseAuth user is null after sign-in.');
      }

      // Get fresh user data from Firestore to ensure we have the latest fields
      final freshUserDoc = await _authService.firestore.collection('users').doc(uid).get();
      if (freshUserDoc.exists) {
        _currentUser = User.fromDocument(uid, freshUserDoc.data()!);
      } else {
        // Fallback if Firestore doc doesn't exist yet
        final roleStr = await _authService.getUserRole(uid);
        final role = switch (roleStr) {
          'admin' => UserRole.admin,
          'seller' => UserRole.seller,
          _ => UserRole.buyer,
        };

        _currentUser = User(
          id: uid,
          email: fbUser?.email ?? '',
          name: fbUser?.displayName ?? (fbUser?.email?.split('@').first.toUpperCase() ?? 'USER'),
          photoUrl: fbUser?.photoURL,
          role: role,
          provider: 'email',
          emailVerified: fbUser?.emailVerified ?? false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      await NotificationService().saveFcmToken(uid);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password, UserRole role) async {
     try {
       final userCredential = await _authService.signUpWithEmailPassword(email, password);
       await _authService.createOrUpdateUserInFirestore(
         userCredential,
         displayName: name,
         role: role.toString().split('.').last,
       );

       final fbUser = userCredential.user;
       final uid = fbUser?.uid;
       if (uid == null) {
         throw StateError('FirebaseAuth user is null after sign-up.');
       }

       // Get fresh user data from Firestore to ensure we have the latest fields
       final freshUserDoc = await _authService.firestore.collection('users').doc(uid).get();
       if (freshUserDoc.exists) {
         _currentUser = User.fromDocument(uid, freshUserDoc.data()!);
       } else {
         // Fallback if Firestore doc doesn't exist yet
         _currentUser = User(
           id: uid,
           email: fbUser?.email ?? '',
           name: name,
           photoUrl: fbUser?.photoURL,
           role: role,
           provider: 'email',
           emailVerified: fbUser?.emailVerified ?? false,
           createdAt: DateTime.now(),
           updatedAt: DateTime.now(),
         );
       }
       await NotificationService().saveFcmToken(uid);
       notifyListeners();
     } catch (e) {
       rethrow;
     }
  }

  /// Sends email verification to the current user.
  Future<void> sendEmailVerification() async {
    await _authService.sendEmailVerification();
  }

  /// Checks if the current user's email is verified.
  Future<bool> isEmailVerified() async {
    final isVerified = await _authService.isEmailVerified();
    if (isVerified && _currentUser != null && !_currentUser!.emailVerified) {
      try {
        await _authService.firestore.collection('users').doc(_currentUser!.id).update({
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        _currentUser = User(
          id: _currentUser!.id,
          email: _currentUser!.email,
          name: _currentUser!.name,
          photoUrl: _currentUser!.photoUrl,
          role: _currentUser!.role,
          provider: _currentUser!.provider,
          emailVerified: true,
          createdAt: _currentUser!.createdAt,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      } catch (e) {
        // Silently log or ignore update errors during checking
      }
    }
    return isVerified;
  }

  Future<void> signInWithGoogle() async {
    try {
      final userCredential = await _authService.loginWithGoogle();
      await _authService.createOrUpdateUserInFirestore(userCredential);

      final fbUser = userCredential.user;
      final uid = fbUser?.uid;
      if (uid == null) {
        throw StateError('FirebaseAuth user is null after Google sign-in.');
      }

      // Get fresh user data from Firestore to ensure we have the latest fields
      final freshUserDoc = await _authService.firestore.collection('users').doc(uid).get();
      if (freshUserDoc.exists) {
        _currentUser = User.fromDocument(uid, freshUserDoc.data()!);
      } else {
        // Fallback if Firestore doc doesn't exist yet
        final roleStr = await _authService.getUserRole(uid);
        final role = switch (roleStr) {
          'admin' => UserRole.admin,
          'seller' => UserRole.seller,
          _ => UserRole.buyer,
        };

        _currentUser = User(
          id: uid,
          email: fbUser?.email ?? '',
          name: fbUser?.displayName ?? (fbUser?.email?.split('@').first.toUpperCase() ?? 'USER'),
          photoUrl: fbUser?.photoURL,
          role: role,
          provider: 'google',
          emailVerified: fbUser?.emailVerified ?? true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
      await NotificationService().saveFcmToken(uid);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    if (_currentUser != null) {
      try {
        await NotificationService().deleteFcmToken(_currentUser!.id);
      } catch (e) {
        debugPrint('Error deleting FCM Token on logout: $e');
      }
    }
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}