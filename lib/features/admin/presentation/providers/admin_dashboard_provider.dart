import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../orders/data/models/order_model.dart';
import '../../data/models/dashboard_stats_model.dart';

// Secili tarih araligi state'i
class DateRangeState {
  final DateTime start;
  final DateTime end;

  const DateRangeState({required this.start, required this.end});

  factory DateRangeState.lastSevenDays() {
    final now = DateTime.now();
    return DateRangeState(
      start: now.subtract(const Duration(days: 6)),
      end: now,
    );
  }

  DateRangeState copyWith({DateTime? start, DateTime? end}) {
    return DateRangeState(
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }
}

// Tarih araligi notifier
class DateRangeNotifier extends Notifier<DateRangeState> {
  @override
  DateRangeState build() => DateRangeState.lastSevenDays();

  void setRange(DateTime start, DateTime end) {
    state = DateRangeState(start: start, end: end);
  }
}

final selectedDateRangeProvider =
    NotifierProvider<DateRangeNotifier, DateRangeState>(DateRangeNotifier.new);

// Siparis filtre notifier
class OrderStatusFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setFilter(String? status) => state = status;
}

final selectedOrderStatusFilterProvider =
    NotifierProvider<OrderStatusFilterNotifier, String?>(
        OrderStatusFilterNotifier.new);

// Sayfa notifier
class OrdersPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int page) => state = page;
  void reset() => state = 0;
}

final ordersPageProvider =
    NotifierProvider<OrdersPageNotifier, int>(OrdersPageNotifier.new);

/// Son 7 günün siparişlerini Firestore'dan çekip istatistikleri türetir.
/// Seçili tarih aralığı değişince yeniden tetiklenir.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  ref.watch(selectedDateRangeProvider);

  final now = DateTime.now();
  final weekAgo = DateTime(now.year, now.month, now.day)
      .subtract(const Duration(days: 6));

  final snap = await FirebaseFirestore.instance
      .collection(AppConstants.ordersCollection)
      .where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo),
      )
      .orderBy('createdAt', descending: true)
      .get();

  final orders = snap.docs.map(OrderModel.fromFirestore).toList();
  return DashboardStats.fromOrders(orders, now);
});

// Filtrelenmis son siparisler (pagination + status filter)
final filteredRecentOrdersProvider =
    Provider<List<RecentOrderSummary>>((ref) {
  final statsAsync = ref.watch(dashboardStatsProvider);
  final statusFilter = ref.watch(selectedOrderStatusFilterProvider);
  final page = ref.watch(ordersPageProvider);
  const pageSize = 5;

  return statsAsync.when(
    data: (stats) {
      var orders = stats.recentOrders;
      if (statusFilter != null && statusFilter.isNotEmpty) {
        orders = orders
            .where((o) => o.status.value == statusFilter)
            .toList();
      }
      final startIndex = page * pageSize;
      if (startIndex >= orders.length) return [];
      final endIndex = (startIndex + pageSize).clamp(0, orders.length);
      return orders.sublist(startIndex, endIndex);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Toplam sayfa sayisi
final totalOrderPagesProvider = Provider<int>((ref) {
  final statsAsync = ref.watch(dashboardStatsProvider);
  final statusFilter = ref.watch(selectedOrderStatusFilterProvider);
  const pageSize = 5;

  return statsAsync.when(
    data: (stats) {
      var orders = stats.recentOrders;
      if (statusFilter != null && statusFilter.isNotEmpty) {
        orders = orders
            .where((o) => o.status.value == statusFilter)
            .toList();
      }
      return (orders.length / pageSize).ceil().clamp(1, 999);
    },
    loading: () => 1,
    error: (_, __) => 1,
  );
});
