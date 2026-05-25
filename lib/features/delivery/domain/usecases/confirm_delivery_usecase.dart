import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/delivery_route_entity.dart';
import '../repositories/i_delivery_repository.dart';

/// Teslimat onaylama parametrelerini tutan value object.
class ConfirmDeliveryParams {
  final String orderId;

  const ConfirmDeliveryParams({required this.orderId});
}

/// Siparişi teslim edildi olarak işaretleyen use case.
///
/// Kullanım:
/// ```dart
/// final result = await confirmDeliveryUseCase(
///   ConfirmDeliveryParams(orderId: 'order_123'),
/// );
/// result.fold(
///   (failure) => handleError(failure.message),
///   (updated) => handleSuccess(updated),
/// );
/// ```
class ConfirmDeliveryUseCase {
  final IDeliveryRepository _repository;

  const ConfirmDeliveryUseCase(this._repository);

  Future<Either<Failure, DeliveryRouteEntity>> call(
    ConfirmDeliveryParams params,
  ) {
    return _repository.confirmDelivery(params.orderId);
  }
}
