import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../datasources/notification_api_datasource.dart';
import '../models/notification_model.dart';

/// Bildirim repository sözleşmesi.
/// Test ortamında mock implementasyon geçilebilir.
abstract class NotificationRepository {
  /// Kullanıcının bildirimlerini getir.
  ///
  /// Not: Backend artık tek kaynak (Sanctum bearer token ile kimlik
  /// doğrulanmış kullanıcı). `userId` parametresi geriye dönük uyumluluk
  /// için tutulur ancak API çağrısında kullanılmaz (`/v1/notifications`
  /// her zaman `request.user()` bildirimlerini döner).
  ///
  /// `Stream` olarak döner ki mevcut `StreamProvider` tabanlı UI değişmeden
  /// çalışsın; tek bir fetch sonucu emit edilir (gerçek zamanlı değil).
  Stream<List<NotificationModel>> watchNotifications(String userId);

  /// Tek bildirimi okundu olarak işaretle.
  Future<void> markAsRead(String userId, String notificationId);

  /// Kullanıcının tüm okunmamış bildirimlerini okundu yap.
  Future<void> markAllAsRead(String userId);
}

/// Backend (Laravel Sanctum) API implementasyonu.
/// Endpoint'ler: `/v1/notifications/*`.
class ApiNotificationRepository implements NotificationRepository {
  final INotificationApiDatasource _datasource;

  ApiNotificationRepository(this._datasource);

  // ──────────────────────────────────────────────────────────────────────────
  // Okuma
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Stream<List<NotificationModel>> watchNotifications(String userId) async* {
    try {
      final notifications = await _datasource.getNotifications();
      yield notifications;
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationRepository.watchNotifications: $e');
      rethrow;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Yazma
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _datasource.markSingleRead(notificationId);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationRepository.markAsRead: $e');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _datasource.markRead(const []);
    } catch (e) {
      if (kDebugMode) debugPrint('NotificationRepository.markAllAsRead: $e');
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final notificationApiDatasourceProvider =
    Provider<INotificationApiDatasource>((ref) {
  return NotificationApiDatasource(ref.watch(apiClientProvider).dio);
});

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return ApiNotificationRepository(ref.watch(notificationApiDatasourceProvider));
});
