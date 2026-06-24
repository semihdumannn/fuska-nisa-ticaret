// ignore: unused_import
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/providers/core_providers.dart';

class SubscriptionRemoteDatasource {
  // ignore: unused_field
  final Dio _dio;
  SubscriptionRemoteDatasource(this._dio);

  // Backend hazır olunca: final response = await _dio.get(ApiEndpoints.subscriptions);
  Future<List<Map<String, dynamic>>> getSubscriptions() async => [];
}

final subscriptionDatasourceProvider = Provider<SubscriptionRemoteDatasource>(
  (ref) => SubscriptionRemoteDatasource(ref.watch(apiClientProvider).dio),
);

final subscriptionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(subscriptionDatasourceProvider).getSubscriptions();
});
