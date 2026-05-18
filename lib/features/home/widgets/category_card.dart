import 'package:flutter/material.dart';
import 'package:nisa_ticaret/core/constants/category_icons.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/products/data/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CategoryIconWidget(
      categoryIcon: _resolveIcon(category),
      onTap: onTap,
    );
  }

  /// Önce Firestore'daki iconName+color'ı dene; yoksa slug'a göre statik fallback.
  static CategoryIcon _resolveIcon(CategoryModel category) {
    // Firestore'da iconName varsa dinamik ikon kullan
    if (category.iconName.isNotEmpty) {
      final iconData = _materialIconFromName(category.iconName);
      if (iconData != null) {
        final fg = _parseColor(category.color) ?? AppColors.primary;
        final bg = fg.withValues(alpha: 0.12);
        return CategoryIcon(
          icon: iconData,
          backgroundColor: bg,
          foregroundColor: fg,
          label: category.name,
        );
      }
    }

    // slug bazlı statik fallback
    return _slugFallback(category.slug, category.name);
  }

  static CategoryIcon _slugFallback(String slug, String label) {
    switch (slug) {
      case 'su':
        return CategoryIcon(
          svgPath: CategoryIcons.water.svgPath,
          backgroundColor: CategoryIcons.water.backgroundColor,
          foregroundColor: CategoryIcons.water.foregroundColor,
          label: label,
        );
      case 'gazli-icecek':
        return CategoryIcon(
          svgPath: CategoryIcons.carbonated.svgPath,
          backgroundColor: CategoryIcons.carbonated.backgroundColor,
          foregroundColor: CategoryIcons.carbonated.foregroundColor,
          label: label,
        );
      case 'meyve-suyu':
        return CategoryIcon(
          icon: CategoryIcons.juice.icon,
          backgroundColor: CategoryIcons.juice.backgroundColor,
          foregroundColor: CategoryIcons.juice.foregroundColor,
          label: label,
        );
      case 'soda':
        return CategoryIcon(
          icon: CategoryIcons.soda.icon,
          backgroundColor: CategoryIcons.soda.backgroundColor,
          foregroundColor: CategoryIcons.soda.foregroundColor,
          label: label,
        );
      case 'kampanya':
        return CategoryIcon(
          svgPath: CategoryIcons.promo.svgPath,
          backgroundColor: CategoryIcons.promo.backgroundColor,
          foregroundColor: CategoryIcons.promo.foregroundColor,
          label: label,
        );
      default:
        return CategoryIcon(
          icon: Icons.category_outlined,
          backgroundColor: AppColors.border,
          foregroundColor: AppColors.textSecondary,
          label: label,
        );
    }
  }

  /// Material icon adından IconData döndürür.
  /// Firestore'da "water_drop", "local_drink" gibi snake_case isimler beklenir.
  static IconData? _materialIconFromName(String name) {
    const map = <String, IconData>{
      'water_drop': Icons.water_drop,
      'water': Icons.water,
      'local_drink': Icons.local_drink,
      'liquor': Icons.liquor,
      'local_bar': Icons.local_bar,
      'emoji_food_beverage': Icons.emoji_food_beverage,
      'coffee': Icons.coffee,
      'sports_bar': Icons.sports_bar,
      'wine_bar': Icons.wine_bar,
      'breakfast_dining': Icons.breakfast_dining,
      'category': Icons.category,
      'category_outlined': Icons.category_outlined,
      'star': Icons.star,
      'local_offer': Icons.local_offer,
      'sell': Icons.sell,
      'percent': Icons.percent,
      'new_releases': Icons.new_releases,
      'bolt': Icons.bolt,
      'eco': Icons.eco,
      'grass': Icons.grass,
      'spa': Icons.spa,
      'set_meal': Icons.set_meal,
      'blender': Icons.blender,
      'kitchen': Icons.kitchen,
      'shopping_bag': Icons.shopping_bag,
      'inventory_2': Icons.inventory_2,
    };
    return map[name];
  }

  /// "#RRGGBB" veya "RRGGBB" hex string'i Color'a çevirir.
  static Color? _parseColor(String hex) {
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
      if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return null;
  }
}
