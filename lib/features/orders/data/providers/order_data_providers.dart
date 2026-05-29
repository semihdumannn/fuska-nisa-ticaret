import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../delivery/data/providers/delivery_data_providers.dart';
import '../datasources/order_remote_datasource.dart';
import '../repositories/order_repository_impl.dart';
import '../../domain/repositories/i_order_repository.dart';

final orderRemoteDatasourceProvider =
    Provider<IOrderRemoteDatasource>((ref) {
  return OrderRemoteDatasource(ref.watch(apiClientProvider).dio);
});

final apiOrderRepositoryProvider = Provider<IOrderRepository>((ref) {
  return OrderRepositoryImpl(
    ref.watch(orderRemoteDatasourceProvider),
    ref.watch(deliveryRemoteDatasourceProvider),
  );
});
