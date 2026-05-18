// delivery_status_update_test.dart
//
// OrderStatus gecis mantigi ve StatusHistory model seviyesinde dogrulaniyor.
// Firebase/Riverpod bagimliligi yok; saf Dart enum + model logic test edilir.

import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';

// ---------------------------------------------------------------------------
// Yardimci: StatusHistory entry olusturur
// ---------------------------------------------------------------------------
StatusHistory _makeHistory({
  OrderStatus status = OrderStatus.pending,
  String by = 'system',
  DateTime? timestamp,
}) {
  return StatusHistory(
    status: status,
    timestamp: timestamp ?? DateTime(2026, 5, 4, 10, 0),
    by: by,
  );
}

// ---------------------------------------------------------------------------
// Yardimci: Minimal OrderModel olusturur (statusHistory degistirilebilir)
// ---------------------------------------------------------------------------
OrderModel _makeOrder({
  String id = 'order1',
  OrderStatus status = OrderStatus.onTheWay,
  List<StatusHistory>? statusHistory,
  String? assignedTo,
}) {
  final now = DateTime(2026, 5, 4, 10, 0);
  return OrderModel(
    id: id,
    orderNo: 'NST-2026-00001',
    customerId: 'cust1',
    customerName: 'Mehmet Yilmaz',
    customerPhone: '05321112233',
    source: OrderSource.customerApp,
    createdBy: 'cust1',
    status: status,
    statusHistory: statusHistory ??
        [
          _makeHistory(status: OrderStatus.pending),
          _makeHistory(status: status),
        ],
    items: [
      OrderItem(
        productId: 'prod1',
        productName: 'Limonlu Soda',
        qty: 6,
        unitPrice: 8.0,
        totalPrice: 48.0,
      ),
    ],
    deliveryAddress: const DeliveryAddress(
      fullAddress: 'Cumhuriyet Cad. No:12',
      district: 'Bandirma',
      city: 'Balikesir',
    ),
    paymentMethod: PaymentMethod.cardOnDelivery,
    subtotal: 48.0,
    discount: 0,
    total: 48.0,
    assignedTo: assignedTo,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Durum gecisi simulate eden yardimci (Firestore olmadan)
// Gercekte updateOrderStatus Firestore'a yazar; burada model kopyalama
// ile ayni gozlemlenen sonucu test ederiz.
// ---------------------------------------------------------------------------
OrderModel _simulateStatusUpdate(
  OrderModel order,
  OrderStatus newStatus,
  String updatedBy,
) {
  final newHistory = StatusHistory(
    status: newStatus,
    timestamp: DateTime(2026, 5, 4, 14, 0),
    by: updatedBy,
  );
  return OrderModel(
    id: order.id,
    orderNo: order.orderNo,
    customerId: order.customerId,
    customerName: order.customerName,
    customerPhone: order.customerPhone,
    source: order.source,
    createdBy: order.createdBy,
    status: newStatus,
    statusHistory: [...order.statusHistory, newHistory],
    items: order.items,
    deliveryAddress: order.deliveryAddress,
    paymentMethod: order.paymentMethod,
    paymentStatus: order.paymentStatus,
    assignedTo: order.assignedTo,
    subtotal: order.subtotal,
    discount: order.discount,
    total: order.total,
    notes: order.notes,
    createdAt: order.createdAt,
    updatedAt: DateTime(2026, 5, 4, 14, 0),
  );
}

void main() {
  // =========================================================================
  // OrderStatus enum deger testleri
  // =========================================================================
  group('OrderStatus enum degerleri', () {
    test('OrderStatus.delivered.value == "delivered"', () {
      expect(OrderStatus.delivered.value, 'delivered');
    });

    test('OrderStatus.onTheWay.value == "on_the_way"', () {
      expect(OrderStatus.onTheWay.value, 'on_the_way');
    });

    test('OrderStatus.pending.value == "pending"', () {
      expect(OrderStatus.pending.value, 'pending');
    });

    test('OrderStatus.confirmed.value == "confirmed"', () {
      expect(OrderStatus.confirmed.value, 'confirmed');
    });

    test('OrderStatus.preparing.value == "preparing"', () {
      expect(OrderStatus.preparing.value, 'preparing');
    });

    test('OrderStatus.cancelled.value == "cancelled"', () {
      expect(OrderStatus.cancelled.value, 'cancelled');
    });
  });

  // =========================================================================
  // OrderStatus.fromString parse testleri
  // =========================================================================
  group('OrderStatus.fromString parse', () {
    test('"on_the_way" dogru parse ediyor', () {
      expect(OrderStatus.fromString('on_the_way'), OrderStatus.onTheWay);
    });

    test('"delivered" dogru parse ediyor', () {
      expect(OrderStatus.fromString('delivered'), OrderStatus.delivered);
    });

    test('"pending" dogru parse ediyor', () {
      expect(OrderStatus.fromString('pending'), OrderStatus.pending);
    });

    test('"confirmed" dogru parse ediyor', () {
      expect(OrderStatus.fromString('confirmed'), OrderStatus.confirmed);
    });

    test('"preparing" dogru parse ediyor', () {
      expect(OrderStatus.fromString('preparing'), OrderStatus.preparing);
    });

    test('"cancelled" dogru parse ediyor', () {
      expect(OrderStatus.fromString('cancelled'), OrderStatus.cancelled);
    });

    test('bilinmeyen string "pending" donduruyor', () {
      expect(OrderStatus.fromString('unknown_status'), OrderStatus.pending);
    });

    test('bos string "pending" donduruyor', () {
      expect(OrderStatus.fromString(''), OrderStatus.pending);
    });
  });

  // =========================================================================
  // onTheWay -> delivered gecisi
  // =========================================================================
  group('onTheWay -> delivered gecisi', () {
    test('onTheWay siparisi delivered yapilabiliyor', () {
      final order = _makeOrder(status: OrderStatus.onTheWay);
      final updated = _simulateStatusUpdate(
        order,
        OrderStatus.delivered,
        'delivery_uid',
      );
      expect(updated.status, OrderStatus.delivered);
    });

    test('guncelleme sonrasi id degismiyor', () {
      final order = _makeOrder(id: 'order_abc', status: OrderStatus.onTheWay);
      final updated = _simulateStatusUpdate(
          order, OrderStatus.delivered, 'delivery_uid');
      expect(updated.id, 'order_abc');
    });

    test('guncelleme sonrasi total degismiyor', () {
      final order = _makeOrder(status: OrderStatus.onTheWay);
      final updated = _simulateStatusUpdate(
          order, OrderStatus.delivered, 'delivery_uid');
      expect(updated.total, order.total);
    });

    test('canDeliver: onTheWay iken true', () {
      final order = _makeOrder(status: OrderStatus.onTheWay);
      final canDeliver = order.status == OrderStatus.onTheWay;
      expect(canDeliver, isTrue);
    });

    test('canDeliver: delivered iken false', () {
      final order = _makeOrder(status: OrderStatus.delivered);
      final canDeliver = order.status == OrderStatus.onTheWay;
      expect(canDeliver, isFalse);
    });

    test('canDeliver: pending iken false', () {
      final order = _makeOrder(status: OrderStatus.pending);
      final canDeliver = order.status == OrderStatus.onTheWay;
      expect(canDeliver, isFalse);
    });

    test('canDeliver: preparing iken false', () {
      final order = _makeOrder(status: OrderStatus.preparing);
      final canDeliver = order.status == OrderStatus.onTheWay;
      expect(canDeliver, isFalse);
    });

    test('canDeliver: cancelled iken false', () {
      final order = _makeOrder(status: OrderStatus.cancelled);
      final canDeliver = order.status == OrderStatus.onTheWay;
      expect(canDeliver, isFalse);
    });
  });

  // =========================================================================
  // StatusHistory listesi buyuyor
  // =========================================================================
  group('statusHistory guncelleme', () {
    test('yeni entry eklenince liste boyutu 1 artiyor', () {
      final initial = [
        _makeHistory(status: OrderStatus.pending),
        _makeHistory(status: OrderStatus.onTheWay),
      ];
      final order = _makeOrder(
        status: OrderStatus.onTheWay,
        statusHistory: initial,
      );
      expect(order.statusHistory.length, 2);

      final updated = _simulateStatusUpdate(
          order, OrderStatus.delivered, 'delivery_uid');
      expect(updated.statusHistory.length, 3);
    });

    test('yeni entry dogru status iceriyor', () {
      final order = _makeOrder(
        status: OrderStatus.onTheWay,
        statusHistory: [_makeHistory(status: OrderStatus.onTheWay)],
      );
      final updated = _simulateStatusUpdate(
          order, OrderStatus.delivered, 'delivery_uid');
      final lastEntry = updated.statusHistory.last;
      expect(lastEntry.status, OrderStatus.delivered);
    });

    test('yeni entry dogru "by" bilgisini iceriyor', () {
      final order = _makeOrder(
        status: OrderStatus.onTheWay,
        statusHistory: [_makeHistory(status: OrderStatus.onTheWay)],
      );
      final updated = _simulateStatusUpdate(
          order, OrderStatus.delivered, 'delivery_user_99');
      expect(updated.statusHistory.last.by, 'delivery_user_99');
    });

    test('onceki history entryleri korunuyor', () {
      final initial = [
        _makeHistory(status: OrderStatus.pending, by: 'system'),
        _makeHistory(status: OrderStatus.confirmed, by: 'admin_1'),
        _makeHistory(status: OrderStatus.onTheWay, by: 'admin_1'),
      ];
      final order = _makeOrder(
        status: OrderStatus.onTheWay,
        statusHistory: initial,
      );
      final updated = _simulateStatusUpdate(
          order, OrderStatus.delivered, 'delivery_uid');
      // Onceki 3 entry hala var
      expect(updated.statusHistory[0].status, OrderStatus.pending);
      expect(updated.statusHistory[1].status, OrderStatus.confirmed);
      expect(updated.statusHistory[2].status, OrderStatus.onTheWay);
      expect(updated.statusHistory[3].status, OrderStatus.delivered);
    });

    test('StatusHistory.toMap dogru status string yazar', () {
      final entry = _makeHistory(status: OrderStatus.delivered, by: 'drv1');
      final map = entry.toMap();
      expect(map['status'], 'delivered');
      expect(map['by'], 'drv1');
    });

    test('StatusHistory.fromMap on_the_way dogru parse ediyor', () {
      final map = {
        'status': 'on_the_way',
        'by': 'delivery_user',
        'timestamp': null, // fromMap bunu DateTime.now() ile kapsar
      };
      final entry = StatusHistory.fromMap(map);
      expect(entry.status, OrderStatus.onTheWay);
      expect(entry.by, 'delivery_user');
    });
  });

  // =========================================================================
  // DeliveryAddress model testleri (teslimat feature icin)
  // =========================================================================
  group('DeliveryAddress', () {
    test('koordinatli adres dogru parse ediliyor', () {
      final map = {
        'fullAddress': 'Ataturk Bulvari No:10',
        'district': 'Altieylul',
        'city': 'Balikesir',
        'lat': 39.6484,
        'lng': 27.8826,
        'notes': 'Kapi kodu: 1234',
      };
      final addr = DeliveryAddress.fromMap(map);
      expect(addr.lat, 39.6484);
      expect(addr.lng, 27.8826);
      expect(addr.notes, 'Kapi kodu: 1234');
    });

    test('koordinatsiz adres null lat/lng ile parse ediliyor', () {
      final map = {
        'fullAddress': 'Cumhuriyet Mah. No:5',
        'district': 'Bigadic',
        'city': 'Balikesir',
      };
      final addr = DeliveryAddress.fromMap(map);
      expect(addr.lat, isNull);
      expect(addr.lng, isNull);
    });

    test('koordinat varligina gore navigate butonu aktif olur', () {
      const addrWithCoords = DeliveryAddress(
        fullAddress: 'Test Cad.',
        district: 'Test',
        city: 'Balikesir',
        lat: 39.6,
        lng: 27.8,
      );
      final canNavigate = addrWithCoords.lat != null ||
          addrWithCoords.fullAddress.isNotEmpty;
      expect(canNavigate, isTrue);
    });

    test('koordinatsiz adresde fullAddress dolu ise navigate aktif', () {
      const addrNoCoords = DeliveryAddress(
        fullAddress: 'Herhangi Cad. No:1',
        district: 'Merkez',
        city: 'Balikesir',
      );
      final canNavigate =
          addrNoCoords.lat != null || addrNoCoords.fullAddress.isNotEmpty;
      expect(canNavigate, isTrue);
    });

    test('fullAddress bos ve koordinat yok ise navigate mantiksal olarak disable', () {
      const addrEmpty = DeliveryAddress(
        fullAddress: '',
        district: 'Merkez',
        city: 'Balikesir',
      );
      final canNavigate =
          addrEmpty.lat != null || addrEmpty.fullAddress.isNotEmpty;
      expect(canNavigate, isFalse);
    });
  });
}
