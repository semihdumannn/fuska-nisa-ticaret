import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/api_user_model.dart';
import '../models/login_response_model.dart';

abstract class IAuthRemoteDatasource {
  Future<LoginResponseModel> loginWithFirebaseToken(String firebaseToken);
  Future<void> logout();
  Future<ApiUserModel> getCurrentUser();
}

class AuthRemoteDatasource implements IAuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  @override
  Future<LoginResponseModel> loginWithFirebaseToken(
      String firebaseToken) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.firebaseLogin,
        data: {'id_token': firebaseToken},
      );
      return LoginResponseModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
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
      return ApiUserModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
