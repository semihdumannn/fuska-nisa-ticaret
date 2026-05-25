import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/cart/domain/entities/cart_entity.dart';
import 'package:nisa_ticaret/features/cart/domain/entities/cart_item_entity.dart';

void main() {
  // Yardimci factory fonksiyon — her testte tekrar tekrar yazmayi onler
  CartItemEntity makeItem({
    String id = 'item1',
    int productId = 1,
    String productName = 'Test Urun',
    double unitPrice = 10.0,
    int quantity = 1,
    int? variantId,
  }) {
    return CartItemEntity(
      id: id,
      productId: productId,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity,
      variantId: variantId,
    );
  }

  group('CartEntity', () {
    group('bos sepet durumu', () {
      test('bos sepette isEmpty true donmeli', () {
        const cart = CartEntity();
        expect(cart.isEmpty, isTrue);
      });

      test('bos sepette isNotEmpty false donmeli', () {
        const cart = CartEntity();
        expect(cart.isNotEmpty, isFalse);
      });

      test('bos sepette totalItems sifir olmali', () {
        const cart = CartEntity();
        expect(cart.totalItems, equals(0));
      });

      test('bos sepette subtotal sifir olmali', () {
        const cart = CartEntity();
        expect(cart.subtotal, equals(0.0));
      });

      test('bos sepette discount sifir olmali', () {
        const cart = CartEntity();
        expect(cart.discount, equals(0.0));
      });

      test('bos sepette total sifir olmali', () {
        const cart = CartEntity();
        expect(cart.total, equals(0.0));
      });
    });

    group('subtotal hesaplama', () {
      test('tek urun icin subtotal unitPrice x quantity olmali', () {
        final cart = CartEntity(
          items: [makeItem(unitPrice: 25.0, quantity: 2)],
        );
        expect(cart.subtotal, equals(50.0));
      });

      test('birden fazla urun icin subtotal toplamlarinin toplami olmali', () {
        final cart = CartEntity(
          items: [
            makeItem(id: 'a', productId: 1, unitPrice: 15.0, quantity: 3),
            makeItem(id: 'b', productId: 2, unitPrice: 20.0, quantity: 2),
          ],
        );
        // 15*3 + 20*2 = 45 + 40 = 85
        expect(cart.subtotal, equals(85.0));
      });

      test('kesirli fiyatlarla subtotal dogru hesaplanmali', () {
        final cart = CartEntity(
          items: [makeItem(unitPrice: 9.99, quantity: 3)],
        );
        expect(cart.subtotal, closeTo(29.97, 0.001));
      });
    });

    group('totalItems hesaplama', () {
      test('tek urun icin totalItems quantity kadar olmali', () {
        final cart = CartEntity(
          items: [makeItem(quantity: 5)],
        );
        expect(cart.totalItems, equals(5));
      });

      test('birden fazla urun icin totalItems quantity toplamlari olmali', () {
        final cart = CartEntity(
          items: [
            makeItem(id: 'a', productId: 1, quantity: 3),
            makeItem(id: 'b', productId: 2, quantity: 7),
          ],
        );
        expect(cart.totalItems, equals(10));
      });

      test('her birinden bir adet ise totalItems urun sayisina esit olmali', () {
        final cart = CartEntity(
          items: [
            makeItem(id: 'a', productId: 1, quantity: 1),
            makeItem(id: 'b', productId: 2, quantity: 1),
            makeItem(id: 'c', productId: 3, quantity: 1),
          ],
        );
        expect(cart.totalItems, equals(3));
      });
    });

    group('discount ve total', () {
      test('discountAmount yoksa discount 0.0 donmeli', () {
        final cart = CartEntity(
          items: [makeItem(unitPrice: 50.0, quantity: 1)],
        );
        expect(cart.discount, equals(0.0));
      });

      test('discountAmount varsa discount o degeri donmeli', () {
        final cart = CartEntity(
          items: [makeItem(unitPrice: 50.0, quantity: 1)],
          discountAmount: 10.0,
        );
        expect(cart.discount, equals(10.0));
      });

      test('total = subtotal - discount olmali', () {
        final cart = CartEntity(
          items: [makeItem(unitPrice: 100.0, quantity: 2)],
          discountAmount: 30.0,
        );
        // subtotal=200, discount=30 → total=170
        expect(cart.total, equals(170.0));
      });

      test('discount yokken total subtotala esit olmali', () {
        final cart = CartEntity(
          items: [makeItem(unitPrice: 75.0, quantity: 2)],
        );
        expect(cart.total, equals(cart.subtotal));
      });

      test('couponCode ve discountAmount birlikte saklanabilmeli', () {
        final cart = CartEntity(
          items: [makeItem(unitPrice: 100.0, quantity: 1)],
          couponCode: 'INDIRIM20',
          discountAmount: 20.0,
        );
        expect(cart.couponCode, equals('INDIRIM20'));
        expect(cart.discount, equals(20.0));
        expect(cart.total, equals(80.0));
      });
    });

    group('containsProduct', () {
      test('sepette olan urun icin true donmeli', () {
        final cart = CartEntity(
          items: [makeItem(productId: 42)],
        );
        expect(cart.containsProduct(42), isTrue);
      });

      test('sepette olmayan urun icin false donmeli', () {
        final cart = CartEntity(
          items: [makeItem(productId: 1)],
        );
        expect(cart.containsProduct(99), isFalse);
      });

      test('bos sepette containsProduct her zaman false donmeli', () {
        const cart = CartEntity();
        expect(cart.containsProduct(1), isFalse);
      });

      test('variantId ile eslesen urun bulunmali', () {
        final cart = CartEntity(
          items: [makeItem(productId: 5, variantId: 10)],
        );
        expect(cart.containsProduct(5, variantId: 10), isTrue);
      });

      test('farkli variantId ile eslesme olmamali', () {
        final cart = CartEntity(
          items: [makeItem(productId: 5, variantId: 10)],
        );
        expect(cart.containsProduct(5, variantId: 20), isFalse);
      });

      test('variantId null iken null eslesme dogru calismal', () {
        final cart = CartEntity(
          items: [makeItem(productId: 5, variantId: null)],
        );
        expect(cart.containsProduct(5), isTrue);
        expect(cart.containsProduct(5, variantId: null), isTrue);
      });
    });

    group('findItem', () {
      test('mevcut urun icin CartItemEntity donmeli', () {
        final item = makeItem(productId: 7, unitPrice: 30.0, quantity: 2);
        final cart = CartEntity(items: [item]);

        final found = cart.findItem(7);
        expect(found, isNotNull);
        expect(found!.productId, equals(7));
        expect(found.unitPrice, equals(30.0));
      });

      test('olmayan urun icin null donmeli', () {
        final cart = CartEntity(
          items: [makeItem(productId: 1)],
        );
        expect(cart.findItem(999), isNull);
      });

      test('bos sepette findItem null donmeli', () {
        const cart = CartEntity();
        expect(cart.findItem(1), isNull);
      });

      test('variantId eslesen urun donmeli', () {
        final item = makeItem(productId: 3, variantId: 15);
        final cart = CartEntity(items: [item]);

        final found = cart.findItem(3, variantId: 15);
        expect(found, isNotNull);
        expect(found!.variantId, equals(15));
      });

      test('variantId eslesmeyen urun null donmeli', () {
        final cart = CartEntity(
          items: [makeItem(productId: 3, variantId: 15)],
        );
        expect(cart.findItem(3, variantId: 99), isNull);
      });
    });

    group('copyWith', () {
      test('notes guncelleme kopya olusturmali', () {
        final original = CartEntity(
          items: [makeItem()],
        );
        final copy = original.copyWith(notes: 'Kapisinin ziline basma');
        expect(copy.notes, equals('Kapisinin ziline basma'));
        expect(copy.items, equals(original.items));
      });

      test('couponCode guncellenebilmeli', () {
        const original = CartEntity(couponCode: 'ESKI');
        final copy = original.copyWith(couponCode: 'YENI');
        expect(copy.couponCode, equals('YENI'));
      });

      test('items guncellenebilmeli', () {
        const original = CartEntity();
        final newItems = [makeItem(productId: 5, quantity: 3)];
        final copy = original.copyWith(items: newItems);
        expect(copy.items.length, equals(1));
        expect(copy.items.first.productId, equals(5));
      });
    });
  });

  group('CartItemEntity', () {
    test('totalPrice = unitPrice x quantity olmali', () {
      const item = CartItemEntity(
        id: 'x',
        productId: 1,
        productName: 'Su',
        unitPrice: 12.5,
        quantity: 4,
      );
      expect(item.totalPrice, equals(50.0));
    });

    test('variantName yoksa displayName sadece productName olmali', () {
      const item = CartItemEntity(
        id: 'x',
        productId: 1,
        productName: 'Gazoz',
        unitPrice: 5.0,
        quantity: 1,
      );
      expect(item.displayName, equals('Gazoz'));
    });

    test('variantName varsa displayName "productName - variantName" olmali', () {
      const item = CartItemEntity(
        id: 'x',
        productId: 1,
        productName: 'Su',
        variantName: '19 Lt Damacana',
        unitPrice: 40.0,
        quantity: 1,
      );
      expect(item.displayName, equals('Su - 19 Lt Damacana'));
    });

    test('copyWith quantity gunceller', () {
      const item = CartItemEntity(
        id: 'x',
        productId: 1,
        productName: 'Su',
        unitPrice: 10.0,
        quantity: 1,
      );
      final updated = item.copyWith(quantity: 5);
      expect(updated.quantity, equals(5));
      expect(updated.unitPrice, equals(10.0));
      expect(updated.totalPrice, equals(50.0));
    });
  });
}
