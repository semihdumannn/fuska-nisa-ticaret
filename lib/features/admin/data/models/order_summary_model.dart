import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';

class OrderSummaryModel {
  final String id;
  final String orderNo;
  final DateTime date;
  final double amount;
  final OrderStatus status;
  final int itemCount;

  const OrderSummaryModel({
    required this.id,
    required this.orderNo,
    required this.date,
    required this.amount,
    required this.status,
    required this.itemCount,
  });

  factory OrderSummaryModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final items = d['items'] as List<dynamic>? ?? [];
    return OrderSummaryModel(
      id: doc.id,
      orderNo: d['orderNo'] as String? ?? '',
      date: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (d['total'] as num? ?? 0).toDouble(),
      status: OrderStatus.fromString(d['status'] as String? ?? 'pending'),
      itemCount: items.length,
    );
  }

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) {
    return OrderSummaryModel(
      id: json['id'] as String? ?? '',
      orderNo: json['orderNo'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      amount: (json['amount'] as num? ?? 0).toDouble(),
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      itemCount: (json['itemCount'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNo': orderNo,
      'date': date.toIso8601String(),
      'amount': amount,
      'status': status.value,
      'itemCount': itemCount,
    };
  }

  /// Kullaniciya ait mock siparis listesi
  static List<OrderSummaryModel> mockForUser(String userId) {
    final now = DateTime.now();

    final mockData = <String, List<OrderSummaryModel>>{
      'u001': [
        OrderSummaryModel(
          id: 'ord-u001-001',
          orderNo: 'NT-2024-0047',
          date: now.subtract(const Duration(days: 1)),
          amount: 450.0,
          status: OrderStatus.delivered,
          itemCount: 3,
        ),
        OrderSummaryModel(
          id: 'ord-u001-002',
          orderNo: 'NT-2024-0039',
          date: now.subtract(const Duration(days: 7)),
          amount: 280.0,
          status: OrderStatus.delivered,
          itemCount: 2,
        ),
        OrderSummaryModel(
          id: 'ord-u001-003',
          orderNo: 'NT-2024-0031',
          date: now.subtract(const Duration(days: 14)),
          amount: 620.0,
          status: OrderStatus.delivered,
          itemCount: 5,
        ),
        OrderSummaryModel(
          id: 'ord-u001-004',
          orderNo: 'NT-2024-0022',
          date: now.subtract(const Duration(days: 21)),
          amount: 190.0,
          status: OrderStatus.delivered,
          itemCount: 1,
        ),
        OrderSummaryModel(
          id: 'ord-u001-005',
          orderNo: 'NT-2024-0015',
          date: now.subtract(const Duration(days: 30)),
          amount: 340.0,
          status: OrderStatus.cancelled,
          itemCount: 2,
        ),
      ],
      'u002': [
        OrderSummaryModel(
          id: 'ord-u002-001',
          orderNo: 'NT-2024-0043',
          date: now.subtract(const Duration(days: 3)),
          amount: 380.0,
          status: OrderStatus.delivered,
          itemCount: 3,
        ),
        OrderSummaryModel(
          id: 'ord-u002-002',
          orderNo: 'NT-2024-0028',
          date: now.subtract(const Duration(days: 18)),
          amount: 520.0,
          status: OrderStatus.delivered,
          itemCount: 4,
        ),
        OrderSummaryModel(
          id: 'ord-u002-003',
          orderNo: 'NT-2024-0050',
          date: now.subtract(const Duration(hours: 6)),
          amount: 230.0,
          status: OrderStatus.preparing,
          itemCount: 2,
        ),
      ],
      'u006': [
        OrderSummaryModel(
          id: 'ord-u006-001',
          orderNo: 'NT-2024-0041',
          date: now.subtract(const Duration(days: 5)),
          amount: 230.0,
          status: OrderStatus.delivered,
          itemCount: 2,
        ),
        OrderSummaryModel(
          id: 'ord-u006-002',
          orderNo: 'NT-2024-0035',
          date: now.subtract(const Duration(days: 12)),
          amount: 280.0,
          status: OrderStatus.delivered,
          itemCount: 2,
        ),
        OrderSummaryModel(
          id: 'ord-u006-003',
          orderNo: 'NT-2024-0051',
          date: now.subtract(const Duration(hours: 2)),
          amount: 170.0,
          status: OrderStatus.onTheWay,
          itemCount: 1,
        ),
      ],
      'u007': [
        OrderSummaryModel(
          id: 'ord-u007-001',
          orderNo: 'NT-2024-0020',
          date: now.subtract(const Duration(days: 35)),
          amount: 260.0,
          status: OrderStatus.delivered,
          itemCount: 2,
        ),
        OrderSummaryModel(
          id: 'ord-u007-002',
          orderNo: 'NT-2024-0010',
          date: now.subtract(const Duration(days: 60)),
          amount: 190.0,
          status: OrderStatus.cancelled,
          itemCount: 1,
        ),
      ],
      'u008': [
        OrderSummaryModel(
          id: 'ord-u008-001',
          orderNo: 'NT-2024-0045',
          date: now.subtract(const Duration(days: 2)),
          amount: 340.0,
          status: OrderStatus.delivered,
          itemCount: 3,
        ),
        OrderSummaryModel(
          id: 'ord-u008-002',
          orderNo: 'NT-2024-0038',
          date: now.subtract(const Duration(days: 9)),
          amount: 410.0,
          status: OrderStatus.delivered,
          itemCount: 3,
        ),
        OrderSummaryModel(
          id: 'ord-u008-003',
          orderNo: 'NT-2024-0030',
          date: now.subtract(const Duration(days: 16)),
          amount: 230.0,
          status: OrderStatus.delivered,
          itemCount: 2,
        ),
        OrderSummaryModel(
          id: 'ord-u008-004',
          orderNo: 'NT-2024-0052',
          date: now.subtract(const Duration(hours: 8)),
          amount: 140.0,
          status: OrderStatus.confirmed,
          itemCount: 1,
        ),
      ],
      'u009': [
        OrderSummaryModel(
          id: 'ord-u009-001',
          orderNo: 'NT-2024-0044',
          date: now.subtract(const Duration(days: 3)),
          amount: 560.0,
          status: OrderStatus.delivered,
          itemCount: 4,
        ),
        OrderSummaryModel(
          id: 'ord-u009-002',
          orderNo: 'NT-2024-0036',
          date: now.subtract(const Duration(days: 10)),
          amount: 780.0,
          status: OrderStatus.delivered,
          itemCount: 6,
        ),
        OrderSummaryModel(
          id: 'ord-u009-003',
          orderNo: 'NT-2024-0027',
          date: now.subtract(const Duration(days: 20)),
          amount: 320.0,
          status: OrderStatus.delivered,
          itemCount: 2,
        ),
      ],
      'u010': [
        OrderSummaryModel(
          id: 'ord-u010-001',
          orderNo: 'NT-2024-0048',
          date: now.subtract(const Duration(days: 1)),
          amount: 230.0,
          status: OrderStatus.pending,
          itemCount: 2,
        ),
      ],
    };

    return mockData[userId] ?? [];
  }
}
