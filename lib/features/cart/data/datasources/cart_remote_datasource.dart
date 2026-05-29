import 'package:dio/dio.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';

class ApiCartItemModel {
  final int id;
  final int productId;
  final int? variantId;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? productName;

  const ApiCartItemModel({
    required this.id,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.productName,
  });

  factory ApiCartItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return ApiCartItemModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      variantId: json['variant_id'] as int?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      lineTotal: (json['line_total'] as num).toDouble(),
      productName: product?['name'] as String?,
    );
  }
}

class ApiCartModel {
  final int id;
  final int itemCount;
  final double subtotal;
  final List<ApiCartItemModel> items;

  const ApiCartModel({
    required this.id,
    required this.itemCount,
    required this.subtotal,
    required this.items,
  });

  factory ApiCartModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return ApiCartModel(
      id: json['id'] as int,
      itemCount: json['item_count'] as int? ?? rawItems.length,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      items: rawItems
          .map((i) =>
              ApiCartItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

abstract class ICartRemoteDatasource {
  Future<ApiCartModel> getCart();
  Future<ApiCartModel> addItem({
    required int productId,
    required int quantity,
    int? variantId,
  });
  Future<ApiCartModel> updateItem({required int itemId, required int quantity});
  Future<ApiCartModel> removeItem(int itemId);
  Future<void> clearCart();
}

class CartRemoteDatasource implements ICartRemoteDatasource {
  final Dio _dio;

  CartRemoteDatasource(this._dio);

  ApiCartModel _parseCartResponse(dynamic responseData) {
    final rawData = responseData;
    final Map<String, dynamic> json;

    if (rawData is Map && rawData.containsKey('data')) {
      json = rawData['data'] as Map<String, dynamic>;
    } else {
      json = rawData as Map<String, dynamic>;
    }

    return ApiCartModel.fromJson(json);
  }

  @override
  Future<ApiCartModel> getCart() async {
    try {
      final response = await _dio.get(ApiEndpoints.cart);
      return _parseCartResponse(response.data);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiCartModel> addItem({
    required int productId,
    required int quantity,
    int? variantId,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.cartItems,
        data: {
          'product_id': productId,
          'quantity': quantity,
          if (variantId != null) 'variant_id': variantId,
        },
      );
      return _parseCartResponse(response.data);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiCartModel> updateItem({
    required int itemId,
    required int quantity,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.cartItem(itemId),
        data: {'quantity': quantity},
      );
      return _parseCartResponse(response.data);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<ApiCartModel> removeItem(int itemId) async {
    try {
      final response =
          await _dio.delete(ApiEndpoints.cartItem(itemId));
      return _parseCartResponse(response.data);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      await _dio.delete(ApiEndpoints.cart);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}
