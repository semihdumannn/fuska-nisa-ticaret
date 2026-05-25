import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/profile/domain/entities/address_entity.dart';

void main() {
  // Yardımcı factory
  AddressEntity makeAddress({
    int? id,
    String title = 'Ev',
    String fullName = 'Ali Veli',
    String phone = '+905551234567',
    String addressLine = 'Atatürk Cd. No:12',
    String city = 'İstanbul',
    String? district,
    String? neighborhood,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) {
    return AddressEntity(
      id: id,
      title: title,
      fullName: fullName,
      phone: phone,
      addressLine: addressLine,
      city: city,
      district: district,
      neighborhood: neighborhood,
      postalCode: postalCode,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );
  }

  group('AddressEntity', () {
    group('fullAddress', () {
      test('sadece addressLine ve city varsa "addressLine, city" olmalı', () {
        final addr = makeAddress(
          addressLine: 'Atatürk Cd. No:5',
          city: 'Ankara',
        );
        expect(addr.fullAddress, equals('Atatürk Cd. No:5, Ankara'));
      });

      test('district de varsa "addressLine, district, city" olmalı', () {
        final addr = makeAddress(
          addressLine: 'Bağdat Cd. No:20',
          district: 'Kadıköy',
          city: 'İstanbul',
        );
        expect(addr.fullAddress, equals('Bağdat Cd. No:20, Kadıköy, İstanbul'));
      });

      test('neighborhood de varsa "addressLine, neighborhood, district, city" olmalı', () {
        final addr = makeAddress(
          addressLine: 'Çiçek Sk. No:3',
          neighborhood: 'Moda',
          district: 'Kadıköy',
          city: 'İstanbul',
        );
        expect(addr.fullAddress, equals('Çiçek Sk. No:3, Moda, Kadıköy, İstanbul'));
      });

      test('neighborhood varsa district null ise yine de doğru çalışmalı', () {
        final addr = makeAddress(
          addressLine: 'Sahil Yolu No:1',
          neighborhood: 'Sahil',
          district: null,
          city: 'İzmir',
        );
        expect(addr.fullAddress, equals('Sahil Yolu No:1, Sahil, İzmir'));
      });
    });

    group('hasCoordinates', () {
      test('latitude ve longitude her ikisi de varsa true olmalı', () {
        final addr = makeAddress(latitude: 41.0082, longitude: 28.9784);
        expect(addr.hasCoordinates, isTrue);
      });

      test('latitude null ise false olmalı', () {
        final addr = makeAddress(latitude: null, longitude: 28.9784);
        expect(addr.hasCoordinates, isFalse);
      });

      test('longitude null ise false olmalı', () {
        final addr = makeAddress(latitude: 41.0082, longitude: null);
        expect(addr.hasCoordinates, isFalse);
      });

      test('her ikisi de null ise false olmalı', () {
        final addr = makeAddress(latitude: null, longitude: null);
        expect(addr.hasCoordinates, isFalse);
      });
    });

    group('copyWith', () {
      test('city güncellenince diğer alanlar korunmalı', () {
        final original = makeAddress(
          addressLine: 'Test Sk. No:1',
          city: 'Eski Şehir',
          isDefault: true,
        );
        final copy = original.copyWith(city: 'Yeni Şehir');
        expect(copy.city, equals('Yeni Şehir'));
        expect(copy.addressLine, equals('Test Sk. No:1'));
        expect(copy.isDefault, isTrue);
      });

      test('isDefault güncellenebilmeli', () {
        final original = makeAddress(isDefault: false);
        final copy = original.copyWith(isDefault: true);
        expect(copy.isDefault, isTrue);
        expect(original.isDefault, isFalse); // orijinal değişmemeli
      });

      test('koordinatlar güncellenebilmeli', () {
        final original = makeAddress(latitude: null, longitude: null);
        final copy = original.copyWith(latitude: 39.9, longitude: 32.8);
        expect(copy.hasCoordinates, isTrue);
        expect(original.hasCoordinates, isFalse);
      });

      test('id güncellenebilmeli', () {
        final original = makeAddress(id: null);
        final copy = original.copyWith(id: 99);
        expect(copy.id, equals(99));
      });

      test('district ve neighborhood güncellenebilmeli', () {
        final original = makeAddress(district: null, neighborhood: null);
        final copy = original.copyWith(district: 'Beşiktaş', neighborhood: 'Levent');
        expect(copy.district, equals('Beşiktaş'));
        expect(copy.neighborhood, equals('Levent'));
      });
    });

    group('Equatable', () {
      test('aynı id, title, addressLine, city, isDefault olan adresler eşit olmalı', () {
        final a = makeAddress(id: 1, title: 'Ev', addressLine: 'X Sk.', city: 'İstanbul', isDefault: true);
        final b = makeAddress(id: 1, title: 'Ev', addressLine: 'X Sk.', city: 'İstanbul', isDefault: true);
        expect(a, equals(b));
      });

      test('farklı city olan adresler eşit olmamalı', () {
        final a = makeAddress(id: 1, city: 'İstanbul');
        final b = makeAddress(id: 1, city: 'Ankara');
        expect(a, isNot(equals(b)));
      });
    });

    group('isteğe bağlı alanlar', () {
      test('id null olabilmeli (kayıt öncesi)', () {
        final addr = makeAddress(id: null);
        expect(addr.id, isNull);
      });

      test('postalCode saklanabilmeli', () {
        final addr = makeAddress(postalCode: '34000');
        expect(addr.postalCode, equals('34000'));
      });

      test('isDefault varsayılan olarak false olmalı', () {
        final addr = makeAddress();
        expect(addr.isDefault, isFalse);
      });
    });
  });
}
