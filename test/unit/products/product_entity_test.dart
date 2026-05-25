import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/products/domain/entities/product_entity.dart';

void main() {
  final baseDate = DateTime(2024, 1, 1);

  // Yardimci factory — sadece gerekli alanlari override et
  ProductEntity makeProduct({
    String id = 'p1',
    String name = 'Test Urun',
    double? primaryPrice,
    double? primarySalePrice,
    int? primaryStock,
    String? koliVariantId,
    double? koliPrice,
    double? koliSalePrice,
    int? koliStock,
    int? koliPackageQty,
    bool isActive = true,
    bool isFeatured = false,
    List<String> categoryIds = const ['cat1'],
    String brandId = 'brand1',
  }) {
    return ProductEntity(
      id: id,
      name: name,
      primaryPrice: primaryPrice,
      primarySalePrice: primarySalePrice,
      primaryStock: primaryStock,
      koliVariantId: koliVariantId,
      koliPrice: koliPrice,
      koliSalePrice: koliSalePrice,
      koliStock: koliStock,
      koliPackageQty: koliPackageQty,
      isActive: isActive,
      isFeatured: isFeatured,
      categoryIds: categoryIds,
      brandId: brandId,
      createdAt: baseDate,
      updatedAt: baseDate,
    );
  }

  group('ProductEntity', () {
    group('effectivePrice', () {
      test('primarySalePrice varsa effectivePrice salePrice donmeli', () {
        final p = makeProduct(primaryPrice: 50.0, primarySalePrice: 40.0);
        expect(p.effectivePrice, equals(40.0));
      });

      test('primarySalePrice yoksa effectivePrice primaryPrice donmeli', () {
        final p = makeProduct(primaryPrice: 50.0);
        expect(p.effectivePrice, equals(50.0));
      });

      test('hem fiyat hem salePrice yoksa effectivePrice 0.0 donmeli', () {
        final p = makeProduct();
        expect(p.effectivePrice, equals(0.0));
      });

      test('koliPrice varsa effectivePrice koliPrice oncelikli olmali', () {
        final p = makeProduct(
          primaryPrice: 50.0,
          primarySalePrice: 40.0,
          koliVariantId: 'kv1',
          koliPrice: 90.0,
        );
        // koliSalePrice yok, koliPrice doner
        expect(p.effectivePrice, equals(90.0));
      });

      test('koliSalePrice varsa effectivePrice koliSalePrice donmeli', () {
        final p = makeProduct(
          primaryPrice: 50.0,
          koliVariantId: 'kv1',
          koliPrice: 90.0,
          koliSalePrice: 75.0,
        );
        expect(p.effectivePrice, equals(75.0));
      });
    });

    group('price getter', () {
      test('koliPrice varsa price koliPrice donmeli', () {
        final p = makeProduct(
          primaryPrice: 20.0,
          koliVariantId: 'kv1',
          koliPrice: 80.0,
        );
        expect(p.price, equals(80.0));
      });

      test('koliPrice yoksa price primaryPrice donmeli', () {
        final p = makeProduct(primaryPrice: 20.0);
        expect(p.price, equals(20.0));
      });

      test('her ikisi de yoksa price 0.0 donmeli', () {
        final p = makeProduct();
        expect(p.price, equals(0.0));
      });
    });

    group('hasDiscount', () {
      test('salePrice < price iken hasDiscount true olmali', () {
        final p = makeProduct(primaryPrice: 100.0, primarySalePrice: 80.0);
        expect(p.hasDiscount, isTrue);
      });

      test('salePrice == price iken hasDiscount false olmali', () {
        final p = makeProduct(primaryPrice: 100.0, primarySalePrice: 100.0);
        expect(p.hasDiscount, isFalse);
      });

      test('salePrice > price iken hasDiscount false olmali', () {
        final p = makeProduct(primaryPrice: 80.0, primarySalePrice: 100.0);
        expect(p.hasDiscount, isFalse);
      });

      test('salePrice null iken hasDiscount false olmali', () {
        final p = makeProduct(primaryPrice: 100.0);
        expect(p.hasDiscount, isFalse);
      });

      test('hem price hem salePrice null iken hasDiscount false olmali', () {
        final p = makeProduct();
        expect(p.hasDiscount, isFalse);
      });

      test('price sifir iken hasDiscount false olmali', () {
        final p = makeProduct(primaryPrice: 0.0, primarySalePrice: 0.0);
        expect(p.hasDiscount, isFalse);
      });

      test('koli icin koliSalePrice < koliPrice iken hasDiscount true olmali', () {
        final p = makeProduct(
          koliVariantId: 'kv1',
          koliPrice: 100.0,
          koliSalePrice: 85.0,
        );
        expect(p.hasDiscount, isTrue);
      });
    });

    group('discountPercentage', () {
      test('yuzde 20 indirim dogru hesaplanmali', () {
        final p = makeProduct(primaryPrice: 100.0, primarySalePrice: 80.0);
        expect(p.discountPercentage, equals(20.0));
      });

      test('yuzde 50 indirim dogru hesaplanmali', () {
        final p = makeProduct(primaryPrice: 200.0, primarySalePrice: 100.0);
        expect(p.discountPercentage, equals(50.0));
      });

      test('indirim yoksa discountPercentage 0.0 donmeli', () {
        final p = makeProduct(primaryPrice: 100.0);
        expect(p.discountPercentage, equals(0.0));
      });

      test('price sifir iken discountPercentage 0.0 donmeli', () {
        final p = makeProduct(primaryPrice: 0.0, primarySalePrice: 0.0);
        expect(p.discountPercentage, equals(0.0));
      });

      test('salePrice >= price iken discountPercentage 0.0 donmeli', () {
        final p = makeProduct(primaryPrice: 50.0, primarySalePrice: 60.0);
        expect(p.discountPercentage, equals(0.0));
      });

      test('koli indirim yuzdesi dogru hesaplanmali', () {
        final p = makeProduct(
          koliVariantId: 'kv1',
          koliPrice: 200.0,
          koliSalePrice: 150.0,
        );
        // (200-150)/200*100 = 25
        expect(p.discountPercentage, equals(25.0));
      });
    });

    group('inStock', () {
      test('primaryStock > 0 iken inStock true olmali', () {
        final p = makeProduct(primaryPrice: 10.0, primaryStock: 5);
        expect(p.inStock, isTrue);
      });

      test('primaryStock = 0 iken inStock false olmali', () {
        final p = makeProduct(primaryPrice: 10.0, primaryStock: 0);
        expect(p.inStock, isFalse);
      });

      test('primaryStock null iken inStock false olmali', () {
        final p = makeProduct(primaryPrice: 10.0);
        expect(p.inStock, isFalse);
      });

      test('koliVariantId varken koliStock > 0 iken inStock true olmali', () {
        final p = makeProduct(
          koliVariantId: 'kv1',
          koliPrice: 80.0,
          koliStock: 10,
        );
        expect(p.inStock, isTrue);
      });

      test('koliVariantId varken koliStock = 0 iken inStock false olmali', () {
        final p = makeProduct(
          koliVariantId: 'kv1',
          koliPrice: 80.0,
          koliStock: 0,
        );
        expect(p.inStock, isFalse);
      });
    });

    group('stock getter', () {
      test('koliStock varsa stock koliStock donmeli', () {
        final p = makeProduct(koliVariantId: 'kv1', koliStock: 12);
        expect(p.stock, equals(12));
      });

      test('koliStock null iken stock primaryStock donmeli', () {
        final p = makeProduct(primaryStock: 8);
        expect(p.stock, equals(8));
      });

      test('ikisi de null iken stock 0 donmeli', () {
        final p = makeProduct();
        expect(p.stock, equals(0));
      });
    });

    group('categoryId (geriye donuk uyumluluk)', () {
      test('categoryIds doluysa categoryId ilk elemani donmeli', () {
        final p = makeProduct(categoryIds: ['cat42', 'cat99']);
        expect(p.categoryId, equals('cat42'));
      });

      test('categoryIds bos ise categoryId bos string donmeli', () {
        final p = makeProduct(categoryIds: []);
        expect(p.categoryId, equals(''));
      });
    });

    group('allImages', () {
      test('imageUrls doluysa allImages imageUrls donmeli', () {
        final p = ProductEntity(
          id: 'p1',
          name: 'Su',
          imageUrls: ['url1', 'url2'],
          createdAt: baseDate,
          updatedAt: baseDate,
        );
        expect(p.allImages, equals(['url1', 'url2']));
      });

      test('imageUrls bos imageUrl varsa tek elemanli liste donmeli', () {
        final p = ProductEntity(
          id: 'p1',
          name: 'Su',
          imageUrl: 'single.jpg',
          createdAt: baseDate,
          updatedAt: baseDate,
        );
        expect(p.allImages, equals(['single.jpg']));
      });

      test('ikisi de yoksa bos liste donmeli', () {
        final p = ProductEntity(
          id: 'p1',
          name: 'Su',
          createdAt: baseDate,
          updatedAt: baseDate,
        );
        expect(p.allImages, isEmpty);
      });
    });
  });

  group('ProductVariantEntity', () {
    test('effectivePrice: salePrice varsa salePrice donmeli', () {
      const variant = ProductVariantEntity(
        id: 'v1',
        productId: 'p1',
        name: '19 Lt',
        price: 50.0,
        salePrice: 40.0,
        unit: 'adet',
        stock: 5,
      );
      expect(variant.effectivePrice, equals(40.0));
    });

    test('effectivePrice: salePrice yoksa price donmeli', () {
      const variant = ProductVariantEntity(
        id: 'v1',
        productId: 'p1',
        name: '5 Lt',
        price: 20.0,
        unit: 'adet',
        stock: 3,
      );
      expect(variant.effectivePrice, equals(20.0));
    });

    test('hasDiscount: salePrice < price iken true donmeli', () {
      const variant = ProductVariantEntity(
        id: 'v1',
        productId: 'p1',
        name: '5 Lt',
        price: 20.0,
        salePrice: 15.0,
        unit: 'adet',
        stock: 3,
      );
      expect(variant.hasDiscount, isTrue);
    });

    test('hasDiscount: salePrice null iken false donmeli', () {
      const variant = ProductVariantEntity(
        id: 'v1',
        productId: 'p1',
        name: '5 Lt',
        price: 20.0,
        unit: 'adet',
        stock: 3,
      );
      expect(variant.hasDiscount, isFalse);
    });

    test('discountPercentage dogru hesaplanmali', () {
      const variant = ProductVariantEntity(
        id: 'v1',
        productId: 'p1',
        name: '5 Lt',
        price: 100.0,
        salePrice: 75.0,
        unit: 'adet',
        stock: 3,
      );
      expect(variant.discountPercentage, equals(25.0));
    });

    test('inStock: stock > 0 iken true olmali', () {
      const variant = ProductVariantEntity(
        id: 'v1',
        productId: 'p1',
        name: '5 Lt',
        price: 20.0,
        unit: 'adet',
        stock: 1,
      );
      expect(variant.inStock, isTrue);
    });

    test('inStock: stock = 0 iken false olmali', () {
      const variant = ProductVariantEntity(
        id: 'v1',
        productId: 'p1',
        name: '5 Lt',
        price: 20.0,
        unit: 'adet',
        stock: 0,
      );
      expect(variant.inStock, isFalse);
    });
  });
}
