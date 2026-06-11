import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Admin tarafinda genisletilmis siparis durumu
// (app_constants.dart'taki OrderStatus'tan bagimsiz, admin icin ekstra durumlar)
// ---------------------------------------------------------------------------
enum AdminOrderStatus {
  pending,
  confirmed,
  preparing,
  onTheWay,
  delivered,
  cancelled,
  refunded;

  String get displayName => switch (this) {
        AdminOrderStatus.pending => 'Bekliyor',
        AdminOrderStatus.confirmed => 'Onaylandı',
        AdminOrderStatus.preparing => 'Hazırlanıyor',
        AdminOrderStatus.onTheWay => 'Yolda',
        AdminOrderStatus.delivered => 'Teslim Edildi',
        AdminOrderStatus.cancelled => 'İptal',
        AdminOrderStatus.refunded => 'İade',
      };

  Color get color => switch (this) {
        AdminOrderStatus.pending => AppColors.statusPending,
        AdminOrderStatus.confirmed => AppColors.statusConfirmed,
        AdminOrderStatus.preparing => AppColors.statusPreparing,
        AdminOrderStatus.onTheWay => AppColors.statusOnTheWay,
        AdminOrderStatus.delivered => AppColors.statusDelivered,
        AdminOrderStatus.cancelled => AppColors.statusCancelled,
        AdminOrderStatus.refunded => AppColors.statusRefunded,
      };

  IconData get icon => switch (this) {
        AdminOrderStatus.pending => Icons.schedule_outlined,
        AdminOrderStatus.confirmed => Icons.check_circle_outline,
        AdminOrderStatus.preparing => Icons.restaurant_outlined,
        AdminOrderStatus.onTheWay => Icons.local_shipping_outlined,
        AdminOrderStatus.delivered => Icons.done_all,
        AdminOrderStatus.cancelled => Icons.cancel_outlined,
        AdminOrderStatus.refunded => Icons.replay_outlined,
      };

  /// Backend state machine kuralları: hangi statüye geçilebilir.
  List<AdminOrderStatus> get allowedTransitions => switch (this) {
        AdminOrderStatus.pending    => [confirmed, cancelled],
        AdminOrderStatus.confirmed  => [preparing, cancelled],
        AdminOrderStatus.preparing  => [onTheWay, cancelled],
        AdminOrderStatus.onTheWay   => [delivered, cancelled],
        AdminOrderStatus.delivered  => [refunded],
        AdminOrderStatus.cancelled  => [],
        AdminOrderStatus.refunded   => [],
      };

  bool get isFinal =>
      this == AdminOrderStatus.delivered ||
      this == AdminOrderStatus.cancelled ||
      this == AdminOrderStatus.refunded;
}

// ---------------------------------------------------------------------------
// Admin tarafinda genisletilmis odeme yontemi
// ---------------------------------------------------------------------------
enum AdminPaymentMethod {
  cash,
  creditCard,
  bankTransfer;

  String get displayName => switch (this) {
        AdminPaymentMethod.cash => 'Nakit',
        AdminPaymentMethod.creditCard => 'Kredi Karti',
        AdminPaymentMethod.bankTransfer => 'Havale/EFT',
      };

  IconData get icon => switch (this) {
        AdminPaymentMethod.cash => Icons.money_outlined,
        AdminPaymentMethod.creditCard => Icons.credit_card_outlined,
        AdminPaymentMethod.bankTransfer => Icons.account_balance_outlined,
      };
}

// ---------------------------------------------------------------------------
// Siparis kalemi
// ---------------------------------------------------------------------------
class OrderItemModel {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;
}

// ---------------------------------------------------------------------------
// Is notu
// ---------------------------------------------------------------------------
class InternalNote {
  final String id;
  final String authorName;
  final String content;
  final DateTime createdAt;

  const InternalNote({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });
}

// ---------------------------------------------------------------------------
// Ana admin siparis modeli
// ---------------------------------------------------------------------------
class AdminOrderModel {
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final AdminOrderStatus status;
  final AdminPaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? preparingAt;
  final DateTime? onTheWayAt;
  final DateTime? deliveredAt;
  final String? assignedAgentId;
  final String? assignedAgentName;
  final String? assignedDeliveryId;
  final String? assignedDeliveryName;
  final List<InternalNote> notes;
  final String? cancellationReason;

  const AdminOrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.confirmedAt,
    this.preparingAt,
    this.onTheWayAt,
    this.deliveredAt,
    this.assignedAgentId,
    this.assignedAgentName,
    this.assignedDeliveryId,
    this.assignedDeliveryName,
    this.notes = const [],
    this.cancellationReason,
  });

  AdminOrderModel copyWith({
    String? id,
    String? orderNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    List<OrderItemModel>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    AdminOrderStatus? status,
    AdminPaymentMethod? paymentMethod,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? preparingAt,
    DateTime? onTheWayAt,
    DateTime? deliveredAt,
    String? assignedAgentId,
    String? assignedAgentName,
    String? assignedDeliveryId,
    String? assignedDeliveryName,
    List<InternalNote>? notes,
    String? cancellationReason,
  }) {
    return AdminOrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      preparingAt: preparingAt ?? this.preparingAt,
      onTheWayAt: onTheWayAt ?? this.onTheWayAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      assignedAgentName: assignedAgentName ?? this.assignedAgentName,
      assignedDeliveryId: assignedDeliveryId ?? this.assignedDeliveryId,
      assignedDeliveryName: assignedDeliveryName ?? this.assignedDeliveryName,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  // ── API JSON → AdminOrderModel ────────────────────────────────────────────
  factory AdminOrderModel.fromApiJson(Map<String, dynamic> json) {
    AdminOrderStatus mapStatus(String s) => switch (s) {
          'confirmed'  => AdminOrderStatus.confirmed,
          'preparing'  => AdminOrderStatus.preparing,
          'on_the_way' => AdminOrderStatus.onTheWay,
          'delivered'  => AdminOrderStatus.delivered,
          'cancelled'  => AdminOrderStatus.cancelled,
          _            => AdminOrderStatus.pending,
        };

    AdminPaymentMethod mapPayment(String? s) => switch (s) {
          'card_on_delivery' => AdminPaymentMethod.creditCard,
          'bank_transfer'    => AdminPaymentMethod.bankTransfer,
          _                  => AdminPaymentMethod.cash,
        };

    final customer = json['customer'] as Map<String, dynamic>?;
    final address  = json['address']  as Map<String, dynamic>?;

    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      return OrderItemModel(
        productId:   (m['product_id'] ?? '').toString(),
        productName: m['product_name'] as String? ?? '',
        unitPrice:   (m['unit_price'] as num? ?? 0).toDouble(),
        quantity:    (m['quantity'] as num? ?? 0).toInt(),
      );
    }).toList();

    final addrStr = address != null
        ? [address['full_address'], address['city']]
            .where((s) => s != null && (s as String).isNotEmpty)
            .join(', ')
        : '';

    return AdminOrderModel(
      id:              json['id'].toString(),
      orderNumber:     json['order_number'] as String? ?? '',
      customerId:      customer?['id']?.toString() ?? '',
      customerName:    customer?['name']  as String? ?? '',
      customerPhone:   customer?['phone'] as String? ?? '',
      deliveryAddress: addrStr,
      items:           items,
      subtotal:        (json['subtotal']        as num? ?? 0).toDouble(),
      deliveryFee:     (json['shipping_amount'] as num? ?? 0).toDouble(),
      discount:        (json['discount_amount'] as num? ?? 0).toDouble(),
      total:           (json['total']           as num? ?? 0).toDouble(),
      status:          mapStatus(json['status'] as String? ?? 'pending'),
      paymentMethod:   mapPayment(json['payment_method'] as String?),
      createdAt:       DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      deliveredAt:     json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'] as String)
          : null,
    );
  }
}

