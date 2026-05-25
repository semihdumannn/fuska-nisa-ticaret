import 'package:equatable/equatable.dart';

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Beklemede';
      case OrderStatus.confirmed:
        return 'Onaylandı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.onTheWay:
        return 'Yolda';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get apiValue {
    if (this == OrderStatus.onTheWay) return 'on_the_way';
    return name;
  }

  bool get isActive =>
      this != OrderStatus.delivered && this != OrderStatus.cancelled;

  bool get isFinal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;
}

class OrderEntity extends Equatable {
  final int id;
  final String orderNumber;
  final OrderStatus status;
  final List<OrderItemEntity> items;
  final double subtotal;
  final double? discount;
  final double total;
  final OrderAddressEntity address;
  final String? notes;
  final String? couponCode;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deliveredAt;
  final String? deliveryPersonName;
  final String? trackingNote;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.items,
    required this.subtotal,
    this.discount,
    required this.total,
    required this.address,
    this.notes,
    this.couponCode,
    required this.createdAt,
    this.updatedAt,
    this.deliveredAt,
    this.deliveryPersonName,
    this.trackingNote,
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  bool get canBeCancelled =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  @override
  List<Object?> get props => [id, orderNumber, status, total, createdAt];
}

class OrderItemEntity extends Equatable {
  final int id;
  final int productId;
  final String productName;
  final String? productImageUrl;
  final int? variantId;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    this.variantId,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  String get displayName =>
      variantName != null ? '$productName - $variantName' : productName;

  @override
  List<Object?> get props => [id, productId, variantId, quantity];
}

class OrderAddressEntity extends Equatable {
  final int? id;
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String? district;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  const OrderAddressEntity({
    this.id,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.city,
    this.district,
    this.postalCode,
    this.latitude,
    this.longitude,
  });

  String get fullAddress =>
      '$address, $city${district != null ? ", $district" : ""}';

  @override
  List<Object?> get props => [id, address, city];
}
