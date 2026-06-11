import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class AuthenticateUsecase {
  final IAuthRepository _repository;

  AuthenticateUsecase(this._repository);

  Future<Either<Failure, UserEntity>> call(String phone) {
    return _repository.authenticateWithPhone(phone);
  }
}
