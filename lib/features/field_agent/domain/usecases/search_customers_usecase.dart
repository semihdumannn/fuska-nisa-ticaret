import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';
import '../repositories/i_field_agent_repository.dart';

/// Müşteri arama parametrelerini tutan value object.
class SearchCustomersParams {
  final String query;

  const SearchCustomersParams({required this.query});
}

/// Müşteri araması yapan use case.
///
/// Kullanım:
/// ```dart
/// final result = await searchCustomersUseCase(
///   SearchCustomersParams(query: 'Ahmet'),
/// );
/// result.fold(
///   (failure) => handleError(failure.message),
///   (customers) => handleCustomers(customers),
/// );
/// ```
class SearchCustomersUseCase {
  final IFieldAgentRepository _repository;

  const SearchCustomersUseCase(this._repository);

  Future<Either<Failure, List<CustomerEntity>>> call(
    SearchCustomersParams params,
  ) {
    return _repository.searchCustomers(params.query);
  }
}
