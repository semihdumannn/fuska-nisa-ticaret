import '../../domain/entities/user_entity.dart';

class ApiUserModel {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String role;
  final bool? isActive;
  final ApiUserProfileModel? profile;

  const ApiUserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.isActive,
    this.profile,
  });

  factory ApiUserModel.fromJson(Map<String, dynamic> json) {
    return ApiUserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      isActive: json['is_active'] as bool?,
      profile: json['profile'] != null
          ? ApiUserProfileModel.fromJson(
              Map<String, dynamic>.from(json['profile'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'is_active': isActive,
      'profile': profile?.toJson(),
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      name: name,
      phone: phone,
      email: email,
      role: role,
      isActive: isActive,
      profile: profile?.toEntity(),
    );
  }
}

class ApiUserProfileModel {
  final String? avatarUrl;
  final String? companyName;
  final double? balance;
  final double? creditLimit;

  const ApiUserProfileModel({
    this.avatarUrl,
    this.companyName,
    this.balance,
    this.creditLimit,
  });

  factory ApiUserProfileModel.fromJson(Map<String, dynamic> json) {
    return ApiUserProfileModel(
      avatarUrl: json['avatar_url'] as String?,
      companyName: json['company_name'] as String?,
      balance: _toDouble(json['balance']),
      creditLimit: _toDouble(json['credit_limit']),
    );
  }

  // Backend bazen balance/credit_limit'i String ("0.00") olarak dönüyor
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'avatar_url': avatarUrl,
      'company_name': companyName,
      'balance': balance,
      'credit_limit': creditLimit,
    };
  }

  UserProfileEntity toEntity() {
    return UserProfileEntity(
      avatarUrl: avatarUrl,
      companyName: companyName,
      balance: balance,
      creditLimit: creditLimit,
    );
  }
}
