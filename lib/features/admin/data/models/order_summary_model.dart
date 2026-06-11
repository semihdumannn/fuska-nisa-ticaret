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
}
