import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../datasources/product_remote_datasource.dart';
import '../repositories/api_product_repository_impl.dart';
import '../../domain/repositories/i_product_repository.dart';

final productRemoteDatasourceProvider =
    Provider<IProductRemoteDatasource>((ref) {
  return ProductRemoteDatasource(ref.watch(apiClientProvider).dio);
});

final apiProductRepositoryProvider = Provider<IProductRepository>((ref) {
  return ApiProductRepositoryImpl(
    remoteDatasource: ref.watch(productRemoteDatasourceProvider),
    cacheManager: ref.watch(cacheManagerProvider),
  );
});
