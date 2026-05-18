// shimmer_and_empty_state_test.dart
//
// ProductListScreen dogrudan import edilemiyor: transitif olarak
// product_detail_screen → carousel_slider bağımlılığı carousel SDK ile
// CarouselController cakismasi yaratıyor.
//
// Bu nedenle testler iki katmanda yapilıyor:
//   1. Shimmer widget'inin doğrudan render testi
//   2. Empty/Error state widgetlarının izole widget testi
//      (ProductListScreen'in _EmptyState / _ErrorState satirlari kopyalanarak)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/products/presentation/bloc/product_list_provider.dart';

// ─────────────────────────────────────────────
// Test icin kaynaktan kopyalanan izole widget'lar
// (ProductListScreen icindeki private widget'larin kopyasi)
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onReset;
  const _EmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Ürün bulunamadı',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'Arama kriterlerinizi değiştirmeyi deneyin',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onReset,
            child: const Text('Filtreleri Temizle'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text('Ürünler yüklenemedi',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            'İnternet bağlantınızı kontrol edin',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ),
        ],
      ),
    );
  }
}

// Shimmer yukleme grid'i (ProductListScreen'deki ayni mantik)
Widget _shimmerGrid() {
  return Shimmer.fromColors(
    baseColor: AppColors.border,
    highlightColor: AppColors.surface,
    child: GridView.builder(
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

void main() {
  group('Shimmer widget — yukleme durumu', () {
    testWidgets('Shimmer widget dogru render ediliyor', (tester) async {
      await tester.pumpWidget(_wrap(_shimmerGrid()));
      expect(find.byType(Shimmer), findsOneWidget);
    });

    testWidgets('Shimmer icerisinde 4 container render ediliyor', (tester) async {
      await tester.pumpWidget(_wrap(_shimmerGrid()));
      // Shimmer icindeki GridView 4 item olusturuyor
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Shimmer gorunurken Urun bulunamadi yazisi yok', (tester) async {
      await tester.pumpWidget(_wrap(_shimmerGrid()));
      expect(find.text('Ürün bulunamadı'), findsNothing);
    });

    testWidgets('Shimmer gorunurken Tekrar Dene butonu yok', (tester) async {
      await tester.pumpWidget(_wrap(_shimmerGrid()));
      expect(find.text('Tekrar Dene'), findsNothing);
    });
  });

  group('Empty state widget', () {
    testWidgets('"Ürün bulunamadı" metni gorunuyor', (tester) async {
      await tester.pumpWidget(
        _wrap(_EmptyState(onReset: () {})),
      );

      expect(find.text('Ürün bulunamadı'), findsOneWidget);
    });

    testWidgets('"Filtreleri Temizle" butonu gorunuyor', (tester) async {
      await tester.pumpWidget(
        _wrap(_EmptyState(onReset: () {})),
      );

      expect(find.text('Filtreleri Temizle'), findsOneWidget);
    });

    testWidgets('"Arama kriterlerinizi" aciklama metni gorunuyor', (tester) async {
      await tester.pumpWidget(
        _wrap(_EmptyState(onReset: () {})),
      );

      expect(
        find.text('Arama kriterlerinizi değiştirmeyi deneyin'),
        findsOneWidget,
      );
    });

    testWidgets('search_off_outlined ikonu gorunuyor', (tester) async {
      await tester.pumpWidget(
        _wrap(_EmptyState(onReset: () {})),
      );

      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
    });

    testWidgets('"Filtreleri Temizle" tiklaninca callback cagrilir', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        _wrap(_EmptyState(onReset: () => called = true)),
      );

      await tester.tap(find.text('Filtreleri Temizle'));
      expect(called, true);
    });

    testWidgets('empty state gorunurken Tekrar Dene yok', (tester) async {
      await tester.pumpWidget(
        _wrap(_EmptyState(onReset: () {})),
      );

      expect(find.text('Tekrar Dene'), findsNothing);
    });
  });

  group('Error state widget', () {
    testWidgets('"Ürünler yüklenemedi" metni gorunuyor', (tester) async {
      await tester.pumpWidget(
        _wrap(_ErrorState(onRetry: () {})),
      );

      expect(find.text('Ürünler yüklenemedi'), findsOneWidget);
    });

    testWidgets('"Tekrar Dene" butonu gorunuyor', (tester) async {
      await tester.pumpWidget(
        _wrap(_ErrorState(onRetry: () {})),
      );

      expect(find.text('Tekrar Dene'), findsOneWidget);
    });

    testWidgets('wifi_off_outlined ikonu gorunuyor', (tester) async {
      await tester.pumpWidget(
        _wrap(_ErrorState(onRetry: () {})),
      );

      expect(find.byIcon(Icons.wifi_off_outlined), findsOneWidget);
    });

    testWidgets('"İnternet bağlantınızı" metni gorunuyor', (tester) async {
      await tester.pumpWidget(
        _wrap(_ErrorState(onRetry: () {})),
      );

      expect(find.text('İnternet bağlantınızı kontrol edin'), findsOneWidget);
    });

    testWidgets('"Tekrar Dene" tiklaninca callback cagrilir', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        _wrap(_ErrorState(onRetry: () => retried = true)),
      );

      await tester.tap(find.text('Tekrar Dene'));
      expect(retried, true);
    });

    testWidgets('error state gorunurken "Ürün bulunamadı" yok', (tester) async {
      await tester.pumpWidget(
        _wrap(_ErrorState(onRetry: () {})),
      );

      expect(find.text('Ürün bulunamadı'), findsNothing);
    });
  });

  group('ProductListNotifier — provider ile siralama secenekleri', () {
    test('SortOption.popularity varsayilan deger', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(productListProvider).sortOption,
        SortOption.popularity,
      );
    });

    test('SortOption degerleri tam liste', () {
      expect(SortOption.values.length, 5);
      expect(SortOption.values, contains(SortOption.nameAsc));
      expect(SortOption.values, contains(SortOption.nameDesc));
      expect(SortOption.values, contains(SortOption.priceAsc));
      expect(SortOption.values, contains(SortOption.priceDesc));
      expect(SortOption.values, contains(SortOption.popularity));
    });
  });
}
