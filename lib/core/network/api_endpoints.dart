/// API endpoint path sabitleri.
/// baseUrl harcode edilmez — AppConfig.instance.baseUrl'den okunur (ApiClient'te).
/// Tüm path'ler /v1/ prefix'i içerir.
class ApiEndpoints {
  ApiEndpoints._();

  static const String _v1 = '/v1';

  // Auth
  static const auth = '$_v1/auth';
  static const deviceRegister = '$auth/device-register';
  static const totpLogin = '$auth/totp-login';
  static const serverTime = '$auth/server-time';
  static const logout = '$auth/logout';
  static const me = '$auth/me';

  // Products
  static const products = '$_v1/products';
  static const productsSearch = '$products/search';
  static String productDetail(int id) => '$products/$id';

  // Categories
  static const categories = '$_v1/categories';

  // Brands
  static const brands = '$_v1/brands';

  // Orders
  static const orders = '$_v1/orders';
  static String orderDetail(int id) => '$orders/$id';
  static String orderCancel(int id) => '$orders/$id/cancel';

  // Admin orders
  static const adminOrders = '$_v1/admin/orders';
  static String adminOrderStatus(int id) => '$adminOrders/$id/status';

  // Admin users
  static const adminUsers = '$_v1/admin/users';
  static String adminUserStatus(int id) => '$adminUsers/$id/status';

  // Admin products (kategori CRUD yok — API desteklemiyor)
  static const adminProducts = '$_v1/products';
  static String adminProductDetail(int id) => '$_v1/products/$id';

  // Profile
  static const profile = '$_v1/profile';

  // Addresses
  static const addresses = '$_v1/addresses';
  static String addressDetail(int id) => '$addresses/$id';
  static String addressSetDefault(int id) => '$addresses/$id/set-default';

  // Campaigns
  static const campaigns = '$_v1/campaigns';

  // Delivery
  static const deliveryOrders = '$_v1/delivery/orders';
  static String deliveryOrder(int id) => '$deliveryOrders/$id';
  static String deliveryAssign(int id) => '$deliveryOrders/$id/assign';
  static String deliveryOnTheWay(int id) => '$deliveryOrders/$id/on-the-way';
  static String deliveryDeliver(int id) => '$deliveryOrders/$id/deliver';

  // Notifications
  static const notifications = '$_v1/notifications';
  static const notificationsMarkRead = '$notifications/mark-read';
  static const notificationsUnreadCount = '$notifications/unread-count';
  static String notificationById(String id) => '$notifications/$id';

  // Devices (FCM token)
  static const devices = '$_v1/devices';

  // Analytics (admin)
  static const adminAnalyticsDashboard = '$_v1/admin/analytics/dashboard';
  static const adminAnalyticsRevenue = '$_v1/admin/analytics/revenue';
  static const adminAnalyticsTopCustomers =
      '$_v1/admin/analytics/top-customers';
  static const adminAnalyticsTopProducts = '$_v1/admin/analytics/top-products';
  static const adminAnalyticsCustomerGrowth =
      '$_v1/admin/analytics/customer-growth';

  // Subscriptions (backend hazırlandığında aktif)
  static const subscriptions = '$_v1/subscriptions';
  static String subscriptionDetail(int id) => '$subscriptions/$id';

  // Favorites (backend hazırlandığında aktif)
  static const favorites = '$_v1/favorites';
  static String favoriteDetail(String id) => '$favorites/$id';
}
