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

    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    await _remoteConfig.setDefaults({
      // API
      'api_baseUrl': 'https://semihdumannn-nisa-ticaret-panel.hf.space/api',
      'api_timeout': 30,

      // Features
      'features_whatsappEnabled': true,

      // Cache TTL (saniye)
      'cache_categoriesTtl': 86400,      // 24 saat
      'cache_productsTtl': 21600,        // 6 saat
      'cache_ordersTtl': 3600,           // 1 saat

      // Limits
      'limits_maxCartItems': 100,
      'limits_minOrderAmount': 200.0,

      // Version Control
      'app_currentVersion': '1.0.0',
      'app_forceUpdateVersion': '1.0.0',

      // Business
      'whatsapp_number': '+905551234567',
      'min_order_amount': 200.0,
    });

    try {
      await _remoteConfig.fetchAndActivate();
      if (kDebugMode) debugPrint('✅ Remote Config loaded');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Remote Config fetch failed: $e');
      if (kDebugMode) debugPrint('   Using default values from setDefaults()');
    }
  }

  // ============ API & Networking ============
  String get baseUrl => _remoteConfig.getString('api_baseUrl');
  int get apiTimeout => _remoteConfig.getInt('api_timeout');

  // ============ Features ============
  bool get isWhatsappEnabled => _remoteConfig.getBool('features_whatsappEnabled');

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

  // ============ Limits ============
  int get maxCartItems => _remoteConfig.getInt('limits_maxCartItems');
}

/// Singleton instance
final appConfig = AppConfig();
