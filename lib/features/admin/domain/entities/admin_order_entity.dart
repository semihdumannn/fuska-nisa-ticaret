import 'package:equatable/equatable.dart';
import '../../../orders/domain/entities/order_entity.dart';

class AdminOrderEntity extends Equatable {
  final int id;
  final String orderNumber;
  final OrderStatus status;
  final String customerName;
  final String customerPhone;
  final double total;
  final int itemCount;
  final DateTime createdAt;
  final String? assignedTo;
  final String? deliveryPersonName;

  const AdminOrderEntity({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.total,
    required this.itemCount,
    required this.createdAt,
    this.assignedTo,
    this.deliveryPersonName,
  });

  @override
  List<Object?> get props => [id, status, total];
}
