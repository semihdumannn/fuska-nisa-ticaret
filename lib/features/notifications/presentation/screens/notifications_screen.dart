import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../data/models/notification_model.dart';
import '../bloc/notification_provider.dart';

// Unread card background — AppColors.pinkLight
const Color _kUnreadBg = Color(0xFFFCE3F1);

// ---------------------------------------------------------------------------
// Filter enum
// ---------------------------------------------------------------------------
enum _NotificationFilter {
  all,
  unread,
  orders,
  promos;

  String get label {
    switch (this) {
      case _NotificationFilter.all:
        return 'Tümü';
      case _NotificationFilter.unread:
        return 'Okunmamış';
      case _NotificationFilter.orders:
        return 'Siparişler';
      case _NotificationFilter.promos:
        return 'Kampanyalar';
    }
  }
}

// ---------------------------------------------------------------------------
// NotificationsScreen
// ---------------------------------------------------------------------------
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotificationFilter _activeFilter = _NotificationFilter.all;

  List<NotificationModel> _applyFilter(List<NotificationModel> all) {
    switch (_activeFilter) {
      case _NotificationFilter.all:
        return all;
      case _NotificationFilter.unread:
        return all.where((n) => !n.isRead).toList();
      case _NotificationFilter.orders:
        return all
            .where((n) => n.type == NotificationType.orderUpdate)
            .toList();
      case _NotificationFilter.promos:
        return all.where((n) => n.type == NotificationType.promotion).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Kullanici bilgisi alinamadi')),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Bildirimler')),
            body: _buildLoginRequired(),
          );
        }
        return _buildAuthenticated(user.uid);
      },
    );
  }

  Widget _buildAuthenticated(String userId) {
    final notificationsAsync = ref.watch(notificationsProvider(userId));
    final unreadCount = ref.watch(unreadCountProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: const Text('Bildirimler'),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => _markAllAsRead(userId),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Tümünü Oku'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterChips(
            activeFilter: _activeFilter,
            onFilterChanged: (filter) =>
                setState(() => _activeFilter = filter),
          ),
          Expanded(
            child: notificationsAsync.when(
              loading: () => _buildShimmer(),
              error: (error, _) => _buildErrorState(error),
              data: (all) {
                final filtered = _applyFilter(all);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return _buildNotificationList(filtered, userId);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllAsRead(String userId) async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead(userId);
    ref.invalidate(notificationsProvider(userId));
  }

  Widget _buildNotificationList(
      List<NotificationModel> notifications, String userId) {
    final grouped = _groupNotifications(notifications);
    final sections = grouped.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: sections.fold<int>(
          0, (sum, e) => sum + 1 + e.value.length),
      itemBuilder: (context, index) {
        // Flatten sections with headers
        int cursor = 0;
        for (final section in sections) {
          if (index == cursor) {
            return _SectionHeader(label: section.key);
          }
          cursor++;
          final itemIndex = index - cursor;
          if (itemIndex < section.value.length) {
            final notification = section.value[itemIndex];
            return _NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification, userId),
            );
          }
          cursor += section.value.length;
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Bildirimleri: Bugün / Bu Hafta / Daha Önce olarak grupla
  Map<String, List<NotificationModel>> _groupNotifications(
      List<NotificationModel> notifications) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(const Duration(days: 6));

    final Map<String, List<NotificationModel>> groups = {
      'Bugun': [],
      'Bu Hafta': [],
      'Daha Önce': [],
    };

    for (final n in notifications) {
      if (n.createdAt.isAfter(todayStart)) {
        groups['Bugun']!.add(n);
      } else if (n.createdAt.isAfter(weekStart)) {
        groups['Bu Hafta']!.add(n);
      } else {
        groups['Daha Önce']!.add(n);
      }
    }

    // Bos gruplari kaldir
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  void _handleNotificationTap(
      NotificationModel notification, String userId) {
    // Okundu olarak isaretle
    final repo = ref.read(notificationRepositoryProvider);
    if (!notification.isRead) {
      repo.markAsRead(userId, notification.id).then((_) {
        ref.invalidate(notificationsProvider(userId));
      });
    }

    // Route varsa navigate et
    final route = notification.route;
    if (route != null && route.isNotEmpty && mounted) {
      context.push(route);
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Bildirimler yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_activeFilter) {
      case _NotificationFilter.all:
        message = 'Henuz bildiriminiz yok';
        icon = Icons.notifications_none_outlined;
        break;
      case _NotificationFilter.unread:
        message = 'Tum bildirimleri okudunuz';
        icon = Icons.done_all;
        break;
      case _NotificationFilter.orders:
        message = 'Siparis bildiriminiz yok';
        icon = Icons.local_shipping_outlined;
        break;
      case _NotificationFilter.promos:
        message = 'Kampanya bildiriminiz yok';
        icon = Icons.local_offer_outlined;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text(
              'Bildirimleri gorebilmek icin giris yapmaniz gerekiyor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _FilterChips — horizontal scroll, aktif chip primary pembe
// ---------------------------------------------------------------------------
class _FilterChips extends StatelessWidget {
  final _NotificationFilter activeFilter;
  final ValueChanged<_NotificationFilter> onFilterChanged;

  const _FilterChips({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _NotificationFilter.values.map((filter) {
          final isActive = filter == activeFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isActive,
              onSelected: (_) => onFilterChanged(filter),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textPrimary,
              ),
              side: BorderSide(
                color: isActive ? AppColors.primary : AppColors.border,
              ),
              showCheckmark: false,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionHeader — Bugun / Bu Hafta / Daha Önce
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NotificationCard
// ---------------------------------------------------------------------------
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final typeColor = _typeColor(notification.type);
    final typeIcon = _typeIcon(notification.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? _kUnreadBg : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isUnread
                    ? AppColors.pinkLight
                    : AppColors.navBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                typeIcon,
                size: 20,
                color: isUnread ? AppColors.primary : typeColor,
              ),
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + timestamp row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            // Okunmamış: secondary (lacivert) — açık pembe arka planda WCAG AA kontrast sağlar
                            color: isUnread
                                ? AppColors.secondary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.navBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatTime(notification.createdAt),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Body
                  Text(
                    notification.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Unread dot
            if (isUnread) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _typeColor(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return AppColors.secondary;
      case NotificationType.promotion:
        return AppColors.accent;
      case NotificationType.system:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.orderUpdate:
        return Icons.local_shipping_outlined;
      case NotificationType.promotion:
        return Icons.local_offer_outlined;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Az once';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
    if (diff.inHours < 24) return '${diff.inHours} sa';
    if (diff.inDays < 7) return '${diff.inDays} gun once';
    return DateFormat('dd MMM', 'tr').format(dt);
  }
}
