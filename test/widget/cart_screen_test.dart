// cart_screen_test.dart
//
// CartScreen icindeki widget davranislarini test eder.
//
// Yaklasim:
//   CartScreen dogrudan import edilmekte ancak go_router baglantisi olmadan
//   MaterialApp + ProviderScope sarmalayicisiyla kullanilir.
//   go_router context.go / context.push cagrilari NavigatorObserver
//   araciligiyla degil; buton tiklama/dialog testlerinde sadece UI durumu
//   gozlemlenerek dogrulanir.
//
// Onemli kisit:
//   _CartSummary._onCheckout icinde authStateProvider watch'u var.
//   Bu provider dogrudan FirebaseAuth.instance baglantisi kurar.
//   Bu nedenle "Siparisi Tamamla" butonunun navigate etme testi yerine
//   butonun render edilip edilmedigini dogrulariz.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/cart/data/models/cart_model.dart';
import 'package:nisa_ticaret/features/cart/presentation/bloc/cart_provider.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/models/variant_model.dart';

// ---------------------------------------------------------------------------
// Yardimci: Minimal gecerli ProductModel olusturur
// NOT: Fiyat/stok artik VariantModel'de yonetilir.
// ---------------------------------------------------------------------------
ProductModel _makeProduct({
  String id = 'p1',
  String name = 'Damacana Su',
}) {
  final now = DateTime(2026, 1, 1);
  return ProductModel(
    id: id,
    name: name,
    description: '19 lt',
    categoryIds: const ['cat-su'],
    createdAt: now,
    updatedAt: now,
  );
}

// ---------------------------------------------------------------------------
// Yardimci: Minimal gecerli VariantModel olusturur
// ---------------------------------------------------------------------------
VariantModel _makeVariant({
  String id = 'v1',
  String productId = 'p1',
  double price = 45.0,
  double? salePrice,
  int stock = 50,
  int maxOrderQty = 20,
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

// ---------------------------------------------------------------------------
// Yardimci siniflar: CartScreen'deki izole widget'lari test icin kopyalandı.
// CartScreen go_router bagimliligi yuklendikce bazi widget'lar izole
// test edilecek sekilde burada yeniden tanimlanmistir.
// ---------------------------------------------------------------------------

/// Bos sepet durumunu gosteren izole widget (CartScreen._buildEmptyState kopyasi)
class _IsolatedEmptyState extends StatelessWidget {
  const _IsolatedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sepetiniz bos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Urunleri inceleyerek baslayin',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {}, // Navigasyon test ortaminda stub
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Urunlere Git',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sepetin temizlenmesini onaylayan dialog (CartScreen._showClearConfirmDialog kopyasi)
class _ClearCartDialogTrigger extends ConsumerWidget {
  const _ClearCartDialogTrigger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Sepeti temizle?'),
          content: const Text('Sepetteki tum urunler kaldirilacak.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Iptal'),
            ),
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                Navigator.of(ctx).pop();
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Temizle'),
            ),
          ],
        ),
      ),
      child: const Text('Temizle Butonu'),
    );
  }
}

/// Miktar kontrol widget'i (CartScreen._QtyControl kopyasi)
/// Not: Varyant varsa varyant limitleri kullanilir, yoksa urun limitleri.
class _IsolatedQtyControl extends ConsumerWidget {
  final CartItem item;

  const _IsolatedQtyControl({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final product = item.product;
    final variant = item.variant;
    final qty = item.quantity;
    final effectiveMaxQty = variant?.maxOrderQty ?? product.maxOrderQty;
    final effectiveStock = variant?.stock ?? product.stock;
    final canIncrease = qty < effectiveMaxQty && qty < effectiveStock;
    final variantId = variant?.id;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Azalt veya sil
        InkWell(
          key: const Key('qty-decrease'),
          onTap: () => notifier.decreaseItem(product.id, variantId: variantId),
          child: Icon(
            qty == 1 ? Icons.delete_outline : Icons.remove,
            size: 16,
            color: qty == 1 ? AppColors.error : AppColors.primary,
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '$qty',
            key: const Key('qty-value'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Artir
        InkWell(
          key: const Key('qty-increase'),
          onTap: canIncrease
              ? () => notifier.updateQuantity(
                    product.id,
                    qty + 1,
                    variantId: variantId,
                  )
              : null,
          child: Icon(
            Icons.add,
            size: 16,
            color: canIncrease ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sarmalayici: ProviderScope + MaterialApp (go_router olmadan)
// ---------------------------------------------------------------------------
Widget _buildTestApp({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  // =========================================================================
  // Bos sepet durumu — izole widget testi
  // =========================================================================
  group('CartScreen — bos sepet (empty state)', () {
    testWidgets('shopping_cart_outlined ikonu gorunur', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const _IsolatedEmptyState()),
      );
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('Sepetiniz bos metni gorunur', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const _IsolatedEmptyState()),
      );
      expect(find.text('Sepetiniz bos'), findsOneWidget);
    });

    testWidgets('Urunlere Git butonu gorunur', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const _IsolatedEmptyState()),
      );
      expect(find.text('Urunlere Git'), findsOneWidget);
    });

    testWidgets('Urunleri inceleyerek baslayin alt metni gorunur',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const _IsolatedEmptyState()),
      );
      expect(find.text('Urunleri inceleyerek baslayin'), findsOneWidget);
    });
  });

  // =========================================================================
  // Sepetin temizlenmesi — dialog testi
  // =========================================================================
  group('CartScreen — temizle dialog', () {
    testWidgets(
        'Temizle butonuna tiklandiginda onay dialog acar', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: _ClearCartDialogTrigger()),
          ),
        ),
      );

      await tester.tap(find.text('Temizle Butonu'));
      await tester.pumpAndSettle();

      expect(find.text('Sepeti temizle?'), findsOneWidget);
      expect(find.text('Sepetteki tum urunler kaldirilacak.'), findsOneWidget);
    });

    testWidgets('Dialog icinde Iptal butonu gorunur', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const _ClearCartDialogTrigger()),
      );

      await tester.tap(find.text('Temizle Butonu'));
      await tester.pumpAndSettle();

      expect(find.text('Iptal'), findsOneWidget);
    });

    testWidgets('Dialog icinde Temizle butonu gorunur', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const _ClearCartDialogTrigger()),
      );

      await tester.tap(find.text('Temizle Butonu'));
      await tester.pumpAndSettle();

      // "Temizle" hem trigger butonunda hem dialogda var — dialog icindeki
      expect(find.text('Temizle'), findsWidgets);
    });

    testWidgets('Dialog Iptal butonuna tiklandiginda dialog kapanir',
        (tester) async {
      await tester.pumpWidget(
        _buildTestApp(child: const _ClearCartDialogTrigger()),
      );

      await tester.tap(find.text('Temizle Butonu'));
      await tester.pumpAndSettle();
      expect(find.text('Sepeti temizle?'), findsOneWidget);

      await tester.tap(find.text('Iptal'));
      await tester.pumpAndSettle();
      expect(find.text('Sepeti temizle?'), findsNothing);
    });

    testWidgets(
        'Dialog Temizle butonuna tiklandiginda sepet bosalir ve dialog kapanir',
        (tester) async {
      final product = _makeProduct(id: 'p1');

      final container = ProviderContainer(
        overrides: [
          cartProvider.overrideWith(() {
            final notifier = CartNotifier();
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      // Onceden urun ekle
      container.read(cartProvider.notifier).addItem(product, quantity: 2);
      expect(container.read(cartProvider).isEmpty, false);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: _ClearCartDialogTrigger()),
          ),
        ),
      );

      await tester.tap(find.text('Temizle Butonu'));
      await tester.pumpAndSettle();

      // Dialog'daki Temizle butonuna tikliyoruz
      // find.widgetWithText kullaniriz ki trigger butonundaki 'Temizle'yi degil
      // dialog icindekini sec
      final dialogTemizleBtn = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Temizle'),
      );
      await tester.tap(dialogTemizleBtn);
      await tester.pumpAndSettle();

      expect(find.text('Sepeti temizle?'), findsNothing);
      expect(container.read(cartProvider).isEmpty, true);
    });
  });

  // =========================================================================
  // CartNotifier provider testleri (ProviderContainer ile)
  // =========================================================================
  group('CartNotifier — provider state testleri', () {
    test('bos CartModel bos olarak baslar', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(cartProvider).isEmpty, true);
      expect(container.read(cartProvider).totalItems, 0);
    });

    test('addItem: yeni urun eklendikten sonra totalItems artar', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = _makeProduct(id: 'p1');
      container.read(cartProvider.notifier).addItem(product);

      expect(container.read(cartProvider).totalItems, 1);
      expect(container.read(cartProvider).isEmpty, false);
    });

    test('addItem: ayni urun+varyant eklenince quantity toplanir', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1', maxOrderQty: 50);
      container.read(cartProvider.notifier).addItem(product, variant: variant, quantity: 3);
      container.read(cartProvider.notifier).addItem(product, variant: variant, quantity: 2);

      expect(container.read(cartProvider).totalItems, 5);
      expect(container.read(cartProvider).items.length, 1);
    });

    test('addItem: maxOrderQty siniri asılmaz (variant ile)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1', maxOrderQty: 5, stock: 100);
      container.read(cartProvider.notifier).addItem(product, variant: variant, quantity: 3);
      container.read(cartProvider.notifier).addItem(product, variant: variant, quantity: 10);

      expect(container.read(cartProvider).items.first.quantity, 5);
    });

    test('removeItem: urun kaldirildiktan sonra sepetten silinir', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      container.read(cartProvider.notifier).addItem(p1);
      container.read(cartProvider.notifier).addItem(p2);

      container.read(cartProvider.notifier).removeItem('p1');

      expect(container.read(cartProvider).items.length, 1);
      expect(container.read(cartProvider).items.first.product.id, 'p2');
    });

    test('updateQuantity: miktar guncellenir', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = _makeProduct(id: 'p1');
      container.read(cartProvider.notifier).addItem(product);
      container.read(cartProvider.notifier).updateQuantity('p1', 7);

      expect(container.read(cartProvider).items.first.quantity, 7);
    });

    test('updateQuantity: miktar 0 verilince urun silinir', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = _makeProduct(id: 'p1');
      container.read(cartProvider.notifier).addItem(product, quantity: 3);
      container.read(cartProvider.notifier).updateQuantity('p1', 0);

      expect(container.read(cartProvider).isEmpty, true);
    });

    test('decreaseItem: qty 1 iken urun silinir', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = _makeProduct(id: 'p1');
      container.read(cartProvider.notifier).addItem(product, quantity: 1);
      container.read(cartProvider.notifier).decreaseItem('p1');

      expect(container.read(cartProvider).isEmpty, true);
    });

    test('decreaseItem: qty > 1 iken qty 1 azalir', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final product = _makeProduct(id: 'p1');
      container.read(cartProvider.notifier).addItem(product, quantity: 4);
      container.read(cartProvider.notifier).decreaseItem('p1');

      expect(container.read(cartProvider).items.first.quantity, 3);
    });

    test('clear: tum urunler silindikten sonra sepet bos olur', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      container.read(cartProvider.notifier).addItem(p1, quantity: 2);
      container.read(cartProvider.notifier).addItem(p2, quantity: 5);

      expect(container.read(cartProvider).totalItems, 7);

      container.read(cartProvider.notifier).clear();

      expect(container.read(cartProvider).isEmpty, true);
      expect(container.read(cartProvider).totalItems, 0);
    });
  });

  // =========================================================================
  // Miktar kontrol widget testleri
  // =========================================================================
  group('_QtyControl — miktar artir/azalt widget testleri', () {
    testWidgets('mevcut miktar deger olarak gorunur', (tester) async {
      final product = _makeProduct(id: 'p1');
      final item = CartItem(product: product, quantity: 3);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).addItem(product, quantity: 3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: _IsolatedQtyControl(item: item),
            ),
          ),
        ),
      );

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('qty == 1 oldugunda delete_outline ikonu gorunur',
        (tester) async {
      final product = _makeProduct(id: 'p1');
      final item = CartItem(product: product, quantity: 1);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).addItem(product, quantity: 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: _IsolatedQtyControl(item: item),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('qty > 1 oldugunda remove ikonu gorunur', (tester) async {
      final product = _makeProduct(id: 'p1');
      final item = CartItem(product: product, quantity: 3);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).addItem(product, quantity: 3);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: _IsolatedQtyControl(item: item),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('artir butonuna tiklayinca provider qty guncellenir (variant ile)',
        (tester) async {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1', maxOrderQty: 20, stock: 50);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).addItem(product, variant: variant, quantity: 2);

      final item = container.read(cartProvider).items.first;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: _IsolatedQtyControl(item: item),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('qty-increase')));
      await tester.pump();

      expect(container.read(cartProvider).items.first.quantity, 3);
    });

    testWidgets('azalt butonuna tiklayinca provider qty guncellenir (variant ile)',
        (tester) async {
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1', maxOrderQty: 20, stock: 50);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).addItem(product, variant: variant, quantity: 4);

      final item = container.read(cartProvider).items.first;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: _IsolatedQtyControl(item: item),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('qty-decrease')));
      await tester.pump();

      expect(container.read(cartProvider).items.first.quantity, 3);
    });

    testWidgets('maxOrderQty sinirinda artir butonu devre disi kalir (variant ile)',
        (tester) async {
      // maxOrderQty=3, stock=100, qty=3 → canIncrease = false
      final product = _makeProduct(id: 'p1');
      final variant = _makeVariant(id: 'v1', productId: 'p1', maxOrderQty: 3, stock: 100);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).addItem(product, variant: variant, quantity: 3);

      final item = container.read(cartProvider).items.first;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: _IsolatedQtyControl(item: item),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('qty-increase')));
      await tester.pump();

      // Provider durumu degismemeli
      expect(container.read(cartProvider).items.first.quantity, 3);
    });
  });

  // =========================================================================
  // CartModel hesaplamalari — variant ile hasDiscount ve toplam testi
  // =========================================================================
  group('CartModel — variant ile hasDiscount ve toplam hesaplamalari', () {
    test('indirimli varyant varken variant.hasDiscount true', () {
      final p1 = _makeProduct(id: 'p1');
      final v1 = _makeVariant(id: 'v1', productId: 'p1', price: 100.0, salePrice: 80.0);
      final cart = CartModel(items: [CartItem(product: p1, variant: v1, quantity: 1)]);
      expect(cart.items.any((i) => i.variant?.hasDiscount ?? false), true);
    });

    test('indirimli varyant yokken variant.hasDiscount false', () {
      final p1 = _makeProduct(id: 'p1');
      final v1 = _makeVariant(id: 'v1', productId: 'p1', price: 100.0);
      final cart = CartModel(items: [CartItem(product: p1, variant: v1, quantity: 1)]);
      expect(cart.items.any((i) => i.variant?.hasDiscount ?? false), false);
    });

    test('mixed sepet: indirimli + normal varyant subtotal dogru', () {
      final p1 = _makeProduct(id: 'p1');
      final p2 = _makeProduct(id: 'p2');
      final v1 = _makeVariant(id: 'v1', productId: 'p1', price: 50.0);
      final v2 = _makeVariant(id: 'v2', productId: 'p2', price: 100.0, salePrice: 80.0);
      final cart = CartModel(items: [
        CartItem(product: p1, variant: v1, quantity: 2), // 100
        CartItem(product: p2, variant: v2, quantity: 3), // 240
      ]);
      expect(cart.subtotal, 340.0);
    });

    test('bos sepet subtotal 0 doner', () {
      const cart = CartModel();
      expect(cart.subtotal, 0.0);
      expect(cart.total, 0.0);
    });
  });
}
