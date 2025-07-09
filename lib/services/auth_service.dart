import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Account creation with all checks
  Future<String?> createAccount({
    required String fullName,
    required String email,
    required String institutionName,
    required String password,
  }) async {
    // 1. Check if email exists in Firebase Auth
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    if (methods.isNotEmpty) {
      return "This email is already registered. Please use a different email.";
    }

    // 2. Create user in Firebase Auth
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCred.user!.uid;

      // 3. Save fields in Firestore (now authenticated)
      await _firestore.collection('users').doc(uid).set({
        'fullName': fullName,
        'email': email,
        'institutionName': institutionName,
        // 'password': password, // Removed for security
      });

      // 4. Save fields in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fullName', fullName);
      await prefs.setString('email', email);
      await prefs.setString('institutionName', institutionName);
      // await prefs.setString('password', password); // Removed for security

      return null; // Success
    } catch (e) {
      return "Error creating account: $e";
    }
  }

  // Login logic
  Future<String?> login({String? email, required String password}) async {
    final prefs = await SharedPreferences.getInstance();
    email ??= prefs.getString('email');
    if (email == null) {
      return "No email stored. Please log in with email and password.";
    }
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // await prefs.setString('password', password); // Removed for security
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Authentication failed.";
    } catch (e) {
      return "Authentication failed: $e";
    }
  }

  // Load user info from SharedPreferences
  Future<Map<String, String?>> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'fullName': prefs.getString('fullName'),
      'email': prefs.getString('email'),
      'institutionName': prefs.getString('institutionName'),
      // 'password': prefs.getString('password'), // Removed for security
    };
  }
} 