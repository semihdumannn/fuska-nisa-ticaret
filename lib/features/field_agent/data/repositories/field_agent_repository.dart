import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/order_repository.dart';

// ---------------------------------------------------------------------------
// FieldAgentStats — saha personelinin günlük istatistikleri
// ---------------------------------------------------------------------------
class FieldAgentStats {
  final int totalOrders;
  final int pendingOrders;
  final int preparingOrders;
  final int onTheWayOrders;
  final int deliveredOrders;
  final double totalSales;

  const FieldAgentStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.preparingOrders,
    required this.onTheWayOrders,
    required this.deliveredOrders,
    required this.totalSales,
  });

  factory FieldAgentStats.fromOrders(List<OrderModel> orders) {
    return FieldAgentStats(
      totalOrders: orders.length,
      pendingOrders: orders
          .where((o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.confirmed)
          .length,
      preparingOrders:
          orders.where((o) => o.status == OrderStatus.preparing).length,
      onTheWayOrders:
          orders.where((o) => o.status == OrderStatus.onTheWay).length,
      deliveredOrders:
          orders.where((o) => o.status == OrderStatus.delivered).length,
      totalSales: orders
          .where((o) => o.status == OrderStatus.delivered)
          .fold(0.0, (acc, o) => acc + o.total),
    );
  }

  static const empty = FieldAgentStats(
    totalOrders: 0,
    pendingOrders: 0,
    preparingOrders: 0,
    onTheWayOrders: 0,
    deliveredOrders: 0,
    totalSales: 0,
  );
}

// ---------------------------------------------------------------------------
// FieldAgentRepository
// ---------------------------------------------------------------------------
class FieldAgentRepository {
  final FirebaseFirestore _firestore;
  final OrderRepository _orderRepository;

  FieldAgentRepository({
    FirebaseFirestore? firestore,
    required OrderRepository orderRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _orderRepository = orderRepository;

  // =========================================================================
  // Stats
  // =========================================================================

  /// Saha personelinin bugünkü istatistiklerini döner (tek seferlik okuma).
  /// Firestore okuma sayısını azaltmak için caller tarafında çok sık çağrılmamalı;
  /// todayOrdersProvider stream'i zaten anlık güncelleme sağlar.
  Future<FieldAgentStats> getTodayStats(String agentUid) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _firestore
        .collection(AppConstants.ordersCollection)
        .where('createdBy', isEqualTo: agentUid)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    final orders =
        snap.docs.map((d) => OrderModel.fromFirestore(d)).toList();
    return FieldAgentStats.fromOrders(orders);
  }

  // =========================================================================
  // Gerçek-zamanlı stream'ler (cache yok — CLAUDE.md)
  // =========================================================================

  /// Bugünkü siparişleri gerçek zamanlı dinle — createdBy + createdAt index kullanır.
  Stream<List<OrderModel>> watchTodayOrders(String agentUid) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return _firestore
        .collection(AppConstants.ordersCollection)
        .where('createdBy', isEqualTo: agentUid)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => OrderModel.fromFirestore(d)).toList());
  }

  // =========================================================================
  // Sipariş işlemleri (OrderRepository'ye delegate)
  // =========================================================================

  /// Hızlı sipariş oluştur — müşteri adına field_agent tarafından kullanılır.
  /// OrderRepository.createOrder'a delegate eder.
  Future<String> createQuickOrder(OrderModel order) async {
    return _orderRepository.createOrder(order);
  }

  /// Sipariş durumunu güncelle — OrderRepository.updateOrderStatus'a delegate eder.
  Future<void> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    required String updatedBy,
  }) async {
    return _orderRepository.updateOrderStatus(
      orderId: orderId,
      newStatus: newStatus,
      updatedBy: updatedBy,
    );
  }

  // =========================================================================
  // Müşteri işlemleri
  // =========================================================================

  /// Tüm müşterileri çek — ada göre sıralı, max 100 kayıt.
  /// role + name bileşik index gerektirir (firestore.indexes.json).
  Future<List<UserModel>> getCustomers() async {
    final snap = await _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'customer')
        .orderBy('name')
        .limit(100)
        .get();
    return snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
  }

  /// İsim veya telefon numarasına göre müşteri ara (client-side filtre).
  /// Firestore'da full-text search olmadığından getCustomers() sonucunu filtreler;
  /// büyük veri setleri için Algolia/Typesense entegrasyonu düşünülmeli.
  Future<List<UserModel>> searchCustomers(String query) async {
    if (query.isEmpty) return getCustomers();
    final all = await getCustomers();
    final q = query.toLowerCase();
    return all
        .where((u) =>
            u.name.toLowerCase().contains(q) || u.phone.contains(q))
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Provider — singleton repository
// ---------------------------------------------------------------------------
final fieldAgentRepositoryProvider = Provider<FieldAgentRepository>((ref) {
  return FieldAgentRepository(
    orderRepository: ref.watch(orderRepositoryProvider),
  );
});

// ---------------------------------------------------------------------------
// Günlük istatistikler — todayOrdersProvider'dan türetilir (ekstra Firestore
// okuma yapmaz; stream zaten açık, ayrı get() gerekmez — Spark optimizasyonu).
// ---------------------------------------------------------------------------
final todayStatsProvider = Provider<FieldAgentStats>((ref) {
  final orders = ref.watch(todayOrdersProvider).value ?? [];
  return FieldAgentStats.fromOrders(orders);
});

// ---------------------------------------------------------------------------
// Bugünkü siparişler — StreamProvider (gerçek-zamanlı, cache yok)
// ---------------------------------------------------------------------------
final todayOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();
  return ref
      .watch(fieldAgentRepositoryProvider)
      .watchTodayOrders(user.uid);
});
