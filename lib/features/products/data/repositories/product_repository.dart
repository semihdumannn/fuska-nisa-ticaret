import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/providers/data_version_provider.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/providers/product_data_providers.dart';
import 'package:nisa_ticaret/features/products/domain/entities/product_entity.dart';

// ────────────────────────────────────────────────────────────
// Riverpod Providers
// ────────────────────────────────────────────────────────────

/// Tüm ürünleri sayfalayarak çeker — 100'lük batch'lerle tüm sayfalara gider.
final allProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(apiProductRepositoryProvider);

  const perPage = 100;
  final all = <ProductModel>[];
  var page = 1;

  while (true) {
    final result = await repo.getProducts(page: page, perPage: perPage);
    final batch = result.fold((_) => <ProductEntity>[], (p) => p);
    all.addAll(batch.map((e) => e.toProductModel()));
    if (batch.length < perPage) break; // son sayfa
    page++;
  }

  return all;
});

// ─── Paginated product list (lazy loading) ──────────────────────────────────

class ProductsPageState {
  final List<ProductModel> products;
  final bool isLoadingMore;
  final bool hasMore;
  final int _nextPage;

  const ProductsPageState({
    this.products = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    int nextPage = 2,
  }) : _nextPage = nextPage;

  ProductsPageState copyWith({
    List<ProductModel>? products,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextPage,
  }) {
    return ProductsPageState(
      products: products ?? this.products,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextPage: nextPage ?? _nextPage,
    );
  }
}

class ProductsPageNotifier extends AsyncNotifier<ProductsPageState> {
  static const _perPage = 50;

  @override
  Future<ProductsPageState> build() async {
    ref.watch(dataVersionProvider);
    return _fetchPage(1, existing: []);
  }

  Future<ProductsPageState> _fetchPage(
    int page, {
    required List<ProductModel> existing,
  }) async {
    final repo = ref.read(apiProductRepositoryProvider);
    final result = await repo.getProducts(page: page, perPage: _perPage);
    final batch = result.fold((_) => <ProductEntity>[], (p) => p);
    final newProducts = batch.map((e) => e.toProductModel()).toList();
    return ProductsPageState(
      products: [...existing, ...newProducts],
      isLoadingMore: false,
      hasMore: batch.length >= _perPage,
      nextPage: page + 1,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final next = await _fetchPage(current._nextPage, existing: current.products);
    state = AsyncData(next);
  }
}

final productsPageProvider =
    AsyncNotifierProvider<ProductsPageNotifier, ProductsPageState>(
  ProductsPageNotifier.new,
);

final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await repo.getFeaturedProducts();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (entities) => entities.map((e) => e.toProductModel()).toList(),
  );
});

/// Bir kategorideki urunler — "Benzer urunler" bolumu icin.
final productsByCategoryProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, categoryId) async {
  ref.watch(dataVersionProvider);
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await repo.getProducts(categoryId: categoryId, perPage: 10);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (entities) => entities.map((e) => e.toProductModel()).toList(),
  );
});
