import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/i_admin_repository.dart';

class ToggleUserStatusUsecase {
  final IAdminRepository _repository;
  ToggleUserStatusUsecase(this._repository);

  Future<Either<Failure, void>> call(String userId, bool isActive) =>
      _repository.toggleUserStatus(userId, isActive);
}
