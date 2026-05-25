import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/product_data_providers.dart';
import '../../domain/entities/brand_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_brands_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_product_detail_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';

export '../../data/providers/product_data_providers.dart'
    show productRemoteDatasourceProvider, apiProductRepositoryProvider;

// ---------------------------------------------------------------------------
// Products list state
// ---------------------------------------------------------------------------

@immutable
class ProductsState {
  final List<ProductEntity> products;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final String? activeCategoryId;
  final String? activeBrandId;
  final String? activeSearchQuery;
  final String? activeSortBy;

  const ProductsState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 1,
    this.activeCategoryId,
    this.activeBrandId,
    this.activeSearchQuery,
    this.activeSortBy,
  });

  ProductsState copyWith({
    List<ProductEntity>? products,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? hasMore,
    int? currentPage,
    String? activeCategoryId,
    bool clearCategory = false,
    String? activeBrandId,
    bool clearBrand = false,
    String? activeSearchQuery,
    bool clearSearch = false,
    String? activeSortBy,
    bool clearSort = false,
  }) {
    return ProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      activeCategoryId:
          clearCategory ? null : (activeCategoryId ?? this.activeCategoryId),
      activeBrandId: clearBrand ? null : (activeBrandId ?? this.activeBrandId),
      activeSearchQuery:
          clearSearch ? null : (activeSearchQuery ?? this.activeSearchQuery),
      activeSortBy: clearSort ? null : (activeSortBy ?? this.activeSortBy),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier (Riverpod 3.x — Notifier<T>)
// ---------------------------------------------------------------------------

class ApiProductsNotifier extends Notifier<ProductsState> {
  @override
  ProductsState build() {
    // Eager load on creation
    Future.microtask(() => _fetchProducts(resetState: true));
    return const ProductsState(isLoading: true);
  }

  // -----------------------------------------------------------------------
  // Public API
  // -----------------------------------------------------------------------

  Future<void> refresh() => _fetchProducts(resetState: true);

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await _fetchProducts(resetState: false);
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    state = ProductsState(
      isLoading: true,
      activeSearchQuery: trimmed.isEmpty ? null : trimmed,
    );
    await _fetchProducts(resetState: true);
  }

  Future<void> filterByCategory(String? categoryId) async {
    state = ProductsState(
      isLoading: true,
      activeCategoryId: categoryId,
      activeBrandId: state.activeBrandId,
      activeSortBy: state.activeSortBy,
    );
    await _fetchProducts(resetState: true);
  }

  Future<void> filterByBrand(String? brandId) async {
    state = ProductsState(
      isLoading: true,
      activeCategoryId: state.activeCategoryId,
      activeBrandId: brandId,
      activeSortBy: state.activeSortBy,
    );
    await _fetchProducts(resetState: true);
  }

  Future<void> sortBy(String? sortKey) async {
    state = ProductsState(
      isLoading: true,
      activeCategoryId: state.activeCategoryId,
      activeBrandId: state.activeBrandId,
      activeSearchQuery: state.activeSearchQuery,
      activeSortBy: sortKey,
    );
    await _fetchProducts(resetState: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // -----------------------------------------------------------------------
  // Private fetch
  // -----------------------------------------------------------------------

  Future<void> _fetchProducts({required bool resetState}) async {
    final page = resetState ? 1 : state.currentPage;

    final repo = ref.read(apiProductRepositoryProvider);
    final result = await GetProductsUsecase(repo)(
      page: page,
      categoryId: state.activeCategoryId,
      brandId: state.activeBrandId,
      searchQuery: state.activeSearchQuery,
      sortBy: state.activeSortBy,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (products) {
        final newProducts =
            resetState ? products : [...state.products, ...products];
        state = state.copyWith(
          products: newProducts,
          isLoading: false,
          hasMore: products.length >= 20,
          currentPage: page + 1,
          clearError: true,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final apiProductsNotifierProvider =
    NotifierProvider<ApiProductsNotifier, ProductsState>(
  ApiProductsNotifier.new,
);

/// Kategori bazlı ürün listesi
final apiProductsByCategoryProvider =
    FutureProvider.family<List<ProductEntity>, String>((ref, categoryId) async {
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await GetProductsUsecase(repo)(categoryId: categoryId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (products) => products,
  );
});

/// Öne çıkan ürünler
final apiFeaturedProductsProvider =
    FutureProvider<List<ProductEntity>>((ref) async {
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await repo.getFeaturedProducts();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (products) => products,
  );
});

/// Kategoriler (24 saat cache)
final apiCategoriesProvider =
    FutureProvider<List<CategoryEntity>>((ref) async {
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await GetCategoriesUsecase(repo)();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (categories) => categories,
  );
});

/// Markalar
final apiBrandsProvider = FutureProvider<List<BrandEntity>>((ref) async {
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await GetBrandsUsecase(repo)();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (brands) => brands,
  );
});

/// Ürün detay (ID bazlı, cache'li)
final apiProductDetailProvider =
    FutureProvider.family<ProductEntity, String>((ref, productId) async {
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await GetProductDetailUsecase(repo)(productId);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (product) => product,
  );
});

/// Arama sonuçları
final apiSearchResultsProvider =
    FutureProvider.family<List<ProductEntity>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await SearchProductsUsecase(repo)(query.trim());
  return result.fold(
    (failure) => throw Exception(failure.message),
    (products) => products,
  );
});
