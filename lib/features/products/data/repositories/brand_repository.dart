import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/services/cache_service.dart';
import 'package:nisa_ticaret/features/products/data/models/brand_model.dart';
import 'package:nisa_ticaret/features/products/data/providers/product_data_providers.dart';
import 'package:nisa_ticaret/features/products/data/repositories/category_repository.dart'
    show RepositoryException;

class BrandRepository {
  final FirebaseFirestore _firestore;
  final CacheService _cache;

  static const _cacheKey = 'brands_v1';
  static const _cacheTtl = Duration(hours: 24);

  BrandRepository({
    FirebaseFirestore? firestore,
    CacheService? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? cacheService;

  /// Cache-first: 24 saat tazeyse Firebase'e gitme.
  Future<List<BrandModel>> getBrands() async {
    if (_cache.exists(_cacheKey) && _cache.isFresh(_cacheKey, _cacheTtl)) {
      final cached = _cache.getList(_cacheKey, BrandModel.fromJson);
      if (cached != null) return cached;
    }
    return _fetchAndCache();
  }

  /// Real-time stream: isActive==true, order'a gore sirali.
  Stream<List<BrandModel>> watchBrands() {
    return _firestore
        .collection(AppConstants.brandsCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snap) {
          final brands = snap.docs
              .map((doc) => BrandModel.fromFirestore(doc))
              .toList();
          _cache.setList(_cacheKey, brands).ignore();
          return brands;
        })
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw RepositoryException(
              'Markalar alinamadi: ${error.message}',
              cause: error,
            );
          }
          throw error;
        });
  }

  /// Cache'i iptal et ve Firebase'den yenile.
  Future<List<BrandModel>> refresh() async {
    await _cache.clear(_cacheKey);
    return _fetchAndCache();
  }

  // ────────────────────────────────────────────────────────────
  // Private
  // ────────────────────────────────────────────────────────────

  Future<List<BrandModel>> _fetchAndCache() async {
    try {
      final snap = await _firestore
          .collection(AppConstants.brandsCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      final brands = snap.docs
          .map((doc) => BrandModel.fromFirestore(doc))
          .toList();

      await _cache.setList(_cacheKey, brands);
      return brands;
    } on FirebaseException catch (e) {
      throw RepositoryException(
        'Markalar alinamadi: ${e.message}',
        cause: e,
      );
    }
  }
}

// ────────────────────────────────────────────────────────────
// Riverpod Providers
// ────────────────────────────────────────────────────────────

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepository();
});

final brandsProvider = FutureProvider<List<BrandModel>>((ref) async {
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await repo.getBrands();
  return result.fold(
    (failure) => throw Exception(failure.message),
    (entities) => entities.map((e) => e.toBrandModel()).toList(),
  );
});

final brandsStreamProvider = StreamProvider<List<BrandModel>>((ref) {
  return ref.watch(brandRepositoryProvider).watchBrands();
});
