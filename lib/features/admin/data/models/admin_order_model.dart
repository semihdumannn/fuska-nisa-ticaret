import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
        AdminOrderStatus.confirmed => 'Onaylandi',
        AdminOrderStatus.preparing => 'Hazirlaniyor',
        AdminOrderStatus.onTheWay => 'Yolda',
        AdminOrderStatus.delivered => 'Teslim Edildi',
        AdminOrderStatus.cancelled => 'Iptal',
        AdminOrderStatus.refunded => 'Iade',
      };

  Color get color => switch (this) {
        AdminOrderStatus.pending => const Color(0xFFFF9800),
        AdminOrderStatus.confirmed => const Color(0xFF00A6AB),
        AdminOrderStatus.preparing => const Color(0xFFE73A99),
        AdminOrderStatus.onTheWay => const Color(0xFF13275A),
        AdminOrderStatus.delivered => const Color(0xFF43A047),
        AdminOrderStatus.cancelled => const Color(0xFFF44336),
        AdminOrderStatus.refunded => const Color(0xFF9C27B0),
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

  // ── Firestore → AdminOrderModel ──────────────────────────────────────────
  factory AdminOrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    AdminOrderStatus mapStatus(String s) => switch (s) {
          'confirmed' => AdminOrderStatus.confirmed,
          'preparing' => AdminOrderStatus.preparing,
          'on_the_way' => AdminOrderStatus.onTheWay,
          'delivered' => AdminOrderStatus.delivered,
          'cancelled' => AdminOrderStatus.cancelled,
          _ => AdminOrderStatus.pending,
        };

    AdminPaymentMethod mapPayment(String s) => switch (s) {
          'card_on_delivery' => AdminPaymentMethod.creditCard,
          'bank_transfer' => AdminPaymentMethod.bankTransfer,
          _ => AdminPaymentMethod.cash,
        };

    DateTime? parseTs(String key) =>
        (d[key] as Timestamp?)?.toDate();

    final addr = d['deliveryAddress'] as Map<String, dynamic>? ?? {};
    final addrStr = [
      addr['fullAddress'] ?? '',
      addr['district'] ?? '',
      addr['city'] ?? '',
    ].where((s) => s.isNotEmpty).join(', ');

    final rawItems = d['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      return OrderItemModel(
        productId: m['productId'] as String? ?? '',
        productName: m['productName'] as String? ?? '',
        unitPrice: (m['unitPrice'] as num? ?? 0).toDouble(),
        quantity: (m['qty'] as num? ?? 0).toInt(),
      );
    }).toList();

    return AdminOrderModel(
      id: doc.id,
      orderNumber: d['orderNo'] as String? ?? '',
      customerId: d['customerId'] as String? ?? '',
      customerName: d['customerName'] as String? ?? '',
      customerPhone: d['customerPhone'] as String? ?? '',
      deliveryAddress: addrStr,
      items: items,
      subtotal: (d['subtotal'] as num? ?? 0).toDouble(),
      deliveryFee: 0,
      discount: (d['discount'] as num? ?? 0).toDouble(),
      total: (d['total'] as num? ?? 0).toDouble(),
      status: mapStatus(d['status'] as String? ?? 'pending'),
      paymentMethod: mapPayment(d['paymentMethod'] as String? ?? 'cash'),
      createdAt: parseTs('createdAt') ?? DateTime.now(),
      confirmedAt: parseTs('confirmedAt'),
      preparingAt: parseTs('preparingAt'),
      onTheWayAt: parseTs('onTheWayAt'),
      deliveredAt: parseTs('deliveredAt'),
      assignedDeliveryId: d['assignedTo'] as String?,
      cancellationReason: d['cancellationReason'] as String?,
    );
  }

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
}

// ---------------------------------------------------------------------------
// Mock — artık kullanılmıyor, Firestore stream bağlandı (admin_orders_provider)
// ---------------------------------------------------------------------------
List<AdminOrderModel> generateMockOrders() {
  final now = DateTime.now();

  AdminOrderModel make({
    required String id,
    required String orderNo,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String address,
    required List<OrderItemModel> items,
    required double deliveryFee,
    required double discount,
    required AdminOrderStatus status,
    required AdminPaymentMethod payment,
    required int hoursAgo,
    String? agentId,
    String? agentName,
    String? deliveryId,
    String? deliveryName,
    List<InternalNote> notes = const [],
    String? cancelReason,
  }) {
    final created = now.subtract(Duration(hours: hoursAgo));
    final sub = items.fold(0.0, (sum, i) => sum + i.total);
    final total = sub + deliveryFee - discount;
    return AdminOrderModel(
      id: id,
      orderNumber: orderNo,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: address,
      items: items,
      subtotal: sub,
      deliveryFee: deliveryFee,
      discount: discount,
      total: total,
      status: status,
      paymentMethod: payment,
      createdAt: created,
      confirmedAt: status.index >= AdminOrderStatus.confirmed.index
          ? created.add(const Duration(minutes: 10))
          : null,
      preparingAt: status.index >= AdminOrderStatus.preparing.index
          ? created.add(const Duration(minutes: 20))
          : null,
      onTheWayAt: status.index >= AdminOrderStatus.onTheWay.index
          ? created.add(const Duration(minutes: 45))
          : null,
      deliveredAt: status == AdminOrderStatus.delivered
          ? created.add(const Duration(hours: 2))
          : null,
      assignedAgentId: agentId,
      assignedAgentName: agentName,
      assignedDeliveryId: deliveryId,
      assignedDeliveryName: deliveryName,
      notes: notes,
      cancellationReason: cancelReason,
    );
  }

  return [
    make(
      id: 'ord001',
      orderNo: 'NT-2024-0048',
      customerId: 'cust01',
      customerName: 'Ahmet Yilmaz',
      customerPhone: '05321234567',
      address: 'Altieylul Mah. Ataturk Cad. No:12 D:3, Balikesir',
      items: const [
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 3),
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 2),
      ],
      deliveryFee: 15.0,
      discount: 0.0,
      status: AdminOrderStatus.pending,
      payment: AdminPaymentMethod.cash,
      hoursAgo: 1,
    ),
    make(
      id: 'ord002',
      orderNo: 'NT-2024-0047',
      customerId: 'cust02',
      customerName: 'Fatma Kaya',
      customerPhone: '05451234567',
      address: 'Karesi Mah. Istiklal Cad. No:45, Balikesir',
      items: const [
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 24),
        OrderItemModel(productId: 'p4', productName: 'Portakal Suyu 1L', unitPrice: 35.0, quantity: 2),
      ],
      deliveryFee: 10.0,
      discount: 15.0,
      status: AdminOrderStatus.confirmed,
      payment: AdminPaymentMethod.creditCard,
      hoursAgo: 2,
      agentId: 'agent1',
      agentName: 'Mehmet Kaya',
    ),
    make(
      id: 'ord003',
      orderNo: 'NT-2024-0046',
      customerId: 'cust03',
      customerName: 'Mehmet Demir',
      customerPhone: '05551234567',
      address: 'Yeni Mah. Cumhuriyet Cad. No:7, Balikesir',
      items: const [
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 5),
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 4),
        OrderItemModel(productId: 'p4', productName: 'Portakal Suyu 1L', unitPrice: 35.0, quantity: 3),
      ],
      deliveryFee: 20.0,
      discount: 30.0,
      status: AdminOrderStatus.preparing,
      payment: AdminPaymentMethod.bankTransfer,
      hoursAgo: 3,
      agentId: 'agent2',
      agentName: 'Hasan Celik',
      notes: [
        InternalNote(
          id: 'n1',
          authorName: 'Admin',
          content: 'Musteri daha once sikayet etmisti, dikkatli olunmali.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
        ),
      ],
    ),
    make(
      id: 'ord004',
      orderNo: 'NT-2024-0045',
      customerId: 'cust04',
      customerName: 'Zeynep Arslan',
      customerPhone: '05321111111',
      address: 'Bahcelievler Mah. Gazi Cad. No:33, Balikesir',
      items: const [
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 48),
      ],
      deliveryFee: 10.0,
      discount: 0.0,
      status: AdminOrderStatus.onTheWay,
      payment: AdminPaymentMethod.cash,
      hoursAgo: 4,
      agentId: 'agent1',
      agentName: 'Mehmet Kaya',
      deliveryId: 'del1',
      deliveryName: 'Zeynep Arslan',
    ),
    make(
      id: 'ord005',
      orderNo: 'NT-2024-0044',
      customerId: 'cust05',
      customerName: 'Ali Celik',
      customerPhone: '05422222222',
      address: 'Merkez Mah. Hastane Cad. No:55, Balikesir',
      items: const [
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 2),
        OrderItemModel(productId: 'p4', productName: 'Portakal Suyu 1L', unitPrice: 35.0, quantity: 6),
      ],
      deliveryFee: 15.0,
      discount: 0.0,
      status: AdminOrderStatus.delivered,
      payment: AdminPaymentMethod.creditCard,
      hoursAgo: 5,
      agentId: 'agent2',
      agentName: 'Hasan Celik',
      deliveryId: 'del2',
      deliveryName: 'Kadir Yildiz',
    ),
    make(
      id: 'ord006',
      orderNo: 'NT-2024-0043',
      customerId: 'cust06',
      customerName: 'Elif Sahin',
      customerPhone: '05333333333',
      address: 'Gonen Mah. Sehit Cad. No:18, Balikesir',
      items: const [
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 8),
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 12),
      ],
      deliveryFee: 10.0,
      discount: 0.0,
      status: AdminOrderStatus.cancelled,
      payment: AdminPaymentMethod.cash,
      hoursAgo: 6,
      cancelReason: 'Musteri vazgecti',
    ),
    make(
      id: 'ord007',
      orderNo: 'NT-2024-0042',
      customerId: 'cust07',
      customerName: 'Hasan Ozturk',
      customerPhone: '05444444444',
      address: 'Kayalioğlu Mah. Orman Cad. No:3, Balikesir',
      items: const [
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 10),
      ],
      deliveryFee: 25.0,
      discount: 50.0,
      status: AdminOrderStatus.delivered,
      payment: AdminPaymentMethod.bankTransfer,
      hoursAgo: 8,
      agentId: 'agent1',
      agentName: 'Mehmet Kaya',
      deliveryId: 'del1',
      deliveryName: 'Zeynep Arslan',
    ),
    make(
      id: 'ord008',
      orderNo: 'NT-2024-0041',
      customerId: 'cust08',
      customerName: 'Ayse Yildiz',
      customerPhone: '05555555555',
      address: 'Eski Kuyumcular Mah. No:9, Balikesir',
      items: const [
        OrderItemModel(productId: 'p4', productName: 'Portakal Suyu 1L', unitPrice: 35.0, quantity: 4),
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 2),
      ],
      deliveryFee: 10.0,
      discount: 0.0,
      status: AdminOrderStatus.refunded,
      payment: AdminPaymentMethod.creditCard,
      hoursAgo: 10,
      notes: [
        InternalNote(
          id: 'n2',
          authorName: 'Admin',
          content: 'Urun hasarli geldi, iade onaylandi.',
          createdAt: DateTime.now().subtract(const Duration(hours: 9)),
        ),
      ],
    ),
    make(
      id: 'ord009',
      orderNo: 'NT-2024-0040',
      customerId: 'cust09',
      customerName: 'Ibrahim Koc',
      customerPhone: '05316666666',
      address: 'Atatürk Mah. Erguvan Sok. No:21, Balikesir',
      items: const [
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 60),
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 2),
      ],
      deliveryFee: 15.0,
      discount: 20.0,
      status: AdminOrderStatus.pending,
      payment: AdminPaymentMethod.cash,
      hoursAgo: 12,
    ),
    make(
      id: 'ord010',
      orderNo: 'NT-2024-0039',
      customerId: 'cust10',
      customerName: 'Serkan Bulut',
      customerPhone: '05427777777',
      address: 'Adnan Menderes Mah. No:67, Balikesir',
      items: const [
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 6),
        OrderItemModel(productId: 'p4', productName: 'Portakal Suyu 1L', unitPrice: 35.0, quantity: 3),
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 24),
      ],
      deliveryFee: 10.0,
      discount: 0.0,
      status: AdminOrderStatus.confirmed,
      payment: AdminPaymentMethod.creditCard,
      hoursAgo: 14,
      agentId: 'agent2',
      agentName: 'Hasan Celik',
    ),
    make(
      id: 'ord011',
      orderNo: 'NT-2024-0038',
      customerId: 'cust11',
      customerName: 'Nalan Erdogan',
      customerPhone: '05338888888',
      address: 'Lale Mah. Karanfil Sok. No:14, Balikesir',
      items: const [
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 4),
      ],
      deliveryFee: 15.0,
      discount: 10.0,
      status: AdminOrderStatus.preparing,
      payment: AdminPaymentMethod.bankTransfer,
      hoursAgo: 16,
      agentId: 'agent1',
      agentName: 'Mehmet Kaya',
    ),
    make(
      id: 'ord012',
      orderNo: 'NT-2024-0037',
      customerId: 'cust12',
      customerName: 'Mustafa Aydin',
      customerPhone: '05459999999',
      address: 'Kircagiz Mah. Dag Yolu No:5, Balikesir',
      items: const [
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 36),
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 4),
      ],
      deliveryFee: 10.0,
      discount: 0.0,
      status: AdminOrderStatus.onTheWay,
      payment: AdminPaymentMethod.cash,
      hoursAgo: 18,
      agentId: 'agent2',
      agentName: 'Hasan Celik',
      deliveryId: 'del2',
      deliveryName: 'Kadir Yildiz',
    ),
    make(
      id: 'ord013',
      orderNo: 'NT-2024-0036',
      customerId: 'cust13',
      customerName: 'Sevgi Tekin',
      customerPhone: '05320000001',
      address: 'Bahce Mah. Gul Sok. No:22, Balikesir',
      items: const [
        OrderItemModel(productId: 'p4', productName: 'Portakal Suyu 1L', unitPrice: 35.0, quantity: 8),
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 1),
      ],
      deliveryFee: 10.0,
      discount: 0.0,
      status: AdminOrderStatus.delivered,
      payment: AdminPaymentMethod.creditCard,
      hoursAgo: 22,
      agentId: 'agent1',
      agentName: 'Mehmet Kaya',
      deliveryId: 'del1',
      deliveryName: 'Zeynep Arslan',
    ),
    make(
      id: 'ord014',
      orderNo: 'NT-2024-0035',
      customerId: 'cust14',
      customerName: 'Burak Polat',
      customerPhone: '05450000002',
      address: 'Yeni Mahalle Uyanis Cad. No:31, Balikesir',
      items: const [
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 12),
      ],
      deliveryFee: 15.0,
      discount: 30.0,
      status: AdminOrderStatus.cancelled,
      payment: AdminPaymentMethod.cash,
      hoursAgo: 26,
      cancelReason: 'Stok yetersizligi nedeniyle iptal edildi',
    ),
    make(
      id: 'ord015',
      orderNo: 'NT-2024-0034',
      customerId: 'cust15',
      customerName: 'Aysegul Gunes',
      customerPhone: '05560000003',
      address: 'Uzunalan Mah. Meydan Sok. No:8, Balikesir',
      items: const [
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 6),
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 24),
        OrderItemModel(productId: 'p4', productName: 'Portakal Suyu 1L', unitPrice: 35.0, quantity: 4),
      ],
      deliveryFee: 20.0,
      discount: 40.0,
      status: AdminOrderStatus.delivered,
      payment: AdminPaymentMethod.bankTransfer,
      hoursAgo: 30,
      agentId: 'agent2',
      agentName: 'Hasan Celik',
      deliveryId: 'del2',
      deliveryName: 'Kadir Yildiz',
      notes: [
        InternalNote(
          id: 'n3',
          authorName: 'Hasan Celik',
          content: 'Musteri kapi yok notunu birakti, kapida teslim edildi.',
          createdAt: DateTime.now().subtract(const Duration(hours: 28)),
        ),
      ],
    ),
    make(
      id: 'ord016',
      orderNo: 'NT-2024-0033',
      customerId: 'cust16',
      customerName: 'Tuncay Dogan',
      customerPhone: '05320000004',
      address: 'Esentepe Mah. Konut Cad. No:17, Balikesir',
      items: const [
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 48),
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 6),
      ],
      deliveryFee: 15.0,
      discount: 0.0,
      status: AdminOrderStatus.pending,
      payment: AdminPaymentMethod.cash,
      hoursAgo: 35,
    ),
    make(
      id: 'ord017',
      orderNo: 'NT-2024-0032',
      customerId: 'cust17',
      customerName: 'Gonul Akyuz',
      customerPhone: '05450000005',
      address: 'Altinoluk Mah. Sahil Cad. No:4, Balikesir',
      items: const [
        OrderItemModel(productId: 'p4', productName: 'Portakal Suyu 1L', unitPrice: 35.0, quantity: 10),
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 3),
      ],
      deliveryFee: 20.0,
      discount: 25.0,
      status: AdminOrderStatus.confirmed,
      payment: AdminPaymentMethod.creditCard,
      hoursAgo: 40,
      agentId: 'agent1',
      agentName: 'Mehmet Kaya',
    ),
    make(
      id: 'ord018',
      orderNo: 'NT-2024-0031',
      customerId: 'cust18',
      customerName: 'Emre Cakir',
      customerPhone: '05560000006',
      address: 'Sumer Mah. Yildirim Sok. No:29, Balikesir',
      items: const [
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 10),
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 60),
      ],
      deliveryFee: 15.0,
      discount: 0.0,
      status: AdminOrderStatus.onTheWay,
      payment: AdminPaymentMethod.bankTransfer,
      hoursAgo: 45,
      agentId: 'agent2',
      agentName: 'Hasan Celik',
      deliveryId: 'del1',
      deliveryName: 'Zeynep Arslan',
    ),
    make(
      id: 'ord019',
      orderNo: 'NT-2024-0030',
      customerId: 'cust19',
      customerName: 'Perihan Unal',
      customerPhone: '05320000007',
      address: 'Sakarya Mah. Ihlamur Cad. No:11, Balikesir',
      items: const [
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 8),
        OrderItemModel(productId: 'p4', productName: 'Portakal Suyu 1L', unitPrice: 35.0, quantity: 5),
      ],
      deliveryFee: 20.0,
      discount: 60.0,
      status: AdminOrderStatus.refunded,
      payment: AdminPaymentMethod.creditCard,
      hoursAgo: 50,
      notes: [
        InternalNote(
          id: 'n4',
          authorName: 'Admin',
          content: 'Damacana bozuk cikti, tam iade yapildi.',
          createdAt: DateTime.now().subtract(const Duration(hours: 48)),
        ),
      ],
    ),
    make(
      id: 'ord020',
      orderNo: 'NT-2024-0029',
      customerId: 'cust20',
      customerName: 'Kamil Sezer',
      customerPhone: '05450000008',
      address: 'Demirci Mah. Fabrika Yolu No:2, Balikesir',
      items: const [
        OrderItemModel(productId: 'p2', productName: 'Pet Su 0.5L', unitPrice: 3.0, quantity: 120),
        OrderItemModel(productId: 'p3', productName: 'Cola 1L', unitPrice: 25.0, quantity: 24),
        OrderItemModel(productId: 'p1', productName: 'Damacana Su 19L', unitPrice: 45.0, quantity: 5),
      ],
      deliveryFee: 30.0,
      discount: 100.0,
      status: AdminOrderStatus.delivered,
      payment: AdminPaymentMethod.bankTransfer,
      hoursAgo: 60,
      agentId: 'agent1',
      agentName: 'Mehmet Kaya',
      deliveryId: 'del2',
      deliveryName: 'Kadir Yildiz',
      notes: [
        InternalNote(
          id: 'n5',
          authorName: 'Mehmet Kaya',
          content: 'Buyuk hacimli siparis, ekstra arac kullanildi.',
          createdAt: DateTime.now().subtract(const Duration(hours: 58)),
        ),
        InternalNote(
          id: 'n6',
          authorName: 'Admin',
          content: 'Kurumsal musteri, indirim uygulanabilir.',
          createdAt: DateTime.now().subtract(const Duration(hours: 59)),
        ),
      ],
    ),
  ];
}
