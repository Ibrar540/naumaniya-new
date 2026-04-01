import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class NotificationProvider extends ChangeNotifier {
  final AuthService _auth;
  Timer? _pollTimer;

  int _pendingRequestCount = 0;
  List<Map<String, dynamic>> _inAppNotifications = [];

  int get pendingRequestCount => _pendingRequestCount;
  List<Map<String, dynamic>> get inAppNotifications => _inAppNotifications;
  bool get hasUnread => _inAppNotifications.any((n) => n['read'] != true);

  NotificationProvider(this._auth) {
    _startPolling();
  }

  void _startPolling() {
    // Poll every 30 seconds when app is open
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
    _poll(); // immediate first check
  }

  Future<void> _poll() async {
    if (!_auth.isAuthenticated) return;
    try {
      if (_auth.isAdmin) {
        final reqs = await _auth.getPendingRequests();
        final newCount = reqs.length;
        if (newCount > _pendingRequestCount && _pendingRequestCount != -1) {
          // New requests arrived since last poll
          final diff = newCount - _pendingRequestCount;
          for (int i = 0; i < diff && i < reqs.length; i++) {
            _addNotification(
              title: 'New Admin Request',
              body: '${reqs[i]['user_name']} requested admin access',
              type: 'admin_request',
            );
          }
        }
        _pendingRequestCount = newCount;
      }

      // Fetch in-app notifications from backend
      final notifications = await _auth.getNotifications();
      _inAppNotifications = notifications;
      notifyListeners();
    } catch (_) {}
  }

  void _addNotification(
      {required String title, required String body, required String type}) {
    _inAppNotifications.insert(0, {
      'title': title,
      'body': body,
      'type': type,
      'read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  Future<void> refresh() => _poll();

  void markAllRead() {
    for (final n in _inAppNotifications) {
      n['read'] = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
