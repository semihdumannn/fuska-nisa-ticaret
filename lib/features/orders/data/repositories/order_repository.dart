import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';
import 'package:nisa_ticaret/features/orders/data/providers/order_data_providers.dart';
import 'package:nisa_ticaret/features/orders/domain/entities/order_entity.dart';
import 'package:nisa_ticaret/features/orders/domain/usecases/get_order_detail_usecase.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // =========================================================================
  // Yazma
  // =========================================================================

  /// Siparis olustur — Firestore'a yaz, orderNo dondur
  Future<String> createOrder(OrderModel order) async {
    final orderNo = _generateOrderNo();
    final ref =
        _firestore.collection(AppConstants.ordersCollection).doc();

    final orderWithId = OrderModel(
      id: ref.id,
      orderNo: orderNo,
      customerId: order.customerId,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      source: order.source,
      createdBy: order.createdBy,
      status: order.status,
      statusHistory: order.statusHistory,
      items: order.items,
      deliveryAddress: order.deliveryAddress,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      assignedTo: order.assignedTo,
      estimatedDelivery: order.estimatedDelivery,
      deliveredAt: order.deliveredAt,
      subtotal: order.subtotal,
      discount: order.discount,
      total: order.total,
      notes: order.notes,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );

    await ref.set(orderWithId.toFirestore());
    return orderNo;
  }

  /// Kullanicinin siparislerini tek seferlik cek — Future
  Future<List<OrderModel>> getUserOrders(String userId) async {
    final snap = await _firestore
        .collection(AppConstants.ordersCollection)
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => OrderModel.fromFirestore(d)).toList();
  }

  // =========================================================================
  // Private helpers
  // =========================================================================

  String _generateOrderNo() {
    final year = DateTime.now().year;
    final random = Random().nextInt(99999).toString().padLeft(5, '0');
    return 'NST-$year-$random';
  }
}

// ---------------------------------------------------------------------------
// Provider — singleton Firestore repository (field_agent vb. icin korunuyor)
// ---------------------------------------------------------------------------
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

// ---------------------------------------------------------------------------
// Kullanicinin siparisleri — API (FutureProvider)
// ---------------------------------------------------------------------------
final userOrdersProvider = FutureProvider<List<OrderEntity>>((ref) async {
  final repo = ref.watch(apiOrderRepositoryProvider);
  final result = await repo.getOrders(page: 1, perPage: 50);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (orders) => orders,
  );
});

// ---------------------------------------------------------------------------
// Tekil siparis detayi — API (FutureProvider.family)
// ---------------------------------------------------------------------------
final orderStreamProvider =
    FutureProvider.family<OrderEntity, String>((ref, orderId) async {
  final id = int.tryParse(orderId) ?? 0;
  final repo = ref.watch(apiOrderRepositoryProvider);
  final result = await GetOrderDetailUsecase(repo)(id);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (order) => order,
  );
});

// ---------------------------------------------------------------------------
// Aktif siparisler — API (pending/confirmed/preparing/on_the_way)
// ---------------------------------------------------------------------------
final activeOrdersProvider = FutureProvider<List<OrderEntity>>((ref) async {
  final repo = ref.watch(apiOrderRepositoryProvider);
  final result = await repo.getOrders(page: 1, perPage: 100);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (orders) => orders.where((o) => o.status.isActive).toList(),
  );
});
