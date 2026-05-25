import 'package:dartz/dartz.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDatasource _remoteDatasource;
  final FirebaseAuthDatasource _firebaseDatasource;
  final AuthLocalDatasource _localDatasource;

  AuthRepositoryImpl({
    required IAuthRemoteDatasource remoteDatasource,
    required FirebaseAuthDatasource firebaseDatasource,
    required AuthLocalDatasource localDatasource,
  })  : _remoteDatasource = remoteDatasource,
        _firebaseDatasource = firebaseDatasource,
        _localDatasource = localDatasource;

  @override
  Future<Either<Failure, void>> sendOTP(String phone) async {
    try {
      await _firebaseDatasource.sendOTP(phone);
      return const Right(null);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> loginWithPhoneOTP({
    required String phone,
    required String otp,
  }) async {
    try {
      final firebaseToken = await _firebaseDatasource.verifyOTP(otp);
      final loginResponse =
          await _remoteDatasource.loginWithFirebaseToken(firebaseToken);
      await _localDatasource.saveToken(loginResponse.token);
      await _localDatasource.saveUser(loginResponse.user);
      return Right(loginResponse.user.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _remoteDatasource.logout();
      await _firebaseDatasource.signOut();
      await _localDatasource.clearToken();
      await _localDatasource.clearUser();
      return const Right(null);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final cachedUser = _localDatasource.getUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }
      final user = await _remoteDatasource.getCurrentUser();
      await _localDatasource.saveUser(user);
      return Right(user.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  bool get isLoggedIn => _localDatasource.hasToken;
}
