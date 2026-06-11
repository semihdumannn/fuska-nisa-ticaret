import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class IAuthRepository {
  /// Telefon numarası ile cihaz-bağlı TOTP doğrulaması yapar.
  ///
  /// Cihazda kayıtlı secret yoksa veya farklı bir telefona aitse
  /// `device-register` ile yeni/var olan secret alınır ve cihaza kaydedilir.
  /// Secret mevcutsa `totp-login` ile sessizce giriş yapılır.
  Future<Either<Failure, UserEntity>> authenticateWithPhone(String phone);

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, UserEntity>> getCurrentUser();

  bool get isLoggedIn;
}
