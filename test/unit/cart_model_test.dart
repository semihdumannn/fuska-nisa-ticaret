import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/models/variant_model.dart';
import 'package:nisa_ticaret/features/cart/data/models/cart_model.dart';

// Minimal gecerli ProductModel olusturur (artik fiyat/stok yok)
ProductModel _makeProduct({
  String id = 'p1',
}) {
  final now = DateTime(2026, 1, 1);
  return ProductModel(
    id: id,
    name: 'Urun $id',
    description: 'Aciklama',
    categoryId: 'cat1',
    createdAt: now,
    updatedAt: now,
  );
}

// Minimal gecerli VariantModel olusturur
VariantModel _makeVariant({
  String id = 'v1',
  String productId = 'p1',
  double price = 100.0,
  double? salePrice,
  int maxOrderQty = 50,
  int stock = 100,
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
    maxOrderQty: maxOrderQty,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('CartItem', () {
    test('total = effectivePrice * quantity (sale yokken)', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 100.0);
      final item = CartItem(product: product, variant: variant, quantity: 3);
      expect(item.total, 300.0);
    });

    test('total = salePrice * quantity (sale varken)', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 100.0, salePrice: 80.0);
      final item = CartItem(product: product, variant: variant, quantity: 2);
      expect(item.total, 160.0);
    });

    test('variant yokken total 0 doner (ProductModel fallback)', () {
      final product = _makeProduct();
      final item = CartItem(product: product, quantity: 3);
      expect(item.total, 0.0); // ProductModel.effectivePrice = 0.0
    });

    test('copyWith quantity degistirir, product ayni kalir', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 50.0);
      final item = CartItem(product: product, variant: variant, quantity: 1);
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.product.id, product.id);
    });

    test('copyWith quantity verilmezse mevcut deger korunur', () {
      final product = _makeProduct();
      final item = CartItem(product: product, quantity: 7);
      final copy = item.copyWith();
      expect(copy.quantity, 7);
    });
  });

  group('CartModel - temel durumlar', () {
    test('bos CartModel isEmpty true doner', () {
      const cart = CartModel();
      expect(cart.isEmpty, true);
    });

    test('en az bir item varsa isEmpty false doner', () {
      final product = _makeProduct();
      final cart = CartModel(items: [CartItem(product: product, quantity: 1)]);
      expect(cart.isEmpty, false);
    });

    test('totalItems: 2 urun 3+2 adet → 5', () {
      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      final v1 = _makeVariant(id: 'v1', productId: 'p1', price: 10.0);
      final v2 = _makeVariant(id: 'v2', productId: 'p2', price: 20.0);
      final cart = CartModel(items: [
        CartItem(product: p1, variant: v1, quantity: 3),
        CartItem(product: p2, variant: v2, quantity: 2),
      ]);
      expect(cart.totalItems, 5);
    });

    test('subtotal dogru hesaplanir', () {
      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      final v1 = _makeVariant(id: 'v1', productId: 'p1', price: 100.0);
      final v2 = _makeVariant(id: 'v2', productId: 'p2', price: 50.0, salePrice: 40.0);
      final cart = CartModel(items: [
        CartItem(product: p1, variant: v1, quantity: 2), // 200
        CartItem(product: p2, variant: v2, quantity: 3), // 120
      ]);
      expect(cart.subtotal, 320.0);
    });

    test('total == subtotal', () {
      final product = _makeProduct();
      final variant = _makeVariant(price: 75.0);
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 4)]);
      expect(cart.total, cart.subtotal);
    });
  });

  group('CartModel.addItem', () {
    test('yeni urun items listesine eklenir', () {
      const cart = CartModel();
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1');
      final updated = cart.addItem(product, variant: variant);
      expect(updated.items.length, 1);
      expect(updated.items.first.product.id, 'p1');
      expect(updated.items.first.quantity, 1);
    });

    test('var olan urun+varyant tekrar eklenince quantity artar', () {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1', maxOrderQty: 50);
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 2)]);
      final updated = cart.addItem(product, variant: variant, quantity: 3);
      expect(updated.items.length, 1);
      expect(updated.items.first.quantity, 5);
    });

    test('addItem maxOrderQty sinirini gecmez', () {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1', maxOrderQty: 5);
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 4)]);
      final updated = cart.addItem(product, variant: variant, quantity: 10);
      expect(updated.items.first.quantity, 5); // clamp(0, 5)
    });

    test('ozel quantity ile ekleme', () {
      const cart = CartModel();
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1');
      final updated = cart.addItem(product, variant: variant, quantity: 4);
      expect(updated.items.first.quantity, 4);
    });
  });

  group('CartModel.removeItem', () {
    test('belirtilen urun+varyant kaldirilir, diger items kalir', () {
      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      final v1 = _makeVariant(id: 'v1', productId: 'p1');
      final v2 = _makeVariant(id: 'v2', productId: 'p2');
      final cart = CartModel(items: [
        CartItem(product: p1, variant: v1, quantity: 1),
        CartItem(product: p2, variant: v2, quantity: 2),
      ]);
      final updated = cart.removeItem('p1', variantId: 'v1');
      expect(updated.items.length, 1);
      expect(updated.items.first.product.id, 'p2');
    });

    test('olmayan urun id silindikten sonra liste degismez', () {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1');
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 1)]);
      final updated = cart.removeItem('p99');
      expect(updated.items.length, 1);
    });
  });

  group('CartModel.updateQuantity', () {
    test('quantity guncellenir', () {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1');
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 2)]);
      final updated = cart.updateQuantity('p1', 7, variantId: 'v1');
      expect(updated.items.first.quantity, 7);
    });

    test('quantity=0 iken item silinir', () {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1');
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 3)]);
      final updated = cart.updateQuantity('p1', 0, variantId: 'v1');
      expect(updated.items.isEmpty, true);
    });

    test('negatif quantity de item siler', () {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1');
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 3)]);
      final updated = cart.updateQuantity('p1', -1, variantId: 'v1');
      expect(updated.items.isEmpty, true);
    });
  });

  group('CartModel.clear', () {
    test('clear sonrasi items bos olur', () {
      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      final v1 = _makeVariant(id: 'v1', productId: 'p1');
      final v2 = _makeVariant(id: 'v2', productId: 'p2');
      final cart = CartModel(items: [
        CartItem(product: p1, variant: v1, quantity: 2),
        CartItem(product: p2, variant: v2, quantity: 5),
      ]);
      final cleared = cart.clear();
      expect(cleared.items.isEmpty, true);
      expect(cleared.totalItems, 0);
    });
  });

  group('CartModel.containsProduct', () {
    test('var olan urun+varyant icin true doner', () {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1');
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 1)]);
      expect(cart.containsProduct('p1', variantId: 'v1'), true);
    });

    test('olmayan urun icin false doner', () {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1');
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 1)]);
      expect(cart.containsProduct('p99'), false);
    });

    test('bos sepette false doner', () {
      const cart = CartModel();
      expect(cart.containsProduct('p1'), false);
    });
  });

  group('CartModel.quantityOf', () {
    test('var olan urun+varyant miktarini doner', () {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1');
      final cart = CartModel(items: [CartItem(product: product, variant: variant, quantity: 4)]);
      expect(cart.quantityOf('p1', variantId: 'v1'), 4);
    });

    test('olmayan urun icin 0 doner', () {
      const cart = CartModel();
      expect(cart.quantityOf('p99'), 0);
    });
  });
}
