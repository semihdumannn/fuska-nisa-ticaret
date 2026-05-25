import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/api_address_model.dart';
import '../models/api_profile_model.dart';

abstract class IProfileRemoteDatasource {
  Future<ApiProfileModel> getProfile();
  Future<ApiProfileModel> updateProfile({
    String? name,
    String? email,
    String? companyName,
  });
  Future<String> updateAvatar(String imagePath);
  Future<List<ApiAddressModel>> getAddresses();
  Future<ApiAddressModel> getAddressDetail(int id);
  Future<ApiAddressModel> addAddress(Map<String, dynamic> addressData);
  Future<ApiAddressModel> updateAddress(int id, Map<String, dynamic> data);
  Future<void> deleteAddress(int id);
  Future<void> setDefaultAddress(int id);
}

class ProfileRemoteDatasource implements IProfileRemoteDatasource {
  final Dio _dio;

  ProfileRemoteDatasource(this._dio);

  @override
  Future<ApiProfileModel> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      return ApiProfileModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiProfileModel> updateProfile({
    String? name,
    String? email,
    String? companyName,
  }) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.profile,
        data: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (companyName != null) 'company_name': companyName,
        },
      );
      return ApiProfileModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<String> updateAvatar(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(imagePath),
      });
      final response = await _dio.post(
        '${ApiEndpoints.profile}/avatar',
        data: formData,
      );
      return response.data['data']['avatar_url'] as String;
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<List<ApiAddressModel>> getAddresses() async {
    try {
      final response = await _dio.get(ApiEndpoints.addresses);
      final data = response.data['data'] as List;
      return data
          .map((json) =>
              ApiAddressModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiAddressModel> getAddressDetail(int id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.addresses}/$id');
      return ApiAddressModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiAddressModel> addAddress(Map<String, dynamic> addressData) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.addresses,
        data: addressData,
      );
      return ApiAddressModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiAddressModel> updateAddress(
      int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        '${ApiEndpoints.addresses}/$id',
        data: data,
      );
      return ApiAddressModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> deleteAddress(int id) async {
    try {
      await _dio.delete('${ApiEndpoints.addresses}/$id');
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> setDefaultAddress(int id) async {
    try {
      await _dio.post('${ApiEndpoints.addresses}/$id/default');
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
