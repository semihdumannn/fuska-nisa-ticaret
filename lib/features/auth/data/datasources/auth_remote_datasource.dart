import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/api_user_model.dart';
import '../models/device_register_response_model.dart';
import '../models/login_response_model.dart';

abstract class IAuthRemoteDatasource {
  Future<DeviceRegisterResponseModel> registerDevice({
    required String phone,
    String? name,
    required String deviceName,
  });
  Future<LoginResponseModel> totpLogin({
    required String phone,
    required String code,
    required String deviceName,
  });
  Future<int> getServerTime();
  Future<void> logout();
  Future<ApiUserModel> getCurrentUser();
}

class AuthRemoteDatasource implements IAuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  @override
  Future<DeviceRegisterResponseModel> registerDevice({
    required String phone,
    String? name,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.deviceRegister,
        data: {
          'phone': phone,
          if (name != null) 'name': name,
          'device_name': deviceName,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return DeviceRegisterResponseModel.fromJson(body);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<LoginResponseModel> totpLogin({
    required String phone,
    required String code,
    required String deviceName,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.totpLogin,
        data: {
          'phone': phone,
          'code': code,
          'device_name': deviceName,
        },
      );
      final body = response.data as Map<String, dynamic>;
      return LoginResponseModel.fromJson(body);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<int> getServerTime() async {
    try {
      final response = await _dio.get(ApiEndpoints.serverTime);
      final body = response.data as Map<String, dynamic>;
      return body['timestamp'] as int;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiUserModel> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      final body = response.data as Map<String, dynamic>;
      // data wrapper varsa içini al, yoksa direkt kullan
      final userJson = body.containsKey('data')
          ? body['data'] as Map<String, dynamic>
          : body;
      return ApiUserModel.fromJson(userJson);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
