import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/field_agent_stats_entity.dart';
import '../repositories/i_field_agent_repository.dart';

/// Saha personelinin günlük istatistiklerini getiren use case.
///
/// Kullanım:
/// ```dart
/// final result = await getDailyStatsUseCase();
/// result.fold(
///   (failure) => handleError(failure.message),
///   (stats) => handleStats(stats),
/// );
/// ```
class GetDailyStatsUseCase {
  final IFieldAgentRepository _repository;

  const GetDailyStatsUseCase(this._repository);

  Future<Either<Failure, FieldAgentStatsEntity>> call() {
    return _repository.getDailyStats();
  }
}
