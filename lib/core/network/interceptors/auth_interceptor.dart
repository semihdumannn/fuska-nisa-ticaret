import 'package:dio/dio.dart';
import '../../cache/cache_manager.dart';

class AuthInterceptor extends Interceptor {
  final CacheManager _cacheManager;

  AuthInterceptor(this._cacheManager);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _cacheManager.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _cacheManager.clearToken();
    }
    handler.next(err);
  }
}
