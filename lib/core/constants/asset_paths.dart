/// Asset Paths — SVG ve Image dosyalarının merkezi yönetimi
class AssetPaths {
  AssetPaths._(); // Private constructor

  // Base paths
  static const String _iconsBase = 'assets/icons';
  static const String _imagesBase = 'assets/images';

  // === IMAGES ===

  /// Splash screen background (pembe gradient + wave)
  static const String splashWaveBg = '$_imagesBase/splash_wave_bg.png';
  
  /// Design reference mockup
  static const String designReference = '$_imagesBase/design_reference.png';
  
  /// Asset library (icon set preview)
  static const String assetLibrary = '$_imagesBase/asset_library.png';

  // === CATEGORY ICONS (SVG) ===
  
  /// Su kategorisi ikonu (damla)
  static const String icCatWater = '$_iconsBase/ic_cat_water.svg';
  
  /// Gazlı içecek kategorisi ikonu
  static const String icCatBeverage = '$_iconsBase/ic_cat_beverage.svg';
  
  /// Kampanya/Promo ikonu
  static const String icCatPromo = '$_iconsBase/ic_cat_promo.svg';

  // === NAVIGATION ICONS (SVG) ===
  
  /// Ana sayfa ikonu (home)
  static const String icNavHome = '$_iconsBase/ic_nav_home.svg';
  
  /// Sepet ikonu (cart)
  static const String icNavCart = '$_iconsBase/ic_nav_cart.svg';
  
  /// Siparişlerim ikonu (orders/clipboard)
  static const String icNavOrders = '$_iconsBase/ic_nav_orders.svg';
  
  /// Profil ikonu (user)
  static const String icNavProfile = '$_iconsBase/ic_nav_profile.svg';

  // === TERMINAL ICONS (SVG) ===
  
  /// Arama ikonu (search)
  static const String icTerminalSearch = '$_iconsBase/ic_terminal_search.svg';
  
  /// Geçmiş ikonu (history)
  static const String icTerminalHistory = '$_iconsBase/ic_terminal_history.svg';

  // === UTILITY ICONS (SVG) ===
  
  /// Onay ikonu (checkmark)
  static const String icOnay = '$_iconsBase/ic_onay.svg';
}
