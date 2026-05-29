import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/delivery_order_model.dart';

abstract class IDeliveryRemoteDatasource {
  /// Teslimatcıya atanmış/aktif siparişleri döner.
  Future<List<DeliveryOrderModel>> getDeliveryOrders();

  /// Tek teslimat siparişini döner.
  Future<DeliveryOrderModel> getDeliveryOrderDetail(int orderId);

  /// Siparişi teslimatçıya ata (PUT /delivery/orders/{id}/assign).
  Future<DeliveryOrderModel> assignOrder(int orderId);

  /// Siparişi "yolda" olarak işaretle (PUT /delivery/orders/{id}/on-the-way).
  Future<DeliveryOrderModel> markOnTheWay(int orderId);

  /// Siparişi teslim edildi olarak işaretle (PUT /delivery/orders/{id}/deliver).
  Future<DeliveryOrderModel> deliverOrder(int orderId);
}

class DeliveryRemoteDatasource implements IDeliveryRemoteDatasource {
  final Dio _dio;

  DeliveryRemoteDatasource(this._dio);

  @override
  Future<List<DeliveryOrderModel>> getDeliveryOrders() async {
    try {
      final response = await _dio.get(ApiEndpoints.deliveryOrders);
      final rawData = response.data;
      final List<dynamic> data;

      if (rawData is Map && rawData.containsKey('data')) {
        data = rawData['data'] as List;
      } else if (rawData is List) {
        data = rawData;
      } else {
        return [];
      }

      return data
          .map((json) =>
              DeliveryOrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<DeliveryOrderModel> getDeliveryOrderDetail(int orderId) async {
    try {
      final response = await _dio.get(ApiEndpoints.deliveryOrder(orderId));
      final rawData = response.data;
      final Map<String, dynamic> json;

      if (rawData is Map && rawData.containsKey('data')) {
        json = rawData['data'] as Map<String, dynamic>;
      } else {
        json = rawData as Map<String, dynamic>;
      }

      return DeliveryOrderModel.fromJson(json);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<DeliveryOrderModel> assignOrder(int orderId) async {
    try {
      final response = await _dio.put(ApiEndpoints.deliveryAssign(orderId));
      return DeliveryOrderModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<DeliveryOrderModel> markOnTheWay(int orderId) async {
    try {
      final response = await _dio.put(ApiEndpoints.deliveryOnTheWay(orderId));
      return DeliveryOrderModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<DeliveryOrderModel> deliverOrder(int orderId) async {
    try {
      final response = await _dio.put(ApiEndpoints.deliveryDeliver(orderId));
      return DeliveryOrderModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
