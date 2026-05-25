/// API endpoint path sabitleri.
/// baseUrl harcode edilmez — AppConfig.instance.baseUrl'den okunur (ApiClient'te).
class ApiEndpoints {
  ApiEndpoints._();

  // Auth endpoints
  static const auth = '/auth';
  static const firebaseLogin = '$auth/firebase-login';
  static const logout = '$auth/logout';
  static const me = '$auth/me';

  // Product endpoints
  static const products = '/products';
  static String productDetail(int id) => '$products/$id';

  // Category endpoints
  static const categories = '/categories';

  // Brand endpoints
  static const brands = '/brands';

  // Order endpoints
  static const orders = '/orders';
  static String orderDetail(int id) => '$orders/$id';

  // Profile endpoints
  static const profile = '/profile';
  static const addresses = '/addresses';

  // Config endpoint
  static const config = '/config';

  // Coupon endpoints
  static const coupons = '/coupons';
  static const validateCoupon = '$coupons/validate';
}
