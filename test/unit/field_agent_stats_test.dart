// field_agent_stats_test.dart
//
// FieldAgentStats.fromOrders ve FieldAgentStats.empty icin unit testler.
// Firebase bagimliligi yok; saf Dart logic test edilir.
// OrderModel instance'lari minimal constructor ile olusturulur.

import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/field_agent/data/repositories/field_agent_repository.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';

// ---------------------------------------------------------------------------
// Yardimci: Minimal OrderModel olusturur
// ---------------------------------------------------------------------------
OrderModel _makeOrder({
  String id = 'order1',
  String orderNo = 'NST-2026-00001',
  OrderStatus status = OrderStatus.pending,
  double total = 100.0,
}) {
  final now = DateTime(2026, 5, 1, 10, 0);
  return OrderModel(
    id: id,
    orderNo: orderNo,
    customerId: 'cust1',
    customerName: 'Test Musteri',
    customerPhone: '05001234567',
    source: OrderSource.fieldAgent,
    createdBy: 'agent1',
    status: status,
    statusHistory: [
      StatusHistory(
        status: OrderStatus.pending,
        timestamp: now,
        by: 'agent1',
      ),
    ],
    items: [
      OrderItem(
        productId: 'prod1',
        productName: 'Damacana Su',
        qty: 1,
        unitPrice: total,
        totalPrice: total,
      ),
    ],
    deliveryAddress: const DeliveryAddress(
      fullAddress: 'Test Adres',
      district: 'Merkez',
      city: 'Balikesir',
    ),
    paymentMethod: PaymentMethod.cash,
    subtotal: total,
    discount: 0,
    total: total,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // =========================================================================
  // FieldAgentStats.empty
  // =========================================================================
  group('FieldAgentStats.empty', () {
    test('sentinel degerler sifirdir', () {
      const stats = FieldAgentStats.empty;
      expect(stats.totalOrders, 0);
      expect(stats.pendingOrders, 0);
      expect(stats.preparingOrders, 0);
      expect(stats.onTheWayOrders, 0);
      expect(stats.deliveredOrders, 0);
      expect(stats.totalSales, 0.0);
    });

    test('const olarak kullanilabilir', () {
      const a = FieldAgentStats.empty;
      const b = FieldAgentStats.empty;
      // const ayni referans oldugu icin identical kontrolu gecer
      expect(identical(a, b), isTrue);
    });

    test('field degerleri dogru tipte', () {
      const stats = FieldAgentStats.empty;
      expect(stats.totalOrders, isA<int>());
      expect(stats.pendingOrders, isA<int>());
      expect(stats.preparingOrders, isA<int>());
      expect(stats.onTheWayOrders, isA<int>());
      expect(stats.deliveredOrders, isA<int>());
      expect(stats.totalSales, isA<double>());
    });
  });

  // =========================================================================
  // FieldAgentStats constructor
  // =========================================================================
  group('FieldAgentStats constructor', () {
    test('tum field\'lar dogru atanir', () {
      const stats = FieldAgentStats(
        totalOrders: 10,
        pendingOrders: 3,
        preparingOrders: 2,
        onTheWayOrders: 1,
        deliveredOrders: 4,
        totalSales: 450.0,
      );

      expect(stats.totalOrders, 10);
      expect(stats.pendingOrders, 3);
      expect(stats.preparingOrders, 2);
      expect(stats.onTheWayOrders, 1);
      expect(stats.deliveredOrders, 4);
      expect(stats.totalSales, 450.0);
    });

    test('const ile olusturulabilir', () {
      const stats = FieldAgentStats(
        totalOrders: 5,
        pendingOrders: 1,
        preparingOrders: 1,
        onTheWayOrders: 1,
        deliveredOrders: 2,
        totalSales: 200.0,
      );
      expect(stats.totalOrders, 5);
    });
  });

  // =========================================================================
  // FieldAgentStats.fromOrders — bos liste
  // =========================================================================
  group('FieldAgentStats.fromOrders — bos liste', () {
    test('tum sayilar sifir, totalSales 0.0', () {
      final stats = FieldAgentStats.fromOrders([]);

      expect(stats.totalOrders, 0);
      expect(stats.pendingOrders, 0);
      expect(stats.preparingOrders, 0);
      expect(stats.onTheWayOrders, 0);
      expect(stats.deliveredOrders, 0);
      expect(stats.totalSales, 0.0);
    });
  });

  // =========================================================================
  // FieldAgentStats.fromOrders — sadece pending siparişler
  // =========================================================================
  group('FieldAgentStats.fromOrders — sadece pending', () {
    test('pendingOrders N, totalSales 0 (delivered degil)', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.pending, total: 100.0),
        _makeOrder(id: 'o2', status: OrderStatus.pending, total: 200.0),
        _makeOrder(id: 'o3', status: OrderStatus.pending, total: 150.0),
      ];

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.totalOrders, 3);
      expect(stats.pendingOrders, 3);
      expect(stats.preparingOrders, 0);
      expect(stats.onTheWayOrders, 0);
      expect(stats.deliveredOrders, 0);
      // Delivered olmadigi icin totalSales sifir olmali
      expect(stats.totalSales, 0.0);
    });

    test('confirmed siparisler de pendingOrders\'a dahil edilir', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.pending),
        _makeOrder(id: 'o2', status: OrderStatus.confirmed),
      ];

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.pendingOrders, 2);
      expect(stats.totalSales, 0.0);
    });

    test('tek pending siparis', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.pending, total: 75.0),
      ];

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.totalOrders, 1);
      expect(stats.pendingOrders, 1);
      expect(stats.totalSales, 0.0);
    });
  });

  // =========================================================================
  // FieldAgentStats.fromOrders — karisik statusler
  // =========================================================================
  group('FieldAgentStats.fromOrders — karisik statusler', () {
    test('her sayac dogru hesaplanir', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.pending, total: 50.0),
        _makeOrder(id: 'o2', status: OrderStatus.confirmed, total: 60.0),
        _makeOrder(id: 'o3', status: OrderStatus.preparing, total: 70.0),
        _makeOrder(id: 'o4', status: OrderStatus.onTheWay, total: 80.0),
        _makeOrder(id: 'o5', status: OrderStatus.delivered, total: 90.0),
        _makeOrder(id: 'o6', status: OrderStatus.cancelled, total: 100.0),
      ];

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.totalOrders, 6);
      // pending + confirmed = 2
      expect(stats.pendingOrders, 2);
      expect(stats.preparingOrders, 1);
      expect(stats.onTheWayOrders, 1);
      expect(stats.deliveredOrders, 1);
      // Sadece delivered siparisin totali: 90.0
      expect(stats.totalSales, 90.0);
    });

    test('birden fazla preparing siparisi dogru sayilir', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.preparing, total: 40.0),
        _makeOrder(id: 'o2', status: OrderStatus.preparing, total: 50.0),
        _makeOrder(id: 'o3', status: OrderStatus.onTheWay, total: 60.0),
      ];

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.totalOrders, 3);
      expect(stats.pendingOrders, 0);
      expect(stats.preparingOrders, 2);
      expect(stats.onTheWayOrders, 1);
      expect(stats.deliveredOrders, 0);
      expect(stats.totalSales, 0.0);
    });

    test('cancelled siparisler totalSales\'a dahil edilmez', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.cancelled, total: 200.0),
        _makeOrder(id: 'o2', status: OrderStatus.cancelled, total: 300.0),
        _makeOrder(id: 'o3', status: OrderStatus.delivered, total: 100.0),
      ];

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.totalSales, 100.0);
      expect(stats.deliveredOrders, 1);
    });
  });

  // =========================================================================
  // FieldAgentStats.fromOrders — sadece delivered
  // =========================================================================
  group('FieldAgentStats.fromOrders — sadece delivered', () {
    test('totalSales dogru hesaplanir', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.delivered, total: 100.0),
        _makeOrder(id: 'o2', status: OrderStatus.delivered, total: 200.0),
        _makeOrder(id: 'o3', status: OrderStatus.delivered, total: 50.0),
      ];

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.totalOrders, 3);
      expect(stats.deliveredOrders, 3);
      expect(stats.totalSales, 350.0);
      expect(stats.pendingOrders, 0);
    });

    test('tek delivered siparis', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.delivered, total: 75.5),
      ];

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.totalOrders, 1);
      expect(stats.deliveredOrders, 1);
      expect(stats.totalSales, 75.5);
    });

    test('kucuk ondalik degerler dogru toplanir', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.delivered, total: 10.25),
        _makeOrder(id: 'o2', status: OrderStatus.delivered, total: 20.50),
        _makeOrder(id: 'o3', status: OrderStatus.delivered, total: 5.25),
      ];

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.totalSales, closeTo(36.0, 0.001));
    });
  });

  // =========================================================================
  // FieldAgentStats.fromOrders — buyuk liste performans kontrolu
  // =========================================================================
  group('FieldAgentStats.fromOrders — buyuk liste', () {
    test('100 siparis dogru hesaplanir', () {
      final orders = List.generate(100, (i) {
        final status = i % 5 == 0
            ? OrderStatus.delivered
            : i % 3 == 0
                ? OrderStatus.preparing
                : OrderStatus.pending;
        return _makeOrder(id: 'o$i', status: status, total: 10.0);
      });

      final stats = FieldAgentStats.fromOrders(orders);

      expect(stats.totalOrders, 100);
      // delivered: i % 5 == 0 → 0,5,10...,95 = 20 adet
      expect(stats.deliveredOrders, 20);
      expect(stats.totalSales, 200.0);
    });
  });
}
