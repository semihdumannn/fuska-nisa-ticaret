import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/delivery_route_entity.dart';
import '../repositories/i_delivery_repository.dart';

/// Aktif teslimat rotasını getiren use case.
///
/// Kullanım:
/// ```dart
/// final result = await getDeliveryRouteUseCase();
/// result.fold(
///   (failure) => handleError(failure.message),
///   (route) => handleRoute(route),
/// );
/// ```
class GetDeliveryRouteUseCase {
  final IDeliveryRepository _repository;

  const GetDeliveryRouteUseCase(this._repository);

  Future<Either<Failure, List<DeliveryRouteEntity>>> call() {
    return _repository.getDeliveryRoute();
  }
}
