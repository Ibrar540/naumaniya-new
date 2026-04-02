import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Runs [action] only when the current user is admin.
/// If the user is not admin, shows a read-only SnackBar message.
Future<bool> runIfAdmin(BuildContext context, Future<void> Function() action) async {
  try {
    final auth = AuthService();
    await auth.initialize();
    if (auth.isAdmin) {
      await action();
      return true;
    }
  } catch (_) {}

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('You have read only access')),
  );
  return false;
}
