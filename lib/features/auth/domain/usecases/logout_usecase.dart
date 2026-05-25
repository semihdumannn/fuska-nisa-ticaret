import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/i_auth_repository.dart';

class LogoutUsecase {
  final IAuthRepository _repository;

  LogoutUsecase(this._repository);

  Future<Either<Failure, void>> call() {
    return _repository.logout();
  }
}
