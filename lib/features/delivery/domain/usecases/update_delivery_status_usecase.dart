import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/delivery_route_entity.dart';
import '../repositories/i_delivery_repository.dart';

/// Teslimat durumu güncelleme parametrelerini tutan value object.
///
/// [status] geçerli değerleri: 'pending', 'on_the_way', 'delivered'
class UpdateDeliveryStatusParams {
  final String orderId;
  final String status;

  const UpdateDeliveryStatusParams({
    required this.orderId,
    required this.status,
  });
}

/// Siparişin teslimat durumunu güncelleyen use case.
///
/// Kullanım:
/// ```dart
/// final result = await updateDeliveryStatusUseCase(
///   UpdateDeliveryStatusParams(orderId: 'order_123', status: 'on_the_way'),
/// );
/// result.fold(
///   (failure) => handleError(failure.message),
///   (updated) => handleSuccess(updated),
/// );
/// ```
class UpdateDeliveryStatusUseCase {
  final IDeliveryRepository _repository;

  const UpdateDeliveryStatusUseCase(this._repository);

  Future<Either<Failure, DeliveryRouteEntity>> call(
    UpdateDeliveryStatusParams params,
  ) {
    return _repository.updateDeliveryStatus(params.orderId, params.status);
  }
}
