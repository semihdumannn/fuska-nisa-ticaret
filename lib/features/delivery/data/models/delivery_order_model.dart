import '../../domain/entities/delivery_route_entity.dart';

/// API'nin OrderResource → DeliveryRouteEntity dönüşümü.
/// Delivery endpoint'leri /v1/delivery/orders/* aynı OrderResource döner.
class DeliveryOrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final double total;
  final String? notes;
  final String? deliveredAt;
  final DeliveryAddressModel address;
  final DeliveryCustomerModel? customer;
  final List<DeliveryItemModel> items;

  const DeliveryOrderModel({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    this.notes,
    this.deliveredAt,
    required this.address,
    this.customer,
    required this.items,
  });

  factory DeliveryOrderModel.fromJson(Map<String, dynamic> json) {
    final addressJson = json['address'] as Map<String, dynamic>? ?? {};
    final customerJson = json['customer'] as Map<String, dynamic>?;

    return DeliveryOrderModel(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String? ?? '#${json['id']}',
      status: json['status'] as String,
      total: (json['total'] as num).toDouble(),
      notes: json['notes'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      address: DeliveryAddressModel.fromJson(addressJson),
      customer: customerJson != null
          ? DeliveryCustomerModel.fromJson(customerJson)
          : null,
      items: (json['items'] as List? ?? [])
          .map((i) =>
              DeliveryItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  DeliveryRouteEntity toEntity() {
    return DeliveryRouteEntity(
      id: id.toString(),
      customerName: customer?.name ?? address.title ?? 'Müşteri',
      address: address.fullAddress,
      phone: customer?.phone ?? '',
      status: status,
      notes: notes,
      latitude: address.latitude,
      longitude: address.longitude,
      orderNumber: orderNumber,
      orderTotal: total,
      items: items
          .map((i) => DeliveryItemEntity(
                productName: i.productName,
                quantity: i.quantity,
                unit: i.unit,
              ))
          .toList(),
    );
  }
}

class DeliveryAddressModel {
  final String fullAddress;
  final String? title;
  final double? latitude;
  final double? longitude;

  const DeliveryAddressModel({
    required this.fullAddress,
    this.title,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddressModel.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressModel(
      fullAddress: json['full_address'] as String? ?? '',
      title: json['title'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }
}

class DeliveryCustomerModel {
  final String name;
  final String? phone;

  const DeliveryCustomerModel({required this.name, this.phone});

  factory DeliveryCustomerModel.fromJson(Map<String, dynamic> json) {
    return DeliveryCustomerModel(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
    );
  }
}

class DeliveryItemModel {
  final String productName;
  final int quantity;
  final String unit;

  const DeliveryItemModel({
    required this.productName,
    required this.quantity,
    required this.unit,
  });

  factory DeliveryItemModel.fromJson(Map<String, dynamic> json) {
    return DeliveryItemModel(
      productName: json['product_name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unit: json['unit'] as String? ?? 'adet',
    );
  }
}
