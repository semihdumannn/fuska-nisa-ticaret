import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';

// ─── Background handler (top-level function zorunlu) ─────────────────────────
// FCM kütüphanesi bu fonksiyonu ayrı bir Isolate'te çağırır.
// @pragma annotasyonu: tree-shaking sırasında silinmemesi için zorunlu.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background Isolate'te Firebase zaten initialize edilmiş olmalı
  // (main.dart'ta Firebase.initializeApp çağrılmış).
  debugPrint(
    '[FCM Background] title: ${message.notification?.title} | '
    'type: ${message.data['type']}',
  );
  // Background bildirimleri sistem tepsisinde otomatik gösterilir.
  // Ek işlem gerekirse burada yapılır (örn. local DB güncelleme).
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationService — FCM token yönetimi + foreground/background handler
// ─────────────────────────────────────────────────────────────────────────────

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Flutter Local Notifications — foreground'da bildirim göstermek için
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Foreground'da alınan son mesaj — navigasyon için (örn. splash sonrası)
  RemoteMessage? _pendingMessage;

  /// Uygulama açılırken bekleyen mesajı döner ve temizler.
  RemoteMessage? consumePendingMessage() {
    final msg = _pendingMessage;
    _pendingMessage = null;
    return msg;
  }

  // ─── initialize ────────────────────────────────────────────────────────────

  /// main.dart'ta Firebase.initializeApp'tan sonra çağrılmalı.
  ///
  /// Sıralama:
  /// 1. Background handler kaydet (uygulama kapalıyken çalışır)
  /// 2. Sistem izni iste (iOS + Android 13+)
  /// 3. Local notifications kanalı oluştur
  /// 4. FCM token al ve Firestore'a kaydet
  /// 5. Token refresh listener başlat
  /// 6. Foreground mesaj handler başlat
  /// 7. Uygulama kapalıyken tıklanan bildirimi handle et
  Future<void> initialize() async {
    // 1. Background handler — top-level fonksiyon olmalı
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. İzin iste
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false, // iOS: geçici izin değil, kalıcı sor
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Bildirim izni reddedildi.');
      return;
    }

    debugPrint(
      '[FCM] Bildirim izni: ${settings.authorizationStatus.name}',
    );

    // 3. Android bildirim kanalı
    await _initLocalNotifications();

    // 4. FCM token al ve kaydet
    await _fetchAndSaveToken();

    // 5. Token yenilenince güncelle
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token yenilendi.');
      _saveTokenToFirestore(newToken);
    });

    // 6. Foreground mesaj handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 7. Arkaplan'dan tıklanıp açılan bildirim
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] onMessageOpenedApp: ${message.data}');
      _pendingMessage = message;
    });

    // 8. Uygulama tamamen kapalıyken tıklanan bildirim
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] getInitialMessage: ${initialMessage.data}');
      _pendingMessage = initialMessage;
    }

    debugPrint('[FCM] NotificationService initialized.');
  }

  // ─── Local Notifications setup ─────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // Zaten FCM ile istendi
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        // Kullanıcı local notification'a tıkladı — payload route içerir
        debugPrint('[LocalNotif] tıklandı: ${response.payload}');
      },
    );

    // Android 8+ için bildirim kanalı
    const androidChannel = AndroidNotificationChannel(
      'nisa_ticaret_channel',     // id
      'Nisa Ticaret Bildirimleri', // name
      description: 'Sipariş ve kampanya bildirimleri',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // ─── Token yönetimi ────────────────────────────────────────────────────────

  /// FCM token'ı alır, SharedPreferences ve Firestore'a kaydeder.
  Future<void> _fetchAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('[FCM] Token alınamadı.');
        return;
      }
      debugPrint('[FCM] Token alındı: ${token.substring(0, 20)}...');
      await _saveTokenToFirestore(token);
    } catch (e) {
      // Token kritik değil; uygulama açılmaya devam etmeli
      debugPrint('[FCM] Token fetch hatası: $e');
    }
  }

  /// FCM token'ı `users/{uid}` dokümanına kaydeder.
  ///
  /// Kullanıcı giriş yapmamışsa (misafir) sessizce geçer.
  /// Token değişmemişse Firestore yazısı yine de yapılır — idempotent.
  Future<void> _saveTokenToFirestore(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Misafir kullanıcı — token kaydedilemez
      debugPrint('[FCM] Kullanıcı giriş yapmamış, token kaydedilmiyor.');
      return;
    }

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Token Firestore\'a kaydedildi. uid: $uid');
    } catch (e) {
      // Token kaydı kritik değil; sessizce logla
      debugPrint('[FCM] Token Firestore kayıt hatası: $e');
    }
  }

  // ─── Foreground handler ────────────────────────────────────────────────────

  /// Uygulama açıkken gelen FCM mesajını local notification olarak gösterir.
  ///
  /// iOS'ta FCM foreground'da otomatik bildirim göstermez (varsayılan).
  /// Android 13+ aynı kanalda gösterir ama üstten geçmez.
  /// Bu nedenle flutter_local_notifications ile açıkça gösteriyoruz.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint(
      '[FCM Foreground] title: ${message.notification?.title} | '
      'type: ${message.data['type']}',
    );

    final notification = message.notification;
    if (notification == null) return;

    // Foreground'da local notification göster
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

  // ─── Navigasyon yardımcısı ────────────────────────────────────────────────

  /// FCM data payload'ından go_router route path'ini döner.
  ///
  /// Data payload formatı:
  /// ```json
  /// {
  ///   "type": "order_status" | "new_order" | "promo",
  ///   "orderId": "xxx",
  ///   "route": "/orders/xxx"
  /// }
  /// ```
  ///
  /// Kullanım (splash veya app başlangıcında):
  /// ```dart
  /// final pending = notificationService.consumePendingMessage();
  /// if (pending != null) {
  ///   final route = notificationService.routeFromMessage(pending);
  ///   if (route != null) context.go(route);
  /// }
  /// ```
  String? routeFromMessage(RemoteMessage message) {
    final data = message.data;

    // Payload'da doğrudan route varsa kullan
    if (data.containsKey('route')) {
      return data['route'] as String?;
    }

    // Route yoksa type'a göre varsayılan route üret
    final type = data['type'] as String?;
    final orderId = data['orderId'] as String?;

    switch (type) {
      case 'order_status':
      case 'new_order':
        if (orderId != null) return '/orders/$orderId';
        return '/orders';
      case 'promo':
        return '/'; // Ana sayfa
      default:
        return null;
    }
  }

  // ─── Kullanıcı girişi/çıkışı ──────────────────────────────────────────────

  /// Kullanıcı giriş yaptıktan sonra çağrılır.
  /// Token'ı Firestore'a kaydetmek için tetikler.
  Future<void> onUserSignedIn() async {
    await _fetchAndSaveToken();
  }

  /// Kullanıcı çıkış yaptığında token'ı temizler.
  /// Böylece çıkış yapan kullanıcıya bildirim gönderilmez.
  Future<void> onUserSignedOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'fcmToken': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('[FCM] Token Firestore\'dan silindi. uid: $uid');
    } catch (e) {
      debugPrint('[FCM] Token silme hatası: $e');
    }
  }
}

/// Singleton erişim noktası — main.dart ve auth akışında kullanılır.
final notificationService = NotificationService();
