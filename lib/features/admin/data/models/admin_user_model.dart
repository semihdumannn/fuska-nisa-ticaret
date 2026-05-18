import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory AdminUserModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdminUserModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      email: d['email'] as String?,
      role: UserRole.fromString(d['role'] as String? ?? 'customer'),
      isBlocked: !(d['isActive'] as bool? ?? true),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (d['lastLoginAt'] as Timestamp?)?.toDate(),
      totalOrders: (d['totalOrders'] as num? ?? 0).toInt(),
      totalSpent: (d['totalSpent'] as num? ?? 0).toDouble(),
      address: d['address'] as String?,
    );
  }

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      role: UserRole.fromString(json['role'] as String? ?? 'customer'),
      isBlocked: json['isBlocked'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      totalOrders: (json['totalOrders'] as num? ?? 0).toInt(),
      totalSpent: (json['totalSpent'] as num? ?? 0).toDouble(),
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

  /// Mock veri — 10 kullanici
  static List<AdminUserModel> mockList() {
    final now = DateTime.now();
    return [
      AdminUserModel(
        id: 'u001',
        name: 'Ahmet Yilmaz',
        phone: '+905551234567',
        email: 'ahmet@gmail.com',
        role: UserRole.customer,
        isBlocked: false,
        createdAt: now.subtract(const Duration(days: 180)),
        lastLoginAt: now.subtract(const Duration(hours: 3)),
        totalOrders: 15,
        totalSpent: 4250.0,
        address: 'Altieylul Mah. Ataturk Cad. No:12, Balikesir',
      ),
      AdminUserModel(
        id: 'u002',
        name: 'Fatma Demir',
        phone: '+905559876543',
        email: 'fatma.demir@hotmail.com',
        role: UserRole.customer,
        isBlocked: false,
        createdAt: now.subtract(const Duration(days: 95)),
        lastLoginAt: now.subtract(const Duration(days: 1)),
        totalOrders: 8,
        totalSpent: 1870.0,
        address: 'Karesi Mah. Cumhuriyet Cad. No:34, Balikesir',
      ),
      AdminUserModel(
        id: 'u003',
        name: 'Mehmet Kaya',
        phone: '+905554561234',
        role: UserRole.fieldAgent,
        isBlocked: false,
        createdAt: now.subtract(const Duration(days: 365)),
        lastLoginAt: now.subtract(const Duration(hours: 1)),
        totalOrders: 0,
        totalSpent: 0,
      ),
      AdminUserModel(
        id: 'u004',
        name: 'Zeynep Arslan',
        phone: '+905551112233',
        role: UserRole.delivery,
        isBlocked: false,
        createdAt: now.subtract(const Duration(days: 200)),
        lastLoginAt: now.subtract(const Duration(hours: 2)),
        totalOrders: 0,
        totalSpent: 0,
      ),
      AdminUserModel(
        id: 'u005',
        name: 'Ali Admin',
        phone: '+905550000000',
        email: 'admin@nisaticaret.com',
        role: UserRole.admin,
        isBlocked: false,
        createdAt: now.subtract(const Duration(days: 500)),
        lastLoginAt: now.subtract(const Duration(minutes: 10)),
        totalOrders: 0,
        totalSpent: 0,
      ),
      AdminUserModel(
        id: 'u006',
        name: 'Hasan Ozturk',
        phone: '+905553334455',
        email: 'hasan.ozturk@gmail.com',
        role: UserRole.customer,
        isBlocked: false,
        createdAt: now.subtract(const Duration(days: 60)),
        lastLoginAt: now.subtract(const Duration(days: 5)),
        totalOrders: 3,
        totalSpent: 680.0,
        address: 'Merkez Mah. Istasyon Cad. No:7, Balikesir',
      ),
      AdminUserModel(
        id: 'u007',
        name: 'Elif Sahin',
        phone: '+905556667788',
        email: 'elif.sahin@yahoo.com',
        role: UserRole.customer,
        isBlocked: true,
        createdAt: now.subtract(const Duration(days: 120)),
        lastLoginAt: now.subtract(const Duration(days: 30)),
        totalOrders: 2,
        totalSpent: 450.0,
      ),
      AdminUserModel(
        id: 'u008',
        name: 'Murat Celik',
        phone: '+905559998877',
        role: UserRole.customer,
        isBlocked: false,
        createdAt: now.subtract(const Duration(days: 30)),
        lastLoginAt: now.subtract(const Duration(hours: 12)),
        totalOrders: 5,
        totalSpent: 1120.0,
        address: 'Bahcelievler Mah. Gazi Cad. No:22, Balikesir',
      ),
      AdminUserModel(
        id: 'u009',
        name: 'Ayse Yildiz',
        phone: '+905552221100',
        email: 'ayse.yildiz@gmail.com',
        role: UserRole.customer,
        isBlocked: false,
        createdAt: now.subtract(const Duration(days: 250)),
        lastLoginAt: now.subtract(const Duration(days: 2)),
        totalOrders: 22,
        totalSpent: 5640.0,
        address: 'Yeni Mah. Bahar Sok. No:5, Balikesir',
      ),
      AdminUserModel(
        id: 'u010',
        name: 'Ibrahim Koc',
        phone: '+905554445566',
        role: UserRole.customer,
        isBlocked: false,
        createdAt: now.subtract(const Duration(days: 15)),
        lastLoginAt: now.subtract(const Duration(hours: 48)),
        totalOrders: 1,
        totalSpent: 230.0,
      ),
    ];
  }
}
