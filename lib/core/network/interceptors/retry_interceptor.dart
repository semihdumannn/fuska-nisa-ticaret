import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// HF Space cold-start ve geçici ağ hatalarında 2 kez otomatik yeniden dene.
/// Yalnızca timeout ve bağlantı hatalarında tetiklenir; sunucu hataları (4xx/5xx)
/// yeniden denenmez — bunlar intentional response'tur.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 800),
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final attempt = err.requestOptions.extra['retryCount'] as int? ?? 0;

    final shouldRetry = attempt < maxRetries && _isRetryable(err);

    if (!shouldRetry) {
      handler.next(err);
      return;
    }

    err.requestOptions.extra['retryCount'] = attempt + 1;
    debugPrint(
      '🔄 Retry ${attempt + 1}/$maxRetries — '
      '${err.requestOptions.path} (${err.type.name})',
    );

    await Future<void>.delayed(retryDelay * (attempt + 1));

    try {
      final response = await dio.request<dynamic>(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: Options(
          method: err.requestOptions.method,
          headers: err.requestOptions.headers,
          extra: err.requestOptions.extra,
        ),
      );
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      default:
        return false;
    }
  }
}
