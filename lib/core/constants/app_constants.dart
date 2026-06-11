import 'package:nisa_ticaret/core/config/app_config.dart';

export 'package:nisa_ticaret/features/orders/domain/entities/order_entity.dart'
    show OrderStatus;

class AppConstants {
  // App Info
  static const String appName = 'Nisa Ticaret';
  static const String appSlogan = 'Su ve Meşrubat Dağıtımı';
  static const String serviceArea = 'Balıkesir';  // Hizmet bölgesi
  // AppConfig.instance.whatsappNumber kullan — Firebase Remote Config'den gelir.
  // ignore: deprecated_member_use_from_same_package
  @Deprecated('AppConfig.instance.whatsappNumber kullan')
  static const String whatsappNumberLegacy = '+905551234567';

  /// WhatsApp numarasi Firebase Remote Config'den gelir.
  /// Kullanim: AppConfig.instance.whatsappNumber
  static String get whatsappNumber => _AppConfigProxy.whatsappNumber;

  // Firebase Collections
  static const String usersCollection = 'users';
  // customers koleksiyonu = users koleksiyonunun role:'customer' alt kumesi
  static const String customersCollection = 'users';
  // customers/{id}/addresses subcollection
  static const String customerAddressesSubcollection = 'addresses';
  static const String productsCollection = 'products';
  static const String variantsCollection = 'variants';
  static const String brandsCollection = 'brands';
  static const String categoriesCollection = 'categories';
  static const String ordersCollection = 'orders';
  static const String addressesCollection = 'addresses';
  static const String notificationsCollection = 'notifications';
  static const String cartsCollection = 'carts';
  static const String settingsCollection = 'settings';
  static const String appSettingsDoc = 'app';

  // Storage Paths
  static const String productsStoragePath = 'products';
  static const String categoriesStoragePath = 'categories';
  static const String bannersStoragePath = 'banners';

  // Shared Preferences Keys
  static const String keyOnboardingSeen = 'onboarding_seen';
  static const String keyUserId = 'user_id';
  static const String keyUserRole = 'user_role';
  static const String keyFcmToken = 'fcm_token';

  // Pagination
  static const int pageSize = 20;

  // Timeouts
  static const int connectionTimeout = 30000;

  // Map
  static const double defaultLat = 39.6484; // Balıkesir
  static const double defaultLng = 27.8826;
  static const double defaultZoom = 13.0;

  // Defaults
  static const String defaultCity = 'Balıkesir';
}

enum UserRole {
  customer,
  fieldAgent,
  delivery,
  admin;

  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Müşteri';
      case UserRole.fieldAgent:
        return 'Saha Personeli';
      case UserRole.delivery:
        return 'Teslimat';
      case UserRole.admin:
        return 'Admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'field_agent':
        return UserRole.fieldAgent;
      case 'delivery':
        return UserRole.delivery;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.customer;
    }
  }

  String get value {
    switch (this) {
      case UserRole.customer:
        return 'customer';
      case UserRole.fieldAgent:
        return 'field_agent';
      case UserRole.delivery:
        return 'delivery';
      case UserRole.admin:
        return 'admin';
    }
  }
}

enum PaymentMethod {
  cash,
  cardOnDelivery,
  onlineCard;

  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Kapıda Nakit';
      case PaymentMethod.cardOnDelivery:
        return 'Kapıda Kredi Kartı';
      case PaymentMethod.onlineCard:
        return 'Diğer Kredi Kartı';
    }
  }

  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.cardOnDelivery:
        return 'card_on_delivery';
      case PaymentMethod.onlineCard:
        return 'online_card';
    }
  }
}

enum OrderSource {
  customerApp,
  fieldAgent,
  phone;

  String get value {
    switch (this) {
      case OrderSource.customerApp:
        return 'customer_app';
      case OrderSource.fieldAgent:
        return 'field_agent';
      case OrderSource.phone:
        return 'phone';
    }
  }
}

/// AppConstants icindeki get property'leri icin AppConfig'e koprü.
/// Dogrudan AppConfig.instance kullanimini tercih edin.
class _AppConfigProxy {
  static String get whatsappNumber => AppConfig.instance.whatsappNumber;
}
