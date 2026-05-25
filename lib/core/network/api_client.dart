import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'interceptors/auth_interceptor.dart';
import '../cache/cache_manager.dart';
import '../config/app_config.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient(CacheManager cacheManager) {
    final config = AppConfig.instance;
    final timeoutSeconds = config.apiTimeout;
    final timeout = Duration(seconds: timeoutSeconds > 0 ? timeoutSeconds : 30);

    _dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(AuthInterceptor(cacheManager));

    // PrettyDioLogger sadece debug modda — production'da request/response body loglanmaz
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
        ),
      );
    }
  }

  Dio get dio => _dio;
}
