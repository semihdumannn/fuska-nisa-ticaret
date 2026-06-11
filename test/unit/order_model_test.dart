// order_model_test.dart
//
// OrderModel, OrderItem, DeliveryAddress, StatusHistory icin unit testler.
// Firestore bagimliligi olmadigi icin mock DocumentSnapshot kullanilamaz —
// fromFirestore yerine veri katmani (fromMap/toMap) ve dogrudan constructor
// uzerinden test yapilir; ayni mantik fromFirestore'u da kapsar cunku
// fromFirestore icinde de ayni field erisimi kullanilmaktadir.
//
// Testler icin FakeDocumentSnapshot yardimci sinifi olusturuldu; boylece
// cloud_firestore mock paketi olmadan fromFirestore arayuzu de test edilebiliyor.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';

// ---------------------------------------------------------------------------
// Yardimci: Minimal OrderItem olusturur
// ---------------------------------------------------------------------------
OrderItem _makeItem({
  String productId = 'prod1',
  String productName = 'Damacana Su',
  int qty = 2,
  double unitPrice = 45.0,
}) {
  return OrderItem(
    productId: productId,
    productName: productName,
    qty: qty,
    unitPrice: unitPrice,
    totalPrice: unitPrice * qty,
  );
}

// ---------------------------------------------------------------------------
// Yardimci: Minimal DeliveryAddress olusturur
// ---------------------------------------------------------------------------
DeliveryAddress _makeAddress({
  String fullAddress = 'Ataturk Cad. No:1',
  String district = 'Merkez',
  String city = 'Balikesir',
}) {
  return DeliveryAddress(
    fullAddress: fullAddress,
    district: district,
    city: city,
  );
}

// ---------------------------------------------------------------------------
// Yardimci: Minimal OrderModel olusturur
// ---------------------------------------------------------------------------
OrderModel _makeOrder({
  String id = 'order1',
  String orderNo = 'NST-2026-00001',
  String customerId = 'user1',
  OrderStatus status = OrderStatus.pending,
  List<OrderItem>? items,
  List<StatusHistory>? statusHistory,
  PaymentMethod paymentMethod = PaymentMethod.cash,
  OrderSource source = OrderSource.customerApp,
  double subtotal = 90.0,
  double discount = 0.0,
  double total = 90.0,
}) {
  final now = DateTime(2026, 5, 1, 10, 0, 0);
  return OrderModel(
    id: id,
    orderNo: orderNo,
    customerId: customerId,
    customerName: 'Test Musteri',
    customerPhone: '+905551234567',
    source: source,
    createdBy: customerId,
    status: status,
    statusHistory: statusHistory ?? [],
    items: items ?? [_makeItem()],
    deliveryAddress: _makeAddress(),
    paymentMethod: paymentMethod,
    subtotal: subtotal,
    discount: discount,
    total: total,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// FakeDocumentSnapshot — cloud_firestore mock paketi gerekmeden fromFirestore
// cagrilabilmesini saglar.
// ---------------------------------------------------------------------------
// ignore: subtype_of_sealed_class
class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final String _id;
  final Map<String, dynamic> _data;

  _FakeDocumentSnapshot({required String id, required Map<String, dynamic> data})
      : _id = id,
        _data = data;

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  bool get exists => true;

  // Kalan DocumentSnapshot uyeleri: test icin gereksiz, stub olarak bırakıldı.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // =========================================================================
  // OrderItem testleri
  // =========================================================================
  group('OrderItem', () {
    test('fromMap tum alanlari dogru parse eder', () {
      final map = {
        'productId': 'prod-123',
        'productName': 'Soda 1L',
        'imageUrl': 'https://example.com/soda.jpg',
        'qty': 3,
        'unitPrice': 12.5,
        'totalPrice': 37.5,
      };

      final item = OrderItem.fromMap(map);

      expect(item.productId, 'prod-123');
      expect(item.productName, 'Soda 1L');
      expect(item.imageUrl, 'https://example.com/soda.jpg');
      expect(item.qty, 3);
      expect(item.unitPrice, 12.5);
      expect(item.totalPrice, 37.5);
    });

    test('fromMap eksik alanlarda default degerler kullanilir', () {
      final item = OrderItem.fromMap({});
      expect(item.productId, '');
      expect(item.productName, '');
      expect(item.qty, 0);
      expect(item.unitPrice, 0.0);
      expect(item.totalPrice, 0.0);
      expect(item.imageUrl, isNull);
    });

    test('toMap round-trip: fromMap(toMap()) == orijinal', () {
      final original = _makeItem(productId: 'p9', qty: 5, unitPrice: 20.0);
      final roundTrip = OrderItem.fromMap(original.toMap());
      expect(roundTrip.productId, original.productId);
      expect(roundTrip.qty, original.qty);
      expect(roundTrip.unitPrice, original.unitPrice);
      expect(roundTrip.totalPrice, original.totalPrice);
    });

    test('toMap imageUrl null oldugunda map icinde null deger bulunur', () {
      final item = _makeItem();
      final map = item.toMap();
      expect(map.containsKey('imageUrl'), true);
      expect(map['imageUrl'], isNull);
    });
  });

  // =========================================================================
  // DeliveryAddress testleri
  // =========================================================================
  group('DeliveryAddress', () {
    test('fromMap tum alanlari parse eder', () {
      final map = {
        'fullAddress': 'Cumhuriyet Mah. No:5',
        'district': 'Bandirma',
        'city': 'Balikesir',
        'lat': 40.35,
        'lng': 27.97,
        'notes': 'Yan kapidan girin',
      };

      final address = DeliveryAddress.fromMap(map);

      expect(address.fullAddress, 'Cumhuriyet Mah. No:5');
      expect(address.district, 'Bandirma');
      expect(address.city, 'Balikesir');
      expect(address.lat, 40.35);
      expect(address.lng, 27.97);
      expect(address.notes, 'Yan kapidan girin');
    });

    test('fromMap eksik alanlarda city default Balikesir olur', () {
      final address = DeliveryAddress.fromMap({});
      expect(address.city, 'Balıkesir');
      expect(address.lat, isNull);
      expect(address.lng, isNull);
      expect(address.notes, isNull);
    });

    test('toMap round-trip: fromMap(toMap()) esit deger uretir', () {
      final original = _makeAddress(
        fullAddress: 'Test Cad. No:10',
        district: 'Karesi',
      );
      final roundTrip = DeliveryAddress.fromMap(original.toMap());
      expect(roundTrip.fullAddress, original.fullAddress);
      expect(roundTrip.district, original.district);
      expect(roundTrip.city, original.city);
    });
  });

  // =========================================================================
  // StatusHistory testleri
  // =========================================================================
  group('StatusHistory', () {
    test('fromMap status string dogruca OrderStatus enum degerine donusur', () {
      final ts = Timestamp.fromDate(DateTime(2026, 5, 1, 12, 0));
      final history = StatusHistory.fromMap({
        'status': 'on_the_way',
        'timestamp': ts,
        'by': 'driver1',
      });

      expect(history.status, OrderStatus.onTheWay);
      expect(history.by, 'driver1');
      expect(history.timestamp, DateTime(2026, 5, 1, 12, 0));
    });

    test('fromMap bilinmeyen status pending olarak gelir', () {
      final history = StatusHistory.fromMap({
        'status': 'unknown_status',
        'timestamp': Timestamp.now(),
        'by': 'system',
      });
      expect(history.status, OrderStatus.pending);
    });

    test('fromMap timestamp null oldugunda DateTime.now() civari deger alir', () {
      final before = DateTime.now();
      final history = StatusHistory.fromMap({
        'status': 'confirmed',
        'by': 'admin',
        // timestamp eksik
      });
      final after = DateTime.now();
      expect(
        history.timestamp.isAfter(before.subtract(const Duration(seconds: 1))),
        true,
      );
      expect(
        history.timestamp.isBefore(after.add(const Duration(seconds: 1))),
        true,
      );
    });

    test('toMap status degerini value string olarak yazar', () {
      final history = StatusHistory(
        status: OrderStatus.preparing,
        timestamp: DateTime(2026, 5, 1),
        by: 'admin',
      );
      final map = history.toMap();
      expect(map['status'], 'preparing');
      expect(map['by'], 'admin');
      expect(map['timestamp'], isA<Timestamp>());
    });

    test('tum siparis durumlari icin fromMap round-trip dogru calisir', () {
      final statuses = {
        'pending': OrderStatus.pending,
        'confirmed': OrderStatus.confirmed,
        'preparing': OrderStatus.preparing,
        'on_the_way': OrderStatus.onTheWay,
        'delivered': OrderStatus.delivered,
        'cancelled': OrderStatus.cancelled,
      };

      for (final entry in statuses.entries) {
        final history = StatusHistory.fromMap({
          'status': entry.key,
          'timestamp': Timestamp.now(),
          'by': 'system',
        });
        expect(history.status, entry.value,
            reason: '${entry.key} dogru enum degerine donusmeliydi');
      }
    });
  });

  // =========================================================================
  // OrderModel testleri
  // =========================================================================
  group('OrderModel', () {
    test('totalItems: items listesindeki tum qty degerleri toplanir', () {
      final order = _makeOrder(
        items: [
          _makeItem(qty: 3),
          _makeItem(productId: 'prod2', qty: 2),
          _makeItem(productId: 'prod3', qty: 5),
        ],
      );
      expect(order.totalItems, 10);
    });

    test('totalItems: items bos oldugunda 0 doner', () {
      final order = _makeOrder(items: []);
      expect(order.totalItems, 0);
    });

    test('toFirestore: zorunlu alanlar doğru serialize edilir', () {
      final order = _makeOrder(
        id: 'ord99',
        orderNo: 'NST-2026-99999',
        status: OrderStatus.confirmed,
        paymentMethod: PaymentMethod.cardOnDelivery,
      );
      final map = order.toFirestore();

      expect(map['orderNo'], 'NST-2026-99999');
      expect(map['customerId'], 'user1');
      expect(map['status'], 'confirmed');
      expect(map['paymentMethod'], 'card_on_delivery');
      expect(map['subtotal'], 90.0);
      expect(map['total'], 90.0);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('toFirestore: items listesi dogru map\'e donusur', () {
      final order = _makeOrder(items: [
        _makeItem(productId: 'p1', qty: 3, unitPrice: 10.0),
        _makeItem(productId: 'p2', qty: 1, unitPrice: 25.0),
      ]);
      final map = order.toFirestore();
      final itemsList = map['items'] as List<dynamic>;
      expect(itemsList.length, 2);
      expect((itemsList[0] as Map)['productId'], 'p1');
      expect((itemsList[1] as Map)['productId'], 'p2');
    });

    test('toFirestore: statusHistory listesi dogru map\'e donusur', () {
      final history = [
        StatusHistory(
          status: OrderStatus.pending,
          timestamp: DateTime(2026, 5, 1),
          by: 'system',
        ),
        StatusHistory(
          status: OrderStatus.confirmed,
          timestamp: DateTime(2026, 5, 1, 1),
          by: 'admin1',
        ),
      ];
      final order = _makeOrder(statusHistory: history);
      final map = order.toFirestore();
      final historyList = map['statusHistory'] as List<dynamic>;
      expect(historyList.length, 2);
      expect((historyList[0] as Map)['status'], 'pending');
      expect((historyList[1] as Map)['status'], 'confirmed');
    });

    test('toFirestore: estimatedDelivery null oldugunda null yazilir', () {
      final order = _makeOrder();
      final map = order.toFirestore();
      expect(map['estimatedDelivery'], isNull);
      expect(map['deliveredAt'], isNull);
    });

    test('toFirestore: estimatedDelivery dolu oldugunda Timestamp yazilir', () {
      final eta = DateTime(2026, 5, 2, 14, 0);
      final order = OrderModel(
        id: 'o1',
        orderNo: 'NST-2026-00001',
        customerId: 'u1',
        customerName: 'Musteri',
        customerPhone: '+905551234567',
        source: OrderSource.customerApp,
        createdBy: 'u1',
        status: OrderStatus.preparing,
        statusHistory: const [],
        items: [_makeItem()],
        deliveryAddress: _makeAddress(),
        paymentMethod: PaymentMethod.cash,
        subtotal: 90.0,
        total: 90.0,
        estimatedDelivery: eta,
        createdAt: DateTime(2026, 5, 1),
        updatedAt: DateTime(2026, 5, 1),
      );
      final map = order.toFirestore();
      expect(map['estimatedDelivery'], isA<Timestamp>());
    });

    test('fromFirestore: FakeDocumentSnapshot ile tum alanlar parse edilir', () {
      final createdAt = DateTime(2026, 5, 1, 9, 0, 0);
      final updatedAt = DateTime(2026, 5, 1, 10, 0, 0);

      final fakeDoc = _FakeDocumentSnapshot(
        id: 'doc-abc',
        data: {
          'orderNo': 'NST-2026-55555',
          'customerId': 'cust99',
          'customerName': 'Ali Veli',
          'customerPhone': '+905559998877',
          'source': 'customer_app',
          'createdBy': 'cust99',
          'status': 'preparing',
          'statusHistory': [
            {
              'status': 'pending',
              'timestamp': Timestamp.fromDate(createdAt),
              'by': 'system',
            },
          ],
          'items': [
            {
              'productId': 'prod-x',
              'productName': 'Maden Suyu',
              'qty': 6,
              'unitPrice': 8.0,
              'totalPrice': 48.0,
            },
          ],
          'deliveryAddress': {
            'fullAddress': 'Izmir Cad. No:7',
            'district': 'Karesi',
            'city': 'Balikesir',
          },
          'paymentMethod': 'cash',
          'paymentStatus': 'pending',
          'subtotal': 48.0,
          'discount': 0.0,
          'total': 48.0,
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': Timestamp.fromDate(updatedAt),
        },
      );

      final order = OrderModel.fromFirestore(fakeDoc);

      expect(order.id, 'doc-abc');
      expect(order.orderNo, 'NST-2026-55555');
      expect(order.customerId, 'cust99');
      expect(order.customerName, 'Ali Veli');
      expect(order.status, OrderStatus.preparing);
      expect(order.source, OrderSource.customerApp);
      expect(order.paymentMethod, PaymentMethod.cash);
      expect(order.statusHistory.length, 1);
      expect(order.statusHistory.first.status, OrderStatus.pending);
      expect(order.items.length, 1);
      expect(order.items.first.productId, 'prod-x');
      expect(order.items.first.qty, 6);
      expect(order.totalItems, 6);
      expect(order.subtotal, 48.0);
      expect(order.total, 48.0);
      expect(order.createdAt, createdAt);
      expect(order.updatedAt, updatedAt);
    });

    test('fromFirestore: bilinmeyen source fieldAgentApp yerine customerApp gelir', () {
      final fakeDoc = _FakeDocumentSnapshot(
        id: 'x',
        data: {
          'source': 'unknown_source',
          'orderNo': '',
          'customerId': '',
          'customerName': '',
          'customerPhone': '',
          'createdBy': '',
          'status': 'pending',
          'statusHistory': <dynamic>[],
          'items': <dynamic>[],
          'deliveryAddress': <String, dynamic>{},
          'paymentMethod': 'cash',
          'subtotal': 0.0,
          'total': 0.0,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      );
      final order = OrderModel.fromFirestore(fakeDoc);
      expect(order.source, OrderSource.customerApp);
    });

    test('fromFirestore: bilinmeyen paymentMethod cash olarak gelir', () {
      final fakeDoc = _FakeDocumentSnapshot(
        id: 'x',
        data: {
          'orderNo': '',
          'customerId': '',
          'customerName': '',
          'customerPhone': '',
          'source': 'customer_app',
          'createdBy': '',
          'status': 'pending',
          'statusHistory': <dynamic>[],
          'items': <dynamic>[],
          'deliveryAddress': <String, dynamic>{},
          'paymentMethod': 'bitcoin', // bilinmeyen
          'subtotal': 0.0,
          'total': 0.0,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      );
      final order = OrderModel.fromFirestore(fakeDoc);
      expect(order.paymentMethod, PaymentMethod.cash);
    });
  });

  // =========================================================================
  // OrderStatus enum testleri
  // =========================================================================
  group('OrderStatus', () {
    test('displayName her durum icin Turkce deger doner', () {
      expect(OrderStatus.pending.displayName, 'Beklemede');
      expect(OrderStatus.confirmed.displayName, 'Onaylandı');
      expect(OrderStatus.preparing.displayName, 'Hazırlanıyor');
      expect(OrderStatus.onTheWay.displayName, 'Yolda');
      expect(OrderStatus.delivered.displayName, 'Teslim Edildi');
      expect(OrderStatus.cancelled.displayName, 'İptal Edildi');
    });

    test('value her durum icin dogru string deger doner', () {
      expect(OrderStatus.pending.value, 'pending');
      expect(OrderStatus.confirmed.value, 'confirmed');
      expect(OrderStatus.preparing.value, 'preparing');
      expect(OrderStatus.onTheWay.value, 'on_the_way');
      expect(OrderStatus.delivered.value, 'delivered');
      expect(OrderStatus.cancelled.value, 'cancelled');
    });

    test('fromString tum tanimli degerleri dogru enum\'a donusturur', () {
      expect(OrderStatus.fromString('pending'), OrderStatus.pending);
      expect(OrderStatus.fromString('confirmed'), OrderStatus.confirmed);
      expect(OrderStatus.fromString('preparing'), OrderStatus.preparing);
      expect(OrderStatus.fromString('on_the_way'), OrderStatus.onTheWay);
      expect(OrderStatus.fromString('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromString('cancelled'), OrderStatus.cancelled);
    });

    test('fromString bilinmeyen deger icin pending doner', () {
      expect(OrderStatus.fromString(''), OrderStatus.pending);
      expect(OrderStatus.fromString('random_value'), OrderStatus.pending);
    });
  });

  // =========================================================================
  // PaymentMethod enum testleri
  // =========================================================================
  group('PaymentMethod', () {
    test('displayName her odeme yontemi icin Turkce deger doner', () {
      expect(PaymentMethod.cash.displayName, 'Kapıda Nakit');
      expect(PaymentMethod.cardOnDelivery.displayName, 'Kapıda Kredi Kartı');
    });

    test('value her odeme yontemi icin dogru string doner', () {
      expect(PaymentMethod.cash.value, 'cash');
      expect(PaymentMethod.cardOnDelivery.value, 'card_on_delivery');
    });
  });

  // =========================================================================
  // OrderSource enum testleri
  // =========================================================================
  group('OrderSource', () {
    test('value her siparis kaynagi icin dogru string doner', () {
      expect(OrderSource.customerApp.value, 'customer_app');
      expect(OrderSource.fieldAgent.value, 'field_agent');
      expect(OrderSource.phone.value, 'phone');
    });
  });
}
