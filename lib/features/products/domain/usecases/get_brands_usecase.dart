import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/brand_entity.dart';
import '../repositories/i_product_repository.dart';

class GetBrandsUsecase {
  final IProductRepository _repository;

  GetBrandsUsecase(this._repository);

  Future<Either<Failure, List<BrandEntity>>> call() {
    return _repository.getBrands();
  }
}
