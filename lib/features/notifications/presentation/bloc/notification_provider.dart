import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

export '../../data/repositories/notification_repository.dart'
    show notificationRepositoryProvider;

// ─── notificationsProvider ────────────────────────────────────────────────────
// Kullanıcının bildirimlerini backend API'den (Sanctum token) getirir.
// `userId` parametresi backend tarafında kullanılmaz (request.user() esas
// alınır), ancak provider'ı kullanıcı bazlı invalidate edebilmek için tutulur.
// Cache KULLANILMAZ — bildirimler sık değişebilir (CLAUDE.md).
// ─────────────────────────────────────────────────────────────────────────────

final notificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  if (userId.isEmpty) return const Stream.empty();
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotifications(userId);
});

// ─── unreadCountProvider ─────────────────────────────────────────────────────
// Okunmamış bildirim sayısı — bottom nav badge için.
// notificationsProvider'dan türetilir, ek API çağrısı yapmaz.
// ─────────────────────────────────────────────────────────────────────────────

final unreadCountProvider = Provider.family<int, String>((ref, userId) {
  final notificationsAsync = ref.watch(notificationsProvider(userId));
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
