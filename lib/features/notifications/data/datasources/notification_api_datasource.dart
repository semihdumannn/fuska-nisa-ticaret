import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';

class ApiNotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String createdAt;

  const ApiNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.data,
    required this.createdAt,
  });

  factory ApiNotificationModel.fromJson(Map<String, dynamic> json) {
    return ApiNotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      isRead: json['is_read'] as bool? ?? json['read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String? ??
          DateTime.now().toIso8601String(),
    );
  }
}

abstract class INotificationApiDatasource {
  Future<List<ApiNotificationModel>> getNotifications();
  Future<int> getUnreadCount();
  Future<void> markRead(List<String> ids);
  Future<void> deleteNotification(String id);
}

class NotificationApiDatasource implements INotificationApiDatasource {
  final Dio _dio;

  NotificationApiDatasource(this._dio);

  @override
  Future<List<ApiNotificationModel>> getNotifications() async {
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
          .map((json) =>
              ApiNotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final response =
          await _dio.get(ApiEndpoints.notificationsUnreadCount);
      return (response.data['count'] as num?)?.toInt() ??
          (response.data['data'] as num?)?.toInt() ?? 0;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> markRead(List<String> ids) async {
    try {
      await _dio.post(
        ApiEndpoints.notificationsMarkRead,
        data: {'ids': ids},
      );
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
