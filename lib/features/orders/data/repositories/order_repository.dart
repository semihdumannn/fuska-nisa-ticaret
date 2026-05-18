import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';

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

  /// Siparis durumu guncelle — admin/staff/delivery icin.
  /// statusHistory'ye yeni giris ekler, status ve updatedAt gunceller.
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    required String updatedBy,
    DateTime? estimatedDelivery,
  }) async {
    final newHistoryEntry = StatusHistory(
      status: newStatus,
      timestamp: DateTime.now(),
      by: updatedBy,
    ).toMap();

    final update = <String, dynamic>{
      'status': newStatus.value,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([newHistoryEntry]),
    };

    if (newStatus == OrderStatus.delivered) {
      update['deliveredAt'] = FieldValue.serverTimestamp();
    }
    if (estimatedDelivery != null) {
      update['estimatedDelivery'] = Timestamp.fromDate(estimatedDelivery);
    }

    await _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update(update);
  }

  /// Teslimat personeli ata — admin/staff icin
  Future<void> assignDelivery({
    required String orderId,
    required String deliveryUserId,
  }) async {
    await _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .update({
      'assignedTo': deliveryUserId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// FCM bildirim tetikleyici — Cloud Functions Firestore trigger ile otomatik calisir.
  Future<void> triggerNotification({
    required String orderId,
    required OrderStatus status,
  }) async {
    debugPrint('[FCM] Order $orderId status → ${status.value}');
  }

  // =========================================================================
  // Tek seferlik okumalar (Future)
  // =========================================================================

  /// Tek siparis — Future (stream degil, tek seferlik okuma)
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .get();
    if (!doc.exists) return null;
    return OrderModel.fromFirestore(doc);
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
  // Gercek-zamanli stream'ler (cache yok — CLAUDE.md)
  // =========================================================================

  /// Kullanicinin siparislerini gercek zamanli dinle
  Stream<List<OrderModel>> watchUserOrders(String userId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('customerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromFirestore(d)).toList());
  }

  /// Tek siparis detayini gercek zamanli dinle
  Stream<OrderModel?> watchOrder(String orderId) {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .doc(orderId)
        .snapshots()
        .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
  }

  /// Staff/admin icin aktif siparisler — pending, confirmed, preparing, on_the_way
  Stream<List<OrderModel>> watchActiveOrders() {
    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('status', whereIn: [
          OrderStatus.pending.value,
          OrderStatus.confirmed.value,
          OrderStatus.preparing.value,
          OrderStatus.onTheWay.value,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromFirestore(d)).toList());
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
// Provider — singleton repository
// ---------------------------------------------------------------------------
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

// ---------------------------------------------------------------------------
// Kullanicinin siparisleri — gercek zamanli stream (cache yok: CLAUDE.md)
// ---------------------------------------------------------------------------
final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref.watch(orderRepositoryProvider).watchUserOrders(user.uid);
});

// ---------------------------------------------------------------------------
// Tekil siparis stream — OrderDetailScreen icin
// ---------------------------------------------------------------------------
final orderStreamProvider =
    StreamProvider.family<OrderModel?, String>((ref, orderId) {
  return ref.watch(orderRepositoryProvider).watchOrder(orderId);
});

// ---------------------------------------------------------------------------
// Aktif siparisler — staff/admin paneli icin (cache yok)
// ---------------------------------------------------------------------------
final activeOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).watchActiveOrders();
});
