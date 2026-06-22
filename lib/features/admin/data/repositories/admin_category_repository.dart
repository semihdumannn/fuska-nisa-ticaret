import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/services/cache_service.dart';
import 'package:nisa_ticaret/features/products/data/models/category_model.dart';

/// Admin-özel kategori yazma operasyonları.
///
/// NOT: Kategori CRUD API endpoint'i mevcut değil (bkz. ApiEndpoints — not).
/// Bu nedenle [toggleActive], [deleteCategory], [saveCategory] metodları
/// şu an desteklenmiyor ve çağrıldığında [UnsupportedCategoryOperationException]
/// fırlatır. UI katmanı bu exception'ı yakalayarak kullanıcıya bilgi verir.
class UnsupportedCategoryOperationException implements Exception {
  const UnsupportedCategoryOperationException();

  @override
  String toString() => 'Bu işlem şu an desteklenmiyor';
}

class AdminCategoryRepository {
  final CacheService _cache;

  AdminCategoryRepository({CacheService? cache})
      : _cache = cache ?? cacheService;

  // ─── isActive Toggle ────────────────────────────────────────────────────────

  /// Kategori CRUD API endpoint'i olmadığından bu işlem desteklenmiyor.
  Future<void> toggleActive(CategoryModel category) async {
    throw const UnsupportedCategoryOperationException();
  }

  // ─── Delete ─────────────────────────────────────────────────────────────────

  /// Kategori CRUD API endpoint'i olmadığından bu işlem desteklenmiyor.
  Future<void> deleteCategory(String categoryId) async {
    throw const UnsupportedCategoryOperationException();
  }

  // ─── Save (Create / Update) ─────────────────────────────────────────────────

  /// Kategori CRUD API endpoint'i olmadığından bu işlem desteklenmiyor.
  Future<void> saveCategory({
    required CategoryModel category,
    required bool isUpdate,
  }) async {
    throw const UnsupportedCategoryOperationException();
  }

  // ─── Cache Invalidation ──────────────────────────────────────────────────────

  /// Hive cache'teki kategori girdisini temizler.
  /// data_versions Firestore güncellemesi kaldırıldı — artık kullanılmıyor.
  Future<void> invalidateCache() async {
    await _cache.clear('categories_v1');
    await _cache.clear('categories_v2');
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

final adminCategoryRepositoryProvider = Provider<AdminCategoryRepository>((ref) {
  return AdminCategoryRepository();
});
