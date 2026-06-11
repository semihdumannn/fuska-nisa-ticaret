import 'package:dartz/dartz.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../../core/error/exception_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/i_profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';
import '../models/api_address_model.dart';

class ProfileRepositoryImpl implements IProfileRepository {
  final IProfileRemoteDatasource _remoteDatasource;
  final CacheManager _cacheManager;

  ProfileRepositoryImpl({
    required IProfileRemoteDatasource remoteDatasource,
    required CacheManager cacheManager,
  })  : _remoteDatasource = remoteDatasource,
        _cacheManager = cacheManager;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      final model = await _remoteDatasource.getProfile();
      final entity = model.toEntity();
      return Right(entity);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? name,
    String? email,
    String? companyName,
  }) async {
    try {
      final model = await _remoteDatasource.updateProfile(
        name: name,
        email: email,
        companyName: companyName,
      );
      await _cacheManager.invalidate(CacheKeys.userProfile);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, String>> updateAvatar(String imagePath) async {
    try {
      final avatarUrl = await _remoteDatasource.updateAvatar(imagePath);
      return Right(avatarUrl);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, List<AddressEntity>>> getAddresses() async {
    try {
      final models = await _remoteDatasource.getAddresses();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> getAddressDetail(int id) async {
    try {
      final model = await _remoteDatasource.getAddressDetail(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> addAddress(
      AddressEntity address) async {
    try {
      final model = await _remoteDatasource
          .addAddress(ApiAddressModel.entityToJson(address));
      await _cacheManager.invalidateByPrefix(CacheKeys.addresses);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, AddressEntity>> updateAddress(
      AddressEntity address) async {
    try {
      final model = await _remoteDatasource.updateAddress(
        address.id!,
        ApiAddressModel.entityToJson(address),
      );
      await _cacheManager.invalidateByPrefix(CacheKeys.addresses);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAddress(int id) async {
    try {
      await _remoteDatasource.deleteAddress(id);
      await _cacheManager.invalidateByPrefix(CacheKeys.addresses);
      return const Right(null);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> setDefaultAddress(int id) async {
    try {
      await _remoteDatasource.setDefaultAddress(id);
      await _cacheManager.invalidateByPrefix(CacheKeys.addresses);
      return const Right(null);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }

  @override
  Future<Either<Failure, void>> clearProfileCache() async {
    try {
      await _cacheManager.invalidate(CacheKeys.userProfile);
      await _cacheManager.invalidateByPrefix(CacheKeys.addresses);
      return const Right(null);
    } catch (e) {
      return Left(ExceptionHandler.handleException(e));
    }
  }
}
