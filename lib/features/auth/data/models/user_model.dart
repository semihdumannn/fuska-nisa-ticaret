import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'api_user_model.dart';

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final bool isActive;
  final String? assignedRegion;
  final int totalOrders;
  final DateTime? lastOrderDate;
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.isActive = true,
    this.assignedRegion,
    this.totalOrders = 0,
    this.lastOrderDate,
    this.fcmToken,
    required this.createdAt,
  });

  bool get isStaff =>
      role == UserRole.admin ||
      role == UserRole.fieldAgent ||
      role == UserRole.delivery;

  bool get isAdmin => role == UserRole.admin;

  /// Backend (Laravel API) kullanıcısından UserModel oluşturur.
  factory UserModel.fromApiUser(ApiUserModel apiUser) {
    return UserModel(
      uid: apiUser.id.toString(),
      name: apiUser.name,
      phone: apiUser.phone,
      email: apiUser.email,
      role: UserRole.fromString(apiUser.role),
      isActive: apiUser.isActive ?? true,
      createdAt: DateTime.now(),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      role: UserRole.fromString(data['role'] ?? 'customer'),
      isActive: data['isActive'] ?? true,
      assignedRegion: data['assignedRegion'],
      totalOrders: data['totalOrders'] ?? 0,
      lastOrderDate: (data['lastOrderDate'] as Timestamp?)?.toDate(),
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.value,
      'isActive': isActive,
      'assignedRegion': assignedRegion,
      'totalOrders': totalOrders,
      'lastOrderDate': lastOrderDate != null ? Timestamp.fromDate(lastOrderDate!) : null,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    bool? isActive,
    String? assignedRegion,
    int? totalOrders,
    DateTime? lastOrderDate,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      assignedRegion: assignedRegion ?? this.assignedRegion,
      totalOrders: totalOrders ?? this.totalOrders,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [uid, name, phone, role, isActive];
}
