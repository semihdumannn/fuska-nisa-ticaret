import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../datasources/device_remote_datasource.dart';

final deviceRemoteDatasourceProvider =
    Provider<IDeviceRemoteDatasource>((ref) {
  return DeviceRemoteDatasource(ref.watch(apiClientProvider).dio);
});
