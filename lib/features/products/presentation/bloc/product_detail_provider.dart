import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/repositories/product_repository.dart';

final productDetailProvider =
    FutureProvider.family<ProductModel?, String>((ref, id) async {
  return ref.watch(productRepositoryProvider).getProduct(id);
});
