import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/config/app_config.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/providers/data_version_provider.dart';
import 'package:nisa_ticaret/core/services/cache_service.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/providers/product_data_providers.dart';
import 'package:nisa_ticaret/features/products/domain/entities/product_entity.dart';
import 'package:nisa_ticaret/features/products/data/repositories/category_repository.dart'
    show RepositoryException;

class ProductRepository {
  final FirebaseFirestore _firestore;
  final CacheService _cache;

  static const _allProductsCacheKey = 'products_all_v2';
  static const _featuredCacheKey = 'products_featured_v2';
  Duration get _cacheTtl => appConfig.productsCacheDuration;

  ProductRepository({
    FirebaseFirestore? firestore,
    CacheService? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? cacheService;

  /// staleWhileRevalidate: cache varsa hemen döndür, arka planda güncelle.
  Future<List<ProductModel>> getProducts() async {
    return _staleWhileRevalidate(
      cacheKey: _allProductsCacheKey,
      fetch: () => _fetchProducts(),
    );
  }

  /// staleWhileRevalidate: öne çıkan ürünler.
  Future<List<ProductModel>> getFeaturedProducts() async {
    return _staleWhileRevalidate(
      cacheKey: _featuredCacheKey,
      fetch: () => _fetchFeaturedProducts(),
    );
  }

  /// staleWhileRevalidate: kategori bazlı ürünler.
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final key = 'products_cat_${categoryId}_v2';
    return _staleWhileRevalidate(
      cacheKey: key,
      fetch: () => _fetchProductsByCategory(categoryId),
    );
  }

  /// Tek ürün: önce tüm ürün cache'ini tara, yoksa Firestore'dan çek.
  Future<ProductModel?> getProduct(String id) async {
    final allCached = _cache.getList(_allProductsCacheKey, ProductModel.fromJson);
    if (allCached != null) {
      try {
        return allCached.firstWhere((p) => p.id == id);
      } catch (_) {
        // cache'de yok, Firestore'dan çek
      }
    }

    try {
      final doc = await _firestore
          .collection(AppConstants.productsCollection)
          .doc(id)
          .get();

      if (!doc.exists) return null;
      return ProductModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw RepositoryException('Ürün alınamadı: ${e.message}', cause: e);
    }
  }

  /// Real-time stream: isActive==true, order'a göre sıralı.
  Stream<List<ProductModel>> watchProducts() {
    return _firestore
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snap) {
          final products = snap.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
          _cache.setList(_allProductsCacheKey, products).ignore();
          return products;
        })
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw RepositoryException(
              'Ürünler alınamadı: ${error.message}',
              cause: error,
            );
          }
          throw error;
        });
  }

  /// Real-time stream: belirli kategorideki aktif ürünler.
  Stream<List<ProductModel>> watchProductsByCategory(String categoryId) {
    final cacheKey = 'products_cat_${categoryId}_v2';
    return _firestore
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .where('categoryIds', arrayContains: categoryId)
        .orderBy('order')
        .snapshots()
        .map((snap) {
          final products = snap.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
          _cache.setList(cacheKey, products).ignore();
          return products;
        })
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw RepositoryException(
              'Kategori ürünleri alınamadı: ${error.message}',
              cause: error,
            );
          }
          throw error;
        });
  }

  /// Tüm ürün cache'lerini temizle ve yeniden çek.
  Future<void> refresh() async {
    await Future.wait([
      _cache.clear(_allProductsCacheKey),
      _cache.clear(_featuredCacheKey),
    ]);
  }

  // ────────────────────────────────────────────────────────────
  // Private helpers
  // ────────────────────────────────────────────────────────────

  Future<List<ProductModel>> _staleWhileRevalidate({
    required String cacheKey,
    required Future<List<ProductModel>> Function() fetch,
  }) async {
    final cached = _cache.getList(cacheKey, ProductModel.fromJson);
    if (cached != null) {
      if (_cache.isExpired(cacheKey, _cacheTtl)) {
        unawaited(_fetchAndCache(cacheKey, fetch));
      }
      return cached;
    }
    return _fetchAndCache(cacheKey, fetch);
  }

  Future<List<ProductModel>> _fetchAndCache(
    String key,
    Future<List<ProductModel>> Function() fetch,
  ) async {
    try {
      final products = await fetch();
      await _cache.setList(key, products);
      return products;
    } on FirebaseException catch (e) {
      throw RepositoryException('Ürünler alınamadı: ${e.message}', cause: e);
    }
  }

  Future<List<ProductModel>> _fetchProducts() async {
    final snap = await _firestore
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();
    return snap.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  Future<List<ProductModel>> _fetchFeaturedProducts() async {
    final snap = await _firestore
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('order')
        .get();
    return snap.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }

  Future<List<ProductModel>> _fetchProductsByCategory(
      String categoryId) async {
    final snap = await _firestore
        .collection(AppConstants.productsCollection)
        .where('isActive', isEqualTo: true)
        .where('categoryIds', arrayContains: categoryId)
        .orderBy('order')
        .get();
    return snap.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
  }
}

// ────────────────────────────────────────────────────────────
// Riverpod Providers
// ────────────────────────────────────────────────────────────

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

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

final productsByCategoryProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, categoryId) {
  ref.watch(dataVersionProvider);
  return ref
      .watch(productRepositoryProvider)
      .getProductsByCategory(categoryId);
});

final watchProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).watchProducts();
});
