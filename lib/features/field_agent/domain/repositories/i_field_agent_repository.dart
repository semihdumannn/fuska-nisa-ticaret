import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/customer_entity.dart';
import '../entities/field_agent_stats_entity.dart';

/// Saha personeli domain repository sözleşmesi.
/// Implementasyon data katmanında yapılır — domain pure Dart kalır.
abstract class IFieldAgentRepository {
  /// Saha personelinin bugünkü sipariş istatistiklerini döner.
  /// Başarıda [FieldAgentStatsEntity], hata durumunda [Failure] döner.
  Future<Either<Failure, FieldAgentStatsEntity>> getDailyStats();

  /// Verilen sorguya göre müşteri arar.
  /// [query] boş string ise tüm müşteriler döner (sayfa limiti uygulanır).
  Future<Either<Failure, List<CustomerEntity>>> searchCustomers(String query);

  /// Verilen [customerId] ile tek müşteri detayını döner.
  /// Müşteri bulunamazsa [NotFoundFailure] döner.
  Future<Either<Failure, CustomerEntity>> getCustomerDetail(String customerId);
}
