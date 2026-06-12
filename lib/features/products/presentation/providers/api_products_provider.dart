import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/product_data_providers.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_products_usecase.dart';
import '../../domain/usecases/search_products_usecase.dart';

export '../../data/providers/product_data_providers.dart'
    show productRemoteDatasourceProvider, apiProductRepositoryProvider;

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Kategori bazlı ürün listesi (server-side filtreleme).
/// keepAlive + 10 dk timer: kullanıcı kategori değiştirip geri gelince
/// provider hayatta kalır → cache/in-memory'den anında yanıt verir.
final apiProductsByCategoryProvider =
    FutureProvider.family<List<ProductEntity>, String>((ref, categoryId) async {
  // Provider son subscriber ayrıldıktan 10 dakika sonra dispose edilir.
  final link = ref.keepAlive();
  Timer(const Duration(minutes: 10), link.close);

  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await GetProductsUsecase(repo)(
    categoryId: categoryId,
    perPage: 100,
  );
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
