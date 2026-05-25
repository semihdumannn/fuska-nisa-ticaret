import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/i_auth_repository.dart';
import 'auth_datasource_providers.dart';

final apiAuthRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDatasource: ref.watch(authRemoteDatasourceProvider),
    firebaseDatasource: ref.watch(firebaseAuthDatasourceProvider),
    localDatasource: ref.watch(authLocalDatasourceProvider),
  );
});
