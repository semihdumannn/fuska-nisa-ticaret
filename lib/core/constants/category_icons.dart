import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'asset_paths.dart';

/// Kategori İkonları ve Renkleri (Fuska Edition + Real SVG Assets)
/// 
/// Gerçek SVG icon'lar kullanarak profesyonel görünüm
class CategoryIcons {
  /// Su kategorisi (Turkuaz) - GERÇEK SVG
  static const CategoryIcon water = CategoryIcon(
    svgPath: AssetPaths.icCatWater,
    backgroundColor: Color(0xFFE0F7F8), // Açık turkuaz
    foregroundColor: Color(0xFF00A6AB), // Turkuaz
    label: 'Su',
  );
  
  /// Gazlı içecekler (Pembe) - GERÇEK SVG
  static const CategoryIcon carbonated = CategoryIcon(
    svgPath: AssetPaths.icCatBeverage,
    backgroundColor: Color(0xFFFCE4F0), // Açık pembe
    foregroundColor: Color(0xFFE73A99), // Fuska pembesi
    label: 'Gazlı İçecek',
  );
  
  /// Kampanya/Promo (Gradient) - GERÇEK SVG
  static const CategoryIcon promo = CategoryIcon(
    svgPath: AssetPaths.icCatPromo,
    backgroundColor: Color(0xFFFFF3E0), // Açık turuncu
    foregroundColor: Color(0xFFF57C00), // Turuncu
    label: 'Kampanya',
  );
  
  /// Meyve suları (Lacivert) - Flutter Icon (SVG yok)
  static const CategoryIcon juice = CategoryIcon(
    icon: Icons.emoji_food_beverage,
    backgroundColor: Color(0xFFE8EBF3), // Açık lacivert
    foregroundColor: Color(0xFF13275A), // Lacivert
    label: 'Meyve Suyu',
  );
  
  /// Soda (Yeşil) - Flutter Icon (SVG yok)
  static const CategoryIcon soda = CategoryIcon(
    icon: Icons.local_bar,
    backgroundColor: Color(0xFFE8F5E9), // Açık yeşil
    foregroundColor: Color(0xFF388E3C), // Koyu yeşil
    label: 'Soda',
  );
  
  /// Tüm kategorileri liste olarak döndür
  static List<CategoryIcon> get all => [
    water,
    carbonated,
    juice,
    soda,
    promo,
  ];
}

/// Kategori ikon modeli (SVG veya Flutter Icon)
class CategoryIcon {
  final String? svgPath;  // SVG dosya yolu (varsa)
  final IconData? icon;   // Flutter icon (SVG yoksa)
  final Color backgroundColor;
  final Color foregroundColor;
  final String label;
  
  const CategoryIcon({
    this.svgPath,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.label,
  }) : assert(svgPath != null || icon != null, 'Either svgPath or icon must be provided');
  
  /// SVG mi Flutter Icon mı kontrol et
  bool get isSvg => svgPath != null;
}

/// Kategori icon widget'ı (SVG + Flutter Icon hybrid)
class CategoryIconWidget extends StatelessWidget {
  final CategoryIcon categoryIcon;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;
  
  const CategoryIconWidget({
    super.key,
    required this.categoryIcon,
    this.isSelected = false,
    this.onTap,
    this.size = 56,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: categoryIcon.backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? categoryIcon.foregroundColor
                    : Colors.black.withValues(alpha: 0.08),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: categoryIcon.isSvg
                  // SVG Icon (errorBuilder: dosya bulunamazsa Flutter Icon'a fall back)
                  ? SvgPicture.asset(
                      categoryIcon.svgPath!,
                      width: size * 0.5,
                      height: size * 0.5,
                      colorFilter: ColorFilter.mode(
                        categoryIcon.foregroundColor,
                        BlendMode.srcIn,
                      ),
                      placeholderBuilder: (_) => Icon(
                        Icons.category_outlined,
                        size: size * 0.5,
                        color: categoryIcon.foregroundColor,
                      ),
                    )
                  // Flutter Icon
                  : Icon(
                      categoryIcon.icon!,
                      size: size * 0.5,
                      color: categoryIcon.foregroundColor,
                    ),
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Label
          Text(
            categoryIcon.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected 
                  ? categoryIcon.foregroundColor 
                  : const Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }
}
