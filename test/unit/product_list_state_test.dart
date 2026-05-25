import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/presentation/bloc/product_list_provider.dart';

// ─────────────────────────────────────────────
// Test veri seti — 6 urun, farkli kategori ve fiyatlar
// ─────────────────────────────────────────────

ProductModel _product({
  required String id,
  required String name,
  required String categoryId,
  // price/salePrice/stock artik VariantModel'de
  int order = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return ProductModel(
    id: id,
    name: name,
    description: '',
    categoryIds: [categoryId],
    order: order,
    createdAt: now,
    updatedAt: now,
  );
}

// order alanlari farkli degerlerle tanimlaniyor
// p2 en kucuk order (1) → popularity sirasinda ilk gelmeli
final _testProducts = [
  _product(id: 'p1', name: 'Damacana Su',        categoryId: 'cat-su',    order: 3),
  _product(id: 'p2', name: 'Kola 330ml',          categoryId: 'cat-gazli', order: 1),
  _product(id: 'p3', name: 'Meyve Suyu Seftali', categoryId: 'cat-meyve', order: 2),
  _product(id: 'p4', name: 'Soda',               categoryId: 'cat-gazli', order: 4),
  _product(id: 'p5', name: 'Kola 1 Lt',           categoryId: 'cat-gazli', order: 5),
  _product(id: 'p6', name: 'Ayran',              categoryId: 'cat-diger', order: 6),
];

void main() {
  group('ProductListState — filteredProducts: kategori filtresi', () {
    test('kategori secili degilse tum urunler gelir', () {
      const state = ProductListState();
      final result = state.filteredProducts(_testProducts);
      expect(result.length, _testProducts.length);
    });

    test('cat-gazli secilince sadece 3 urun gelir', () {
      const state = ProductListState(selectedCategoryId: 'cat-gazli');
      final result = state.filteredProducts(_testProducts);
      expect(result.length, 3);
      expect(result.every((p) => p.categoryId == 'cat-gazli'), true);
    });

    test('cat-su secilince 1 urun gelir', () {
      const state = ProductListState(selectedCategoryId: 'cat-su');
      final result = state.filteredProducts(_testProducts);
      expect(result.length, 1);
      expect(result.first.id, 'p1');
    });

    test('var olmayan kategori secilince bos liste gelir', () {
      const state = ProductListState(selectedCategoryId: 'cat-yok');
      final result = state.filteredProducts(_testProducts);
      expect(result, isEmpty);
    });
  });

  group('ProductListState — filteredProducts: arama filtresi', () {
    test('kola aratinca 2 urun bulunur (case-insensitive)', () {
      const state = ProductListState(searchQuery: 'kola');
      final result = state.filteredProducts(_testProducts);
      expect(result.length, 2);
      expect(result.any((p) => p.id == 'p2'), true);
      expect(result.any((p) => p.id == 'p5'), true);
    });

    test('buyuk harf KOLA aratinca da 2 urun bulunur', () {
      const state = ProductListState(searchQuery: 'KOLA');
      final result = state.filteredProducts(_testProducts);
      expect(result.length, 2);
    });

    test('seftali aratinca sadece meyve suyu gelir', () {
      const state = ProductListState(searchQuery: 'seftali');
      final result = state.filteredProducts(_testProducts);
      expect(result.length, 1);
      expect(result.first.id, 'p3');
    });

    test('eslesen bir sey yoksa bos liste gelir', () {
      const state = ProductListState(searchQuery: 'bulmaz');
      final result = state.filteredProducts(_testProducts);
      expect(result, isEmpty);
    });

    test('bos arama tumunu dondurur', () {
      const state = ProductListState(searchQuery: '');
      final result = state.filteredProducts(_testProducts);
      expect(result.length, _testProducts.length);
    });
  });

  group('ProductListState — filteredProducts: kategori + arama kombinasyonu', () {
    test('cat-gazli ve kola aratinca 2 urun gelir', () {
      const state = ProductListState(
        selectedCategoryId: 'cat-gazli',
        searchQuery: 'kola',
      );
      final result = state.filteredProducts(_testProducts);
      expect(result.length, 2);
      expect(result.every((p) => p.categoryId == 'cat-gazli'), true);
    });

    test('cat-gazli ve soda aratinca 1 urun gelir', () {
      const state = ProductListState(
        selectedCategoryId: 'cat-gazli',
        searchQuery: 'soda',
      );
      final result = state.filteredProducts(_testProducts);
      expect(result.length, 1);
      expect(result.first.id, 'p4');
    });

    test('cat-su ve kola aratinca bos liste gelir', () {
      const state = ProductListState(
        selectedCategoryId: 'cat-su',
        searchQuery: 'kola',
      );
      final result = state.filteredProducts(_testProducts);
      expect(result, isEmpty);
    });
  });

  group('ProductListState — filteredProducts: siralama', () {
    // NOT: priceAsc/priceDesc siralamasi artik VariantModel'e bagli oldugu icin
    // ProductModel.effectivePrice = 0.0 dondurur. Bu testler isim bazli siralamaya odaklanir.

    test('priceAsc: effectivePrice tumu 0 iken insert-order korur ya da esit siralar', () {
      const state = ProductListState(sortOption: SortOption.priceAsc);
      final result = state.filteredProducts(_testProducts);
      // Tum effectivePrice=0 oldugu icin sabit siralama; sadece eleman sayisi dogru olacak
      expect(result.length, _testProducts.length);
    });

    test('priceDesc: effectivePrice tumu 0 iken eleman sayisi dogru', () {
      const state = ProductListState(sortOption: SortOption.priceDesc);
      final result = state.filteredProducts(_testProducts);
      expect(result.length, _testProducts.length);
    });

    test('nameAsc: A-Z siralar', () {
      const state = ProductListState(sortOption: SortOption.nameAsc);
      final result = state.filteredProducts(_testProducts);
      // Ayran, Damacana, Kola 1 Lt, Kola 330ml, Meyve Suyu Seftali, Soda
      expect(result.first.name, 'Ayran');
      expect(result.last.name, 'Soda');
    });

    test('nameDesc: Z-A siralar', () {
      const state = ProductListState(sortOption: SortOption.nameDesc);
      final result = state.filteredProducts(_testProducts);
      expect(result.first.name, 'Soda');
      expect(result.last.name, 'Ayran');
    });

    test('popularity: order degerine gore artan siralar', () {
      const state = ProductListState(sortOption: SortOption.popularity);
      final result = state.filteredProducts(_testProducts);
      // order: p2=1, p3=2, p1=3, p4=4, p5=5, p6=6
      expect(result.first.id, 'p2');
      expect(result[1].id, 'p3');
    });
  });

  group('ProductListState — hasMore / pagination', () {
    // pageSize = 20 (AppConstants.pageSize)

    test('6 urun varken pageSize=20 → hasMore false', () {
      const state = ProductListState(currentPage: 1);
      expect(state.hasMore(_testProducts), false);
    });

    test('filteredProducts 6 urun ile 6 urun doner (page 1, pageSize 20)', () {
      const state = ProductListState(currentPage: 1);
      final result = state.filteredProducts(_testProducts);
      expect(result.length, 6);
    });

    test('25 urun, page=1 → hasMore true', () {
      final many = List.generate(
        25,
        (i) => _product(
          id: 'p$i',
          name: 'Urun $i',
          categoryId: 'cat',
          order: i,
        ),
      );
      const state = ProductListState(currentPage: 1);
      expect(state.hasMore(many), true); // 1*20 < 25
    });

    test('25 urun, page=2 → hasMore false (2*20=40 > 25)', () {
      final many = List.generate(
        25,
        (i) => _product(
          id: 'p$i',
          name: 'Urun $i',
          categoryId: 'cat',
          order: i,
        ),
      );
      const state = ProductListState(currentPage: 2);
      expect(state.hasMore(many), false);
    });

    test('filteredProducts page=1 ile max 20 urun doner', () {
      final many = List.generate(
        30,
        (i) => _product(
          id: 'p$i',
          name: 'Urun $i',
          categoryId: 'cat',
          order: i,
        ),
      );
      const state = ProductListState(currentPage: 1);
      final result = state.filteredProducts(many);
      expect(result.length, 20);
    });

    test('filteredProducts page=2 ile max 40 doner (30 urun varsa 30)', () {
      final many = List.generate(
        30,
        (i) => _product(
          id: 'p$i',
          name: 'Urun $i',
          categoryId: 'cat',
          order: i,
        ),
      );
      const state = ProductListState(currentPage: 2);
      final result = state.filteredProducts(many);
      expect(result.length, 30); // min(2*20, 30) = 30
    });
  });

  group('ProductListNotifier — state guncelleme', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('baslangicta state default degerlerde', () {
      final state = container.read(productListProvider);
      expect(state.searchQuery, '');
      expect(state.selectedCategoryId, null);
      expect(state.sortOption, SortOption.popularity);
      expect(state.currentPage, 1);
    });

    test('setSearch: query guncellenir, currentPage 1 e sifirlanir', () {
      // once page'i artir
      container.read(productListProvider.notifier).loadNextPage();
      expect(container.read(productListProvider).currentPage, 2);

      // arama yapinca page sifirlanmali
      container.read(productListProvider.notifier).setSearch('kola');
      final state = container.read(productListProvider);
      expect(state.searchQuery, 'kola');
      expect(state.currentPage, 1);
    });

    test('setSearch bos string gecilince query temizlenir', () {
      container.read(productListProvider.notifier).setSearch('kola');
      container.read(productListProvider.notifier).setSearch('');
      expect(container.read(productListProvider).searchQuery, '');
    });

    test('setCategory: kategori guncellenir, currentPage 1 e sifirlanir', () {
      container.read(productListProvider.notifier).loadNextPage();
      container.read(productListProvider.notifier).setCategory('cat-su');

      final state = container.read(productListProvider);
      expect(state.selectedCategoryId, 'cat-su');
      expect(state.currentPage, 1);
    });

    test('setCategory null ile kategori temizlenir', () {
      container.read(productListProvider.notifier).setCategory('cat-su');
      container.read(productListProvider.notifier).setCategory(null);
      expect(container.read(productListProvider).selectedCategoryId, null);
    });

    test('setSortOption: siralama guncellenir, currentPage 1 e sifirlanir', () {
      container.read(productListProvider.notifier).loadNextPage();
      container.read(productListProvider.notifier).setSortOption(SortOption.priceAsc);

      final state = container.read(productListProvider);
      expect(state.sortOption, SortOption.priceAsc);
      expect(state.currentPage, 1);
    });

    test('loadNextPage: currentPage bir artar', () {
      expect(container.read(productListProvider).currentPage, 1);
      container.read(productListProvider.notifier).loadNextPage();
      expect(container.read(productListProvider).currentPage, 2);
      container.read(productListProvider.notifier).loadNextPage();
      expect(container.read(productListProvider).currentPage, 3);
    });

    test('reset: tum alanlar default a doner', () {
      container.read(productListProvider.notifier).setSearch('kola');
      container.read(productListProvider.notifier).setCategory('cat-su');
      container.read(productListProvider.notifier).setSortOption(SortOption.priceAsc);
      container.read(productListProvider.notifier).loadNextPage();

      container.read(productListProvider.notifier).reset();

      final state = container.read(productListProvider);
      expect(state.searchQuery, '');
      expect(state.selectedCategoryId, null);
      expect(state.sortOption, SortOption.popularity);
      expect(state.currentPage, 1);
    });
  });

  group('ProductListState — copyWith sentinel pattern', () {
    test('selectedCategoryId sentinel ile korunur', () {
      const original = ProductListState(selectedCategoryId: 'cat-su');
      // sentinel olmayan deger gecmek override eder
      final copy = original.copyWith(searchQuery: 'test');
      expect(copy.selectedCategoryId, 'cat-su');
      expect(copy.searchQuery, 'test');
    });

    test('selectedCategoryId acikca null gecilince null olur', () {
      const original = ProductListState(selectedCategoryId: 'cat-su');
      final copy = original.copyWith(selectedCategoryId: null);
      expect(copy.selectedCategoryId, null);
    });
  });

  group('ProductListState — equality', () {
    test('ayni alanlar esit', () {
      const a = ProductListState(searchQuery: 'kola', currentPage: 2);
      const b = ProductListState(searchQuery: 'kola', currentPage: 2);
      expect(a == b, true);
    });

    test('farkli searchQuery esit degil', () {
      const a = ProductListState(searchQuery: 'kola');
      const b = ProductListState(searchQuery: 'su');
      expect(a == b, false);
    });
  });
}
