import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String? imageUrl;
  final int qty;
  final double unitPrice;
  final double totalPrice;
  final String? variantId;
  final String? variantName;
  final String? brandName;

  const OrderItem({
    required this.productId,
    required this.productName,
    this.imageUrl,
    required this.qty,
    required this.unitPrice,
    required this.totalPrice,
    this.variantId,
    this.variantName,
    this.brandName,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      qty: (map['qty'] as num? ?? 0).toInt(),
      unitPrice: (map['unitPrice'] as num? ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] as num? ?? 0).toDouble(),
      variantId: map['variantId'] as String?,
      variantName: map['variantName'] as String?,
      brandName: map['brandName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'qty': qty,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'variantId': variantId,
      'variantName': variantName,
      'brandName': brandName,
    };
  }

  @override
  List<Object?> get props => [productId, variantId, qty, unitPrice];
}

class DeliveryAddress extends Equatable {
  final String fullAddress;
  final String district;
  final String city;
  final double? lat;
  final double? lng;
  final String? notes;

  const DeliveryAddress({
    required this.fullAddress,
    required this.district,
    required this.city,
    this.lat,
    this.lng,
    this.notes,
  });

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      fullAddress: map['fullAddress'] ?? '',
      district: map['district'] ?? '',
      city: map['city'] ?? 'Balıkesir',
      lat: map['lat']?.toDouble(),
      lng: map['lng']?.toDouble(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullAddress': fullAddress,
      'district': district,
      'city': city,
      'lat': lat,
      'lng': lng,
      'notes': notes,
    };
  }

  @override
  List<Object?> get props => [fullAddress, district];
}

class StatusHistory extends Equatable {
  final OrderStatus status;
  final DateTime timestamp;
  final String by;

  const StatusHistory({
    required this.status,
    required this.timestamp,
    required this.by,
  });

  factory StatusHistory.fromMap(Map<String, dynamic> map) {
    return StatusHistory(
      status: OrderStatus.fromString(map['status'] ?? 'pending'),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      by: map['by'] ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'timestamp': Timestamp.fromDate(timestamp),
      'by': by,
    };
  }

  @override
  List<Object?> get props => [status, timestamp];
}

class OrderModel extends Equatable {
  final String id;
  final String orderNo;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final OrderSource source;
  final String createdBy;
  final OrderStatus status;
  final List<StatusHistory> statusHistory;
  final List<OrderItem> items;
  final DeliveryAddress deliveryAddress;
  final PaymentMethod paymentMethod;
  final String paymentStatus;
  final String? assignedTo;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final double subtotal;
  final double discount;
  final double total;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.id,
    required this.orderNo,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.source,
    required this.createdBy,
    required this.status,
    required this.statusHistory,
    required this.items,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.assignedTo,
    this.estimatedDelivery,
    this.deliveredAt,
    required this.subtotal,
    this.discount = 0,
    required this.total,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalItems => items.fold(0, (acc, item) => acc + item.qty);

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      orderNo: data['orderNo'] ?? '',
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      source: OrderSource.values.firstWhere(
        (e) => e.value == (data['source'] ?? 'customer_app'),
        orElse: () => OrderSource.customerApp,
      ),
      createdBy: data['createdBy'] ?? '',
      status: OrderStatus.fromString(data['status'] ?? 'pending'),
      statusHistory: (data['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => StatusHistory.fromMap(e as Map<String, dynamic>))
          .toList(),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      deliveryAddress: DeliveryAddress.fromMap(
        data['deliveryAddress'] as Map<String, dynamic>? ?? {},
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.value == (data['paymentMethod'] ?? 'cash'),
        orElse: () => PaymentMethod.cash,
      ),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      assignedTo: data['assignedTo'],
      estimatedDelivery: (data['estimatedDelivery'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      notes: data['notes'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderNo': orderNo,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'source': source.value,
      'createdBy': createdBy,
      'status': status.value,
      'statusHistory': statusHistory.map((e) => e.toMap()).toList(),
      'items': items.map((e) => e.toMap()).toList(),
      'deliveryAddress': deliveryAddress.toMap(),
      'paymentMethod': paymentMethod.value,
      'paymentStatus': paymentStatus,
      'assignedTo': assignedTo,
      'estimatedDelivery': estimatedDelivery != null
          ? Timestamp.fromDate(estimatedDelivery!)
          : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [id, orderNo, status, total];
}
