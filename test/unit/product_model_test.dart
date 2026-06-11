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
    categoryIds: [categoryId],
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

    test('inStock getter: primaryStock > 0 iken true doner', () {
      final p = ProductModel(
        id: 'p1',
        name: 'Test',
        description: '',
        primaryStock: 5,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      expect(p.inStock, true);
    });

    test('inStock getter: stok alani yokken false doner', () {
      expect(makeProduct().inStock, false);
    });

    test('unit getter koli doner (model varsayilani)', () {
      expect(makeProduct().unit, 'koli');
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
