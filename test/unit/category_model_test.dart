import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/features/products/data/models/category_model.dart';

// Test yardimci: minimal gecerli CategoryModel olusturur
CategoryModel makeCategory({
  String id = 'cat1',
  String name = 'Su',
  String slug = 'su',
  String iconName = 'water_drop',
  String? iconAsset,
  String color = '#00A6AB',
  int sortOrder = 1,
  bool isActive = true,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 1, 1);
  return CategoryModel(
    id: id,
    name: name,
    slug: slug,
    iconName: iconName,
    iconAsset: iconAsset,
    color: color,
    sortOrder: sortOrder,
    isActive: isActive,
    createdAt: createdAt ?? now,
    updatedAt: updatedAt ?? now,
  );
}

void main() {
  group('CategoryModel — toFirestore', () {
    test('beklenen anahtarlari iceriyor', () {
      final cat = makeCategory();
      final map = cat.toFirestore();

      expect(map.containsKey('name'), true);
      expect(map.containsKey('slug'), true);
      expect(map.containsKey('iconName'), true);
      expect(map.containsKey('iconAsset'), true);
      expect(map.containsKey('color'), true);
      expect(map.containsKey('sortOrder'), true);
      expect(map.containsKey('isActive'), true);
      expect(map.containsKey('createdAt'), true);
      expect(map.containsKey('updatedAt'), true);
    });

    test('iconAsset null oldugunda map da null gelir', () {
      final cat = makeCategory(iconAsset: null);
      final map = cat.toFirestore();
      expect(map['iconAsset'], null);
    });

    test('iconAsset dolu oldugunda map da string gelir', () {
      final cat = makeCategory(iconAsset: 'assets/icons/ic_cat_water.svg');
      final map = cat.toFirestore();
      expect(map['iconAsset'], 'assets/icons/ic_cat_water.svg');
    });

    test('parentId null ise map e dahil edilmez', () {
      final cat = makeCategory();
      final map = cat.toFirestore();
      expect(map.containsKey('parentId'), false);
    });
  });

  group('CategoryModel — == operatoru sadece id karsilastirir', () {
    test('ayni id, farkli name → esit', () {
      final a = makeCategory(id: 'cat1', name: 'Su');
      final b = makeCategory(id: 'cat1', name: 'Farkli Ad');
      expect(a == b, true);
    });

    test('farkli id → esit degil', () {
      final a = makeCategory(id: 'cat1');
      final b = makeCategory(id: 'cat2');
      expect(a == b, false);
    });

    test('ayni nesne kendisiyle esit', () {
      final a = makeCategory(id: 'cat1');
      expect(a == a, true);
    });

    test('hashCode ayni id icin esit', () {
      final a = makeCategory(id: 'xyz', name: 'A');
      final b = makeCategory(id: 'xyz', name: 'B');
      expect(a.hashCode, b.hashCode);
    });
  });

  group('CategoryModel — copyWith', () {
    test('deger degistirilmeden copyWith ayni degerleri korur', () {
      final original = makeCategory(
        id: 'cat1',
        name: 'Su',
        iconAsset: 'assets/icons/ic_cat_water.svg',
      );
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.iconAsset, original.iconAsset);
    });

    test('name degistirilir, diger alanlar korunur', () {
      final original = makeCategory(id: 'cat1', name: 'Su', sortOrder: 1);
      final copy = original.copyWith(name: 'Meyve Suyu');

      expect(copy.name, 'Meyve Suyu');
      expect(copy.id, original.id);
      expect(copy.sortOrder, original.sortOrder);
    });

    test('iconAsset null dan degere guncellenir', () {
      final original = makeCategory(iconAsset: null);
      final copy = original.copyWith(iconAsset: 'assets/icons/ic_cat_water.svg');
      expect(copy.iconAsset, 'assets/icons/ic_cat_water.svg');
    });

    test('iconAsset sentinel pattern: copyWith ile null a cekme desteklenmez (mevcut davranis)', () {
      // Mevcut copyWith implementasyonu sentinel kullanmadigi icin
      // iconAsset null gecilirse null'a degilse null'a donmez (mevcut kod davranisi)
      final original = makeCategory(iconAsset: 'assets/icons/ic_cat_water.svg');
      // copyWith'te iconAsset: null gecmek null yerine var olan degeri tutar
      // cunku: iconAsset ?? this.iconAsset => null ?? 'path' = 'path'
      final copy = original.copyWith(iconAsset: null);
      // Mevcut implementasyonda null gecilince this.iconAsset korunur
      expect(copy.iconAsset, original.iconAsset);
    });

    test('sortOrder guncellenir', () {
      final original = makeCategory(sortOrder: 1);
      final copy = original.copyWith(sortOrder: 5);
      expect(copy.sortOrder, 5);
    });

    test('isActive guncellenir', () {
      final original = makeCategory(isActive: true);
      final copy = original.copyWith(isActive: false);
      expect(copy.isActive, false);
    });
  });
}
