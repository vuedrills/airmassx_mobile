import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../core/service_locator.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  late final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Firebase is already initialized in main.dart
    _fcm = FirebaseMessaging.instance;

    // 2. Request permissions (especially for iOS, but good for Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
    }

    // 3. Setup Local Notifications for Foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initializationSettings);

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@drawable/ic_notification',
            ),
          ),
        );
      }
    });

    // 5. Handle Token Refresh
    _fcm.onTokenRefresh.listen((newToken) {
      _updateTokenOnBackend(newToken);
    });

    // 6. Initial token update
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenOnBackend(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Failed to get initial FCM token: $e');
      }
    }
  }

  Future<void> updateToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenOnBackend(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Failed to get FCM token: $e');
      }
    }
  }

  Future<void> _updateTokenOnBackend(String token) async {
    try {
      final apiService = getIt<ApiService>();
      if (apiService.isAuthenticated) {
        print('NotificationService: Updating FCM token on backend...');
        print('NotificationService: Token (first 20 chars): ${token.substring(0, 20)}...');
        await apiService.updateFCMToken(token);
        if (kDebugMode) {
          print('NotificationService: FCM Token updated on backend successfully');
        }
      } else {
        if (kDebugMode) {
          print('NotificationService: Not authenticated, skipping FCM token update');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error updating FCM token on backend: $e');
      }
    }
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }
}
