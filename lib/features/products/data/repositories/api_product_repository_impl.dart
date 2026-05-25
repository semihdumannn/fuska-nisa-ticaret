import 'package:dartz/dartz.dart';

import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/brand_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/i_product_repository.dart';
import '../datasources/product_remote_datasource.dart';

class ApiProductRepositoryImpl implements IProductRepository {
  final IProductRemoteDatasource _remoteDatasource;
  final CacheManager _cacheManager;

  ApiProductRepositoryImpl({
    required IProductRemoteDatasource remoteDatasource,
    required CacheManager cacheManager,
  })  : _remoteDatasource = remoteDatasource,
        _cacheManager = cacheManager;

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    int page = 1,
    int perPage = 20,
    String? categoryId,
    String? brandId,
    String? searchQuery,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
  }) async {
    // Cache sadece ilk sayfa, filtre yoksa
    final isFirstPageNoFilter = page == 1 &&
        categoryId == null &&
        brandId == null &&
        searchQuery == null &&
        sortBy == null &&
        minPrice == null &&
        maxPrice == null;

    if (isFirstPageNoFilter) {
      final cached =
          _cacheManager.getCachedData<List<dynamic>>(CacheKeys.products);
      if (cached != null) {
        try {
          final entities = cached
              .map((item) =>
                  _productEntityFromMap(item as Map<dynamic, dynamic>))
              .toList();
          return Right(entities);
        } catch (_) {
          // Cache bozuksa sil ve network'ten al
          await _cacheManager.invalidate(CacheKeys.products);
        }
      }
    }

    try {
      final models = await _remoteDatasource.getProducts(
        page: page,
        perPage: perPage,
        categoryId: categoryId != null ? int.tryParse(categoryId) : null,
        brandId: brandId != null ? int.tryParse(brandId) : null,
        searchQuery: searchQuery,
        sortBy: sortBy,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

      final entities = models.map((m) => m.toEntity()).toList();

      // Sadece ilk sayfa, filtre yoksa cache'le
      if (isFirstPageNoFilter) {
        await _cacheManager.cacheData(
          CacheKeys.products,
          models.map((m) => m.toMap()).toList(),
          ttl: CacheKeys.productsTtl,
        );
      }

      return Right(entities);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, ProductEntity>> getProductDetail(String id) async {
    final numId = int.tryParse(id);
    if (numId == null) {
      return const Left(NotFoundFailure('Gecersiz urun ID'));
    }

    final cacheKey = CacheKeys.product(numId);
    final cached = _cacheManager.getCachedData<Map<dynamic, dynamic>>(cacheKey);
    if (cached != null) {
      try {
        return Right(_productEntityFromMap(cached));
      } catch (_) {
        await _cacheManager.invalidate(cacheKey);
      }
    }

    try {
      final model = await _remoteDatasource.getProductDetail(numId);
      final entity = model.toEntity();

      await _cacheManager.cacheData(
        cacheKey,
        model.toMap(),
        ttl: CacheKeys.productsTtl,
      );

      return Right(entity);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() async {
    // Categories: 24 saat cache
    final cached =
        _cacheManager.getCachedData<List<dynamic>>(CacheKeys.categories);
    if (cached != null) {
      // Cache var ama kategoriler karmaşık nesne — yeniden fetch et
      // (cache sadece TTL kontrolü için kullanılır)
      try {
        final models = await _remoteDatasource.getCategories();
        return Right(models.map((m) => m.toEntity()).toList());
      } catch (e) {
        return Left(ExceptionHandler.handleException(e));
      }
    }

    try {
      final models = await _remoteDatasource.getCategories();
      final entities = models.map((m) => m.toEntity()).toList();

      // TTL flag'i cache'le — bir sonraki çağrıda TTL kontrolü yapılacak
      await _cacheManager.cacheData(
        CacheKeys.categories,
        ['cached'],
        ttl: CacheKeys.categoriesTtl,
      );

      return Right(entities);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<BrandEntity>>> getBrands() async {
    try {
      final models = await _remoteDatasource.getBrands();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> searchProducts(
      String query) async {
    try {
      final models = await _remoteDatasource.searchProducts(query);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getFeaturedProducts() async {
    try {
      final models = await _remoteDatasource.getFeaturedProducts();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  // Cache map'ten ProductEntity oluşturur (sadece temel alanlar)
  ProductEntity _productEntityFromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    return ProductEntity(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      imageUrls: map['image_urls'] != null
          ? List<String>.from(map['image_urls'] as List)
          : [],
      categoryIds: map['category_ids'] != null
          ? (map['category_ids'] as List)
              .map((id) => id.toString())
              .toList()
          : [],
      brandId: map['brand_id']?.toString() ?? '',
      isActive: map['is_active'] as bool? ?? true,
      isFeatured: map['is_featured'] as bool? ?? false,
      primaryPrice: map['price'] != null
          ? (map['price'] as num).toDouble()
          : null,
      primarySalePrice: map['sale_price'] != null
          ? (map['sale_price'] as num).toDouble()
          : null,
      primaryStock: map['stock_quantity'] as int?,
      tags: map['tags'] != null
          ? List<String>.from(map['tags'] as List)
          : [],
      order: map['order'] as int? ?? 0,
      createdAt: now,
      updatedAt: now,
    );
  }
}
