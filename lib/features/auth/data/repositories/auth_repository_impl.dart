import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/totp_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_response_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;
  final TotpService _totpService;

  AuthRepositoryImpl({
    required IAuthRemoteDatasource remoteDatasource,
    required AuthLocalDatasource localDatasource,
    required TotpService totpService,
  })  : _remoteDatasource = remoteDatasource,
        _localDatasource = localDatasource,
        _totpService = totpService;

  String get _deviceName => Platform.operatingSystem;

  @override
  Future<Either<Failure, UserEntity>> authenticateWithPhone(
      String phone) async {
    try {
      final offsetMs = await _totpService.getServerTimeOffsetMs();
      final savedSecret = await _localDatasource.getTotpSecret();
      final savedPhone = await _localDatasource.getSavedPhone();

      LoginResponseModel loginResponse;

      if (savedSecret != null && savedPhone == phone) {
        final code = _totpService.generateCode(savedSecret, offsetMs);
        loginResponse = await _remoteDatasource.totpLogin(
          phone: phone,
          code: code,
          deviceName: _deviceName,
        );
      } else {
        final registerResponse = await _remoteDatasource.registerDevice(
          phone: phone,
          deviceName: _deviceName,
        );
        await _localDatasource.saveTotpCredentials(
          phone: phone,
          secret: registerResponse.totpSecret,
        );
        loginResponse = LoginResponseModel(
          token: registerResponse.token,
          user: registerResponse.user,
        );
      }

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
