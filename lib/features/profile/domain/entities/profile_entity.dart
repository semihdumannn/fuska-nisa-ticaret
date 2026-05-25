import 'package:equatable/equatable.dart';

class ProfileEntity extends Equatable {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool? isActive;
  final String? avatarUrl;
  final String? companyName;
  final double? balance;
  final double? creditLimit;
  final DateTime? createdAt;
  final List<AddressReference> addresses;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.isActive,
    this.avatarUrl,
    this.companyName,
    this.balance,
    this.creditLimit,
    this.createdAt,
    this.addresses = const [],
  });

  ProfileEntity copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    bool? isActive,
    String? avatarUrl,
    String? companyName,
    double? balance,
    double? creditLimit,
    DateTime? createdAt,
    List<AddressReference>? addresses,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      companyName: companyName ?? this.companyName,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      createdAt: createdAt ?? this.createdAt,
      addresses: addresses ?? this.addresses,
    );
  }

  @override
  List<Object?> get props => [id, name, phone, email, role];
}

class AddressReference extends Equatable {
  final int id;
  final String title;
  final bool isDefault;

  const AddressReference({
    required this.id,
    required this.title,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [id, title, isDefault];
}
