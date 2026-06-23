import 'package:flutter/material.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/products/data/models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  final bool isSelected;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _resolveIconData(category);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.pinkLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              category.name,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kategori için ikon belirler — Firestore iconName → Material icon map,
  /// yoksa slug bazlı fallback. SVG ikonlar chip içinde desteklenmiyor;
  /// bu durumda null döner ve ikon alanı gösterilmez.
  static IconData? _resolveIconData(CategoryModel category) {
    if (category.iconName.isNotEmpty) {
      final iconData = _materialIconFromName(category.iconName);
      if (iconData != null) return iconData;
    }
    return _slugFallbackIcon(category.slug);
  }

  static IconData? _slugFallbackIcon(String slug) {
    switch (slug) {
      case 'su':
        return Icons.water_drop_outlined;
      case 'gazli-icecek':
        return Icons.bubble_chart_outlined;
      case 'meyve-suyu':
        return Icons.emoji_food_beverage_outlined;
      case 'soda':
        return Icons.local_bar_outlined;
      case 'kampanya':
        return Icons.local_offer_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  /// Material icon adından IconData döndürür.
  static IconData? _materialIconFromName(String name) {
    if (name.isEmpty) return null;
    const map = <String, IconData>{
      'water_drop': Icons.water_drop,
      'water': Icons.water_drop,
      'water_full': Icons.water,
      'local_drink': Icons.local_drink,
      'liquor': Icons.liquor,
      'local_bar': Icons.local_bar,
      'local_cafe': Icons.local_cafe,
      'emoji_food_beverage': Icons.emoji_food_beverage,
      'coffee': Icons.coffee,
      'sports_bar': Icons.sports_bar,
      'wine_bar': Icons.wine_bar,
      'breakfast_dining': Icons.breakfast_dining,
      'category': Icons.category,
      'category_outlined': Icons.category_outlined,
      'star': Icons.star_outlined,
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
      'more_horiz': Icons.more_horiz,
    };
    return map[name];
  }
}
