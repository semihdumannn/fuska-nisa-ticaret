import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/address_entity.dart';
import '../repositories/i_profile_repository.dart';

class GetAddressesUsecase {
  final IProfileRepository _repository;

  GetAddressesUsecase(this._repository);

  Future<Either<Failure, List<AddressEntity>>> call() {
    return _repository.getAddresses();
  }
}
