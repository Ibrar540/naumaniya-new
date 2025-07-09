import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class OfflineAuthService {
  static const _storage = FlutterSecureStorage();
  static const _keyUserId = 'offline_user_id';
  static const _keyPasswordHash = 'offline_password_hash';

  /// Save credentials after successful online login
  static Future<void> saveCredentials(String userId, String password) async {
    final hash = _hashPassword(password);
    await _storage.write(key: _keyUserId, value: userId);
    await _storage.write(key: _keyPasswordHash, value: hash);
  }

  /// Attempt offline login
  static Future<bool> tryOfflineLogin(String userId, String password) async {
    final storedUserId = await _storage.read(key: _keyUserId);
    final storedHash = await _storage.read(key: _keyPasswordHash);
    if (storedUserId == null || storedHash == null) return false;
    if (storedUserId != userId) return false;
    final inputHash = _hashPassword(password);
    return storedHash == inputHash;
  }

  /// Hash password using SHA-256 (for demo; use PBKDF2/bcrypt for production)
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Clear cached credentials (e.g., on logout)
  static Future<void> clearCredentials() async {
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyPasswordHash);
  }
} 