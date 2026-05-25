import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';
import '../repositories/i_field_agent_repository.dart';

/// Müşteri detayı getirme parametrelerini tutan value object.
class GetCustomerDetailParams {
  final String customerId;

  const GetCustomerDetailParams({required this.customerId});
}

/// Tek müşterinin detay bilgisini getiren use case.
///
/// Kullanım:
/// ```dart
/// final result = await getCustomerDetailUseCase(
///   GetCustomerDetailParams(customerId: 'uid_123'),
/// );
/// result.fold(
///   (failure) => handleError(failure.message),
///   (customer) => handleCustomer(customer),
/// );
/// ```
class GetCustomerDetailUseCase {
  final IFieldAgentRepository _repository;

  const GetCustomerDetailUseCase(this._repository);

  Future<Either<Failure, CustomerEntity>> call(
    GetCustomerDetailParams params,
  ) {
    return _repository.getCustomerDetail(params.customerId);
  }
}
