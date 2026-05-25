import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/profile/domain/entities/profile_entity.dart';

void main() {
  // Yardımcı factory
  ProfileEntity makeProfile({
    int id = 1,
    String name = 'Ali Veli',
    String phone = '+905551234567',
    String? email,
    String role = 'customer',
    bool? isActive = true,
    String? avatarUrl,
    String? companyName,
    double? balance,
    double? creditLimit,
    DateTime? createdAt,
    List<AddressReference> addresses = const [],
  }) {
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
      createdAt: createdAt,
      addresses: addresses,
    );
  }

  group('ProfileEntity', () {
    group('temel alanlar', () {
      test('id, name, phone, role doğru atanmalı', () {
        final profile = makeProfile(
          id: 42,
          name: 'Fatma Hanım',
          phone: '+905559876543',
          role: 'admin',
        );
        expect(profile.id, equals(42));
        expect(profile.name, equals('Fatma Hanım'));
        expect(profile.phone, equals('+905559876543'));
        expect(profile.role, equals('admin'));
      });

      test('optional alanlar null olabilmeli', () {
        final profile = makeProfile(email: null, avatarUrl: null, companyName: null);
        expect(profile.email, isNull);
        expect(profile.avatarUrl, isNull);
        expect(profile.companyName, isNull);
      });

      test('balance ve creditLimit null olabilmeli', () {
        final profile = makeProfile(balance: null, creditLimit: null);
        expect(profile.balance, isNull);
        expect(profile.creditLimit, isNull);
      });

      test('balance ve creditLimit değer taşıyabilmeli', () {
        final profile = makeProfile(balance: 250.0, creditLimit: 1000.0);
        expect(profile.balance, equals(250.0));
        expect(profile.creditLimit, equals(1000.0));
      });
    });

    group('copyWith', () {
      test('name güncellenince diğer alanlar korunmalı', () {
        final original = makeProfile(id: 5, phone: '+905550000000');
        final copy = original.copyWith(name: 'Yeni İsim');
        expect(copy.name, equals('Yeni İsim'));
        expect(copy.id, equals(5));
        expect(copy.phone, equals('+905550000000'));
      });

      test('email güncellenebilmeli', () {
        final original = makeProfile(email: 'eski@test.com');
        final copy = original.copyWith(email: 'yeni@test.com');
        expect(copy.email, equals('yeni@test.com'));
      });

      test('role güncellenebilmeli', () {
        final original = makeProfile(role: 'customer');
        final copy = original.copyWith(role: 'field_agent');
        expect(copy.role, equals('field_agent'));
        expect(original.role, equals('customer')); // orijinal değişmemeli
      });

      test('balance güncellenebilmeli', () {
        final original = makeProfile(balance: 100.0);
        final copy = original.copyWith(balance: 500.0);
        expect(copy.balance, equals(500.0));
      });

      test('addresses güncellenebilmeli', () {
        final original = makeProfile(addresses: []);
        final newAddresses = [
          const AddressReference(id: 1, title: 'Ev', isDefault: true),
        ];
        final copy = original.copyWith(addresses: newAddresses);
        expect(copy.addresses.length, equals(1));
        expect(copy.addresses.first.title, equals('Ev'));
      });

      test('isActive güncellenebilmeli', () {
        final original = makeProfile(isActive: true);
        final copy = original.copyWith(isActive: false);
        expect(copy.isActive, isFalse);
      });
    });

    group('Equatable', () {
      test('aynı id, name, phone, email, role olan iki profil eşit olmalı', () {
        final a = makeProfile(id: 1, name: 'Ali', phone: '+90555', email: 'a@b.com', role: 'customer');
        final b = makeProfile(id: 1, name: 'Ali', phone: '+90555', email: 'a@b.com', role: 'customer');
        expect(a, equals(b));
      });

      test('farklı id olan iki profil eşit olmamalı', () {
        final a = makeProfile(id: 1);
        final b = makeProfile(id: 2);
        expect(a, isNot(equals(b)));
      });
    });

    group('addresses listesi', () {
      test('boş addresses listesi ile oluşturulabilmeli', () {
        final profile = makeProfile(addresses: []);
        expect(profile.addresses, isEmpty);
      });

      test('birden fazla AddressReference içerebilmeli', () {
        final profile = makeProfile(addresses: [
          const AddressReference(id: 1, title: 'Ev', isDefault: true),
          const AddressReference(id: 2, title: 'İş', isDefault: false),
        ]);
        expect(profile.addresses.length, equals(2));
        expect(profile.addresses.first.isDefault, isTrue);
        expect(profile.addresses.last.isDefault, isFalse);
      });
    });
  });

  group('AddressReference', () {
    test('id, title, isDefault doğru atanmalı', () {
      const ref = AddressReference(id: 7, title: 'Yazlık', isDefault: false);
      expect(ref.id, equals(7));
      expect(ref.title, equals('Yazlık'));
      expect(ref.isDefault, isFalse);
    });

    test('Equatable: aynı değerler eşit olmalı', () {
      const a = AddressReference(id: 1, title: 'Ev', isDefault: true);
      const b = AddressReference(id: 1, title: 'Ev', isDefault: true);
      expect(a, equals(b));
    });

    test('Equatable: farklı id eşit olmamalı', () {
      const a = AddressReference(id: 1, title: 'Ev', isDefault: true);
      const b = AddressReference(id: 2, title: 'Ev', isDefault: true);
      expect(a, isNot(equals(b)));
    });
  });
}
