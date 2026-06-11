import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Tüm app configuration'ı Remote Config'den yönet
class AppConfig {
  static final _instance = AppConfig._();
  late final FirebaseRemoteConfig _remoteConfig;

  factory AppConfig() => _instance;

  /// Statik singleton erişimi: AppConfig.instance.xxx
  static AppConfig get instance => _instance;

  AppConfig._();
  
  /// Initialize remote config
  /// main.dart'ta Firebase.initializeApp() sonrasında çağrıl
  Future<void> init() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    
    // Varsayılan değerler (app'in offline çalışması için)
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    
    // Varsayılan değerler - Firebase Config'te ayarlar bunları
    await _remoteConfig.setDefaults({
      // API
      'api_baseUrl': 'https://semihdumannn-nisa-ticaret-panel.hf.space/api',
      'api_timeout': 30,
      
      // Firebase
      'firebase_projectId': 'nisa-ticaret',
      'firebase_storageBucket': 'nisa-ticaret.appspot.com',
      
      // Features (Future)
      'features_whatsappEnabled': true,
      'features_smsOtpEnabled': true,
      'features_onlinePaymentEnabled': false,
      
      // Cache TTL (saniye)
      'cache_categoriesTtl': 86400,      // 24 saat
      'cache_productsTtl': 21600,        // 6 saat
      'cache_ordersTtl': 3600,           // 1 saat
      
      // Limits
      'limits_maxCartItems': 100,
      'limits_minOrderAmount': 200.0,
      'limits_maxDeliveryDistance': 15.0,
      
      // Version Control
      'app_currentVersion': '1.0.0',
      'app_forceUpdateVersion': '1.0.0',  // Altında kalırsa update zorunlu
      
      // Business
      'whatsapp_number': '+905551234567',
      'min_order_amount': 200.0,

      // API Endpoints
      'api_coupon_endpoint': '/coupons/validate',
    });
    
    // Fetch & activate
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('✅ Remote Config loaded');
    } catch (e) {
      debugPrint('⚠️ Remote Config fetch failed: $e');
      debugPrint('   Using default values from setDefaults()');
    }
  }
  
  // ============ API & Networking ============
  String get baseUrl => _remoteConfig.getString('api_baseUrl');
  int get apiTimeout => _remoteConfig.getInt('api_timeout');
  String get couponEndpoint => _remoteConfig.getString('api_coupon_endpoint');

  /// Medya/görsel base URL'i. baseUrl sonundaki /api kaldırılır.
  String get storageBaseUrl {
    final base = baseUrl;
    if (base.endsWith('/api')) return base.substring(0, base.length - 4);
    final lastSlash = base.lastIndexOf('/api');
    if (lastSlash != -1) return base.substring(0, lastSlash);
    return base;
  }

  /// Göreli URL'leri mutlak URL'e çevirir. Zaten http ile başlıyorsa dokunmaz.
  String resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = storageBaseUrl;
    return path.startsWith('/') ? '$base$path' : '$base/$path';
  }
  
  // ============ Features ============
  bool get isWhatsappEnabled => _remoteConfig.getBool('features_whatsappEnabled');
  bool get isSmsOtpEnabled => _remoteConfig.getBool('features_smsOtpEnabled');
  bool get isOnlinePaymentEnabled => _remoteConfig.getBool('features_onlinePaymentEnabled');
  
  // ============ Cache Durations (saniye) ============
  int get categoriesCacheTtl => _remoteConfig.getInt('cache_categoriesTtl');
  int get productsCacheTtl => _remoteConfig.getInt('cache_productsTtl');
  int get ordersCacheTtl => _remoteConfig.getInt('cache_ordersTtl');
  
  Duration get categoriesCacheDuration => Duration(seconds: categoriesCacheTtl);
  Duration get productsCacheDuration => Duration(seconds: productsCacheTtl);
  Duration get ordersCacheDuration => Duration(seconds: ordersCacheTtl);
  
  // ============ Business ============
  String get whatsappNumber => _remoteConfig.getString('whatsapp_number');
  double get minOrderAmount => _remoteConfig.getDouble('limits_minOrderAmount');
  
  // ============ Version Control ============
  String get currentVersion => _remoteConfig.getString('app_currentVersion');
  String get forceUpdateVersion => _remoteConfig.getString('app_forceUpdateVersion');
  
  // ============ Firebase ============
  String get firebaseProjectId => _remoteConfig.getString('firebase_projectId');
  String get firebaseStorageBucket => _remoteConfig.getString('firebase_storageBucket');
  
  // ============ Limits ============
  int get maxCartItems => _remoteConfig.getInt('limits_maxCartItems');
  double get maxDeliveryDistance => _remoteConfig.getDouble('limits_maxDeliveryDistance');
}

/// Singleton instance
final appConfig = AppConfig();
