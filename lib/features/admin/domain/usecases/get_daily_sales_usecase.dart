import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_entity.dart';
import '../repositories/i_admin_repository.dart';

class GetDailySalesUsecase {
  final IAdminRepository _repository;
  GetDailySalesUsecase(this._repository);

  Future<Either<Failure, List<DailySalesEntity>>> call({
    required DateTime from,
    required DateTime to,
  }) =>
      _repository.getDailySales(from: from, to: to);
}
