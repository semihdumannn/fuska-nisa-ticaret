import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/config/app_config.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/providers/data_version_provider.dart';
import 'package:nisa_ticaret/core/services/cache_service.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
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
        .where('categoryId', isEqualTo: categoryId)
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
        .where('categoryId', isEqualTo: categoryId)
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

final allProductsProvider = FutureProvider<List<ProductModel>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(productRepositoryProvider).getProducts();
});

final featuredProductsProvider = FutureProvider<List<ProductModel>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(productRepositoryProvider).getFeaturedProducts();
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
