import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class GetCurrentUserUsecase {
  final IAuthRepository _repository;

  GetCurrentUserUsecase(this._repository);

  Future<Either<Failure, UserEntity>> call() {
    return _repository.getCurrentUser();
  }
}
