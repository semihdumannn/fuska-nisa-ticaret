import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../datasources/delivery_remote_datasource.dart';
import '../repositories/delivery_repository_impl.dart';
import '../../domain/repositories/i_delivery_repository.dart';

final deliveryRemoteDatasourceProvider =
    Provider<IDeliveryRemoteDatasource>((ref) {
  return DeliveryRemoteDatasource(ref.watch(apiClientProvider).dio);
});

final deliveryRepositoryProvider = Provider<IDeliveryRepository>((ref) {
  return DeliveryRepositoryImpl(
    remoteDatasource: ref.watch(deliveryRemoteDatasourceProvider),
    cacheManager: ref.watch(cacheManagerProvider),
  );
});
