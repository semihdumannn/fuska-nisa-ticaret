import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/subscription_model.dart';

class SubscriptionRemoteDatasource {
  final Dio _dio;
  SubscriptionRemoteDatasource(this._dio);

  Future<List<SubscriptionModel>> getSubscriptions() async {
    try {
      final response = await _dio.get(ApiEndpoints.subscriptions);
      final rawData = response.data;
      final List<dynamic> list;
      if (rawData is Map && rawData.containsKey('data')) {
        final d = rawData['data'];
        list = d is List ? d : [];
      } else if (rawData is List) {
        list = rawData;
      } else {
        return [];
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(SubscriptionModel.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<SubscriptionModel> createSubscription({
    required String productId,
    String? variantId,
    required String plan,
    String? startDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.subscriptions,
        data: {
          'product_id': productId,
          if (variantId != null) 'variant_id': variantId,
          'plan': plan,
          if (startDate != null) 'start_date': startDate,
        },
      );
      final rawData = response.data;
      final data = rawData is Map && rawData.containsKey('data')
          ? rawData['data'] as Map<String, dynamic>
          : rawData as Map<String, dynamic>;
      return SubscriptionModel.fromJson(data);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<SubscriptionModel> updateSubscription(
    int id, {
    String? plan,
    String? status,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.subscriptionDetail(id),
        data: {
          if (plan != null) 'plan': plan,
          if (status != null) 'status': status,
        },
      );
      final rawData = response.data;
      final data = rawData is Map && rawData.containsKey('data')
          ? rawData['data'] as Map<String, dynamic>
          : rawData as Map<String, dynamic>;
      return SubscriptionModel.fromJson(data);
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }

  Future<void> cancelSubscription(int id) async {
    try {
      await _dio.delete(ApiEndpoints.subscriptionDetail(id));
    } on DioException catch (e) {
      throw ExceptionHandler.handleException(e);
    }
  }
}

final subscriptionDatasourceProvider = Provider<SubscriptionRemoteDatasource>(
  (ref) => SubscriptionRemoteDatasource(ref.watch(apiClientProvider).dio),
);

final subscriptionsProvider = FutureProvider<List<SubscriptionModel>>((ref) async {
  return ref.watch(subscriptionDatasourceProvider).getSubscriptions();
});
