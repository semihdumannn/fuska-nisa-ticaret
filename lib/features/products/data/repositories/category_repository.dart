import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/config/app_config.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/providers/data_version_provider.dart';
import 'package:nisa_ticaret/core/services/cache_service.dart';
import 'package:nisa_ticaret/features/products/data/models/category_model.dart';
import 'package:nisa_ticaret/features/products/data/providers/product_data_providers.dart';
import 'package:nisa_ticaret/features/products/domain/entities/category_entity.dart';

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

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  ref.watch(dataVersionProvider);

  // Önce dedicated endpoint'i dene
  try {
    final repo = ref.watch(apiProductRepositoryProvider);
    final result = await repo.getCategories();
    final entities = result.fold((_) => null, (e) => e);
    if (entities != null && entities.isNotEmpty) {
      final all = <CategoryModel>[];
      void flatten(CategoryEntity entity) {
        all.add(entity.toCategoryModel());
        for (final child in entity.children) {
          flatten(child);
        }
      }
      for (final entity in entities) {
        flatten(entity);
      }
      return all;
    }
  } catch (_) {}

  // Fallback: ürünlere gömülü kategori verisinden türet
  // /v1/categories endpoint'i 500 döndürüyorsa bu yol kullanılır.
  final datasource = ref.watch(productRemoteDatasourceProvider);
  try {
    final products = await datasource.getProducts(page: 1, perPage: 500);
    final seen = <int, CategoryModel>{};
    for (final p in products) {
      for (final cat in p.embeddedCategories) {
        if (!seen.containsKey(cat.id)) {
          seen[cat.id] = CategoryModel(
            id: cat.id.toString(),
            name: cat.name,
            slug: cat.slug,
            iconName: cat.icon ?? '',
            color: cat.color ?? '#000000',
            sortOrder: cat.sortOrder,
            isActive: true,
            parentId: cat.parentId?.toString(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }
    }
    if (seen.isNotEmpty) {
      return seen.values.toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
  } catch (_) {}

  return [];
});

final rootCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  ref.watch(dataVersionProvider);
  final all = await ref.watch(categoriesProvider.future);
  return (all.where((c) => c.isRoot).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
});

final subCategoriesProvider =
    FutureProvider.family<List<CategoryModel>, String>((ref, parentId) async {
  ref.watch(dataVersionProvider);
  final all = await ref.watch(categoriesProvider.future);
  return (all.where((c) => c.parentId == parentId).toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
});
