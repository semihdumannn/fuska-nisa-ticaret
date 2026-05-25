import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/i_product_repository.dart';

class GetProductsUsecase {
  final IProductRepository _repository;

  GetProductsUsecase(this._repository);

  Future<Either<Failure, List<ProductEntity>>> call({
    int page = 1,
    int perPage = 20,
    String? categoryId,
    String? brandId,
    String? searchQuery,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
  }) {
    return _repository.getProducts(
      page: page,
      perPage: perPage,
      categoryId: categoryId,
      brandId: brandId,
      searchQuery: searchQuery,
      sortBy: sortBy,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }
}
