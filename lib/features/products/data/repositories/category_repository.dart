import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/providers/data_version_provider.dart';
import 'package:nisa_ticaret/features/products/data/models/category_model.dart';
import 'package:nisa_ticaret/features/products/data/providers/product_data_providers.dart';
import 'package:nisa_ticaret/features/products/domain/entities/category_entity.dart';

// ────────────────────────────────────────────────────────────
// Riverpod Providers
// ────────────────────────────────────────────────────────────

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
