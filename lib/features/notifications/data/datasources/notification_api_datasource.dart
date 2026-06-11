import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

/// Backend (Laravel Sanctum) bildirim API datasource'u.
/// Endpoint'ler: `/v1/notifications/*` — `app/Modules/Notification`.
abstract class INotificationApiDatasource {
  /// GET /v1/notifications — kimliği doğrulanmış kullanıcının bildirimleri.
  /// Backend `LengthAwarePaginator` döner (`{data: [...], meta: {...}}`).
  Future<List<NotificationModel>> getNotifications();

  /// GET /v1/notifications/unread-count
  Future<int> getUnreadCount();

  /// POST /v1/notifications/mark-read — body: { ids?: int[] }
  /// `ids` boş/yok ise tüm bildirimler okundu işaretlenir.
  Future<void> markRead(List<String> ids);

  /// POST /v1/notifications/{id}/mark-read
  Future<void> markSingleRead(String id);

  /// DELETE /v1/notifications/{id}
  Future<void> deleteNotification(String id);
}

class NotificationApiDatasource implements INotificationApiDatasource {
  final Dio _dio;

  NotificationApiDatasource(this._dio);

  @override
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get(ApiEndpoints.notifications);
      final rawData = response.data;
      final List<dynamic> data;

      if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] as List;
      } else if (rawData is List) {
        data = rawData;
      } else {
        return [];
      }

      return data
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(ApiEndpoints.notificationsUnreadCount);
      final rawData = response.data;
      if (rawData is Map) {
        return (rawData['unread_count'] as num?)?.toInt() ??
            (rawData['count'] as num?)?.toInt() ??
            (rawData['data'] as num?)?.toInt() ??
            0;
      }
      return 0;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> markRead(List<String> ids) async {
    try {
      await _dio.post(
        ApiEndpoints.notificationsMarkRead,
        data: ids.isEmpty
            ? <String, dynamic>{}
            : {'ids': ids.map((id) => int.tryParse(id) ?? id).toList()},
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> markSingleRead(String id) async {
    try {
      await _dio.post('${ApiEndpoints.notificationById(id)}/mark-read');
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await _dio.delete(ApiEndpoints.notificationById(id));
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
