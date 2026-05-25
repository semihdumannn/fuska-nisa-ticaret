import 'package:equatable/equatable.dart';

/// Teslimat rotasındaki tek bir sipariş kalemini temsil eden entity.
class DeliveryItemEntity extends Equatable {
  final String productName;
  final int quantity;
  final String unit;

  const DeliveryItemEntity({
    required this.productName,
    required this.quantity,
    required this.unit,
  });

  @override
  List<Object?> get props => [productName, quantity, unit];
}

/// Teslimat rotasındaki tek bir teslimat noktasını temsil eden domain entity.
/// Firebase veya herhangi bir dış bağımlılık içermez — pure Dart.
///
/// [status] değerleri: 'pending', 'on_the_way', 'delivered'
class DeliveryRouteEntity extends Equatable {
  final String id;
  final String customerName;
  final String address;
  final String phone;
  final String status;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final String orderNumber;
  final double orderTotal;
  final List<DeliveryItemEntity> items;

  const DeliveryRouteEntity({
    required this.id,
    required this.customerName,
    required this.address,
    required this.phone,
    required this.status,
    this.notes,
    this.latitude,
    this.longitude,
    required this.orderNumber,
    required this.orderTotal,
    required this.items,
  });

  /// Teslimat tamamlandı mı?
  bool get isDelivered => status == 'delivered';

  /// Teslimat beklemede mi?
  bool get isPending => status == 'pending';

  /// Yolda mı?
  bool get isOnTheWay => status == 'on_the_way';

  /// Koordinat bilgisi mevcut mu?
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Teslimat yapılabilir mi (yolda durumunda olmalı)?
  bool get canDeliver => status == 'on_the_way';

  @override
  List<Object?> get props => [
        id,
        customerName,
        address,
        phone,
        status,
        notes,
        latitude,
        longitude,
        orderNumber,
        orderTotal,
        items,
      ];
}
