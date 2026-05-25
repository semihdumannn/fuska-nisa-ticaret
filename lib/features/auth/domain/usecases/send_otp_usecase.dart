import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/i_auth_repository.dart';

class SendOtpUsecase {
  final IAuthRepository _repository;

  SendOtpUsecase(this._repository);

  Future<Either<Failure, void>> call(String phone) {
    return _repository.sendOTP(phone);
  }
}
