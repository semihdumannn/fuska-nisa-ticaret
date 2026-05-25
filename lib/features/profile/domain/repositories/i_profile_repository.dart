import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address_entity.dart';
import '../entities/profile_entity.dart';

abstract class IProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();

  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? name,
    String? email,
    String? companyName,
  });

  Future<Either<Failure, String>> updateAvatar(String imagePath);

  Future<Either<Failure, List<AddressEntity>>> getAddresses();

  Future<Either<Failure, AddressEntity>> getAddressDetail(int id);

  Future<Either<Failure, AddressEntity>> addAddress(AddressEntity address);

  Future<Either<Failure, AddressEntity>> updateAddress(AddressEntity address);

  Future<Either<Failure, void>> deleteAddress(int id);

  Future<Either<Failure, void>> setDefaultAddress(int id);

  Future<Either<Failure, void>> clearProfileCache();
}
