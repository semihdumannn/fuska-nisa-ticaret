import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/delivery_route_entity.dart';

/// Teslimat domain repository sözleşmesi.
/// Implementasyon data katmanında yapılır — domain pure Dart kalır.
abstract class IDeliveryRepository {
  /// Aktif teslimat rotasını (bugüne ait siparişleri) döner.
  /// Başarıda [List<DeliveryRouteEntity>], hata durumunda [Failure] döner.
  Future<Either<Failure, List<DeliveryRouteEntity>>> getDeliveryRoute();

  /// Verilen [orderId] ile siparişi teslim edildi olarak işaretler.
  /// Başarıda güncellenmiş [DeliveryRouteEntity] döner.
  Future<Either<Failure, DeliveryRouteEntity>> confirmDelivery(String orderId);

  /// Verilen [orderId] ile siparişin durumunu [status] olarak günceller.
  /// [status] değerleri: 'pending', 'on_the_way', 'delivered'
  Future<Either<Failure, DeliveryRouteEntity>> updateDeliveryStatus(
    String orderId,
    String status,
  );
}
