import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/brand_entity.dart';
import '../entities/category_entity.dart';
import '../entities/product_entity.dart';

abstract class IProductRepository {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    int perPage = 20,
    String? categoryId,
    String? brandId,
    String? searchQuery,
    String? sortBy, // 'price_asc', 'price_desc', 'name', 'newest'
    double? minPrice,
    double? maxPrice,
  });

  Future<Either<Failure, ProductEntity>> getProductDetail(String id);

  Future<Either<Failure, List<CategoryEntity>>> getCategories();

  Future<Either<Failure, List<BrandEntity>>> getBrands();

  Future<Either<Failure, List<ProductEntity>>> searchProducts(String query);

  Future<Either<Failure, List<ProductEntity>>> getFeaturedProducts();
}
