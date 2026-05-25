import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';

final authRemoteDatasourceProvider = Provider<IAuthRemoteDatasource>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return AuthRemoteDatasource(dio);
});

final authLocalDatasourceProvider = Provider<AuthLocalDatasource>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return AuthLocalDatasource(cacheManager);
});
