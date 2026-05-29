import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../datasources/notification_api_datasource.dart';

final notificationApiDatasourceProvider =
    Provider<INotificationApiDatasource>((ref) {
  return NotificationApiDatasource(ref.watch(apiClientProvider).dio);
});

/// API bildirim listesi (kimlik doğrulama gerektirir)
final apiNotificationsProvider =
    FutureProvider<List<ApiNotificationModel>>((ref) async {
  final datasource = ref.watch(notificationApiDatasourceProvider);
  return datasource.getNotifications();
});

/// Okunmamış bildirim sayısı
final notificationUnreadCountProvider =
    FutureProvider<int>((ref) async {
  final datasource = ref.watch(notificationApiDatasourceProvider);
  return datasource.getUnreadCount();
});
