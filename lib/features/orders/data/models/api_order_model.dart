import '../../domain/entities/order_entity.dart';

class ApiOrderModel {
  final int id;
  final String orderNumber;
  final String status;
  final List<ApiOrderItemModel> items;
  final double subtotal;
  final double? discount;
  final double total;
  final ApiOrderAddressModel address;
  final String? notes;
  final String? couponCode;
  final String createdAt;
  final String? updatedAt;
  final String? deliveredAt;
  final String? deliveryPersonName;
  final String? trackingNote;

  const ApiOrderModel({
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

  factory ApiOrderModel.fromJson(Map<String, dynamic> json) {
    return ApiOrderModel(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String? ?? '#${json['id']}',
      status: json['status'] as String,
      items: (json['items'] as List? ?? [])
          .map((i) => ApiOrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: json['discount'] != null
          ? (json['discount'] as num).toDouble()
          : null,
      total: (json['total'] as num).toDouble(),
      address: ApiOrderAddressModel.fromJson(
          json['address'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
      couponCode: json['coupon_code'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String?,
      deliveredAt: json['delivered_at'] as String?,
      deliveryPersonName: json['delivery_person_name'] as String?,
      trackingNote: json['tracking_note'] as String?,
    );
  }

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      orderNumber: orderNumber,
      status: OrderStatus.fromString(status),
      items: items.map((i) => i.toEntity()).toList(),
      subtotal: subtotal,
      discount: discount,
      total: total,
      address: address.toEntity(),
      notes: notes,
      couponCode: couponCode,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: updatedAt != null ? DateTime.tryParse(updatedAt!) : null,
      deliveredAt:
          deliveredAt != null ? DateTime.tryParse(deliveredAt!) : null,
      deliveryPersonName: deliveryPersonName,
      trackingNote: trackingNote,
    );
  }
}

class ApiOrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productImageUrl;
  final int? variantId;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const ApiOrderItemModel({
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

  factory ApiOrderItemModel.fromJson(Map<String, dynamic> json) {
    return ApiOrderItemModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: json['product_name'] as String,
      productImageUrl: json['product_image_url'] as String?,
      variantId: json['variant_id'] as int?,
      variantName: json['variant_name'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: ((json['total'] ?? json['total_price']) as num? ?? 0).toDouble(),
    );
  }

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      id: id,
      productId: productId,
      productName: productName,
      productImageUrl: productImageUrl,
      variantId: variantId,
      variantName: variantName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }
}

class ApiOrderAddressModel {
  final int? id;
  final String fullName;
  final String phone;
  final String address;
  final String city;
  final String? district;
  final String? postalCode;
  final double? latitude;
  final double? longitude;

  const ApiOrderAddressModel({
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

  factory ApiOrderAddressModel.fromJson(Map<String, dynamic> json) {
    return ApiOrderAddressModel(
      id: json['id'] as int?,
      fullName: json['full_name'] as String? ?? json['title'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['full_address'] as String? ?? json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String?,
      postalCode: json['postal_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  OrderAddressEntity toEntity() {
    return OrderAddressEntity(
      id: id,
      fullName: fullName,
      phone: phone,
      address: address,
      city: city,
      district: district,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
