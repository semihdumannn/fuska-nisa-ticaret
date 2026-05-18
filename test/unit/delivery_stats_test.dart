// delivery_stats_test.dart
//
// deliveryOrdersProvider'in filtreleme mantigini model seviyesinde dogrular.
// Firebase/Riverpod bagimliligi yok; saf Dart list filtreleme test edilir.
// Provider'in icindeki where() kosutu ayni sekilde bu testlerde uygulanir.

import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';

// ---------------------------------------------------------------------------
// Yardimci: Minimal OrderModel olusturur
// ---------------------------------------------------------------------------
OrderModel _makeOrder({
  String id = 'order1',
  String orderNo = 'NST-2026-00001',
  OrderStatus status = OrderStatus.onTheWay,
  String? assignedTo,
  double total = 100.0,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 5, 4, 10, 0);
  return OrderModel(
    id: id,
    orderNo: orderNo,
    customerId: 'cust1',
    customerName: 'Test Musteri',
    customerPhone: '05001234567',
    source: OrderSource.customerApp,
    createdBy: 'cust1',
    status: status,
    statusHistory: [
      StatusHistory(
        status: status,
        timestamp: now,
        by: 'system',
      ),
    ],
    items: [
      OrderItem(
        productId: 'prod1',
        productName: 'Damacana Su',
        qty: 2,
        unitPrice: total / 2,
        totalPrice: total,
      ),
    ],
    deliveryAddress: const DeliveryAddress(
      fullAddress: 'Ataturk Cad. No:1',
      district: 'Merkez',
      city: 'Balikesir',
    ),
    paymentMethod: PaymentMethod.cash,
    subtotal: total,
    discount: 0,
    total: total,
    assignedTo: assignedTo,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Provider filtreleme mantigi: deliveryOrdersProvider icindeki where() kosutu
// ---------------------------------------------------------------------------
/// deliveryOrdersProvider'daki filtreleme: o.assignedTo == uid || o.status == onTheWay
List<OrderModel> _applyDeliveryFilter(
  List<OrderModel> orders,
  String uid,
) {
  return orders
      .where((o) => o.assignedTo == uid || o.status == OrderStatus.onTheWay)
      .toList();
}

void main() {
  // =========================================================================
  // deliveryOrdersProvider filtreleme mantigi
  // =========================================================================
  group('deliveryOrdersProvider filtre mantigi', () {
    const uid = 'delivery_user_1';

    // -----------------------------------------------------------------------
    // onTheWay siparisleri
    // -----------------------------------------------------------------------
    group('onTheWay status filtresi', () {
      test('onTheWay siparis listeye giriyor', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.onTheWay),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 1);
        expect(result.first.id, 'o1');
      });

      test('birden fazla onTheWay siparis hepsi giriyor', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.onTheWay),
          _makeOrder(id: 'o2', status: OrderStatus.onTheWay),
          _makeOrder(id: 'o3', status: OrderStatus.onTheWay),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 3);
      });

      test('onTheWay durumundaki siparis assignedTo olmasa da giriyor', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.onTheWay, assignedTo: null),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 1);
      });
    });

    // -----------------------------------------------------------------------
    // assignedTo filtresi
    // -----------------------------------------------------------------------
    group('assignedTo filtresi', () {
      test('assignedTo == uid olan siparis listeye giriyor', () {
        final orders = [
          _makeOrder(
            id: 'o1',
            status: OrderStatus.preparing, // onTheWay degil ama assignedTo eslesiyor
            assignedTo: uid,
          ),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 1);
        expect(result.first.id, 'o1');
      });

      test('assignedTo baska uid olan siparis listeye girmiyor', () {
        final orders = [
          _makeOrder(
            id: 'o1',
            status: OrderStatus.preparing,
            assignedTo: 'baska_kullanici',
          ),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 0);
      });

      test('assignedTo null olan confirmed siparis listeye girmiyor', () {
        final orders = [
          _makeOrder(
            id: 'o1',
            status: OrderStatus.confirmed,
            assignedTo: null,
          ),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 0);
      });
    });

    // -----------------------------------------------------------------------
    // Filtrelenmesi gereken statusler
    // -----------------------------------------------------------------------
    group('diger statusler filtreleniyor', () {
      test('pending siparis filtreleniyor', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.pending, assignedTo: null),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 0);
      });

      test('confirmed siparis filtreleniyor', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.confirmed, assignedTo: null),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 0);
      });

      test('preparing siparis filtreleniyor (assignedTo yok)', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.preparing, assignedTo: null),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 0);
      });

      test('delivered siparis filtreleniyor (assignedTo yok)', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.delivered, assignedTo: null),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 0);
      });

      test('cancelled siparis filtreleniyor', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.cancelled, assignedTo: null),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 0);
      });
    });

    // -----------------------------------------------------------------------
    // Karisik liste
    // -----------------------------------------------------------------------
    group('karisik liste filtresi', () {
      test('karisik listede sadece uygun siparisler giriyor', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.onTheWay),
          _makeOrder(id: 'o2', status: OrderStatus.preparing, assignedTo: uid),
          _makeOrder(id: 'o3', status: OrderStatus.pending, assignedTo: null),
          _makeOrder(id: 'o4', status: OrderStatus.delivered, assignedTo: null),
          _makeOrder(id: 'o5', status: OrderStatus.confirmed, assignedTo: 'baska'),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result.length, 2);
        expect(result.map((o) => o.id).toSet(), {'o1', 'o2'});
      });

      test('hem onTheWay hem assignedTo eslesiminde tekrar sayilmiyor', () {
        final orders = [
          _makeOrder(
            id: 'o1',
            status: OrderStatus.onTheWay,
            assignedTo: uid, // ikisi de esliyor
          ),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        // where() OR kosulu, duplikat yaratmaz
        expect(result.length, 1);
      });
    });

    // -----------------------------------------------------------------------
    // Bos liste
    // -----------------------------------------------------------------------
    group('bos liste durumu', () {
      test('bos liste ile bos sonuc doniyor', () {
        final result = _applyDeliveryFilter([], uid);
        expect(result, isEmpty);
      });

      test('hicbiri eslesmediginde bos liste donuyor', () {
        final orders = [
          _makeOrder(id: 'o1', status: OrderStatus.pending),
          _makeOrder(id: 'o2', status: OrderStatus.confirmed),
        ];
        final result = _applyDeliveryFilter(orders, uid);
        expect(result, isEmpty);
      });
    });
  });
}
