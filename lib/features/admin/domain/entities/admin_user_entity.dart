import 'package:equatable/equatable.dart';

class AdminUserEntity extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role; // 'customer', 'field_agent', 'delivery', 'admin'
  final bool isActive;
  final DateTime? createdAt;
  final double? balance;
  final int orderCount;

  const AdminUserEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.balance,
    this.orderCount = 0,
  });

  bool get isAdmin => role == 'admin';
  bool get isFieldAgent => role == 'field_agent';
  bool get isDelivery => role == 'delivery';
  bool get isCustomer => role == 'customer';

  @override
  List<Object?> get props => [id, name, role, isActive];
}
