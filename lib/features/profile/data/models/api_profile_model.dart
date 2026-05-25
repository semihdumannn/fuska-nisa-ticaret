import '../../domain/entities/profile_entity.dart';

class ApiProfileModel {
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
  final String? createdAt;

  const ApiProfileModel({
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
  });

  factory ApiProfileModel.fromJson(Map<String, dynamic> json) {
    return ApiProfileModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool?,
      avatarUrl: json['avatar_url'] as String?,
      companyName: json['company_name'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      createdAt: json['created_at'] as String?,
    );
  }

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      name: name,
      phone: phone,
      email: email,
      role: role,
      isActive: isActive,
      avatarUrl: avatarUrl,
      companyName: companyName,
      balance: balance,
      creditLimit: creditLimit,
      createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
    );
  }
}
