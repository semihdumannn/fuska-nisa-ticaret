import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nisa_ticaret/core/network/api_endpoints.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint(
      '[FCM Background] title: ${message.notification?.title} | '
      'type: ${message.data['type']}',
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Dio? _dio;
  RemoteMessage? _pendingMessage;

  // Bildirime tıklanınca route yayınlar (foreground tap + background→foreground)
  final _tapRouteController = StreamController<String>.broadcast();
  Stream<String> get onTap => _tapRouteController.stream;

  void setDio(Dio dio) => _dio = dio;

  RemoteMessage? consumePendingMessage() {
    final msg = _pendingMessage;
    _pendingMessage = null;
    return msg;
  }

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      if (kDebugMode) debugPrint('[FCM] Bildirim izni reddedildi.');
      return;
    }

    if (kDebugMode) debugPrint('[FCM] Bildirim izni: ${settings.authorizationStatus.name}');

    await _initLocalNotifications();

    // Startup'ta token al ama backend'e henüz Dio yok — login'de kaydedilecek
    final token = await _getToken();
    if (kDebugMode) debugPrint('[FCM] Token (FULL): $token');

    // Token yenilenince backend'e kaydet
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) debugPrint('[FCM] Token yenilendi.');
      _registerTokenWithBackend(newToken);
    });

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (kDebugMode) debugPrint('[FCM] onMessageOpenedApp: ${message.data}');
      _pendingMessage = message;
      // Uygulama arka plandayken bildirime tıklanınca route yayınla
      final route = routeFromMessage(message);
      if (route != null) _tapRouteController.add(route);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) debugPrint('[FCM] getInitialMessage: ${initialMessage.data}');
      _pendingMessage = initialMessage;
    }

    if (kDebugMode) debugPrint('[FCM] NotificationService initialized.');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: (response) {
        final route = response.payload;
        if (kDebugMode) debugPrint('[LocalNotif] tıklandı: $route');
        if (route != null) _tapRouteController.add(route);
      },
    );

    const androidChannel = AndroidNotificationChannel(
      'nisa_ticaret_channel',
      'Nisa Ticaret Bildirimleri',
      description: 'Sipariş ve kampanya bildirimleri',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<String?> _getToken() async {
    for (int i = 0; i < 3; i++) {
      try {
        final token = await _messaging.getToken();
        if (token != null) return token;
        if (kDebugMode) debugPrint('[FCM] getToken() null döndü (deneme ${i + 1}/3)');
      } catch (e) {
        if (kDebugMode) debugPrint('[FCM] getToken() HATA (deneme ${i + 1}/3): $e');
        if (i < 2) await Future.delayed(Duration(seconds: 2 + i * 2));
      }
    }
    if (kDebugMode) debugPrint('[FCM] Token alınamadı (3 deneme).');
    return null;
  }

  Future<void> _registerTokenWithBackend(String token) async {
    if (_dio == null) {
      if (kDebugMode) debugPrint('[FCM] ❌ Dio null — token gönderilemedi. onUserSignedIn çağrıldı mı?');
      return;
    }
    if (kDebugMode) debugPrint('[FCM] → POST /v1/devices gönderiliyor...');
    try {
      final response = await _dio!.post(
        ApiEndpoints.devices,
        data: {
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
      if (kDebugMode) debugPrint('[FCM] ✅ Token kaydedildi. Status: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] ❌ Token kayıt HATASI: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint(
        '[FCM Foreground] title: ${message.notification?.title} | '
        'type: ${message.data['type']}',
      );
    }

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'nisa_ticaret_channel',
          'Nisa Ticaret Bildirimleri',
          channelDescription: 'Sipariş ve kampanya bildirimleri',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'] as String?,
    );
  }

  String? routeFromMessage(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('route')) return data['route'] as String?;
    final type = data['type'] as String?;
    final orderId = data['orderId'] as String?;
    switch (type) {
      case 'order_status':
      case 'new_order':
        return orderId != null ? '/orders/$orderId' : '/orders';
      case 'promo':
        return '/';
      default:
        return null;
    }
  }

  /// Login sonrası çağrılır — Dio set edilir, token backend'e kaydedilir.
  Future<void> onUserSignedIn({Dio? dio}) async {
    if (dio != null) _dio = dio;
    if (kDebugMode) debugPrint('[FCM] onUserSignedIn çağrıldı. Dio: ${_dio != null ? "✅" : "❌ null"}');
    final token = await _getToken();
    if (kDebugMode) debugPrint('[FCM] Token: ${token != null ? "${token.substring(0, 20)}..." : "❌ null"}');
    if (token != null) await _registerTokenWithBackend(token);
  }

  /// Logout sonrası çağrılır — token backend'den silinir.
  Future<void> onUserSignedOut() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && _dio != null) {
        await _dio!.delete(ApiEndpoints.devices, data: {'token': token});
        if (kDebugMode) debugPrint('[FCM] Token backend\'den silindi.');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[FCM] Backend token silme hatası: $e');
    }
    _dio = null;
  }
}

final notificationService = NotificationService();
