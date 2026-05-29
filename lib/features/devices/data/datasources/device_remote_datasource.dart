import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';

abstract class IDeviceRemoteDatasource {
  /// FCM token'ını API'ye kaydet.
  Future<void> registerDevice(String fcmToken);

  /// Çıkış yapılırken token'ı API'den sil.
  Future<void> unregisterDevice(String fcmToken);
}

class DeviceRemoteDatasource implements IDeviceRemoteDatasource {
  final Dio _dio;

  DeviceRemoteDatasource(this._dio);

  @override
  Future<void> registerDevice(String fcmToken) async {
    try {
      await _dio.post(
        ApiEndpoints.devices,
        data: {
          'token': fcmToken,
          'platform': Platform.isAndroid ? 'android' : 'ios',
        },
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> unregisterDevice(String fcmToken) async {
    try {
      await _dio.delete(
        ApiEndpoints.devices,
        data: {'token': fcmToken},
      );
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
