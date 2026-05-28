import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool get isBuyer => _currentUser?.role == UserRole.buyer;
  bool get isSeller => _currentUser?.role == UserRole.seller;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<void> login(String email, String password) async {
    // Demo login logic
    await Future.delayed(const Duration(seconds: 1));
    
    // Default to buyer for demo, or based on email
    UserRole role = UserRole.buyer;
    if (email.contains('admin')) {
      role = UserRole.admin;
    } else if (email.contains('seller')) {
      role = UserRole.seller;
    }

    _currentUser = User(
      id: 'u1',
      email: email,
      name: email.split('@')[0].toUpperCase(),
      role: role,
    );
    notifyListeners();
  }

  Future<void> register(String name, String email, String password, UserRole role) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = User(
      id: DateTime.now().toString(),
      email: email,
      name: name,
      role: role,
    );
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
