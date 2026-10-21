import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routes.dart';

final FlutterLocalNotificationsPlugin _local =
    FlutterLocalNotificationsPlugin();
String? pendingDeepLink;

/// Background handler WAJIB berupa fungsi top-level (bukan method kelas)
/// dengan anotasi @pragma('vm:entry-point') karena berjalan pada isolate terpisah.
/// Dilarang mengakses BuildContext atau Riverpod di sini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message diterima: ${message.messageId}');
  // Pencatatan atau penyimpanan lokal ringan saja.
  // Navigasi dilakukan oleh listener klik (onMessageOpenedApp / getInitialMessage).
}

void registerBackgroundHandler() {
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('FCM Background message registration skipped: $e');
  }
}

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

Future<void> initLocalNotifications({
  void Function(String route)? onSelectNotification,
}) async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();

  try {
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          pendingDeepLink = payload;
          if (onSelectNotification != null) {
            onSelectNotification(payload);
          }
        }
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

    // 3. Langganan topik kampus (broadcast mahasiswa).
    await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  } catch (e) {
    debugPrint('FCM Token initialization skipped or unconfigured: $e');
    await onToken('mock-fcm-token-campus-client-101');
  }
}

/// Menangani pesan saat aplikasi dalam keadaan Foreground & Background
void listenNotificationHandlers(void Function(String route) go) {
  try {
    // 1. Foreground: sistem TIDAK menampilkan banner otomatis,
    // sehingga harus ditampilkan manual via local notification.
    FirebaseMessaging.onMessage.listen((message) async {
      final targetRoute = routeFromMessage(message.data);
      const androidDetails = AndroidNotificationDetails(
        'pengumuman',
        'Pengumuman Kampus',
        importance: Importance.high,
        priority: Priority.high,
      );

      await _local.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Pengumuman Baru Kampus',
        body: message.notification?.body ?? '',
        notificationDetails: const NotificationDetails(android: androidDetails),
        payload: targetRoute,
      );
    });

    // 2. Background -> diklik dari system tray
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final targetRoute = routeFromMessage(message.data);
      go(targetRoute);
    });
  } catch (e) {
    debugPrint('FCM listeners skipped: $e');
  }
}

/// Menangani notifikasi saat aplikasi dibuka dari keadaan Terminated (mati)
Future<void> handleTerminatedNotification(
  void Function(String route) go,
) async {
  try {
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      final targetRoute = routeFromMessage(initial.data);
      go(targetRoute);
      return;
    }
  } catch (e) {
    debugPrint('FCM getInitialMessage skipped: $e');
  }

  if (pendingDeepLink != null) {
    final route = pendingDeepLink!;
    pendingDeepLink = null;
    go(route);
  }
}

/// Simulasi pengiriman notifikasi lokal untuk pengujian & demo deterministik
Future<void> triggerSimulatedNotification({
  required String title,
  required String body,
  required String route,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'pengumuman',
    'Pengumuman Kampus',
    importance: Importance.high,
    priority: Priority.high,
  );

  await _local.show(
    id: DateTime.now().millisecond,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(android: androidDetails),
    payload: route,
  );
}
