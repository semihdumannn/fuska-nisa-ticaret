import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../features/products/data/models/api_product_model.dart';
import 'admin_orders_provider.dart';

// ---------------------------------------------------------------------------
// Kategori sabitleri — filtre dropdown'ında hâlâ kullanılır.
// Gerçek kategori listesi ayrı bir provider'dan (API) gelecek.
// ---------------------------------------------------------------------------
class ProductCategory {
  const ProductCategory._();

  static const List<Map<String, String>> all = [
    {'id': 'water', 'name': 'Su'},
    {'id': 'sparkling', 'name': 'Gazli Icecek'},
    {'id': 'juice', 'name': 'Meyve Suyu'},
    {'id': 'other', 'name': 'Diger'},
  ];

  static String nameForId(String id) {
    return all.firstWhere(
      (c) => c['id'] == id,
      orElse: () => {'name': id},
    )['name']!;
  }
}

// ---------------------------------------------------------------------------
// AdminProductsNotifier — API tabanlı ürün yönetimi
// ---------------------------------------------------------------------------
class AdminProductsNotifier
    extends Notifier<AsyncValue<List<ApiProductModel>>> {
  Dio get _dio => ref.read(apiClientProvider).dio;

  @override
  AsyncValue<List<ApiProductModel>> build() {
    _load();
    return const AsyncValue.loading();
  }

  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final products = await _fetchAllProducts();
      state = AsyncValue.data(products);
    } on AdminRoleException catch (e, st) {
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<List<ApiProductModel>> _fetchAllProducts() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.adminProducts,
        queryParameters: {'per_page': 200, 'page': 1},
      );
      final body = response.data as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];
      return data
          .map((j) => ApiProductModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const AdminRoleException(
          'Yetersiz yetki: Backend\'de admin rolünüz yok.\n\n'
          'Çözüm: Backend veritabanında kullanıcınızın rolünü "admin" olarak güncelleyin.',
        );
      }
      rethrow;
    }
  }

  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.adminProducts,
        data: productData,
      );
      final json = response.data as Map<String, dynamic>;
      final newProduct = ApiProductModel.fromJson(
        json['data'] as Map<String, dynamic>? ?? json,
      );
      final current = state.value ?? [];
      state = AsyncValue.data([newProduct, ...current]);
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const AdminRoleException('Ürün ekleme yetkisi yok.');
      }
      rethrow;
    }
  }

  Future<void> updateProduct(int id, Map<String, dynamic> productData) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.adminProductDetail(id),
        data: productData,
      );
      final json = response.data as Map<String, dynamic>;
      final updated = ApiProductModel.fromJson(
        json['data'] as Map<String, dynamic>? ?? json,
      );
      final current = state.value ?? [];
      state = AsyncValue.data(current.map((p) {
        return p.id == id ? updated : p;
      }).toList());
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const AdminRoleException('Ürün güncelleme yetkisi yok.');
      }
      rethrow;
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete(ApiEndpoints.adminProductDetail(id));
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((p) => p.id != id).toList());
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw const AdminRoleException('Ürün silme yetkisi yok.');
      }
      rethrow;
    }
  }

  Future<void> toggleActive(int id) async {
    final current = state.value ?? [];
    final product = current.where((p) => p.id == id).firstOrNull;
    if (product == null) return;
    final newActive = !product.isActive;

    // Optimistic update
    state = AsyncValue.data(current.map((p) {
      if (p.id != id) return p;
      return ApiProductModel(
        id: p.id,
        name: p.name,
        description: p.description,
        primaryPrice: p.primaryPrice,
        primarySalePrice: p.primarySalePrice,
        primaryStock: p.primaryStock,
        imageUrl: p.imageUrl,
        imageUrls: p.imageUrls,
        categoryIds: p.categoryIds,
        categoryName: p.categoryName,
        brandId: p.brandId,
        brandName: p.brandName,
        isActive: newActive,
        isFeatured: p.isFeatured,
        unit: p.unit,
        tags: p.tags,
        order: p.order,
        variants: p.variants,
        embeddedCategories: p.embeddedCategories,
        koliVariantId: p.koliVariantId,
        koliPrice: p.koliPrice,
        koliSalePrice: p.koliSalePrice,
        koliStock: p.koliStock,
        koliPackageQty: p.koliPackageQty,
      );
    }).toList());

    try {
      await _dio.put(
        ApiEndpoints.adminProductDetail(id),
        data: {'is_active': newActive},
      );
    } catch (_) {
      // Rollback on error
      await _load();
    }
  }
}

// ---------------------------------------------------------------------------
// Arama + filtre notifier'lari
// ---------------------------------------------------------------------------
class ProductSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

class ProductCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

class ProductsPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int page) => state = page;
  void reset() => state = 0;
}

// ---------------------------------------------------------------------------
// Provider tanımları
// ---------------------------------------------------------------------------
final adminProductsProvider = NotifierProvider<AdminProductsNotifier,
    AsyncValue<List<ApiProductModel>>>(
  AdminProductsNotifier.new,
);

final productSearchProvider =
    NotifierProvider<ProductSearchNotifier, String>(
  ProductSearchNotifier.new,
);

final productCategoryFilterProvider =
    NotifierProvider<ProductCategoryFilterNotifier, String?>(
  ProductCategoryFilterNotifier.new,
);

final productsPageProvider =
    NotifierProvider<ProductsPageNotifier, int>(
  ProductsPageNotifier.new,
);

const int kProductsPerPage = 10;

final filteredProductsProvider = Provider<List<ApiProductModel>>((ref) {
  final asyncProducts = ref.watch(adminProductsProvider);
  final search = ref.watch(productSearchProvider).toLowerCase().trim();
  final categoryFilter = ref.watch(productCategoryFilterProvider);

  ref.listen(productSearchProvider, (_, __) {
    ref.read(productsPageProvider.notifier).reset();
  });
  ref.listen(productCategoryFilterProvider, (_, __) {
    ref.read(productsPageProvider.notifier).reset();
  });

  return asyncProducts.when(
    data: (products) {
      var result = products;
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        result = result
            .where((p) =>
                p.categoryName?.toLowerCase().contains(categoryFilter) ==
                    true ||
                p.embeddedCategories
                    .any((c) => c.name.toLowerCase().contains(categoryFilter)))
            .toList();
      }
      if (search.isNotEmpty) {
        result = result
            .where((p) =>
                p.name.toLowerCase().contains(search) ||
                (p.description?.toLowerCase().contains(search) ?? false) ||
                (p.categoryName?.toLowerCase().contains(search) ?? false) ||
                (p.brandName?.toLowerCase().contains(search) ?? false))
            .toList();
      }
      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final paginatedProductsProvider = Provider<List<ApiProductModel>>((ref) {
  final filtered = ref.watch(filteredProductsProvider);
  final page = ref.watch(productsPageProvider);
  final start = page * kProductsPerPage;
  if (start >= filtered.length) return [];
  final end = (start + kProductsPerPage).clamp(0, filtered.length);
  return filtered.sublist(start, end);
});

final totalProductPagesProvider = Provider<int>((ref) {
  final filtered = ref.watch(filteredProductsProvider);
  return (filtered.length / kProductsPerPage).ceil().clamp(1, 9999);
});

/// Her ürünün ilk aktif varyantını döner — ApiProductModel.variants'tan.
/// Ekstra Firestore/API çağrısı yapmaz.
final adminVariantProvider =
    Provider.family<ApiProductVariantModel?, int>((ref, productId) {
  final products = ref.watch(adminProductsProvider).value ?? [];
  final product = products.where((p) => p.id == productId).firstOrNull;
  if (product == null) return null;
  final active = product.variants.where((v) => v.isActive).toList();
  return active.isNotEmpty ? active.first : product.variants.firstOrNull;
});
