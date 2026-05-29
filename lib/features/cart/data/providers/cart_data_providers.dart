import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../datasources/cart_remote_datasource.dart';

final cartRemoteDatasourceProvider =
    Provider<ICartRemoteDatasource>((ref) {
  return CartRemoteDatasource(ref.watch(apiClientProvider).dio);
});
