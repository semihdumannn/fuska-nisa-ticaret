/// API endpoint path sabitleri.
/// baseUrl harcode edilmez — AppConfig.instance.baseUrl'den okunur (ApiClient'te).
/// Tüm path'ler /v1/ prefix'i içerir.
class ApiEndpoints {
  ApiEndpoints._();

  static const String _v1 = '/v1';

  // Auth
  static const auth = '$_v1/auth';
  static const firebaseLogin = '$auth/firebase-login';
  static const logout = '$auth/logout';
  static const me = '$auth/me';

  // Products
  static const products = '$_v1/products';
  static const productsSearch = '$products/search';
  static String productDetail(int id) => '$products/$id';

  // Categories
  static const categories = '$_v1/categories';
  static String categoryProducts(int id) => '$categories/$id/products';

  // Brands
  static const brands = '$_v1/brands';
  static String brandProducts(int id) => '$brands/$id/products';

  // Orders
  static const orders = '$_v1/orders';
  static String orderDetail(int id) => '$orders/$id';
  static String orderCancel(int id) => '$orders/$id/cancel';
  static String orderPay(int id) => '$orders/$id/pay';

  // Admin orders
  static const adminOrders = '$_v1/admin/orders';
  static String adminOrderStatus(int id) => '$adminOrders/$id/status';

  // Profile
  static const profile = '$_v1/profile';
  static const profileAvatar = '$profile/avatar';

  // Addresses
  static const addresses = '$_v1/addresses';
  static String addressDetail(int id) => '$addresses/$id';
  static String addressSetDefault(int id) => '$addresses/$id/set-default';

  // Config
  static const config = '$_v1/config';

  // Coupons
  static const coupons = '$_v1/coupons';
  static const validateCoupon = '$coupons/validate';

  // Campaigns
  static const campaigns = '$_v1/campaigns';

  // Cart (server-side)
  static const cart = '$_v1/cart';
  static const cartItems = '$cart/items';
  static String cartItem(int id) => '$cartItems/$id';

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
  static const adminAnalyticsOrderStatuses =
      '$_v1/admin/analytics/order-statuses';
  static const adminAnalyticsRevenue = '$_v1/admin/analytics/revenue';
  static const adminAnalyticsTopCustomers =
      '$_v1/admin/analytics/top-customers';
  static const adminAnalyticsTopProducts = '$_v1/admin/analytics/top-products';

  // Inventory
  static const inventoryWarehouses = '$_v1/inventory/warehouses';
  static String inventoryStock(int productId) =>
      '$_v1/inventory/stock/$productId';
  static const inventoryMovements = '$_v1/inventory/movements';
  static const inventoryLowStock = '$_v1/inventory/low-stock';
  static const inventoryReceive = '$_v1/inventory/receive';
  static const inventoryDispatch = '$_v1/inventory/dispatch';
  static const inventoryAdjust = '$_v1/inventory/adjust';
  static const inventoryTransfer = '$_v1/inventory/transfer';

  // Payment
  static const paymentCallback = '$_v1/payment/callback';

  // Health
  static const health = '$_v1/health';
}
