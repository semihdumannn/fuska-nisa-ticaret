import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/config/app_config.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/providers/data_version_provider.dart';
import 'package:nisa_ticaret/core/services/cache_service.dart';
import 'package:nisa_ticaret/features/products/data/models/category_model.dart';

class RepositoryException implements Exception {
  final String message;
  final Object? cause;
  const RepositoryException(this.message, {this.cause});
  @override
  String toString() => 'RepositoryException: $message';
}

class CategoryRepository {
  final FirebaseFirestore _firestore;
  final CacheService _cache;

  static const _cacheKey = 'categories_v2';
  Duration get _cacheTtl => appConfig.categoriesCacheDuration;

  CategoryRepository({
    FirebaseFirestore? firestore,
    CacheService? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? cacheService;

  /// Cache-first: 24 saat tazeyse Firebase'e gitme.
  Future<List<CategoryModel>> getCategories() async {
    if (_cache.exists(_cacheKey) && _cache.isFresh(_cacheKey, _cacheTtl)) {
      final cached = _cache.getList(_cacheKey, CategoryModel.fromJson);
      if (cached != null) return cached;
    }
    return _fetchAndCache();
  }

  /// Real-time stream; her yeni snapshot'ta cache güncellenir.
  Stream<List<CategoryModel>> watchCategories() {
    return _firestore
        .collection(AppConstants.categoriesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) {
          final categories = snap.docs
              .map((doc) => CategoryModel.fromFirestore(doc))
              .toList();
          // Arka planda cache'i güncelle — await gerekmez
          _cache.setList(_cacheKey, categories).ignore();
          return categories;
        })
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw RepositoryException(
              'Kategoriler alınamadı: ${error.message}',
              cause: error,
            );
          }
          throw error;
        });
  }

  /// Sadece kök kategorileri döndür (parentId == null veya boş).
  Future<List<CategoryModel>> getRootCategories() async {
    final all = await getCategories();
    return all.where((c) => c.isRoot).toList();
  }

  /// Belirli bir parent'ın alt kategorilerini Firestore'dan doğrudan çek.
  Future<List<CategoryModel>> getSubCategories(String parentId) async {
    try {
      final snap = await _firestore
          .collection(AppConstants.categoriesCollection)
          .where('parentId', isEqualTo: parentId)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();
      return snap.docs.map((d) => CategoryModel.fromFirestore(d)).toList();
    } on FirebaseException catch (e) {
      throw RepositoryException('Alt kategoriler alınamadı: ${e.message}', cause: e);
    }
  }

  /// Cache'i iptal et ve Firebase'den yenile.
  Future<List<CategoryModel>> refresh() async {
    await _cache.clear(_cacheKey);
    return _fetchAndCache();
  }

  // ────────────────────────────────────────────────────────────
  // Private
  // ────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> _fetchAndCache() async {
    try {
      final snap = await _firestore
          .collection(AppConstants.categoriesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      final categories = snap.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();

      await _cache.setList(_cacheKey, categories);
      return categories;
    } on FirebaseException catch (e) {
      throw RepositoryException(
        'Kategoriler alınamadı: ${e.message}',
        cause: e,
      );
    }
  }
}

// ────────────────────────────────────────────────────────────
// Riverpod Providers
// ────────────────────────────────────────────────────────────

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final rootCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  ref.watch(dataVersionProvider);
  return ref.watch(categoryRepositoryProvider).getRootCategories();
});

final subCategoriesProvider =
    FutureProvider.family<List<CategoryModel>, String>((ref, parentId) {
  ref.watch(dataVersionProvider);
  return ref.watch(categoryRepositoryProvider).getSubCategories(parentId);
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchCategories();
});
