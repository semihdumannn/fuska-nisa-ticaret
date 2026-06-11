import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/models/admin_order_model.dart';

/// Backend'in döndürdüğü 403 hatasını anlamlı mesaja çevirir.
class AdminRoleException implements Exception {
  final String message;
  const AdminRoleException(this.message);
  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Ana siparisler notifier — API tabanlı, 30s polling
// ---------------------------------------------------------------------------
class AdminOrdersNotifier
    extends Notifier<AsyncValue<List<AdminOrderModel>>> {
  Timer? _pollTimer;

  Dio get _dio => ref.read(apiClientProvider).dio;

  @override
  AsyncValue<List<AdminOrderModel>> build() {
    ref.onDispose(() => _pollTimer?.cancel());
    _load();
    _startPolling();
    return const AsyncValue.loading();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final orders = await _fetchAllOrders();
      state = AsyncValue.data(orders);
    } on AdminRoleException catch (e, st) {
      state = AsyncValue.error(e, st);
      _pollTimer?.cancel(); // 403 durumunda polling durdur
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<List<AdminOrderModel>> _fetchAllOrders() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.adminOrders,
        queryParameters: {'per_page': 100, 'page': 1},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];
      return data
          .map((j) => AdminOrderModel.fromApiJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const AdminRoleException(
          'Yetersiz yetki: Backend\'de admin rolünüz yok.\n\n'
          'Çözüm: Backend veritabanında kullanıcınızın rolünü "admin" olarak güncelleyin.\n'
          'Adım: HF Space terminali → php artisan tinker\n'
          'User::where("phone", "<telefonunuz>")->update(["role" => "admin"]);',
        );
      }
      rethrow;
    }
  }

  Future<void> updateStatus(String orderId, AdminOrderStatus status) async {
    final apiStatus = switch (status) {
      AdminOrderStatus.confirmed => 'confirmed',
      AdminOrderStatus.preparing => 'preparing',
      AdminOrderStatus.onTheWay  => 'on_the_way',
      AdminOrderStatus.delivered => 'delivered',
      AdminOrderStatus.cancelled => 'cancelled',
      AdminOrderStatus.refunded  => 'cancelled',
      AdminOrderStatus.pending   => 'pending',
    };

    final id = int.tryParse(orderId);
    if (id == null) return;

    try {
      await _dio.put(
        ApiEndpoints.adminOrderStatus(id),
        data: {'status': apiStatus},
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      final msg = (body is Map ? body['message'] : null) as String?;
      throw Exception(msg ?? 'Durum güncellenemedi (${e.response?.statusCode})');
    }

    final current = state.value ?? [];
    state = AsyncValue.data(current.map((o) {
      if (o.id != orderId) return o;
      return o.copyWith(status: status);
    }).toList());
  }

  Future<void> assignDelivery(
      String orderId, String deliveryId, String deliveryName) async {
    final id = int.tryParse(orderId);
    if (id == null) return;

    await _dio.put(
      '${ApiEndpoints.adminOrders}/$id/assign-delivery',
      data: {'user_id': int.tryParse(deliveryId) ?? deliveryId},
    );

    final current = state.value ?? [];
    state = AsyncValue.data(current.map((o) {
      if (o.id != orderId) return o;
      return o.copyWith(
          assignedDeliveryId: deliveryId, assignedDeliveryName: deliveryName);
    }).toList());
  }

  Future<void> assignAgent(
      String orderId, String agentId, String agentName) async {
    final id = int.tryParse(orderId);
    if (id == null) return;

    await _dio.put(
      '${ApiEndpoints.adminOrders}/$id/assign-agent',
      data: {'user_id': int.tryParse(agentId) ?? agentId},
    );

    final current = state.value ?? [];
    state = AsyncValue.data(current.map((o) {
      if (o.id != orderId) return o;
      return o.copyWith(
          assignedAgentId: agentId, assignedAgentName: agentName);
    }).toList());
  }

  Future<void> addNote(String orderId, String content) async {
    final id = int.tryParse(orderId);
    if (id != null) {
      try {
        await _dio.post(
          '${ApiEndpoints.adminOrders}/$id/notes',
          data: {'content': content},
        );
      } catch (_) {}
    }
    final now = DateTime.now();
    final note = InternalNote(
      id: 'note_${now.millisecondsSinceEpoch}',
      authorName: 'Admin',
      content: content,
      createdAt: now,
    );
    final current = state.value ?? [];
    state = AsyncValue.data(current.map((o) {
      if (o.id != orderId) return o;
      return o.copyWith(notes: [...o.notes, note]);
    }).toList());
  }

  Future<void> bulkConfirm(List<String> orderIds) async {
    for (final orderId in orderIds) {
      await updateStatus(orderId, AdminOrderStatus.confirmed);
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    final id = int.tryParse(orderId);
    if (id == null) return;

    await _dio.post(
      ApiEndpoints.orderCancel(id),
      data: {'reason': reason},
    );

    final current = state.value ?? [];
    state = AsyncValue.data(current.map((o) {
      if (o.id != orderId) return o;
      return o.copyWith(
          status: AdminOrderStatus.cancelled, cancellationReason: reason);
    }).toList());
  }

  Future<void> initiateRefund(String orderId) async {
    await cancelOrder(orderId, 'İade talep edildi');
  }
}

// ---------------------------------------------------------------------------
// Provider tanimlari
// ---------------------------------------------------------------------------
final adminOrdersProvider = NotifierProvider<AdminOrdersNotifier,
    AsyncValue<List<AdminOrderModel>>>(
  AdminOrdersNotifier.new,
);

class _OrderStatusFilterNotifier extends Notifier<Set<AdminOrderStatus>> {
  @override
  Set<AdminOrderStatus> build() => {};
  void set(Set<AdminOrderStatus> v) => state = v;
}

final orderStatusFilterProvider =
    NotifierProvider<_OrderStatusFilterNotifier, Set<AdminOrderStatus>>(
        _OrderStatusFilterNotifier.new);

class _OrderDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;
  void set(DateTimeRange? v) => state = v;
}

final orderDateRangeProvider =
    NotifierProvider<_OrderDateRangeNotifier, DateTimeRange?>(
        _OrderDateRangeNotifier.new);

class _OrderPaymentFilterNotifier extends Notifier<AdminPaymentMethod?> {
  @override
  AdminPaymentMethod? build() => null;
  void set(AdminPaymentMethod? v) => state = v;
}

final orderPaymentFilterProvider =
    NotifierProvider<_OrderPaymentFilterNotifier, AdminPaymentMethod?>(
        _OrderPaymentFilterNotifier.new);

class _OrderSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final orderSearchProvider =
    NotifierProvider<_OrderSearchNotifier, String>(_OrderSearchNotifier.new);

class OrdersPageNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int page) => state = page;
  void reset() => state = 0;
}

final ordersPageProvider =
    NotifierProvider<OrdersPageNotifier, int>(OrdersPageNotifier.new);

const int kOrdersPerPage = 15;

final filteredOrdersProvider = Provider<List<AdminOrderModel>>((ref) {
  final asyncOrders   = ref.watch(adminOrdersProvider);
  final statusFilter  = ref.watch(orderStatusFilterProvider);
  final dateRange     = ref.watch(orderDateRangeProvider);
  final paymentFilter = ref.watch(orderPaymentFilterProvider);
  final search        = ref.watch(orderSearchProvider).toLowerCase().trim();

  ref.listen(orderStatusFilterProvider,  (_, __) => ref.read(ordersPageProvider.notifier).reset());
  ref.listen(orderDateRangeProvider,     (_, __) => ref.read(ordersPageProvider.notifier).reset());
  ref.listen(orderPaymentFilterProvider, (_, __) => ref.read(ordersPageProvider.notifier).reset());
  ref.listen(orderSearchProvider,        (_, __) => ref.read(ordersPageProvider.notifier).reset());

  return asyncOrders.when(
    data: (orders) {
      var result = List<AdminOrderModel>.from(orders);

      if (statusFilter.isNotEmpty) {
        result = result.where((o) => statusFilter.contains(o.status)).toList();
      }

      if (dateRange != null) {
        result = result.where((o) {
          final d = o.createdAt;
          return d.isAfter(dateRange.start.subtract(const Duration(seconds: 1))) &&
              d.isBefore(dateRange.end.add(const Duration(days: 1)));
        }).toList();
      }

      if (paymentFilter != null) {
        result = result.where((o) => o.paymentMethod == paymentFilter).toList();
      }

      if (search.isNotEmpty) {
        result = result.where((o) =>
            o.orderNumber.toLowerCase().contains(search) ||
            o.customerName.toLowerCase().contains(search) ||
            o.customerPhone.contains(search)).toList();
      }

      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    },
    loading: () => [],
    error:   (_, __) => [],
  );
});

final paginatedOrdersProvider = Provider<List<AdminOrderModel>>((ref) {
  final filtered = ref.watch(filteredOrdersProvider);
  final page  = ref.watch(ordersPageProvider);
  final start = page * kOrdersPerPage;
  if (start >= filtered.length) return [];
  final end = (start + kOrdersPerPage).clamp(0, filtered.length);
  return filtered.sublist(start, end);
});

final totalOrderPagesProvider = Provider<int>((ref) {
  final filtered = ref.watch(filteredOrdersProvider);
  return (filtered.length / kOrdersPerPage).ceil().clamp(1, 9999);
});

class _SelectedOrderIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  void set(Set<String> v) => state = v;
}

final selectedOrderIdsProvider =
    NotifierProvider<_SelectedOrderIdsNotifier, Set<String>>(
        _SelectedOrderIdsNotifier.new);

final orderDetailProvider =
    FutureProvider.family<AdminOrderModel, String>((ref, id) async {
  final orders = ref.watch(adminOrdersProvider).value;
  if (orders != null) {
    final found = orders.where((o) => o.id == id).firstOrNull;
    if (found != null) return found;
  }
  throw Exception('Siparis bulunamadı: $id');
});

// Saha/teslimat gorevlileri — Firestore users (sadece user listesi, order değil)
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
    pending:    orders.where((o) => o.status == AdminOrderStatus.pending).length,
    preparing:  orders.where((o) => o.status == AdminOrderStatus.preparing).length,
    onTheWay:   orders.where((o) => o.status == AdminOrderStatus.onTheWay).length,
    todayTotal: orders.where((o) => o.createdAt.isAfter(todayStart)).length,
  );
});
