import '../config/app_config.dart';

class CacheKeys {
  // Products
  static const products = 'products_list';
  static String product(int id) => 'product_$id';
  static String productsByCategory(int categoryId) =>
      'products_category_$categoryId';

  // Categories & Brands
  static const categories = 'categories_list';
  static const brands = 'brands_list';

  // Auth
  static const userProfile = 'user_profile';

  // Addresses
  static const addresses = 'addresses_list';

  // Orders
  static const orders = 'orders_list';
  static String order(int id) => 'order_$id';

  // Config
  static const appConfig = 'app_config';

  // TTL - AppConfig'den dinamik, fallback sabit
  static Duration get productsTtl =>
      AppConfig.instance.productsCacheDuration;

  static Duration get categoriesTtl =>
      AppConfig.instance.categoriesCacheDuration;

  static Duration get userProfileTtl =>
      const Duration(hours: 1); // Remote Config'de yok, sabit

  static Duration get configTtl =>
      const Duration(hours: 12);

  static Duration get ordersTtl =>
      AppConfig.instance.ordersCacheDuration;
}
