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
  group('CategoryModel — fromJson / toJson round-trip', () {
    test('tum alanlar dogru parse edilir', () {
      final now = DateTime(2026, 2, 10, 8, 30);
      final json = {
        'id': 'cat-su',
        'name': 'Su',
        'slug': 'su',
        'iconName': 'water_drop',
        'iconAsset': 'assets/icons/ic_cat_water.svg',
        'color': '#00A6AB',
        'sortOrder': 1,
        'isActive': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final cat = CategoryModel.fromJson(json);

      expect(cat.id, 'cat-su');
      expect(cat.name, 'Su');
      expect(cat.slug, 'su');
      expect(cat.iconName, 'water_drop');
      expect(cat.iconAsset, 'assets/icons/ic_cat_water.svg');
      expect(cat.color, '#00A6AB');
      expect(cat.sortOrder, 1);
      expect(cat.isActive, true);
      expect(cat.createdAt, now);
    });

    test('fromJson -> toJson round-trip esit model uretir', () {
      final now = DateTime(2026, 1, 15);
      final json = {
        'id': 'cat-gazli',
        'name': 'Gazli Icecek',
        'slug': 'gazli',
        'iconName': 'bubble_chart',
        'iconAsset': null,
        'color': '#E73A99',
        'sortOrder': 2,
        'isActive': true,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };

      final cat = CategoryModel.fromJson(json);
      final reEncoded = cat.toJson();
      final rebuilt = CategoryModel.fromJson(reEncoded);

      expect(rebuilt.id, cat.id);
      expect(rebuilt.name, cat.name);
      expect(rebuilt.slug, cat.slug);
      expect(rebuilt.iconName, cat.iconName);
      expect(rebuilt.iconAsset, cat.iconAsset);
      expect(rebuilt.color, cat.color);
      expect(rebuilt.sortOrder, cat.sortOrder);
      expect(rebuilt.isActive, cat.isActive);
    });

    test('eksik alanlar default degerlerle doldurulur', () {
      final cat = CategoryModel.fromJson({'id': 'x'});

      expect(cat.name, '');
      expect(cat.slug, '');
      expect(cat.iconName, '');
      expect(cat.iconAsset, null);
      expect(cat.color, '#000000');
      expect(cat.sortOrder, 0);
      expect(cat.isActive, false);
    });
  });

  group('CategoryModel — iconAsset nullable', () {
    test('iconAsset null oldugunda toJson da null gelir', () {
      final cat = makeCategory(iconAsset: null);
      final json = cat.toJson();
      expect(json.containsKey('iconAsset'), true);
      expect(json['iconAsset'], null);
    });

    test('iconAsset dolu oldugunda toJson da string gelir', () {
      final cat = makeCategory(iconAsset: 'assets/icons/ic_cat_water.svg');
      final json = cat.toJson();
      expect(json['iconAsset'], 'assets/icons/ic_cat_water.svg');
    });

    test('fromJson: iconAsset null key varsa null parse edilir', () {
      final cat = CategoryModel.fromJson({
        'id': 'c1',
        'iconAsset': null,
      });
      expect(cat.iconAsset, null);
    });

    test('fromJson: iconAsset key yoksa null gelir', () {
      final cat = CategoryModel.fromJson({'id': 'c1'});
      expect(cat.iconAsset, null);
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

  group('CategoryModel — toJson anahtarlari', () {
    test('toJson beklenen anahtarlari iceriyor', () {
      final cat = makeCategory();
      final json = cat.toJson();

      expect(json.containsKey('id'), true);
      expect(json.containsKey('name'), true);
      expect(json.containsKey('slug'), true);
      expect(json.containsKey('iconName'), true);
      expect(json.containsKey('iconAsset'), true);
      expect(json.containsKey('color'), true);
      expect(json.containsKey('sortOrder'), true);
      expect(json.containsKey('isActive'), true);
      expect(json.containsKey('createdAt'), true);
      expect(json.containsKey('updatedAt'), true);
    });
  });
}
