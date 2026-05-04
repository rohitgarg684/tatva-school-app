import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final ApiService _api = ApiService();
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSub;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTap);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onMessageTap(initial);
  }

  Future<void> requestPermissionAndRegister() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _registerToken();
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((token) {
        _registerToken(token: token);
      });
    }
  }

  Future<void> _registerToken({String? token}) async {
    try {
      final fcmToken = token ?? await _messaging.getToken();
      if (fcmToken == null) {
        debugPrint('[FCM] getToken() returned null — APNs key may be missing from Firebase Console');
        return;
      }
      debugPrint('[FCM] Registering token: ${fcmToken.substring(0, 12)}…');
      await _api.registerFcmToken(fcmToken);
    } catch (e) {
      debugPrint('[FCM] Token registration failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
  }

  void _onMessageTap(RemoteMessage message) {
    debugPrint('[FCM] Tapped: ${message.data}');
  }
}
