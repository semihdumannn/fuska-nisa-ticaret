import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/admin_user_entity.dart';
import '../repositories/i_admin_repository.dart';

class GetAdminUsersUsecase {
  final IAdminRepository _repository;
  GetAdminUsersUsecase(this._repository);

  Future<Either<Failure, List<AdminUserEntity>>> call({
    int page = 1,
    String? role,
    String? searchQuery,
  }) =>
      _repository.getUsers(page: page, role: role, searchQuery: searchQuery);
}
