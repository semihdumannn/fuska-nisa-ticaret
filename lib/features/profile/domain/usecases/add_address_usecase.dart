import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address_entity.dart';
import '../repositories/i_profile_repository.dart';

class AddAddressUsecase {
  final IProfileRepository _repository;

  AddAddressUsecase(this._repository);

  Future<Either<Failure, AddressEntity>> call(AddressEntity address) {
    if (address.addressLine.trim().isEmpty) {
      return Future.value(
          const Left(ServerFailure('Adres bilgisi bos olamaz')));
    }
    if (address.city.trim().isEmpty) {
      return Future.value(const Left(ServerFailure('Sehir bilgisi gerekli')));
    }
    return _repository.addAddress(address);
  }
}
