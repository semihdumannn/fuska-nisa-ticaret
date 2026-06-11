import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/api_order_model.dart';

abstract class IOrderRemoteDatasource {
  Future<List<ApiOrderModel>> getOrders({
    int page = 1,
    int perPage = 20,
    String? status,
  });

  Future<ApiOrderModel> getOrderDetail(int id);

  Future<ApiOrderModel> createOrder({
    required List<Map<String, dynamic>> items,
    required int addressId,
    String? paymentMethod,
    String? notes,
    String? couponCode,
  });

  Future<ApiOrderModel> cancelOrder(int orderId);

  Future<ApiOrderModel> updateOrderStatus({
    required int orderId,
    required String newStatus,
    String? note,
  });
}

class OrderRemoteDatasource implements IOrderRemoteDatasource {
  final Dio _dio;

  OrderRemoteDatasource(this._dio);

  @override
  Future<List<ApiOrderModel>> getOrders({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.orders,
        queryParameters: {
          'page': page,
          'per_page': perPage,
          if (status != null) 'status': status,
        },
      );
      final data = response.data['data'] as List;
      return data
          .map((json) =>
              ApiOrderModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiOrderModel> getOrderDetail(int id) async {
    try {
      final response = await _dio.get(ApiEndpoints.orderDetail(id));
      return ApiOrderModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiOrderModel> createOrder({
    required List<Map<String, dynamic>> items,
    required int addressId,
    String? paymentMethod,
    String? notes,
    String? couponCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.orders,
        data: {
          'items': items,
          'address_id': addressId,
          'payment_method': paymentMethod ?? 'cash',
          if (notes != null) 'notes': notes,
          if (couponCode != null) 'coupon_code': couponCode,
        },
      );
      final body = response.data as Map<String, dynamic>;
      final json = body.containsKey('data')
          ? body['data'] as Map<String, dynamic>
          : body.containsKey('order')
              ? body['order'] as Map<String, dynamic>
              : body;
      return ApiOrderModel.fromJson(json);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiOrderModel> cancelOrder(int orderId) async {
    try {
      final response =
          await _dio.post(ApiEndpoints.orderCancel(orderId));
      return ApiOrderModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiOrderModel> updateOrderStatus({
    required int orderId,
    required String newStatus,
    String? note,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.adminOrderStatus(orderId),
        data: {
          'status': newStatus,
          if (note != null) 'note': note,
        },
      );
      return ApiOrderModel.fromJson(
          response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
