import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class IAuthRepository {
  Future<Either<Failure, void>> sendOTP(String phone);

  Future<Either<Failure, UserEntity>> loginWithPhoneOTP({
    required String phone,
    required String otp,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  bool get isLoggedIn;
}
