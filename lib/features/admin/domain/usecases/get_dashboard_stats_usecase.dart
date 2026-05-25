import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/i_admin_repository.dart';

class GetDashboardStatsUsecase {
  final IAdminRepository _repository;
  GetDashboardStatsUsecase(this._repository);

  Future<Either<Failure, DashboardStatsEntity>> call() =>
      _repository.getDashboardStats();
}
