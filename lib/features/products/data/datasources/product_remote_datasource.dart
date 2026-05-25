import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/api_brand_model.dart';
import '../models/api_category_model.dart';
import '../models/api_product_model.dart';

abstract class IProductRemoteDatasource {
  Future<List<ApiProductModel>> getProducts({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    int? brandId,
    String? searchQuery,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
  });

  Future<ApiProductModel> getProductDetail(int id);

  Future<List<ApiCategoryModel>> getCategories();

  Future<List<ApiBrandModel>> getBrands();

  Future<List<ApiProductModel>> searchProducts(String query);

  Future<List<ApiProductModel>> getFeaturedProducts();
}

class ProductRemoteDatasource implements IProductRemoteDatasource {
  final Dio _dio;

  ProductRemoteDatasource(this._dio);

  @override
  Future<List<ApiProductModel>> getProducts({
    int page = 1,
    int perPage = 20,
    int? categoryId,
    int? brandId,
    String? searchQuery,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
        if (categoryId != null) 'category_id': categoryId,
        if (brandId != null) 'brand_id': brandId,
        if (searchQuery != null && searchQuery.isNotEmpty) 'q': searchQuery,
        if (sortBy != null) 'sort': sortBy,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
      };

      final response = await _dio.get(
        ApiEndpoints.products,
        queryParameters: queryParams,
      );

      final rawData = response.data;
      final List<dynamic> data;

      // Laravel pagination: {data: [...]} veya düz liste
      if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] as List;
      } else if (rawData is List) {
        data = rawData;
      } else {
        return [];
      }

      return data
          .map((json) =>
              ApiProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiProductModel> getProductDetail(int id) async {
    try {
      final response =
          await _dio.get(ApiEndpoints.productDetail(id));

      final rawData = response.data;
      final Map<String, dynamic> json;

      if (rawData is Map && rawData.containsKey('data')) {
        json = rawData['data'] as Map<String, dynamic>;
      } else {
        json = rawData as Map<String, dynamic>;
      }

      return ApiProductModel.fromJson(json);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<List<ApiCategoryModel>> getCategories() async {
    try {
      final response = await _dio.get(ApiEndpoints.categories);

      final rawData = response.data;
      final List<dynamic> data;

      if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] as List;
      } else if (rawData is List) {
        data = rawData;
      } else {
        return [];
      }

      return data
          .map((json) =>
              ApiCategoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<List<ApiBrandModel>> getBrands() async {
    try {
      final response = await _dio.get(ApiEndpoints.brands);

      final rawData = response.data;
      final List<dynamic> data;

      if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] as List;
      } else if (rawData is List) {
        data = rawData;
      } else {
        return [];
      }

      return data
          .map((json) =>
              ApiBrandModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<List<ApiProductModel>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.products,
        queryParameters: {'q': query, 'per_page': 50},
      );

      final rawData = response.data;
      final List<dynamic> data;

      if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] as List;
      } else if (rawData is List) {
        data = rawData;
      } else {
        return [];
      }

      return data
          .map((json) =>
              ApiProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<List<ApiProductModel>> getFeaturedProducts() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.products,
        queryParameters: {'featured': 1, 'per_page': 10},
      );

      final rawData = response.data;
      final List<dynamic> data;

      if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] as List;
      } else if (rawData is List) {
        data = rawData;
      } else {
        return [];
      }

      return data
          .map((json) =>
              ApiProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
