// delivery_order_filter_test.dart
//
// Teslimat ekrani siparis filtreleme ve istatistik hesaplama testleri.
// _RouteStatsBar widget'indaki hesaplamalar model seviyesinde dogrulaniyor.
// Firebase/Riverpod bagimliligi yok; saf Dart logic test edilir.

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
  double total = 120.0,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime(2026, 5, 4, 10, 0);
  return OrderModel(
    id: id,
    orderNo: orderNo,
    customerId: 'cust1',
    customerName: 'Ali Veli',
    customerPhone: '05320001122',
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
        qty: 3,
        unitPrice: 40.0,
        totalPrice: 120.0,
      ),
    ],
    deliveryAddress: const DeliveryAddress(
      fullAddress: 'Istasyon Cad. No:5',
      district: 'Kepsut',
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
// _RouteStatsBar hesaplama mantigi (ekrandan ayiklandi, pure function)
// ---------------------------------------------------------------------------
int _countRemaining(List<OrderModel> orders) {
  return orders
      .where((o) =>
          o.status != OrderStatus.delivered &&
          o.status != OrderStatus.cancelled)
      .length;
}

int _countDelivered(List<OrderModel> orders) {
  return orders.where((o) => o.status == OrderStatus.delivered).length;
}

/// Tahmini sure: kalan siparis basi 15 dakika
int _estimatedMinutes(int remaining) => remaining * 15;

String _estimatedLabel(int remaining) {
  final minutes = _estimatedMinutes(remaining);
  if (remaining == 0) return '0 dk';
  if (minutes >= 60) {
    return '${(minutes / 60).floor()} sa ${minutes % 60} dk';
  }
  return '$minutes dk';
}

// ---------------------------------------------------------------------------
// Bugunun siparisleri filtresi
// ---------------------------------------------------------------------------
List<OrderModel> _filterToday(List<OrderModel> orders, DateTime today) {
  return orders.where((o) {
    final d = o.createdAt;
    return d.year == today.year &&
        d.month == today.month &&
        d.day == today.day;
  }).toList();
}

void main() {
  final today = DateTime(2026, 5, 4);
  final yesterday = DateTime(2026, 5, 3);
  final tomorrow = DateTime(2026, 5, 5);

  // =========================================================================
  // Bugunun siparisleri filtresi
  // =========================================================================
  group('_filterToday — bugunun siparisleri', () {
    test('bugune ait siparis listeye giriyor', () {
      final orders = [
        _makeOrder(id: 'o1', createdAt: DateTime(2026, 5, 4, 8, 30)),
      ];
      final result = _filterToday(orders, today);
      expect(result.length, 1);
    });

    test('dunkü siparis filtreleniyor', () {
      final orders = [
        _makeOrder(id: 'o1', createdAt: DateTime(2026, 5, 3, 22, 0)),
      ];
      final result = _filterToday(orders, today);
      expect(result.length, 0);
    });

    test('yarinki siparis filtreleniyor', () {
      final orders = [
        _makeOrder(id: 'o1', createdAt: tomorrow),
      ];
      final result = _filterToday(orders, today);
      expect(result.length, 0);
    });

    test('karisik tarihli listede sadece bugunkiler', () {
      final orders = [
        _makeOrder(id: 'o1', createdAt: DateTime(2026, 5, 4, 7, 0)),
        _makeOrder(id: 'o2', createdAt: DateTime(2026, 5, 4, 14, 0)),
        _makeOrder(id: 'o3', createdAt: yesterday),
        _makeOrder(id: 'o4', createdAt: tomorrow),
      ];
      final result = _filterToday(orders, today);
      expect(result.length, 2);
      expect(result.map((o) => o.id).toSet(), {'o1', 'o2'});
    });

    test('bos listede bos donus', () {
      final result = _filterToday([], today);
      expect(result, isEmpty);
    });

    test('gece yarisi saat 23:59 bugune dahil', () {
      final orders = [
        _makeOrder(id: 'o1', createdAt: DateTime(2026, 5, 4, 23, 59)),
      ];
      final result = _filterToday(orders, today);
      expect(result.length, 1);
    });
  });

  // =========================================================================
  // Teslim edilmis sayisi
  // =========================================================================
  group('_countDelivered — teslim edilmis sayisi', () {
    test('delivered siparis sayilmasi dogru', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.delivered),
        _makeOrder(id: 'o2', status: OrderStatus.onTheWay),
      ];
      expect(_countDelivered(orders), 1);
    });

    test('hicbiri delivered degilse 0 donuyor', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.onTheWay),
        _makeOrder(id: 'o2', status: OrderStatus.preparing),
      ];
      expect(_countDelivered(orders), 0);
    });

    test('hepsi delivered ise toplam sayi donuyor', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.delivered),
        _makeOrder(id: 'o2', status: OrderStatus.delivered),
        _makeOrder(id: 'o3', status: OrderStatus.delivered),
      ];
      expect(_countDelivered(orders), 3);
    });

    test('bos listede 0 donuyor', () {
      expect(_countDelivered([]), 0);
    });

    test('cancelled siparisler delivered sayilmiyor', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.cancelled),
        _makeOrder(id: 'o2', status: OrderStatus.delivered),
      ];
      expect(_countDelivered(orders), 1);
    });
  });

  // =========================================================================
  // Kalan siparis sayisi (teslim edilmemis)
  // =========================================================================
  group('_countRemaining — kalan siparis sayisi', () {
    test('onTheWay siparis kalan sayilir', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.onTheWay),
      ];
      expect(_countRemaining(orders), 1);
    });

    test('delivered kalan sayilmaz', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.delivered),
        _makeOrder(id: 'o2', status: OrderStatus.onTheWay),
      ];
      expect(_countRemaining(orders), 1);
    });

    test('cancelled kalan sayilmaz', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.cancelled),
        _makeOrder(id: 'o2', status: OrderStatus.onTheWay),
        _makeOrder(id: 'o3', status: OrderStatus.preparing),
      ];
      // cancelled disinda hepsi kalan
      expect(_countRemaining(orders), 2);
    });

    test('hepsi delivered ise kalan 0', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.delivered),
        _makeOrder(id: 'o2', status: OrderStatus.delivered),
      ];
      expect(_countRemaining(orders), 0);
    });

    test('bos listede kalan 0', () {
      expect(_countRemaining([]), 0);
    });

    test('karisik durumlarda dogru kalan sayisi', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.onTheWay),
        _makeOrder(id: 'o2', status: OrderStatus.onTheWay),
        _makeOrder(id: 'o3', status: OrderStatus.delivered),
        _makeOrder(id: 'o4', status: OrderStatus.cancelled),
        _makeOrder(id: 'o5', status: OrderStatus.preparing),
      ];
      // o1, o2, o5 kalan (delivered ve cancelled haric)
      expect(_countRemaining(orders), 3);
    });
  });

  // =========================================================================
  // Tahmini sure hesabi (kalan x 15 dakika)
  // =========================================================================
  group('_estimatedLabel — tahmini sure hesabi', () {
    test('kalan 0 ise "0 dk" donuyor', () {
      expect(_estimatedLabel(0), '0 dk');
    });

    test('kalan 1 ise "15 dk" donuyor', () {
      expect(_estimatedLabel(1), '15 dk');
    });

    test('kalan 3 ise "45 dk" donuyor', () {
      expect(_estimatedLabel(3), '45 dk');
    });

    test('kalan 4 ise "1 sa 0 dk" donuyor (60 dakika)', () {
      expect(_estimatedLabel(4), '1 sa 0 dk');
    });

    test('kalan 5 ise "1 sa 15 dk" donuyor (75 dakika)', () {
      expect(_estimatedLabel(5), '1 sa 15 dk');
    });

    test('kalan 8 ise "2 sa 0 dk" donuyor (120 dakika)', () {
      expect(_estimatedLabel(8), '2 sa 0 dk');
    });

    test('kalan 10 ise "2 sa 30 dk" donuyor (150 dakika)', () {
      expect(_estimatedLabel(10), '2 sa 30 dk');
    });

    test('tahmini dakika hesabi dogru (kalan * 15)', () {
      expect(_estimatedMinutes(6), 90);
      expect(_estimatedMinutes(2), 30);
      expect(_estimatedMinutes(0), 0);
    });
  });

  // =========================================================================
  // Toplam / Kalan / Teslim tutarlilik kontrolu
  // =========================================================================
  group('istatistik tutarlilik', () {
    test('toplam = teslim + kalan (cancelled yok)', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.onTheWay),
        _makeOrder(id: 'o2', status: OrderStatus.delivered),
        _makeOrder(id: 'o3', status: OrderStatus.delivered),
      ];
      final total = orders.length;
      final delivered = _countDelivered(orders);
      final remaining = _countRemaining(orders);
      expect(delivered + remaining, total);
    });

    test('cancelled ile total != delivered + remaining', () {
      final orders = [
        _makeOrder(id: 'o1', status: OrderStatus.onTheWay),
        _makeOrder(id: 'o2', status: OrderStatus.delivered),
        _makeOrder(id: 'o3', status: OrderStatus.cancelled),
      ];
      final delivered = _countDelivered(orders);
      final remaining = _countRemaining(orders);
      // cancelled toplama dahil degil
      expect(delivered + remaining, 2);
      expect(orders.length, 3);
    });
  });
}
