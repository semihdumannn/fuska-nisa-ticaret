import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/i_product_repository.dart';

class GetProductDetailUsecase {
  final IProductRepository _repository;

  GetProductDetailUsecase(this._repository);

  Future<Either<Failure, ProductEntity>> call(String id) {
    return _repository.getProductDetail(id);
  }
}
