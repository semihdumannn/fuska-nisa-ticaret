// customer_repository_test.dart
//
// CustomerRepository.searchByName isim filtresi ve UserModel field_agent
// ilgili alanlar icin unit testler. Saf Dart logic test edilir, network mock yok.

import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';


// ---------------------------------------------------------------------------
// Yardimci: Minimal UserModel olusturur
// ---------------------------------------------------------------------------
UserModel _makeUser({
  String uid = 'uid1',
  String name = 'Ali Yilmaz',
  String phone = '05001234567',
  UserRole role = UserRole.customer,
  bool isActive = true,
}) {
  return UserModel(
    uid: uid,
    name: name,
    phone: phone,
    role: role,
    isActive: isActive,
    createdAt: DateTime(2026, 1, 1),
  );
}

// ---------------------------------------------------------------------------
// CustomerPage filter mantigi — repository'deki client-side mantigi yansitir.
// searchByName: name.toLowerCase().contains(query.toLowerCase())
// ---------------------------------------------------------------------------
List<UserModel> _clientSideNameFilter(List<UserModel> users, String query) {
  if (query.isEmpty) return users;
  final q = query.toLowerCase();
  return users.where((u) => u.name.toLowerCase().contains(q)).toList();
}

void main() {
  // =========================================================================
  // CustomerRepository.searchByName — client-side filtre mantiginin testleri
  // =========================================================================
  group('CustomerRepository searchByName client-side filtre', () {
    final sampleUsers = [
      _makeUser(uid: 'u1', name: 'Ali Yilmaz'),
      _makeUser(uid: 'u2', name: 'Veli Kaya'),
      _makeUser(uid: 'u3', name: 'Ayse Demir'),
      _makeUser(uid: 'u4', name: 'Mehmet Ozturk'),
      _makeUser(uid: 'u5', name: 'ali celik'), // kucuk harf
    ];

    test('bos query — tum liste donmeli', () {
      final result = _clientSideNameFilter(sampleUsers, '');
      expect(result.length, sampleUsers.length);
    });

    test('eslesme yok — bos liste', () {
      final result = _clientSideNameFilter(sampleUsers, 'zzz');
      expect(result, isEmpty);
    });

    test('buyuk harf query — kucuk harf isime eslesir', () {
      // 'ali celik' ve 'Ali Yilmaz' her ikisi de 'ali' sorgusunda bulunmali
      final result = _clientSideNameFilter(sampleUsers, 'ALI');
      expect(result.length, 2);
      final names = result.map((u) => u.name.toLowerCase()).toList();
      expect(names, everyElement(contains('ali')));
    });

    test('kucuk harf query — buyuk harf isime eslesir', () {
      final result = _clientSideNameFilter(sampleUsers, 'ayse');
      expect(result.length, 1);
      expect(result.first.uid, 'u3');
    });

    test('kismı eslesmı — dogru sonuclar', () {
      final result = _clientSideNameFilter(sampleUsers, 'yil');
      expect(result.length, 1);
      expect(result.first.name, 'Ali Yilmaz');
    });

    test('soyadi ile arama', () {
      final result = _clientSideNameFilter(sampleUsers, 'kaya');
      expect(result.length, 1);
      expect(result.first.uid, 'u2');
    });

    test('birden fazla eslesen sonuc', () {
      final users = [
        _makeUser(uid: 'u1', name: 'Ahmet Arslan'),
        _makeUser(uid: 'u2', name: 'Mehmet Arslan'),
        _makeUser(uid: 'u3', name: 'Fatma Demir'),
      ];

      final result = _clientSideNameFilter(users, 'arslan');
      expect(result.length, 2);
    });

    test('tek karakterlik query', () {
      final users = [
        _makeUser(uid: 'u1', name: 'Ali'),
        _makeUser(uid: 'u2', name: 'Bora'),
        _makeUser(uid: 'u3', name: 'Can'),
      ];

      final result = _clientSideNameFilter(users, 'a');
      // 'Ali', 'Bora', 'Can' hepsinde 'a' harfi var
      expect(result.length, 3);
    });

    test('bosluklu query — tam isim eslesimi', () {
      final result = _clientSideNameFilter(sampleUsers, 'Ali Yilmaz');
      expect(result.length, 1);
      expect(result.first.uid, 'u1');
    });

    test('bos kullanici listesi — bos liste doner', () {
      final result = _clientSideNameFilter([], 'Ali');
      expect(result, isEmpty);
    });

    test('query case-insensitive cift yonlu calisir', () {
      final users = [
        _makeUser(uid: 'u1', name: 'MEHMET YILDIZ'),
        _makeUser(uid: 'u2', name: 'Fatma Sahin'),
      ];

      final resultLower = _clientSideNameFilter(users, 'mehmet');
      final resultUpper = _clientSideNameFilter(users, 'MEHMET');
      final resultMixed = _clientSideNameFilter(users, 'Mehmet');

      expect(resultLower.length, 1);
      expect(resultUpper.length, 1);
      expect(resultMixed.length, 1);
    });
  });

  // =========================================================================
  // UserModel — field_agent icin gerekli alanlar
  // =========================================================================
  group('UserModel field_agent ilgili', () {
    test('customer role dogru atanir', () {
      final user = _makeUser(role: UserRole.customer);
      expect(user.role, UserRole.customer);
      expect(user.role.value, 'customer');
    });

    test('isStaff field_agent icin true doner', () {
      final user = _makeUser(role: UserRole.fieldAgent);
      expect(user.isStaff, isTrue);
    });

    test('isStaff customer icin false doner', () {
      final user = _makeUser(role: UserRole.customer);
      expect(user.isStaff, isFalse);
    });

    test('tum zorunlu field\'lar dogru atanir', () {
      final user = _makeUser(
        uid: 'test-uid',
        name: 'Test Kullanici',
        phone: '05551234567',
        role: UserRole.customer,
        isActive: true,
      );

      expect(user.uid, 'test-uid');
      expect(user.name, 'Test Kullanici');
      expect(user.phone, '05551234567');
      expect(user.role, UserRole.customer);
      expect(user.isActive, isTrue);
    });

    test('isActive varsayilan true', () {
      final user = UserModel(
        uid: 'u1',
        name: 'Ad',
        phone: '0500',
        role: UserRole.customer,
        createdAt: DateTime(2026),
      );
      expect(user.isActive, isTrue);
    });
  });
}
