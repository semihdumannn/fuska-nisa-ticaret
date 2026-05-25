import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../features/products/data/models/product_model.dart';
import '../../../../features/products/data/models/variant_model.dart';

// ---------------------------------------------------------------------------
// Kategori sabitleri — admin formunda kullanilir
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
// AdminProductsNotifier — Firestore stream ile urun listesi
// ---------------------------------------------------------------------------
class AdminProductsNotifier
    extends Notifier<AsyncValue<List<ProductModel>>> {
  @override
  AsyncValue<List<ProductModel>> build() {
    final sub = FirebaseFirestore.instance
        .collection(AppConstants.productsCollection)
        .orderBy('order')
        .snapshots()
        .listen(
          (snap) {
            state = AsyncValue.data(
              snap.docs.map(ProductModel.fromFirestore).toList(),
            );
          },
          onError: (Object e, StackTrace st) {
            state = AsyncValue.error(e, st);
          },
        );
    ref.onDispose(sub.cancel);
    return const AsyncValue.loading();
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .set(product.toFirestore());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .doc(product.id)
          .update(product.toFirestore());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.productsCollection)
          .doc(id)
          .delete();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleActive(String id) async {
    final current = state.value ?? [];
    final product = current.firstWhere((p) => p.id == id);
    await updateProduct(product.copyWith(isActive: !product.isActive));
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
// Provider tanimlari
// ---------------------------------------------------------------------------
final adminProductsProvider =
    NotifierProvider<AdminProductsNotifier, AsyncValue<List<ProductModel>>>(
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

final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
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
        result = result.where((p) => p.categoryIds.contains(categoryFilter)).toList();
      }
      if (search.isNotEmpty) {
        result = result
            .where((p) =>
                p.name.toLowerCase().contains(search) ||
                p.description.toLowerCase().contains(search) ||
                p.categoryIds.any((id) => id.toLowerCase().contains(search)))
            .toList();
      }
      return result;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final paginatedProductsProvider = Provider<List<ProductModel>>((ref) {
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

/// Her urunun ilk aktif varyantini yukle — admin listesinde fiyat/stok icin.
final adminVariantProvider =
    FutureProvider.family<VariantModel?, String>((ref, productId) async {
  final snap = await FirebaseFirestore.instance
      .collection(AppConstants.variantsCollection)
      .where('productId', isEqualTo: productId)
      .where('isActive', isEqualTo: true)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return null;
  return VariantModel.fromFirestore(snap.docs.first);
});
