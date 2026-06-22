import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/providers/product_data_providers.dart';
import 'package:nisa_ticaret/features/products/data/repositories/product_repository.dart';

/// autoDispose: ProductDetailScreen kapanınca belleği serbest bırak.
final productDetailProvider =
    FutureProvider.autoDispose.family<ProductModel?, String>((ref, id) async {
  // Önce bellekteki ürün listesinden bul — ekstra network isteği önler
  final productsAsync = ref.watch(allProductsProvider);
  if (productsAsync.hasValue) {
    final found = productsAsync.value!.where((p) => p.id == id).firstOrNull;
    if (found != null) return found;
  }

  // Bellekte yoksa API'den ürün detayı çek
  final repo = ref.watch(apiProductRepositoryProvider);
  final result = await repo.getProductDetail(id);
  return result.fold(
    (failure) => null,
    (entity) => entity.toProductModel(),
  );
});
