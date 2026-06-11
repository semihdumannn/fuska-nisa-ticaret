import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../cache/cache_manager.dart';
import '../../config/app_config.dart';
import '../../services/totp_service.dart';
import '../../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../../features/auth/data/models/login_response_model.dart';
import '../../network/api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final CacheManager _cacheManager;
  late final AuthLocalDatasource _localDatasource;
  late final TotpService _totpService;
  Dio? _refreshDio; // Token refresh için ayrı Dio — sonsuz döngüyü önler
  bool _isRefreshing = false;

  AuthInterceptor(this._cacheManager) {
    _localDatasource = AuthLocalDatasource(_cacheManager);
    _totpService = TotpService(_getRefreshDio());
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _cacheManager.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        // Yeni token ile aynı isteği tekrar yap
        try {
          final opts = err.requestOptions;
          opts.headers['Authorization'] =
              'Bearer ${_cacheManager.getToken()}';
          final retryDio = _getRefreshDio();
          final response = await retryDio.request<dynamic>(
            opts.path,
            data: opts.data,
            queryParameters: opts.queryParameters,
            options: Options(
              method: opts.method,
              headers: opts.headers,
            ),
          );
          handler.resolve(response);
          return;
        } catch (_) {}
      }
      // Refresh başarısız → token temizle
      await _cacheManager.clearToken();
    }
    handler.next(err);
  }

  /// Cihazda saklı TOTP secret ile sessiz giriş yapar ve Sanctum token'ı yeniler.
  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;
    try {
      final secret = await _localDatasource.getTotpSecret();
      final phone = await _localDatasource.getSavedPhone();
      if (secret == null || phone == null) return false;

      final offsetMs = await _totpService.getServerTimeOffsetMs();
      final code = _totpService.generateCode(secret, offsetMs);

      final dio = _getRefreshDio();
      final response = await dio.post<dynamic>(
        ApiEndpoints.totpLogin,
        data: {
          'phone': phone,
          'code': code,
          'device_name': Platform.operatingSystem,
        },
      );

      final body = response.data as Map<String, dynamic>;
      final loginResponse = LoginResponseModel.fromJson(body);
      if (loginResponse.token.isEmpty) return false;

      await _localDatasource.saveToken(loginResponse.token);
      await _localDatasource.saveUser(loginResponse.user);
      return true;
    } catch (e) {
      debugPrint('AuthInterceptor.refreshToken hata: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Token refresh için Dio instance — AuthInterceptor'sız (sonsuz döngü olmasın)
  Dio _getRefreshDio() {
    return _refreshDio ??= Dio(
      BaseOptions(
        baseUrl: AppConfig.instance.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }
}
