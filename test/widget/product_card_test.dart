import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/home/widgets/product_card.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';

// ─────────────────────────────────────────────
// Test yardimci: gecerli ProductModel olusturur
// NOT: Fiyat/stok artik VariantModel'de. ProductCard sadece
//      meta veri (isim, gorsel) ve navigasyon gosterir.
//      Fiyat gosterimi artik 0.00 TL olarak gorunur (variant secilmeden).
// ─────────────────────────────────────────────

ProductModel _makeProduct({
  String id = 'test-id',
  String name = 'Test Urun',
  String categoryId = 'cat1',
  String? imageUrl,
}) {
  final now = DateTime(2026, 1, 1);
  return ProductModel(
    id: id,
    name: name,
    description: 'Aciklama',
    categoryId: categoryId,
    imageUrl: imageUrl,
    createdAt: now,
    updatedAt: now,
  );
}

// ProductCard'i test ortamina sarmalar
Widget _wrapCard(ProductModel product, {bool showAddButton = true}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 280,
          child: ProductCard(
            product: product,
            showAddButton: showAddButton,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ProductCard — temel icerik', () {
    testWidgets('urun adi gorunuyor', (tester) async {
      final product = _makeProduct(name: 'Damacana Su');
      await tester.pumpWidget(_wrapCard(product));

      expect(find.text('Damacana Su'), findsOneWidget);
    });

    testWidgets('fiyat 0.00 TL gorunuyor (variant secilmeden)', (tester) async {
      // ProductModel.effectivePrice = 0.0 (varyant yokken fallback)
      final product = _makeProduct();
      await tester.pumpWidget(_wrapCard(product));

      expect(find.text('₺0.00'), findsOneWidget);
    });
  });

  group('ProductCard — indirim badge', () {
    testWidgets('ProductModel.hasDiscount=false oldugu icin badge hic gorunmez', (tester) async {
      // Yeni mimaride hasDiscount=false (varyant kontrol eder)
      final product = _makeProduct();
      await tester.pumpWidget(_wrapCard(product));
      await tester.pump();

      expect(find.textContaining('İndirim'), findsNothing);
    });
  });

  group('ProductCard — stok durumu', () {
    testWidgets('ProductModel.inStock=true oldugu icin Stok Yok overlay yok', (tester) async {
      // Yeni mimaride inStock=true (varyant kontrol eder)
      final product = _makeProduct();
      await tester.pumpWidget(_wrapCard(product));
      await tester.pump();

      expect(find.text('Stok Yok'), findsNothing);
    });

    testWidgets('stok true ve showAddButton=true iken ekle butonu gorunuyor', (tester) async {
      // inStock=true geldigi icin + ikonu gozukecek
      final product = _makeProduct();
      await tester.pumpWidget(_wrapCard(product, showAddButton: true));
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('ProductCard — gorsel alani', () {
    testWidgets('imageUrl=null iken placeholder icon gorunuyor', (tester) async {
      final product = _makeProduct(imageUrl: null);
      await tester.pumpWidget(_wrapCard(product));
      await tester.pump();

      expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    });

    testWidgets('imageUrl dolu iken widget agaci olusturulur', (tester) async {
      final product = _makeProduct(imageUrl: 'https://example.com/img.jpg');
      await tester.pumpWidget(_wrapCard(product));
      await tester.pump();

      expect(find.byType(ProductCard), findsOneWidget);
    });
  });

  group('ProductCard — ek deger dogrulamalari', () {
    testWidgets('showAddButton=false iken ekle butonu yok', (tester) async {
      final product = _makeProduct();
      await tester.pumpWidget(_wrapCard(product, showAddButton: false));
      await tester.pump();

      expect(find.byIcon(Icons.add), findsNothing);
    });
  });
}
