import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/i_profile_repository.dart';

class DeleteAddressUsecase {
  final IProfileRepository _repository;

  DeleteAddressUsecase(this._repository);

  Future<Either<Failure, void>> call(int addressId) {
    return _repository.deleteAddress(addressId);
  }
}
