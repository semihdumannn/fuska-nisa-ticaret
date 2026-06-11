import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address_entity.dart';
import '../repositories/i_profile_repository.dart';

class UpdateAddressUsecase {
  final IProfileRepository _repository;

  UpdateAddressUsecase(this._repository);

  Future<Either<Failure, AddressEntity>> call(AddressEntity address) {
    if (address.id == null) {
      return Future.value(
          const Left(ServerFailure('Adres ID bulunamadı')));
    }
    return _repository.updateAddress(address);
  }
}
