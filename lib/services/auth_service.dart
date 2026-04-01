import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'fcm_service.dart';

class AuthService {
  static const String baseUrl = 'https://naumaniya-new.vercel.app';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String fingerprintKey = 'fingerprint_token';

  String? _token;
  User? _currentUser;

  // Getters
  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Initialize auth service (load saved session)
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(tokenKey);
      
      final userData = prefs.getString(userKey);
      if (userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
      }

      // Verify token is still valid
      if (_token != null) {
        final isValid = await _verifyToken();
        if (!isValid) {
          await logout();
        }
      }
    } catch (e) {
      debugPrint('❌ Auth initialization error: $e');
      await logout();
    }
  }

  /// Signup new user
  Future<AuthResponse> signup(String name, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'password': password,
        }),
      );

      // Try to parse JSON safely. If response is not JSON (e.g. server error
      // returns plain text), handle gracefully and return an error response.
      try {
        final decoded = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(decoded);

        if (authResponse.success && authResponse.token != null) {
          await _saveSession(authResponse.token!, authResponse.user!);
        }

        return authResponse;
      } catch (e) {
        debugPrint('❌ Signup parse error: $e');
        debugPrint('❌ Signup raw response: ${response.body}');
        return AuthResponse(
          success: false,
          error: response.body.isNotEmpty ? response.body : 'Connection error. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('❌ Signup error: $e');
      return AuthResponse(
        success: false,
        error: 'Connection error. Please try again.',
      );
    }
  }

  /// Login with name and password
  Future<AuthResponse> login(String name, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'password': password,
        }),
      );

      try {
        final decoded = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(decoded);

        if (authResponse.success && authResponse.token != null) {
          await _saveSession(authResponse.token!, authResponse.user!);
          // Register FCM token so this device receives push notifications
          FCMService().registerTokenWithBackend(authResponse.token!);
        }

        return authResponse;
      } catch (e) {
        debugPrint('❌ Login parse error: $e');
        debugPrint('❌ Login raw response: ${response.body}');
        return AuthResponse(
          success: false,
          error: response.body.isNotEmpty ? response.body : 'Connection error. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return AuthResponse(
        success: false,
        error: 'Connection error. Please try again.',
      );
    }
  }

  /// Enable fingerprint authentication
  Future<String?> enableFingerprint() async {
    try {
      if (_token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/enable-fingerprint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final fingerprintToken = data['fingerprintToken'];
        
        // Save fingerprint token locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(fingerprintKey, fingerprintToken);
        
        return fingerprintToken;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Enable fingerprint error: $e');
      return null;
    }
  }

  /// Login with fingerprint
  Future<AuthResponse> fingerprintLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fingerprintToken = prefs.getString(fingerprintKey);
      final userId = _currentUser?.id;

      if (fingerprintToken == null || userId == null) {
        return AuthResponse(
          success: false,
          error: 'Fingerprint not configured',
        );
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/fingerprint-login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'fingerprintToken': fingerprintToken,
        }),
      );

      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));

      if (authResponse.success && authResponse.token != null) {
        await _saveSession(authResponse.token!, authResponse.user!);
      }

      return authResponse;
    } catch (e) {
      debugPrint('❌ Fingerprint login error: $e');
      return AuthResponse(
        success: false,
        error: 'Connection error. Please try again.',
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    } finally {
      await _clearSession();
    }
  }

  /// Request admin access
  Future<bool> requestAdminAccess(String reason) async {
    try {
      if (_token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-admin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'reason': reason}),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('❌ Request admin error: $e');
      return false;
    }
  }

  /// Create access request (full | readonly) optionally scoped to modules
  Future<bool> createAccessRequest(String type, List<String>? modules, String? reason) async {
    try {
      if (_token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-access'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'type': type,
          'modules': modules,
          'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('❌ Create access request error: $e');
      return false;
    }
  }

  /// Get current user's access requests
  Future<List<Map<String, dynamic>>> getUserAccessRequests() async {
    try {
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/auth/requests'),
        headers: getAuthHeaders(),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['requests']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get user access requests error: $e');
      return [];
    }
  }

  /// Admin: get pending access requests
  Future<List<Map<String, dynamic>>> getAccessRequests() async {
    try {
      if (_token == null || !isAdmin) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/auth/admin/access-requests'),
        headers: getAuthHeaders(),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) return List<Map<String, dynamic>>.from(data['requests']);
      return [];
    } catch (e) {
      debugPrint('❌ Get access requests error: $e');
      return [];
    }
  }

  /// Admin: review access request
  Future<bool> reviewAccessRequest(int requestId, bool approve, {List<String>? grantModules}) async {
    try {
      if (_token == null || !isAdmin) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/review-access-request'),
        headers: getAuthHeaders(),
        body: jsonEncode({ 'requestId': requestId, 'approve': approve, 'grantModules': grantModules }),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('❌ Review access request error: $e');
      return false;
    }
  }

  /// Get notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      if (_token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/auth/notifications'),
        headers: getAuthHeaders(),
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['notifications'] != null) {
        return List<Map<String, dynamic>>.from(data['notifications']);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Get notifications error: $e');
      return [];
    }
  }

  /// Mark a notification as read
  Future<bool> markNotificationRead(int id) async {
    try {
      if (_token == null) return false;
      final response = await http.put(
        Uri.parse('$baseUrl/auth/notifications/$id/read'),
        headers: getAuthHeaders(),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('❌ Mark notification read error: $e');
      return false;
    }
  }

  /// Get pending admin requests (admin only)
  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    try {
      if (_token == null || !isAdmin) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/auth/admin/requests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['requests']);
      }

      return [];
    } catch (e) {
      debugPrint('❌ Get pending requests error: $e');
      return [];
    }
  }

  /// Update current user's profile (name/password)
  Future<bool> updateProfile(String name, String? password) async {
    try {
      if (_token == null) return false;

      final body = {'name': name};
      if (password != null && password.isNotEmpty) body['password'] = password;

      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('❌ Update profile error: $e');
      return false;
    }
  }

  /// Get admin audit history (last 30 days)
  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      if (_token == null || !isAdmin) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/auth/admin/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true && data['history'] != null) {
        return List<Map<String, dynamic>>.from(data['history']);
      }

      return [];
    } catch (e) {
      debugPrint('❌ Get history error: $e');
      return [];
    }
  }

  /// Review admin request (admin only)
  Future<bool> reviewAdminRequest(int requestId, bool approve) async {
    try {
      if (_token == null || !isAdmin) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/admin/review-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'requestId': requestId,
          'approve': approve,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('❌ Review request error: $e');
      return false;
    }
  }

  /// Get all users (admin only)
  Future<List<User>> getAllUsers() async {
    try {
      if (_token == null || !isAdmin) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/auth/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return (data['users'] as List)
            .map((u) => User.fromJson(u))
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Get all users error: $e');
      return [];
    }
  }

  /// Update user status (admin only)
  Future<bool> updateUserStatus(int userId, bool isActive) async {
    try {
      if (_token == null || !isAdmin) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/auth/admin/user-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'userId': userId,
          'isActive': isActive,
        }),
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('❌ Update user status error: $e');
      return false;
    }
  }

  /// Delete user (admin only)
  Future<bool> deleteUser(int userId) async {
    try {
      if (_token == null || !isAdmin) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/auth/admin/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      debugPrint('❌ Delete user error: $e');
      return false;
    }
  }

  /// Private: Save session
  Future<void> _saveSession(String token, User user) async {
    _token = token;
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, jsonEncode(user.toJson()));
  }

  /// Private: Clear session
  Future<void> _clearSession() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  /// Private: Verify token
  Future<bool> _verifyToken() async {
    try {
      if (_token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get authorization header
  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }
}
