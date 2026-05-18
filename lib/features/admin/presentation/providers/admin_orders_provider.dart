import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/admin_order_model.dart';

// ---------------------------------------------------------------------------
// Ana siparisler notifier
// ---------------------------------------------------------------------------
class AdminOrdersNotifier
    extends Notifier<AsyncValue<List<AdminOrderModel>>> {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  AsyncValue<List<AdminOrderModel>> build() {
    final sub = _db
        .collection(AppConstants.ordersCollection)
        .orderBy('createdAt', descending: true)
        .limit(300)
        .snapshots()
        .listen(
          (snap) {
            state = AsyncValue.data(
              snap.docs.map(AdminOrderModel.fromFirestore).toList(),
            );
          },
          onError: (Object e, StackTrace st) => state = AsyncValue.error(e, st),
        );
    ref.onDispose(sub.cancel);
    return const AsyncValue.loading();
  }

  Future<void> updateStatus(String orderId, AdminOrderStatus status) async {
    final fsStatus = switch (status) {
      AdminOrderStatus.confirmed => 'confirmed',
      AdminOrderStatus.preparing => 'preparing',
      AdminOrderStatus.onTheWay => 'on_the_way',
      AdminOrderStatus.delivered => 'delivered',
      AdminOrderStatus.cancelled => 'cancelled',
      AdminOrderStatus.refunded => 'cancelled',
      AdminOrderStatus.pending => 'pending',
    };

    final update = <String, dynamic>{
      'status': fsStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == AdminOrderStatus.confirmed) {
      update['confirmedAt'] = FieldValue.serverTimestamp();
    } else if (status == AdminOrderStatus.onTheWay) {
      update['onTheWayAt'] = FieldValue.serverTimestamp();
    } else if (status == AdminOrderStatus.delivered) {
      update['deliveredAt'] = FieldValue.serverTimestamp();
    }

    await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update(update);
  }

  Future<void> assignDelivery(
      String orderId, String deliveryId, String deliveryName) async {
    await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({
      'assignedTo': deliveryId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> assignAgent(
      String orderId, String agentId, String agentName) async {
    await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({
      'createdBy': agentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addNote(String orderId, String content) async {
    final now = DateTime.now();
    final note = InternalNote(
      id: 'note_${now.millisecondsSinceEpoch}',
      authorName: 'Admin',
      content: content,
      createdAt: now,
    );
    // Admin notları Firestore'a yazılmaz (şema yok) — sadece UI state
    final current = state.value ?? [];
    final updated = current.map((o) {
      if (o.id != orderId) return o;
      return o.copyWith(notes: [...o.notes, note]);
    }).toList();
    state = AsyncValue.data(updated);
  }

  Future<void> bulkConfirm(List<String> orderIds) async {
    final batch = _db.batch();
    for (final id in orderIds) {
      batch.update(
        _db.collection(AppConstants.ordersCollection).doc(id),
        {
          'status': 'confirmed',
          'confirmedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({
      'status': 'cancelled',
      'cancellationReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> initiateRefund(String orderId) async {
    await _db
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({
      'status': 'cancelled',
      'cancellationReason': 'İade talep edildi',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// ---------------------------------------------------------------------------
// Provider tanimlari
// ---------------------------------------------------------------------------
final adminOrdersProvider = NotifierProvider<AdminOrdersNotifier,
    AsyncValue<List<AdminOrderModel>>>(
  AdminOrdersNotifier.new,
);

// Durum filtresi (multi-select) — Riverpod 3.x: NotifierProvider
class _OrderStatusFilterNotifier extends Notifier<Set<AdminOrderStatus>> {
  @override
  Set<AdminOrderStatus> build() => {};
  void set(Set<AdminOrderStatus> v) => state = v;
}

final orderStatusFilterProvider =
    NotifierProvider<_OrderStatusFilterNotifier, Set<AdminOrderStatus>>(
        _OrderStatusFilterNotifier.new);

// Tarih araligi filtresi
class _OrderDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void set(DateTimeRange? v) => state = v;
}

final orderDateRangeProvider =
    NotifierProvider<_OrderDateRangeNotifier, DateTimeRange?>(
        _OrderDateRangeNotifier.new);

// Odeme yontemi filtresi
class _OrderPaymentFilterNotifier extends Notifier<AdminPaymentMethod?> {
  @override
  AdminPaymentMethod? build() => null;
  void set(AdminPaymentMethod? v) => state = v;
}

final orderPaymentFilterProvider =
    NotifierProvider<_OrderPaymentFilterNotifier, AdminPaymentMethod?>(
        _OrderPaymentFilterNotifier.new);

// Arama
class _OrderSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final orderSearchProvider =
    NotifierProvider<_OrderSearchNotifier, String>(_OrderSearchNotifier.new);

// Sayfalama
class OrdersPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int page) => state = page;
  void reset() => state = 0;
}

final ordersPageProvider =
    NotifierProvider<OrdersPageNotifier, int>(OrdersPageNotifier.new);

const int kOrdersPerPage = 15;

// Filtreli siparis listesi
final filteredOrdersProvider = Provider<List<AdminOrderModel>>((ref) {
  final asyncOrders = ref.watch(adminOrdersProvider);
  final statusFilter = ref.watch(orderStatusFilterProvider);
  final dateRange = ref.watch(orderDateRangeProvider);
  final paymentFilter = ref.watch(orderPaymentFilterProvider);
  final search = ref.watch(orderSearchProvider).toLowerCase().trim();

  // Filtre degisince sayfayi sifirla
  ref.listen(orderStatusFilterProvider, (_, __) {
    ref.read(ordersPageProvider.notifier).reset();
  });
  ref.listen(orderDateRangeProvider, (_, __) {
    ref.read(ordersPageProvider.notifier).reset();
  });
  ref.listen(orderPaymentFilterProvider, (_, __) {
    ref.read(ordersPageProvider.notifier).reset();
  });
  ref.listen(orderSearchProvider, (_, __) {
    ref.read(ordersPageProvider.notifier).reset();
  });

  return asyncOrders.when(
    data: (orders) {
      var result = List<AdminOrderModel>.from(orders);

      if (statusFilter.isNotEmpty) {
        result =
            result.where((o) => statusFilter.contains(o.status)).toList();
      }

      if (dateRange != null) {
        result = result.where((o) {
          final d = o.createdAt;
          return d.isAfter(dateRange.start
                  .subtract(const Duration(seconds: 1))) &&
              d.isBefore(
                  dateRange.end.add(const Duration(days: 1)));
        }).toList();
      }

      if (paymentFilter != null) {
        result =
            result.where((o) => o.paymentMethod == paymentFilter).toList();
      }

      if (search.isNotEmpty) {
        result = result
            .where((o) =>
                o.orderNumber.toLowerCase().contains(search) ||
                o.customerName.toLowerCase().contains(search) ||
                o.customerPhone.contains(search))
            .toList();
      }

      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Sayfalanmis liste
final paginatedOrdersProvider = Provider<List<AdminOrderModel>>((ref) {
  final filtered = ref.watch(filteredOrdersProvider);
  final page = ref.watch(ordersPageProvider);
  final start = page * kOrdersPerPage;
  if (start >= filtered.length) return [];
  final end = (start + kOrdersPerPage).clamp(0, filtered.length);
  return filtered.sublist(start, end);
});

final totalOrderPagesProvider = Provider<int>((ref) {
  final filtered = ref.watch(filteredOrdersProvider);
  return (filtered.length / kOrdersPerPage).ceil().clamp(1, 9999);
});

// Secili siparis id'leri (toplu islem icin)
class _SelectedOrderIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void set(Set<String> v) => state = v;
}

final selectedOrderIdsProvider =
    NotifierProvider<_SelectedOrderIdsNotifier, Set<String>>(
        _SelectedOrderIdsNotifier.new);

// Tek siparis detayi
final orderDetailProvider =
    FutureProvider.family<AdminOrderModel, String>((ref, id) async {
  final orders = ref.watch(adminOrdersProvider).value;
  if (orders == null) {
    await Future.delayed(const Duration(milliseconds: 500));
    final retry = ref.read(adminOrdersProvider).value;
    final order = retry?.where((o) => o.id == id).firstOrNull;
    if (order == null) throw Exception('Siparis bulunamadi: $id');
    return order;
  }
  final order = orders.where((o) => o.id == id).firstOrNull;
  if (order == null) throw Exception('Siparis bulunamadi: $id');
  return order;
});

// Saha gorevlileri listesi — Firestore users koleksiyonu
final fieldAgentsProvider =
    FutureProvider<List<({String id, String name})>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .where('role', isEqualTo: 'field_agent')
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .get();
  return snap.docs.map((doc) {
    final data = doc.data();
    return (id: doc.id, name: data['name'] as String? ?? '');
  }).toList();
});

// Teslimat gorevlileri listesi — Firestore users koleksiyonu
final deliveryPersonsProvider =
    FutureProvider<List<({String id, String name})>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .where('role', isEqualTo: 'delivery')
      .where('isActive', isEqualTo: true)
      .orderBy('name')
      .get();
  return snap.docs.map((doc) {
    final data = doc.data();
    return (id: doc.id, name: data['name'] as String? ?? '');
  }).toList();
});

// Dashboard istatistikleri (header chips icin)
final orderStatsProvider = Provider<({
  int pending,
  int preparing,
  int onTheWay,
  int todayTotal,
})>((ref) {
  final orders = ref.watch(adminOrdersProvider).value ?? [];
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  return (
    pending: orders
        .where((o) => o.status == AdminOrderStatus.pending)
        .length,
    preparing: orders
        .where((o) => o.status == AdminOrderStatus.preparing)
        .length,
    onTheWay: orders
        .where((o) => o.status == AdminOrderStatus.onTheWay)
        .length,
    todayTotal: orders
        .where((o) => o.createdAt.isAfter(todayStart))
        .length,
  );
});
