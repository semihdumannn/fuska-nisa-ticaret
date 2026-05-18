import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisa_ticaret/core/constants/category_icons.dart';

// ─────────────────────────────────────────────
// Test yardimcilari
// ─────────────────────────────────────────────

CategoryIcon _svgIcon({
  String svgPath = 'assets/icons/ic_cat_water.svg',
  String label = 'Su',
  Color backgroundColor = const Color(0xFFE0F7F8),
  Color foregroundColor = const Color(0xFF00A6AB),
}) {
  return CategoryIcon(
    svgPath: svgPath,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    label: label,
  );
}

CategoryIcon _iconIcon({
  IconData icon = Icons.emoji_food_beverage,
  String label = 'Meyve Suyu',
  Color backgroundColor = const Color(0xFFE8EBF3),
  Color foregroundColor = const Color(0xFF13275A),
}) {
  return CategoryIcon(
    icon: icon,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    label: label,
  );
}

Widget _wrapWidget(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('CategoryIcon — data class', () {
    test('svgPath dolu → isSvg true', () {
      final ci = _svgIcon();
      expect(ci.isSvg, true);
    });

    test('svgPath null → isSvg false', () {
      final ci = _iconIcon();
      expect(ci.isSvg, false);
    });

    test('label dogru set ediliyor', () {
      final ci = _svgIcon(label: 'Kampanya');
      expect(ci.label, 'Kampanya');
    });

    test('backgroundColor ve foregroundColor dogru set ediliyor', () {
      const bg = Color(0xFFE0F7F8);
      const fg = Color(0xFF00A6AB);
      final ci = _svgIcon(backgroundColor: bg, foregroundColor: fg);
      expect(ci.backgroundColor, bg);
      expect(ci.foregroundColor, fg);
    });

    test('assert: svgPath ve icon ikisi de null ise AssertionError firlatir', () {
      expect(
        () => CategoryIcon(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          label: 'Gecersiz',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('svgPath dolu, icon null → gecerli nesne olusur', () {
      final ci = _svgIcon();
      expect(ci.svgPath, isNotNull);
      expect(ci.icon, isNull);
    });

    test('icon dolu, svgPath null → gecerli nesne olusur', () {
      final ci = _iconIcon();
      expect(ci.icon, isNotNull);
      expect(ci.svgPath, isNull);
    });
  });

  group('CategoryIcons — statik sabitler', () {
    test('water: isSvg true', () {
      expect(CategoryIcons.water.isSvg, true);
    });

    test('juice: isSvg false (Flutter Icon)', () {
      expect(CategoryIcons.juice.isSvg, false);
    });

    test('all listesi 5 eleman iceriyor', () {
      expect(CategoryIcons.all.length, 5);
    });

    test('all listesinde water iceriyor', () {
      expect(CategoryIcons.all.contains(CategoryIcons.water), true);
    });
  });

  group('CategoryIconWidget — Flutter Icon render', () {
    testWidgets('icon widget render edilir', (tester) async {
      final ci = _iconIcon(icon: Icons.local_bar, label: 'Soda');
      await tester.pumpWidget(
        _wrapWidget(CategoryIconWidget(categoryIcon: ci)),
      );

      expect(find.byIcon(Icons.local_bar), findsOneWidget);
    });

    testWidgets('label text gorunuyor', (tester) async {
      final ci = _iconIcon(label: 'Meyve Suyu');
      await tester.pumpWidget(
        _wrapWidget(CategoryIconWidget(categoryIcon: ci)),
      );

      expect(find.text('Meyve Suyu'), findsOneWidget);
    });

    testWidgets('onTap callback cagrilir', (tester) async {
      bool tapped = false;
      final ci = _iconIcon(label: 'Soda');
      await tester.pumpWidget(
        _wrapWidget(
          CategoryIconWidget(
            categoryIcon: ci,
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(CategoryIconWidget));
      expect(tapped, true);
    });

    testWidgets('isSelected=false: bold degil (w500)', (tester) async {
      final ci = _iconIcon(label: 'Soda');
      await tester.pumpWidget(
        _wrapWidget(
          CategoryIconWidget(categoryIcon: ci, isSelected: false),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Soda'));
      expect(textWidget.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('isSelected=true: label bold (w600)', (tester) async {
      final ci = _iconIcon(label: 'Soda');
      await tester.pumpWidget(
        _wrapWidget(
          CategoryIconWidget(categoryIcon: ci, isSelected: true),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Soda'));
      expect(textWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('isSelected=true: label rengi foregroundColor', (tester) async {
      const fg = Color(0xFF388E3C);
      final ci = _iconIcon(foregroundColor: fg, label: 'Soda');
      await tester.pumpWidget(
        _wrapWidget(
          CategoryIconWidget(categoryIcon: ci, isSelected: true),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Soda'));
      expect(textWidget.style?.color, fg);
    });

    testWidgets('onTap null iken tap yapinca hata cikmiyor', (tester) async {
      final ci = _iconIcon(label: 'Soda');
      await tester.pumpWidget(
        _wrapWidget(
          CategoryIconWidget(categoryIcon: ci, onTap: null),
        ),
      );

      // Hata firlatmamali
      await tester.tap(find.byType(CategoryIconWidget));
      expect(tester.takeException(), isNull);
    });
  });

  group('CategoryIconWidget — SVG render', () {
    testWidgets('svgPath olan icon: SvgPicture olmadan, Icon widget yok (SVG)', (tester) async {
      // Test ortaminda SVG asset yuklenmez; widget agaci olusturuluyor mu kontrol et
      final ci = _svgIcon(label: 'Su');
      await tester.pumpWidget(
        _wrapWidget(CategoryIconWidget(categoryIcon: ci)),
      );

      // Label hala gorunuyor olmali
      expect(find.text('Su'), findsOneWidget);
      // Icon widget olmamali (SVG path kullaniliyor)
      expect(find.byIcon(Icons.emoji_food_beverage), findsNothing);
    });

    testWidgets('boyut parametresi calisiyor (size=80)', (tester) async {
      final ci = _iconIcon(label: 'Soda');
      await tester.pumpWidget(
        _wrapWidget(
          CategoryIconWidget(categoryIcon: ci, size: 80),
        ),
      );

      // Container render edildi, hata yok
      expect(find.byType(CategoryIconWidget), findsOneWidget);
    });
  });

  group('CategoryIconWidget — ozel durumlar', () {
    testWidgets('birden fazla widget render edilebilir', (tester) async {
      await tester.pumpWidget(
        _wrapWidget(
          Row(
            children: [
              CategoryIconWidget(categoryIcon: _iconIcon(label: 'A')),
              CategoryIconWidget(categoryIcon: _iconIcon(label: 'B')),
            ],
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
