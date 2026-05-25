import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class LoginUsecase {
  final IAuthRepository _repository;

  LoginUsecase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String phone,
    required String otp,
  }) {
    return _repository.loginWithPhoneOTP(phone: phone, otp: otp);
  }
}
