// order_total_calculation_test.dart
//
// Siparis toplam hesaplama unit testleri.
// VariantModel + OrderItem + OrderModel ve CartItem/CartModel uzerinden
// fiyat hesaplama mantigi kapsamli sekilde test edilir.
// Firebase / Firestore bagimliligi yoktur; saf Dart constructor kullanilir.

import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/models/variant_model.dart';
import 'package:nisa_ticaret/features/cart/data/models/cart_model.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';

// ---------------------------------------------------------------------------
// Yardimci: Minimal ProductModel olusturur (meta veri, fiyat/stok yok)
// ---------------------------------------------------------------------------
ProductModel _makeProduct({
  String id = 'p1',
  String name = 'Test Urun',
  bool isActive = true,
}) {
  final now = DateTime(2026, 1, 1);
  return ProductModel(
    id: id,
    name: name,
    description: 'Test aciklama',
    categoryIds: ['cat1'],
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Yardimci: Minimal VariantModel olusturur
// ---------------------------------------------------------------------------
VariantModel _makeVariant({
  String id = 'v1',
  String productId = 'p1',
  double price = 100.0,
  double? salePrice,
  int stock = 50,
  int minOrderQty = 1,
  int maxOrderQty = 50,
}) {
  final now = DateTime(2026, 1, 1);
  return VariantModel(
    id: id,
    productId: productId,
    name: 'Varyant $id',
    price: price,
    salePrice: salePrice,
    unit: 'adet',
    stock: stock,
    minOrderQty: minOrderQty,
    maxOrderQty: maxOrderQty,
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Yardimci: OrderItem olusturur — qty ve unitPrice parametrik
// ---------------------------------------------------------------------------
OrderItem _makeOrderItem({
  String productId = 'prod1',
  String productName = 'Test Urun',
  String? variantId,
  String? variantName,
  int qty = 1,
  double unitPrice = 100.0,
}) {
  return OrderItem(
    productId: productId,
    productName: productName,
    qty: qty,
    unitPrice: unitPrice,
    totalPrice: unitPrice * qty,
    variantId: variantId,
    variantName: variantName,
  );
}

// ---------------------------------------------------------------------------
// Yardimci: Minimal OrderModel olusturur
// ---------------------------------------------------------------------------
OrderModel _makeOrder({
  String id = 'order1',
  List<OrderItem>? items,
  double subtotal = 0.0,
  double discount = 0.0,
  double total = 0.0,
  OrderStatus status = OrderStatus.delivered,
}) {
  final now = DateTime(2026, 5, 1, 10, 0);
  final orderItems = items ?? [_makeOrderItem()];
  final computedSubtotal = subtotal > 0
      ? subtotal
      : orderItems.fold(0.0, (acc, i) => acc + i.totalPrice);
  final computedTotal = total > 0 ? total : computedSubtotal - discount;

  return OrderModel(
    id: id,
    orderNo: 'NST-2026-$id',
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
    items: orderItems,
    deliveryAddress: const DeliveryAddress(
      fullAddress: 'Test Adres',
      district: 'Merkez',
      city: 'Balikesir',
    ),
    paymentMethod: PaymentMethod.cash,
    subtotal: computedSubtotal,
    discount: discount,
    total: computedTotal,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  // =========================================================================
  // VariantModel fiyat getters
  // =========================================================================
  group('VariantModel fiyat getters', () {
    test('effectivePrice — salePrice yokken price doner', () {
      final variant = _makeVariant(price: 80.0);
      expect(variant.effectivePrice, 80.0);
    });

    test('effectivePrice — salePrice varken salePrice doner', () {
      final variant = _makeVariant(price: 100.0, salePrice: 75.0);
      expect(variant.effectivePrice, 75.0);
    });

    test('hasDiscount — salePrice null iken false', () {
      final variant = _makeVariant(price: 50.0);
      expect(variant.hasDiscount, isFalse);
    });

    test('hasDiscount — salePrice < price iken true', () {
      final variant = _makeVariant(price: 100.0, salePrice: 80.0);
      expect(variant.hasDiscount, isTrue);
    });

    test('hasDiscount — salePrice == price iken false', () {
      final variant = _makeVariant(price: 100.0, salePrice: 100.0);
      expect(variant.hasDiscount, isFalse);
    });

    test('discountPercent — indirim yokken 0.0 doner', () {
      final variant = _makeVariant(price: 100.0);
      expect(variant.discountPercent, 0.0);
    });

    test('discountPercent — 100 TL → 80 TL = yuzde 20 indirim', () {
      final variant = _makeVariant(price: 100.0, salePrice: 80.0);
      expect(variant.discountPercent, 20.0);
    });

    test('discountPercent — 200 TL → 150 TL = yuzde 25 indirim', () {
      final variant = _makeVariant(price: 200.0, salePrice: 150.0);
      expect(variant.discountPercent, 25.0);
    });

    test('inStock — stock > 0 iken true', () {
      final variant = _makeVariant(stock: 1);
      expect(variant.inStock, isTrue);
    });

    test('inStock — stock == 0 iken false', () {
      final variant = _makeVariant(stock: 0);
      expect(variant.inStock, isFalse);
    });
  });

  // =========================================================================
  // CartItem toplam hesaplama (variant ile)
  // =========================================================================
  group('CartItem toplam hesaplama', () {
    test('tek urun qty=1 → effectivePrice kadar', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 45.0);
      final item = CartItem(product: product, variant: variant, quantity: 1);
      expect(item.total, 45.0);
    });

    test('tek urun qty=N → effectivePrice * N', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 30.0);
      final item = CartItem(product: product, variant: variant, quantity: 5);
      expect(item.total, 150.0);
    });

    test('indirimli varyant — salePrice * qty kullanilir', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 100.0, salePrice: 60.0);
      final item = CartItem(product: product, variant: variant, quantity: 3);
      // effectivePrice = 60.0, 60 * 3 = 180
      expect(item.total, 180.0);
    });

    test('indirimli varyant — price degil salePrice baz alinir', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 100.0, salePrice: 60.0);
      final item = CartItem(product: product, variant: variant, quantity: 3);
      // 100 * 3 = 300 olsaydi yanlis olurdu; dogru: 60 * 3 = 180
      expect(item.total, isNot(300.0));
      expect(item.total, 180.0);
    });

    test('qty=0 urun → total 0', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 99.0);
      final item = CartItem(product: product, variant: variant, quantity: 0);
      expect(item.total, 0.0);
    });

    test('ondalikli birim fiyat — dogru carpim', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 12.50);
      final item = CartItem(product: product, variant: variant, quantity: 4);
      expect(item.total, closeTo(50.0, 0.001));
    });

    test('ondalikli indirimli fiyat — salePrice * qty dogru', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 15.75, salePrice: 12.25);
      final item = CartItem(product: product, variant: variant, quantity: 6);
      expect(item.total, closeTo(73.5, 0.001));
    });
  });

  // =========================================================================
  // CartModel coklu urun toplam hesaplama
  // =========================================================================
  group('CartModel coklu urun toplam hesaplama', () {
    test('tek urun sepeti — subtotal == item.total', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 50.0);
      final cart = CartModel(
        items: [CartItem(product: product, variant: variant, quantity: 2)],
      );
      expect(cart.subtotal, 100.0);
    });

    test('iki urun — dogru toplam', () {
      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      final v1 = _makeVariant(id: 'v1', productId: 'p1', price: 100.0);
      final v2 = _makeVariant(id: 'v2', productId: 'p2', price: 50.0);
      final cart = CartModel(items: [
        CartItem(product: p1, variant: v1, quantity: 2), // 200
        CartItem(product: p2, variant: v2, quantity: 3), // 150
      ]);
      expect(cart.subtotal, 350.0);
    });

    test('uc urun karisik indirim — dogru toplam', () {
      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      final p3 = _makeProduct(id: 'p3');
      final v1 = _makeVariant(id: 'v1', productId: 'p1', price: 100.0);
      final v2 = _makeVariant(id: 'v2', productId: 'p2', price: 80.0, salePrice: 60.0);
      final v3 = _makeVariant(id: 'v3', productId: 'p3', price: 40.0);
      final cart = CartModel(items: [
        CartItem(product: p1, variant: v1, quantity: 1), // 100
        CartItem(product: p2, variant: v2, quantity: 2), // 60 * 2 = 120
        CartItem(product: p3, variant: v3, quantity: 5), // 40 * 5 = 200
      ]);
      expect(cart.subtotal, 420.0);
    });

    test('qty=0 item toplama dahil edilmez', () {
      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      final v1 = _makeVariant(id: 'v1', productId: 'p1', price: 50.0);
      final v2 = _makeVariant(id: 'v2', productId: 'p2', price: 100.0);
      final cart = CartModel(items: [
        CartItem(product: p1, variant: v1, quantity: 2), // 100
        CartItem(product: p2, variant: v2, quantity: 0), // 0
      ]);
      expect(cart.subtotal, 100.0);
    });

    test('bos sepet — subtotal 0', () {
      const cart = CartModel();
      expect(cart.subtotal, 0.0);
      expect(cart.total, 0.0);
    });

    test('total == subtotal (CartModel discount olmadigi icin)', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 75.0);
      final cart = CartModel(
        items: [CartItem(product: product, variant: variant, quantity: 4)],
      );
      expect(cart.total, cart.subtotal);
    });

    test('totalItems: tum urunlerin adet toplami', () {
      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      final p3 = _makeProduct(id: 'p3');
      final v1 = _makeVariant(id: 'v1', productId: 'p1');
      final v2 = _makeVariant(id: 'v2', productId: 'p2');
      final v3 = _makeVariant(id: 'v3', productId: 'p3');
      final cart = CartModel(items: [
        CartItem(product: p1, variant: v1, quantity: 3),
        CartItem(product: p2, variant: v2, quantity: 2),
        CartItem(product: p3, variant: v3, quantity: 5),
      ]);
      expect(cart.totalItems, 10);
    });
  });

  // =========================================================================
  // OrderItem.totalPrice dogrulama
  // =========================================================================
  group('OrderItem totalPrice dogrulama', () {
    test('tek kalem qty=1 → totalPrice == unitPrice', () {
      final item = _makeOrderItem(qty: 1, unitPrice: 45.0);
      expect(item.totalPrice, 45.0);
    });

    test('tek kalem qty=N → totalPrice == unitPrice * N', () {
      final item = _makeOrderItem(qty: 4, unitPrice: 25.0);
      expect(item.totalPrice, 100.0);
    });

    test('ondalikli fiyat dogru carpim', () {
      final item = _makeOrderItem(qty: 3, unitPrice: 33.33);
      expect(item.totalPrice, closeTo(99.99, 0.001));
    });

    test('qty=0 — totalPrice 0 olmali', () {
      final item = OrderItem(
        productId: 'prod1',
        productName: 'Test',
        qty: 0,
        unitPrice: 100.0,
        totalPrice: 0.0,
      );
      expect(item.totalPrice, 0.0);
    });

    test('OrderItem variantId ve variantName saklanir', () {
      final item = _makeOrderItem(
        variantId: 'v1',
        variantName: '0.5L Koli',
      );
      expect(item.variantId, 'v1');
      expect(item.variantName, '0.5L Koli');
    });

    test('OrderItem fromMap/toMap round-trip variantId korur', () {
      final item = OrderItem(
        productId: 'p1',
        productName: 'Su',
        qty: 2,
        unitPrice: 30.0,
        totalPrice: 60.0,
        variantId: 'v-abc',
        variantName: 'Adet',
        brandName: 'Nisa',
      );
      final map = item.toMap();
      final rebuilt = OrderItem.fromMap(map);
      expect(rebuilt.variantId, 'v-abc');
      expect(rebuilt.variantName, 'Adet');
      expect(rebuilt.brandName, 'Nisa');
    });
  });

  // =========================================================================
  // OrderModel toplam hesaplama
  // =========================================================================
  group('OrderModel.total hesaplama', () {
    test('tek item — total == item.totalPrice', () {
      final item = _makeOrderItem(qty: 1, unitPrice: 75.0);
      final order = _makeOrder(items: [item]);
      expect(order.total, 75.0);
      expect(order.subtotal, 75.0);
    });

    test('tek item qty=N — total dogru', () {
      final item = _makeOrderItem(qty: 3, unitPrice: 50.0);
      final order = _makeOrder(items: [item]);
      expect(order.total, 150.0);
    });

    test('coklu item — total toplamdir', () {
      final items = [
        _makeOrderItem(productId: 'p1', qty: 2, unitPrice: 100.0), // 200
        _makeOrderItem(productId: 'p2', qty: 1, unitPrice: 50.0),  // 50
        _makeOrderItem(productId: 'p3', qty: 3, unitPrice: 30.0),  // 90
      ];
      final order = _makeOrder(items: items);
      expect(order.total, 340.0);
      expect(order.subtotal, 340.0);
    });

    test('indirimli varyant — salePrice ile hesaplanmis OrderItem', () {
      final item = _makeOrderItem(qty: 2, unitPrice: 60.0);
      final order = _makeOrder(
        items: [item],
        subtotal: 120.0,
        total: 120.0,
      );
      expect(order.total, 120.0);
      expect(order.discount, 0.0);
    });

    test('discount uygulanmis siparis — total = subtotal - discount', () {
      final items = [
        _makeOrderItem(qty: 1, unitPrice: 200.0),
      ];
      final now = DateTime(2026, 5, 1, 10, 0);
      final order = OrderModel(
        id: 'order-disc',
        orderNo: 'NST-2026-disc',
        customerId: 'cust1',
        customerName: 'Test Musteri',
        customerPhone: '05001234567',
        source: OrderSource.fieldAgent,
        createdBy: 'agent1',
        status: OrderStatus.delivered,
        statusHistory: [],
        items: items,
        deliveryAddress: const DeliveryAddress(
          fullAddress: 'Test',
          district: 'Merkez',
          city: 'Balikesir',
        ),
        paymentMethod: PaymentMethod.cash,
        subtotal: 200.0,
        discount: 20.0,
        total: 180.0,
        createdAt: now,
        updatedAt: now,
      );
      expect(order.subtotal, 200.0);
      expect(order.discount, 20.0);
      expect(order.total, 180.0);
    });

    test('totalItems — tum qty degerleri toplanir', () {
      final items = [
        _makeOrderItem(productId: 'p1', qty: 2),
        _makeOrderItem(productId: 'p2', qty: 3),
        _makeOrderItem(productId: 'p3', qty: 1),
      ];
      final order = _makeOrder(items: items);
      expect(order.totalItems, 6);
    });

    test('bos items listesi — totalItems 0, total 0', () {
      final order = _makeOrder(items: [], subtotal: 0.0, total: 0.0);
      expect(order.totalItems, 0);
      expect(order.total, 0.0);
    });

    test('ondalikli fiyatlar dogru toplanir', () {
      final items = [
        _makeOrderItem(productId: 'p1', qty: 3, unitPrice: 14.50), // 43.50
        _makeOrderItem(productId: 'p2', qty: 2, unitPrice: 8.75),  // 17.50
      ];
      final computedTotal =
          items.fold(0.0, (acc, i) => acc + i.totalPrice);
      final order = _makeOrder(
        items: items,
        subtotal: computedTotal,
        total: computedTotal,
      );
      expect(order.total, closeTo(61.0, 0.001));
    });

    test('cok sayida ayni urun — toplam dogru', () {
      final items = List.generate(
        10,
        (i) => _makeOrderItem(productId: 'p$i', qty: 1, unitPrice: 19.99),
      );
      final computedTotal =
          items.fold(0.0, (acc, i) => acc + i.totalPrice);
      final order = _makeOrder(
        items: items,
        subtotal: computedTotal,
        total: computedTotal,
      );
      expect(order.total, closeTo(199.9, 0.001));
    });
  });

  // =========================================================================
  // FieldAgentStats ile OrderModel.total iliskisi
  // =========================================================================
  group('Siparis toplam ve FieldAgent satis hesabi', () {
    test('sadece delivered siparisler satis toplanir', () {
      final deliveredItems = [
        _makeOrderItem(qty: 2, unitPrice: 50.0), // 100
      ];
      final pendingItems = [
        _makeOrderItem(qty: 1, unitPrice: 200.0), // 200 — sayilmamali
      ];

      final orders = [
        _makeOrder(
          id: 'o1',
          items: deliveredItems,
          subtotal: 100.0,
          total: 100.0,
          status: OrderStatus.delivered,
        ),
        _makeOrder(
          id: 'o2',
          items: pendingItems,
          subtotal: 200.0,
          total: 200.0,
          status: OrderStatus.pending,
        ),
      ];

      final deliveredTotal = orders
          .where((o) => o.status == OrderStatus.delivered)
          .fold(0.0, (acc, o) => acc + o.total);

      expect(deliveredTotal, 100.0);
    });

    test('birden fazla delivered siparisin total toplami', () {
      final orders = [
        _makeOrder(
          id: 'o1',
          items: [_makeOrderItem(qty: 1, unitPrice: 150.0)],
          subtotal: 150.0,
          total: 150.0,
          status: OrderStatus.delivered,
        ),
        _makeOrder(
          id: 'o2',
          items: [_makeOrderItem(qty: 2, unitPrice: 75.0)],
          subtotal: 150.0,
          total: 150.0,
          status: OrderStatus.delivered,
        ),
        _makeOrder(
          id: 'o3',
          items: [_makeOrderItem(qty: 1, unitPrice: 300.0)],
          subtotal: 300.0,
          total: 300.0,
          status: OrderStatus.cancelled,
        ),
      ];

      final deliveredTotal = orders
          .where((o) => o.status == OrderStatus.delivered)
          .fold(0.0, (acc, o) => acc + o.total);

      expect(deliveredTotal, 300.0);
    });
  });
}
