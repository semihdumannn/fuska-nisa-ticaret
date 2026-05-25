import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/profile_entity.dart';
import '../repositories/i_profile_repository.dart';

class UpdateProfileInput {
  final String? name;
  final String? email;
  final String? companyName;

  const UpdateProfileInput({
    this.name,
    this.email,
    this.companyName,
  });

  bool get hasChanges => name != null || email != null || companyName != null;
}

class UpdateProfileUsecase {
  final IProfileRepository _repository;

  UpdateProfileUsecase(this._repository);

  Future<Either<Failure, ProfileEntity>> call(UpdateProfileInput input) {
    if (!input.hasChanges) {
      return Future.value(
          const Left(ServerFailure('Guncellenecek alan bulunamadi')));
    }
    return _repository.updateProfile(
      name: input.name,
      email: input.email,
      companyName: input.companyName,
    );
  }
}
