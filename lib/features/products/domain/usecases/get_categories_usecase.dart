import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';
import '../repositories/i_product_repository.dart';

class GetCategoriesUsecase {
  final IProductRepository _repository;

  GetCategoriesUsecase(this._repository);

  Future<Either<Failure, List<CategoryEntity>>> call() {
    return _repository.getCategories();
  }
}
