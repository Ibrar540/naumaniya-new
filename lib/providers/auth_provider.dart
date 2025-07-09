import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  User? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  User? get currentUser => _currentUser;

  Future<void> init() async {
    // No local users to load
  }

  // Registration and login should use AuthService (Firebase Auth) instead

  void logout() {
    _isAuthenticated = false;
    _currentUser = null;
    notifyListeners();
  }
} 