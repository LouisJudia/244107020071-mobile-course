import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();
String? pendingDeepLink;

Future<bool> requestNotificationPermission() async {
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  } catch (e) {
    debugPrint('Error requesting notification permission: $e');
    return false;
  }
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  try {
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        // Klik banner foreground -> teruskan payload ke router.
        pendingDeepLink = response.payload;
      },
    );
  } catch (e) {
    debugPrint('Error initializing local notifications: $e');
  }
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  try {
    // 1. Ambil token saat ini dan kirim ke backend.
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await onToken(token);
    }

    // 2. Token bisa berubah (reinstall, clear data, rotasi keamanan).
    // Listener ini WAJIB ada, jika tidak backend menyimpan token basi.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await onToken(newToken);
    });

    // 3. Langganan topik kampus (mis. semua mahasiswa angkatan).
    await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  } catch (e) {
    debugPrint('FCM Token initialization skipped or unconfigured: $e');
  }
}
