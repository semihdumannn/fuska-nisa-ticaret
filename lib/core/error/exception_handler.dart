import 'package:dio/dio.dart';
import 'failures.dart';

class ExceptionHandler {
  static Failure handleException(dynamic exception) {
    if (exception is DioException) {
      return _handleDioException(exception);
    }
    return ServerFailure(exception.toString());
  }

  static Failure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkFailure('Baglanti zaman asimi');

      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;

        if (statusCode == 401) {
          return const UnauthorizedFailure();
        } else if (statusCode == 404) {
          final message =
              exception.response?.data['message'] ?? 'Bulunamadi';
          return NotFoundFailure(message.toString());
        } else if (statusCode == 422) {
          final errorsRaw = exception.response?.data['errors'];
          if (errorsRaw is Map<String, dynamic>) {
            final errors = errorsRaw.map(
              (key, value) => MapEntry(key, List<String>.from(value as List)),
            );
            return ValidationFailure(errors);
          }
          return const ServerFailure('Dogrulama hatasi', 422);
        } else {
          final message =
              exception.response?.data['message'] ?? 'Sunucu hatasi';
          return ServerFailure(message.toString(), statusCode);
        }

      case DioExceptionType.connectionError:
        return const NetworkFailure('Internet baglantisi yok');

      default:
        return const NetworkFailure('Ag hatasi');
    }
  }
}
