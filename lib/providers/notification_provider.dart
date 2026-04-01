import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class NotificationProvider extends ChangeNotifier {
  final AuthService _auth;
  Timer? _pollTimer;

  // Start at -1 so first poll sets the baseline without triggering fake "new" notifications
  int _pendingRequestCount = -1;
  List<Map<String, dynamic>> _inAppNotifications = [];

  int get pendingRequestCount => _pendingRequestCount < 0 ? 0 : _pendingRequestCount;
  List<Map<String, dynamic>> get inAppNotifications => _inAppNotifications;
  bool get hasUnread => _pendingRequestCount > 0;

  NotificationProvider(this._auth);

  /// Call this after the user has logged in and auth is initialized
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _poll());
    _poll();
  }

  Future<void> _poll() async {
    if (!_auth.isAuthenticated) return;
    try {
      if (_auth.isAdmin) {
        final reqs = await _auth.getPendingRequests();
        final newCount = reqs.length;

        // First poll: just set baseline, don't notify
        if (_pendingRequestCount == -1) {
          _pendingRequestCount = newCount;
        } else if (newCount > _pendingRequestCount) {
          // Genuinely new requests arrived
          _pendingRequestCount = newCount;
        } else {
          _pendingRequestCount = newCount;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh() => _poll();

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
