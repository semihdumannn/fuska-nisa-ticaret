import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/services/cache_service.dart';
import 'package:nisa_ticaret/features/products/data/models/variant_model.dart';
import 'package:nisa_ticaret/features/products/data/repositories/category_repository.dart'
    show RepositoryException;

class VariantRepository {
  final FirebaseFirestore _firestore;
  final CacheService _cache;

  static const _cacheTtl = Duration(hours: 1);

  VariantRepository({
    FirebaseFirestore? firestore,
    CacheService? cache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cache = cache ?? cacheService;

  String _cacheKey(String productId) => 'variants_${productId}_v1';

  /// staleWhileRevalidate: cache varsa hemen don, arka planda guncelle.
  Future<List<VariantModel>> getVariantsByProduct(String productId) async {
    final key = _cacheKey(productId);
    return _staleWhileRevalidate(
      cacheKey: key,
      fetch: () => _fetchVariants(productId),
    );
  }

  /// Real-time stream: productId'ye gore aktif varyantlar.
  Stream<List<VariantModel>> watchVariantsByProduct(String productId) {
    final key = _cacheKey(productId);
    return _firestore
        .collection(AppConstants.variantsCollection)
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final variants = snap.docs
              .map((doc) => VariantModel.fromFirestore(doc))
              .toList();
          _cache.setList(key, variants).ignore();
          return variants;
        })
        .handleError((Object error) {
          if (error is FirebaseException) {
            throw RepositoryException(
              'Varyantlar alinamadi: ${error.message}',
              cause: error,
            );
          }
          throw error;
        });
  }

  /// Cache atlanır — sadece checkout fiyat doğrulaması için kullan.
  /// Firestore'dan direkt okur ve sonucu cache'e yazar.
  Future<List<VariantModel>> getVariantsFresh(String productId) async {
    final variants = await _fetchVariants(productId);
    await _cache.setList(_cacheKey(productId), variants);
    return variants;
  }

  /// Tek urunun cache'ini temizle.
  Future<void> refresh(String productId) async {
    await _cache.clear(_cacheKey(productId));
  }

  // ────────────────────────────────────────────────────────────
  // Private helpers
  // ────────────────────────────────────────────────────────────

  Future<List<VariantModel>> _staleWhileRevalidate({
    required String cacheKey,
    required Future<List<VariantModel>> Function() fetch,
  }) async {
    final cached = _cache.getList(cacheKey, VariantModel.fromJson);
    if (cached != null) {
      if (_cache.isExpired(cacheKey, _cacheTtl)) {
        unawaited(_fetchAndCache(cacheKey, fetch));
      }
      return cached;
    }
    return _fetchAndCache(cacheKey, fetch);
  }

  Future<List<VariantModel>> _fetchAndCache(
    String key,
    Future<List<VariantModel>> Function() fetch,
  ) async {
    try {
      final variants = await fetch();
      await _cache.setList(key, variants);
      return variants;
    } on FirebaseException catch (e) {
      throw RepositoryException('Varyantlar alinamadi: ${e.message}', cause: e);
    }
  }

  Future<List<VariantModel>> _fetchVariants(String productId) async {
    final snap = await _firestore
        .collection(AppConstants.variantsCollection)
        .where('productId', isEqualTo: productId)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.map((doc) => VariantModel.fromFirestore(doc)).toList();
  }
}

// ────────────────────────────────────────────────────────────
// Riverpod Providers
// ────────────────────────────────────────────────────────────

final variantRepositoryProvider = Provider<VariantRepository>((ref) {
  return VariantRepository();
});

/// productId'ye gore aktif varyantlari real-time dinle.
final variantsByProductProvider =
    StreamProvider.family<List<VariantModel>, String>((ref, productId) {
  return ref
      .watch(variantRepositoryProvider)
      .watchVariantsByProduct(productId);
});

/// productId'ye gore aktif varyantlari cache'li getir.
final variantsByProductFutureProvider =
    FutureProvider.family<List<VariantModel>, String>((ref, productId) {
  return ref
      .watch(variantRepositoryProvider)
      .getVariantsByProduct(productId);
});
