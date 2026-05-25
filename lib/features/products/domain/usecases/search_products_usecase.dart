import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/i_product_repository.dart';

class SearchProductsUsecase {
  final IProductRepository _repository;

  SearchProductsUsecase(this._repository);

  Future<Either<Failure, List<ProductEntity>>> call(String query) {
    if (query.trim().isEmpty) {
      return Future.value(const Right([]));
    }
    return _repository.searchProducts(query.trim());
  }
}
