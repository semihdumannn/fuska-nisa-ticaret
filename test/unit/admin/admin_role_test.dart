// admin_role_test.dart
//
// UserRole enum, AdminUserModel serialization ve OrderStatus logic testleri.
// Firebase/Riverpod bagimliligi yok; saf model ve enum seviyesinde dogrulama.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/admin/data/models/admin_user_model.dart';

void main() {
  // --------------------------------------------------------------------------
  // UserRole enum
  // --------------------------------------------------------------------------
  group('UserRole', () {
    test('customer role has correct display name', () {
      expect(UserRole.customer.displayName, 'Müşteri');
    });

    test('fieldAgent role has correct display name', () {
      expect(UserRole.fieldAgent.displayName, 'Saha Personeli');
    });

    test('delivery role has correct display name', () {
      expect(UserRole.delivery.displayName, 'Teslimat');
    });

    test('admin role has correct display name', () {
      expect(UserRole.admin.displayName, 'Admin');
    });

    test('customer value string is customer', () {
      expect(UserRole.customer.value, 'customer');
    });

    test('fieldAgent value string is field_agent', () {
      expect(UserRole.fieldAgent.value, 'field_agent');
    });

    test('delivery value string is delivery', () {
      expect(UserRole.delivery.value, 'delivery');
    });

    test('admin value string is admin', () {
      expect(UserRole.admin.value, 'admin');
    });

    test('all roles have unique values', () {
      final values = UserRole.values.map((r) => r.value).toList();
      expect(values.toSet().length, equals(values.length));
    });

    test('fromString field_agent returns fieldAgent', () {
      expect(UserRole.fromString('field_agent'), UserRole.fieldAgent);
    });

    test('fromString delivery returns delivery', () {
      expect(UserRole.fromString('delivery'), UserRole.delivery);
    });

    test('fromString admin returns admin', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
    });

    test('fromString customer returns customer', () {
      expect(UserRole.fromString('customer'), UserRole.customer);
    });

    test('fromString unknown string defaults to customer', () {
      expect(UserRole.fromString('bilinmeyen_rol'), UserRole.customer);
    });

    test('fromString empty string defaults to customer', () {
      expect(UserRole.fromString(''), UserRole.customer);
    });

    test('role extension roleColor is not null for all roles', () {
      for (final role in UserRole.values) {
        expect(role.roleColor, isA<Color>());
      }
    });

    test('role extension roleIcon is not null for all roles', () {
      for (final role in UserRole.values) {
        expect(role.roleIcon, isA<IconData>());
      }
    });

    test('total role count is 4', () {
      expect(UserRole.values.length, 4);
    });
  });

  // --------------------------------------------------------------------------
  // AdminUserModel
  // --------------------------------------------------------------------------
  group('AdminUserModel', () {
    final baseDate = DateTime(2024, 1, 15);

    AdminUserModel makeUser({
      String id = 'u-test',
      String name = 'Test Kullanici',
      String phone = '+905550001122',
      UserRole role = UserRole.customer,
      bool isBlocked = false,
      int totalOrders = 3,
      double totalSpent = 150.0,
    }) {
      return AdminUserModel(
        id: id,
        name: name,
        phone: phone,
        role: role,
        isBlocked: isBlocked,
        createdAt: baseDate,
        totalOrders: totalOrders,
        totalSpent: totalSpent,
      );
    }

    test('fromJson / toJson round-trip preserves id', () {
      final user = makeUser();
      final restored = AdminUserModel.fromJson(user.toJson());
      expect(restored.id, user.id);
    });

    test('fromJson / toJson round-trip preserves name', () {
      final user = makeUser(name: 'Ayse Yildiz');
      final restored = AdminUserModel.fromJson(user.toJson());
      expect(restored.name, user.name);
    });

    test('fromJson / toJson round-trip preserves phone', () {
      final user = makeUser(phone: '+905559998877');
      final restored = AdminUserModel.fromJson(user.toJson());
      expect(restored.phone, user.phone);
    });

    test('fromJson / toJson round-trip preserves role', () {
      for (final role in UserRole.values) {
        final user = makeUser(role: role);
        final restored = AdminUserModel.fromJson(user.toJson());
        expect(restored.role, role);
      }
    });

    test('fromJson / toJson round-trip preserves isBlocked true', () {
      final user = makeUser(isBlocked: true);
      final restored = AdminUserModel.fromJson(user.toJson());
      expect(restored.isBlocked, isTrue);
    });

    test('fromJson / toJson round-trip preserves totalOrders', () {
      final user = makeUser(totalOrders: 42);
      final restored = AdminUserModel.fromJson(user.toJson());
      expect(restored.totalOrders, 42);
    });

    test('fromJson / toJson round-trip preserves totalSpent', () {
      final user = makeUser(totalSpent: 1234.50);
      final restored = AdminUserModel.fromJson(user.toJson());
      expect(restored.totalSpent, 1234.50);
    });

    test('isBlocked default is false', () {
      final user = AdminUserModel(
        id: 'u-new',
        name: 'Yeni Kullanici',
        phone: '+905550000001',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );
      expect(user.isBlocked, isFalse);
    });

    test('totalOrders default is 0', () {
      final user = AdminUserModel(
        id: 'u-new',
        name: 'Yeni Kullanici',
        phone: '+905550000001',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );
      expect(user.totalOrders, 0);
    });

    test('totalSpent default is 0.0', () {
      final user = AdminUserModel(
        id: 'u-new',
        name: 'Yeni Kullanici',
        phone: '+905550000001',
        role: UserRole.customer,
        createdAt: DateTime.now(),
      );
      expect(user.totalSpent, 0.0);
    });

    test('copyWith isBlocked flips correctly', () {
      final user = makeUser(isBlocked: false);
      final blocked = user.copyWith(isBlocked: true);
      expect(blocked.isBlocked, isTrue);
      expect(blocked.id, user.id); // diger alanlar degismez
    });

    test('copyWith preserves unchanged fields', () {
      final user = makeUser(name: 'Orijinal Ad', totalOrders: 5);
      final updated = user.copyWith(isBlocked: true);
      expect(updated.name, 'Orijinal Ad');
      expect(updated.totalOrders, 5);
    });

    test('copyWith role changes role', () {
      final user = makeUser(role: UserRole.customer);
      final promoted = user.copyWith(role: UserRole.fieldAgent);
      expect(promoted.role, UserRole.fieldAgent);
      expect(user.role, UserRole.customer); // immutability
    });

    test('initials single word name returns first letter', () {
      final user = makeUser(name: 'Mehmet');
      expect(user.initials, 'M');
    });

    test('initials two word name returns first letters of each', () {
      final user = makeUser(name: 'Ahmet Yilmaz');
      expect(user.initials, 'AY');
    });

    test('initials multi word name uses first and last word', () {
      final user = makeUser(name: 'Ali Can Kaya');
      expect(user.initials, 'AK');
    });

    test('fromJson with missing fields uses defaults', () {
      final user = AdminUserModel.fromJson({'id': 'u-x', 'name': 'X', 'phone': '111'});
      expect(user.role, UserRole.customer);
      expect(user.isBlocked, isFalse);
      expect(user.totalOrders, 0);
    });
  });

  // --------------------------------------------------------------------------
  // OrderStatus enum
  // --------------------------------------------------------------------------
  group('OrderStatus', () {
    test('all order statuses have non-empty display names', () {
      for (final status in OrderStatus.values) {
        expect(status.displayName, isNotEmpty);
      }
    });

    test('pending display name is Beklemede', () {
      expect(OrderStatus.pending.displayName, 'Beklemede');
    });

    test('confirmed display name is Onaylandı', () {
      expect(OrderStatus.confirmed.displayName, 'Onaylandı');
    });

    test('preparing display name is Hazırlanıyor', () {
      expect(OrderStatus.preparing.displayName, 'Hazırlanıyor');
    });

    test('onTheWay display name is Yolda', () {
      expect(OrderStatus.onTheWay.displayName, 'Yolda');
    });

    test('delivered display name is Teslim Edildi', () {
      expect(OrderStatus.delivered.displayName, 'Teslim Edildi');
    });

    test('cancelled display name is İptal Edildi', () {
      expect(OrderStatus.cancelled.displayName, 'İptal Edildi');
    });

    test('all order statuses have unique value strings', () {
      final values = OrderStatus.values.map((s) => s.value).toList();
      expect(values.toSet().length, equals(values.length));
    });

    test('onTheWay value is on_the_way', () {
      expect(OrderStatus.onTheWay.value, 'on_the_way');
    });

    test('fromString on_the_way returns onTheWay', () {
      expect(OrderStatus.fromString('on_the_way'), OrderStatus.onTheWay);
    });

    test('fromString unknown defaults to pending', () {
      expect(OrderStatus.fromString('bilinmeyen'), OrderStatus.pending);
    });

    test('total status count is 6', () {
      expect(OrderStatus.values.length, 6);
    });

    test('logical flow contains 5 non-cancelled statuses', () {
      const validFlow = [
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.preparing,
        OrderStatus.onTheWay,
        OrderStatus.delivered,
      ];
      expect(validFlow.length, 5);
      for (final s in validFlow) {
        expect(s, isA<OrderStatus>());
      }
    });
  });
}
