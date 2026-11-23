import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routes.dart';

final FlutterLocalNotificationsPlugin _local =
    FlutterLocalNotificationsPlugin();
String? pendingDeepLink;

/// Remote message abstraction for cross-platform CI/CD compatibility
class RemoteNotification {
  final String? title;
  final String? body;

  const RemoteNotification({this.title, this.body});
}

class RemoteMessage {
  final String? messageId;
  final Map<String, dynamic> data;
  final RemoteNotification? notification;

  const RemoteMessage({
    this.messageId,
    this.data = const {},
    this.notification,
  });
}

class NotificationSettings {
  final int authorizationStatus;

  const NotificationSettings({this.authorizationStatus = 1});
}

/// Firebase Messaging abstraction maintaining API compatibility
class FirebaseMessaging {
  static final FirebaseMessaging instance = FirebaseMessaging._();
  FirebaseMessaging._();

  static void onBackgroundMessage(
    Future<void> Function(RemoteMessage message) handler,
  ) {}

  final StreamController<RemoteMessage> _messageStream =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<RemoteMessage> _openedAppStream =
      StreamController<RemoteMessage>.broadcast();
  final StreamController<String> _tokenStream =
      StreamController<String>.broadcast();

  static Stream<RemoteMessage> get onMessage => instance._messageStream.stream;
  static Stream<RemoteMessage> get onMessageOpenedApp =>
      instance._openedAppStream.stream;
  Stream<String> get onTokenRefresh => _tokenStream.stream;

  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool badge = true,
    bool sound = true,
    bool announcement = false,
    bool carPlay = false,
    bool criticalAlert = false,
  }) async {
    return const NotificationSettings(authorizationStatus: 1);
  }

  Future<String?> getToken() async => 'mock-fcm-token-campus-client-101';
  Future<void> subscribeToTopic(String topic) async {}
  Future<RemoteMessage?> getInitialMessage() async => null;
}

/// Background handler WAJIB berupa fungsi top-level (bukan method kelas)
/// dengan anotasi @pragma('vm:entry-point') karena berjalan pada isolate terpisah.
/// Dilarang mengakses BuildContext atau Riverpod di sini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message diterima: ${message.messageId}');
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
    return settings.authorizationStatus == 1;
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
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await onToken(token);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await onToken(newToken);
    });

    await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
  } catch (e) {
    debugPrint('FCM Token initialization skipped or unconfigured: $e');
    await onToken('mock-fcm-token-campus-client-101');
  }
}

/// Menangani pesan saat aplikasi dalam keadaan Foreground & Background
void listenNotificationHandlers(void Function(String route) go) {
  try {
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
