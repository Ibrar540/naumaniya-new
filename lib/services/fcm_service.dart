import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No need to init Firebase here — it's already initialized
  debugPrint('📩 Background FCM: ${message.notification?.title}');
}

class FCMService {
  static const String baseUrl = 'https://naumaniya-new.vercel.app';
  static const String _fcmTokenKey = 'fcm_device_token';

  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Call once from main.dart after Firebase.initializeApp()
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request permission (Android 13+ and iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Setup local notifications (for foreground display)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // Create high-importance Android channel
    const channel = AndroidNotificationChannel(
      'admin_requests',
      'Admin Requests',
      description: 'Notifications for admin access requests',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Show notification when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'admin_requests',
              'Admin Requests',
              channelDescription: 'Notifications for admin access requests',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        );
      }
    });

    // Get and save FCM token
    await _refreshAndSaveToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      await _saveTokenLocally(newToken);
      await _registerTokenWithBackend(newToken);
    });
  }

  Future<void> _refreshAndSaveToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenLocally(token);
      debugPrint('📱 FCM Token: $token');
    }
  }

  Future<void> _saveTokenLocally(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey) ?? await _messaging.getToken();
  }

  /// Call after login to register this device's token with the backend
  Future<void> registerTokenWithBackend(String authToken) async {
    final fcmToken = await getToken();
    if (fcmToken == null) return;
    await _registerTokenWithBackend(fcmToken, authToken: authToken);
  }

  Future<void> _registerTokenWithBackend(String fcmToken,
      {String? authToken}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedAuth = authToken ?? prefs.getString('auth_token');
      if (storedAuth == null) return;

      await http.post(
        Uri.parse('$baseUrl/auth/register-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $storedAuth',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      debugPrint('✅ FCM token registered with backend');
    } catch (e) {
      debugPrint('❌ FCM token registration failed: $e');
    }
  }

  /// Call on logout to unregister this device
  Future<void> unregisterToken(String authToken) async {
    try {
      final fcmToken = await getToken();
      if (fcmToken == null) return;

      await http.post(
        Uri.parse('$baseUrl/auth/unregister-fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    } catch (e) {
      debugPrint('❌ FCM token unregister failed: $e');
    }
  }
}
