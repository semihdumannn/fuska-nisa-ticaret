import '../config/app_config.dart';

class CacheKeys {
  // Products
  static const products = 'products_list_v2';
  static const featuredProducts = 'products_featured_v1';
  static String product(int id) => 'product_$id';
  static String productsByCategory(int categoryId) =>
      'products_category_$categoryId';

  /// API tarafı kategori filtreli ürün listesi cache key'i.
  /// `ApiProductRepositoryImpl.getProducts` ile aynı pattern'i kullanır
  /// (sayfa-1, perPage'e göre).
  static String apiProductsByCategory(String categoryId, int perPage) =>
      '${products}_cat_${categoryId}_$perPage';

  // Categories
  static const categories = 'categories_list';

  // Auth
  static const userProfile = 'user_profile';

  // Addresses
  static const addresses = 'addresses_list';

  // Orders
  static const orders = 'orders_list';
  static String order(int id) => 'order_$id';

  // Campaigns
  static const campaigns = 'campaigns_list';

  // Notifications
  static const notifications = 'notifications_list';
  static const notificationsUnreadCount = 'notifications_unread_count';

  // Delivery
  static const deliveryOrders = 'delivery_orders_list';

  // TTL - AppConfig'den dinamik, fallback sabit
  static Duration get productsTtl => AppConfig.instance.productsCacheDuration;

  static Duration get categoriesTtl =>
      AppConfig.instance.categoriesCacheDuration;

  static Duration get addressesTtl => const Duration(hours: 24);

  static Duration get userProfileTtl => const Duration(hours: 1);

  static Duration get ordersTtl => AppConfig.instance.ordersCacheDuration;

  static Duration get campaignsTtl => const Duration(hours: 6);

  static Duration get notificationsTtl => const Duration(minutes: 5);

  static Duration get deliveryOrdersTtl => const Duration(minutes: 2);
}
