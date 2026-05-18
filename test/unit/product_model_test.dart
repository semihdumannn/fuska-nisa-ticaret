import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';

// Test yardimci fonksiyonu: minimal gecerli ProductModel olusturur
// NOT: Fiyat/stok artik VariantModel'de. ProductModel sadece meta veri tutar.
ProductModel makeProduct({
  String id = 'p1',
  String name = 'Test Urun',
  String description = 'Aciklama',
  String categoryId = 'cat1',
  String brandId = '',
  String? imageUrl,
  List<String> imageUrls = const [],
  List<String> tags = const [],
  bool isActive = true,
  bool isFeatured = false,
  int order = 0,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 1, 1);
  return ProductModel(
    id: id,
    brandId: brandId,
    name: name,
    description: description,
    categoryId: categoryId,
    imageUrl: imageUrl,
    imageUrls: imageUrls,
    tags: tags,
    isActive: isActive,
    isFeatured: isFeatured,
    order: order,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

void main() {
  group('ProductModel — fromJson / toJson round-trip', () {
    test('tum alanlar dogru parse edilir', () {
      final now = DateTime(2026, 3, 15, 10, 0, 0);
      final json = {
        'id': 'prod1',
        'brandId': 'brand1',
        'name': 'Damacana Su',
        'description': '19 lt damacana',
        'categoryId': 'cat-su',
        'imageUrl': 'https://example.com/img.jpg',
        'imageUrls': ['https://example.com/1.jpg', 'https://example.com/2.jpg'],
        'tags': ['su', 'damacana'],
        'isActive': true,
        'isFeatured': false,
        'order': 3,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 'prod1');
      expect(product.brandId, 'brand1');
      expect(product.name, 'Damacana Su');
      expect(product.description, '19 lt damacana');
      expect(product.categoryId, 'cat-su');
      expect(product.imageUrl, 'https://example.com/img.jpg');
      expect(product.imageUrls,
          ['https://example.com/1.jpg', 'https://example.com/2.jpg']);
      expect(product.tags, ['su', 'damacana']);
      expect(product.isActive, true);
      expect(product.isFeatured, false);
      expect(product.order, 3);
      expect(product.createdAt, now);
    });

    test('fromJson -> toJson round-trip esit urun uretir', () {
      final now = DateTime(2026, 3, 15);
      final json = {
        'id': 'prod2',
        'brandId': '',
        'name': 'Kola',
        'description': 'Soguk icecek',
        'categoryId': 'cat-gazli',
        'imageUrl': null,
        'imageUrls': <String>[],
        'tags': <String>[],
        'isActive': true,
        'isFeatured': false,
        'order': 1,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final product = ProductModel.fromJson(json);
      final reEncoded = product.toJson();
      final rebuilt = ProductModel.fromJson(reEncoded);

      expect(rebuilt.id, product.id);
      expect(rebuilt.brandId, product.brandId);
      expect(rebuilt.name, product.name);
      expect(rebuilt.categoryId, product.categoryId);
    });

    test('eksik alanlar default degerlerle doldurulur', () {
      final product = ProductModel.fromJson({'id': 'x'});

      expect(product.name, '');
      expect(product.description, '');
      expect(product.categoryId, '');
      expect(product.brandId, '');
      expect(product.isActive, true);
      expect(product.isFeatured, false);
      expect(product.order, 0);
      expect(product.imageUrls, isEmpty);
      expect(product.tags, isEmpty);
    });
  });

  group('ProductModel — geriye donuk uyumluluk getterlar', () {
    test('price getter 0.0 doner', () {
      final p = makeProduct();
      expect(p.price, 0.0);
    });

    test('effectivePrice getter 0.0 doner', () {
      final p = makeProduct();
      expect(p.effectivePrice, 0.0);
    });

    test('hasDiscount getter false doner', () {
      expect(makeProduct().hasDiscount, false);
    });

    test('discountPercent getter 0.0 doner', () {
      expect(makeProduct().discountPercent, 0.0);
    });

    test('inStock getter true doner (varyant yonetir)', () {
      expect(makeProduct().inStock, true);
    });

    test('unit getter adet doner', () {
      expect(makeProduct().unit, 'adet');
    });

    test('stock getter 0 doner', () {
      expect(makeProduct().stock, 0);
    });

    test('minOrderQty getter 1 doner', () {
      expect(makeProduct().minOrderQty, 1);
    });

    test('maxOrderQty getter 999 doner', () {
      expect(makeProduct().maxOrderQty, 999);
    });
  });

  group('ProductModel — allImages', () {
    test('imageUrls doluysa imageUrls doner', () {
      final p = makeProduct(
        imageUrls: ['https://a.com/1.jpg', 'https://a.com/2.jpg'],
        imageUrl: 'https://a.com/main.jpg',
      );
      expect(p.allImages, ['https://a.com/1.jpg', 'https://a.com/2.jpg']);
    });

    test('imageUrls bos, imageUrl varsa tek eleman liste doner', () {
      final p = makeProduct(imageUrls: [], imageUrl: 'https://a.com/main.jpg');
      expect(p.allImages, ['https://a.com/main.jpg']);
    });

    test('imageUrls bos, imageUrl null → bos liste doner', () {
      final p = makeProduct(imageUrls: [], imageUrl: null);
      expect(p.allImages, isEmpty);
    });

    test('imageUrls bos, imageUrl bos string → bos liste doner', () {
      final p = makeProduct(imageUrls: [], imageUrl: '');
      expect(p.allImages, isEmpty);
    });
  });

  group('ProductModel — _parseStringList (fromJson ile dolayli test)', () {
    test('imageUrls null → bos liste', () {
      final p = ProductModel.fromJson({'id': 'x'});
      expect(p.imageUrls, isEmpty);
    });

    test('imageUrls gecerli liste → parse edilir', () {
      final p = ProductModel.fromJson({
        'id': 'x',
        'imageUrls': ['https://a.com/1.jpg', 'https://a.com/2.jpg'],
      });
      expect(p.imageUrls.length, 2);
    });

    test('imageUrls bos liste → bos liste', () {
      final p = ProductModel.fromJson({
        'id': 'x',
        'imageUrls': <dynamic>[],
      });
      expect(p.imageUrls, isEmpty);
    });

    test('imageUrls karma liste → sadece String elemanlar alinir', () {
      final p = ProductModel.fromJson({
        'id': 'x',
        'imageUrls': ['https://a.com/1.jpg', 42, null, 'https://a.com/2.jpg'],
      });
      expect(p.imageUrls, ['https://a.com/1.jpg', 'https://a.com/2.jpg']);
    });

    test('imageUrls String degil baska tip → bos liste', () {
      final p = ProductModel.fromJson({
        'id': 'x',
        'imageUrls': 'gecersiz-deger',
      });
      expect(p.imageUrls, isEmpty);
    });
  });

  group('ProductModel — toJson icerigi', () {
    test('toJson beklenen anahtarlari iceriyor', () {
      final p = makeProduct(id: 'abc', name: 'Su');
      final json = p.toJson();

      expect(json['id'], 'abc');
      expect(json['name'], 'Su');
      expect(json.containsKey('brandId'), true);
      expect(json.containsKey('imageUrl'), true);
      expect(json.containsKey('imageUrls'), true);
      expect(json.containsKey('tags'), true);
      expect(json.containsKey('createdAt'), true);
      expect(json.containsKey('updatedAt'), true);
      // Eski alanlar artik yok
      expect(json.containsKey('price'), false);
      expect(json.containsKey('salePrice'), false);
      expect(json.containsKey('stock'), false);
      expect(json.containsKey('unit'), false);
    });
  });

  group('ProductModel — copyWith', () {
    test('name degistirilir', () {
      final p = makeProduct(id: 'p1', name: 'Eski Ad');
      final updated = p.copyWith(name: 'Yeni Ad');
      expect(updated.name, 'Yeni Ad');
      expect(updated.id, 'p1');
    });

    test('brandId degistirilir', () {
      final p = makeProduct(brandId: 'brand-a');
      final updated = p.copyWith(brandId: 'brand-b');
      expect(updated.brandId, 'brand-b');
    });

    test('clearImageUrl ile imageUrl null olur', () {
      final p = makeProduct(imageUrl: 'https://a.com/img.jpg');
      final updated = p.copyWith(clearImageUrl: true);
      expect(updated.imageUrl, null);
    });

    test('isActive toggle edilir', () {
      final p = makeProduct(isActive: true);
      expect(p.copyWith(isActive: false).isActive, false);
    });
  });
}
