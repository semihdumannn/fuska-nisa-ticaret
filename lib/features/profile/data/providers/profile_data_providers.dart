import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../datasources/profile_remote_datasource.dart';
import '../repositories/profile_repository_impl.dart';
import '../../domain/repositories/i_profile_repository.dart';

final profileRemoteDatasourceProvider =
    Provider<IProfileRemoteDatasource>((ref) {
  return ProfileRemoteDatasource(ref.watch(apiClientProvider).dio);
});

final apiProfileRepositoryProvider = Provider<IProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    remoteDatasource: ref.watch(profileRemoteDatasourceProvider),
    cacheManager: ref.watch(cacheManagerProvider),
  );
});
