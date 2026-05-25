import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool? isActive;
  final UserProfileEntity? profile;

  const UserEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.isActive,
    this.profile,
  });

  bool get isAdmin => role == 'admin';
  bool get isFieldAgent => role == 'field_agent';
  bool get isDelivery => role == 'delivery';
  bool get isCustomer => role == 'customer';

  @override
  List<Object?> get props => [id, name, phone, email, role, isActive, profile];
}

class UserProfileEntity extends Equatable {
  final String? avatarUrl;
  final String? companyName;
  final double? balance;
  final double? creditLimit;

  const UserProfileEntity({
    this.avatarUrl,
    this.companyName,
    this.balance,
    this.creditLimit,
  });

  @override
  List<Object?> get props => [avatarUrl, companyName, balance, creditLimit];
}
