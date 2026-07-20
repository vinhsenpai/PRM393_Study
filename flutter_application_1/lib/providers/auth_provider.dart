import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Key used to store the serialized user in SharedPreferences.
const _kCachedUserKey = 'cached_user';

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

  // ─── Internal helpers ───────────────────────────────────────────────────────

  /// Saves user to local cache so we can restore the session on next launch.
  Future<void> _saveUserToCache(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCachedUserKey, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('AuthProvider: error saving user cache: $e');
    }
  }

  /// Reads the cached user. Returns null if nothing is cached.
  Future<User?> _loadUserFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedUserKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return User.fromJson(map);
    } catch (e) {
      debugPrint('AuthProvider: error reading user cache: $e');
      return null;
    }
  }

  /// Removes the cached user (called on logout).
  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedUserKey);
    } catch (e) {
      debugPrint('AuthProvider: error clearing user cache: $e');
    }
  }

  // ─── Initialization ─────────────────────────────────────────────────────────

  Future<void> _initUser() async {
    try {
      // 1. Try to restore from local cache immediately → no loading flicker
      final cached = await _loadUserFromCache();

      // 2. Check if Firebase Auth still has a valid session
      final fbUser = _authService.getCurrentUser();
      if (fbUser == null) {
        // Firebase session expired → clear cache and stay logged out
        await _clearUserCache();
        return;
      }

      // 3. If we have cached data, restore it immediately so the UI renders
      if (cached != null && cached.id == fbUser.uid) {
        _currentUser = cached;
        notifyListeners();
      }

      // 4. Refresh from Firestore in the background
      final doc = await _authService.firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        _currentUser = User.fromDocument(fbUser.uid, doc.data()!);
        await _saveUserToCache(_currentUser!);
        notifyListeners();
      }

      // 5. Re-register FCM token so notifications keep working
      await NotificationService().saveFcmToken(fbUser.uid);
    } catch (e) {
      debugPrint('AuthProvider: error initializing user: $e');
    }
  }

  // ─── State ──────────────────────────────────────────────────────────────────

  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool get isBuyer => _currentUser?.role == UserRole.buyer;
  bool get isSeller => _currentUser?.role == UserRole.seller;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  // ─── Auth actions ────────────────────────────────────────────────────────────

  Future<void> login(String email, String password) async {
    try {
      final userCredential = await _authService.loginWithEmailPassword(email, password);
      await _authService.createOrUpdateUserInFirestore(userCredential);

      final fbUser = userCredential.user;
      final uid = fbUser?.uid;
      if (uid == null) {
        throw StateError('FirebaseAuth user is null after sign-in.');
      }

      // Get fresh user data from Firestore
      final freshUserDoc = await _authService.firestore.collection('users').doc(uid).get();
      if (freshUserDoc.exists) {
        _currentUser = User.fromDocument(uid, freshUserDoc.data()!);
      } else {
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

      // Persist session locally
      await _saveUserToCache(_currentUser!);
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

      final freshUserDoc = await _authService.firestore.collection('users').doc(uid).get();
      if (freshUserDoc.exists) {
        _currentUser = User.fromDocument(uid, freshUserDoc.data()!);
      } else {
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

      await _saveUserToCache(_currentUser!);
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
        await _saveUserToCache(_currentUser!);
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

      final freshUserDoc = await _authService.firestore.collection('users').doc(uid).get();
      if (freshUserDoc.exists) {
        _currentUser = User.fromDocument(uid, freshUserDoc.data()!);
      } else {
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

      await _saveUserToCache(_currentUser!);
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
        debugPrint('AuthProvider: error deleting FCM Token on logout: $e');
      }
    }
    await _authService.signOut();
    await _clearUserCache();
    _currentUser = null;
    notifyListeners();
  }
}