import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/order_data_providers.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/cancel_order_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../../domain/usecases/update_order_status_usecase.dart';

export '../../data/providers/order_data_providers.dart'
    show orderRemoteDatasourceProvider, apiOrderRepositoryProvider;

// ---------------------------------------------------------------------------
// Orders List State
// ---------------------------------------------------------------------------

/// copyWith için null temizleme sentinel'i.
/// `error: _clearError` → error alanını null'a ayarlar.
/// `error` geçilmezse mevcut değer korunur.
const _clearError = Object();

class OrdersState {
  final List<OrderEntity> orders;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final OrderStatus? filterStatus;

  const OrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.filterStatus,
  });

  /// [error] için sentinel kullanımı:
  ///   - Geçilmezse → mevcut `error` korunur
  ///   - `error: _clearError` → `null` olur
  ///   - `error: 'mesaj'` → yeni hata mesajı set edilir
  OrdersState copyWith({
    List<OrderEntity>? orders,
    bool? isLoading,
    Object? error = _clearError, // sentinel: geçilmezse mevcut değer korunur
    bool? hasMore,
    int? currentPage,
    OrderStatus? filterStatus,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _clearError)
          ? this.error // geçilmedi → koru
          : error as String?, // açıkça verildi (null dahil)
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier (Riverpod 3.x)
// ---------------------------------------------------------------------------
class ApiOrdersNotifier extends Notifier<OrdersState> {
  late final GetOrdersUsecase _getOrdersUsecase;
  late final CancelOrderUsecase _cancelOrderUsecase;
  late final CreateOrderUsecase _createOrderUsecase;
  late final UpdateOrderStatusUsecase _updateStatusUsecase;

  @override
  OrdersState build() {
    // 2 dk keepAlive: sipariş listesi sık değişebilir, fazla tutma.
    final link = ref.keepAlive();
    Timer(const Duration(minutes: 2), link.close);

    final repository = ref.watch(apiOrderRepositoryProvider);
    _getOrdersUsecase = GetOrdersUsecase(repository);
    _cancelOrderUsecase = CancelOrderUsecase(repository);
    _createOrderUsecase = CreateOrderUsecase(repository);
    _updateStatusUsecase = UpdateOrderStatusUsecase(repository);

    Future.microtask(loadOrders);

    return const OrdersState();
  }

  Future<void> loadOrders({
    OrderStatus? filterStatus,
    bool refresh = false,
  }) async {
    if (state.isLoading) return;

    if (refresh || filterStatus != state.filterStatus) {
      state = OrdersState(
        isLoading: true,
        filterStatus: filterStatus ?? state.filterStatus,
      );
    } else {
      // error sentinel geçilmediğinde mevcut error korunur
      state = state.copyWith(isLoading: true);
    }

    final result = await _getOrdersUsecase(
      page: refresh ? 1 : state.currentPage,
      status: filterStatus ?? state.filterStatus,
    );

    result.fold(
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
      (orders) {
        final newOrders = refresh || state.currentPage == 1
            ? orders
            : [...state.orders, ...orders];
        state = state.copyWith(
          orders: newOrders,
          isLoading: false,
          hasMore: orders.length >= 20,
          currentPage: (refresh ? 1 : state.currentPage) + 1,
          error: null, // başarıda açıkça temizle
        );
      },
    );
  }

  Future<bool> cancelOrder(int orderId) async {
    final result = await _cancelOrderUsecase(orderId);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (updatedOrder) {
        final updatedOrders = state.orders.map((o) {
          return o.id == orderId ? updatedOrder : o;
        }).toList();
        state = state.copyWith(orders: updatedOrders);
        return true;
      },
    );
  }

  Future<OrderEntity?> createOrder(CreateOrderInput input) async {
    final result = await _createOrderUsecase(input);
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return null;
      },
      (order) {
        state = state.copyWith(orders: [order, ...state.orders]);
        return order;
      },
    );
  }

  Future<bool> updateStatus({
    required int orderId,
    required OrderStatus newStatus,
    String? note,
  }) async {
    final result = await _updateStatusUsecase(
      orderId: orderId,
      newStatus: newStatus,
      note: note,
    );
    return result.fold(
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
      (updatedOrder) {
        final updatedOrders = state.orders.map((o) {
          return o.id == orderId ? updatedOrder : o;
        }).toList();
        state = state.copyWith(orders: updatedOrders);
        return true;
      },
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final apiOrdersNotifierProvider =
    NotifierProvider<ApiOrdersNotifier, OrdersState>(ApiOrdersNotifier.new);
