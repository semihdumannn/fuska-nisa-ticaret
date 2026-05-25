import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/profile_entity.dart';
import '../repositories/i_profile_repository.dart';

class GetProfileUsecase {
  final IProfileRepository _repository;

  GetProfileUsecase(this._repository);

  Future<Either<Failure, ProfileEntity>> call() {
    return _repository.getProfile();
  }
}
