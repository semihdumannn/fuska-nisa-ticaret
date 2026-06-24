import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';

class FavoriteRemoteDatasource {
  final Dio _dio;
  FavoriteRemoteDatasource(this._dio);

  /// Returns `Map<productId, favoriteRecordId>`
  Future<Map<String, int>> getFavorites() async {
    try {
      final response = await _dio.get(ApiEndpoints.favorites);
      final rawData = response.data;
      final List<dynamic> list;

      if (rawData is Map && rawData.containsKey('data')) {
        final d = rawData['data'];
        list = d is List ? d : [];
      } else if (rawData is List) {
        list = rawData;
      } else {
        return {};
      }

      final result = <String, int>{};
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          final id = item['id'];
          final productId = item['product_id'];
          if (id != null && productId != null) {
            result[productId.toString()] = (id as num).toInt();
          }
        }
      }
      return result;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// POST /v1/favorites → returns new favoriteRecordId
  Future<int> addFavorite(String productId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.favorites,
        data: {'product_id': productId},
      );
      final rawData = response.data;
      final Map<String, dynamic> data = rawData is Map && rawData.containsKey('data')
          ? rawData['data'] as Map<String, dynamic>
          : rawData as Map<String, dynamic>;
      return (data['id'] as num).toInt();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  /// DELETE /v1/favorites/{id}
  Future<void> removeFavorite(int favoriteId) async {
    try {
      await _dio.delete(ApiEndpoints.favoriteDetail(favoriteId.toString()));
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
