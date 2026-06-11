import 'package:flutter/material.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';

// UserRole app_constants.dart'ta zaten mevcut.
// Bu extension admin ekranlarinda renk ve etiket icin kullanilir.
extension AdminUserRoleExt on UserRole {
  Color get roleColor {
    switch (this) {
      case UserRole.customer:
        return AppColors.secondary;
      case UserRole.fieldAgent:
        return AppColors.primary;
      case UserRole.delivery:
        return AppColors.accent;
      case UserRole.admin:
        return AppColors.success;
    }
  }

  IconData get roleIcon {
    switch (this) {
      case UserRole.customer:
        return Icons.person_outline;
      case UserRole.fieldAgent:
        return Icons.badge_outlined;
      case UserRole.delivery:
        return Icons.local_shipping_outlined;
      case UserRole.admin:
        return Icons.admin_panel_settings_outlined;
    }
  }
}

class AdminUserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final int totalOrders;
  final double totalSpent;
  final String? address;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.isBlocked = false,
    required this.createdAt,
    this.lastLoginAt,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.address,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final isActive = json['is_active'] as bool? ?? json['isActive'] as bool? ?? true;
    final isBlocked = json['isBlocked'] as bool? ?? !isActive;
    final createdAtRaw = json['created_at'] as String? ?? json['createdAt'] as String?;
    final lastLoginRaw = json['last_login_at'] as String? ?? json['lastLoginAt'] as String?;
    return AdminUserModel(
      id: (json['id'] ?? '').toString(),
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'customer'),
      isBlocked: isBlocked,
      createdAt: createdAtRaw != null ? DateTime.parse(createdAtRaw) : DateTime.now(),
      lastLoginAt: lastLoginRaw != null ? DateTime.parse(lastLoginRaw) : null,
      totalOrders: (json['total_orders'] as num? ?? json['totalOrders'] as num? ?? 0).toInt(),
      totalSpent: (json['total_spent'] as num? ?? json['totalSpent'] as num? ?? 0).toDouble(),
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.value,
      'isBlocked': isBlocked,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'address': address,
    };
  }

  AdminUserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? totalOrders,
    double? totalSpent,
    String? address,
  }) {
    return AdminUserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      address: address ?? this.address,
    );
  }

}
