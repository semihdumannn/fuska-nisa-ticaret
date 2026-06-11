import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';
import '../models/api_user_model.dart';

class AuthLocalDatasource {
  final CacheManager _cacheManager;
  final FlutterSecureStorage _secureStorage;

  static const _totpSecretKey = 'totp_secret';
  static const _totpPhoneKey = 'totp_phone';

  AuthLocalDatasource(
    this._cacheManager, {
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _cacheManager.saveToken(token);
  }

  String? getToken() => _cacheManager.getToken();

  Future<void> clearToken() async {
    await _cacheManager.clearToken();
  }

  bool get hasToken => _cacheManager.hasToken;

  Future<void> saveUser(ApiUserModel user) async {
    await _cacheManager.cacheData(
      CacheKeys.userProfile,
      user.toJson(),
      ttl: CacheKeys.userProfileTtl,
    );
  }

  ApiUserModel? getUser() {
    final json = _cacheManager
        .getCachedData<Map<dynamic, dynamic>>(CacheKeys.userProfile);
    if (json == null) return null;
    try {
      return ApiUserModel.fromJson(deepStringify(json));
    } catch (_) {
      return null;
    }
  }

  /// Hive'dan gelen `Map<dynamic, dynamic>` hiyerarşisini `Map<String, dynamic>`'e dönüştürür.
  static Map<String, dynamic> deepStringify(Map map) {
    return map.map((k, v) {
      final key = k.toString();
      if (v is Map) return MapEntry(key, deepStringify(v));
      if (v is List) return MapEntry(key, _deepStringifyList(v));
      return MapEntry(key, v);
    });
  }

  static List<dynamic> _deepStringifyList(List list) {
    return list.map((v) {
      if (v is Map) return deepStringify(v);
      if (v is List) return _deepStringifyList(v);
      return v;
    }).toList();
  }

  Future<void> clearUser() async {
    await _cacheManager.invalidate(CacheKeys.userProfile);
  }

  // ── TOTP secret & telefon (cihaz-bağlı, SMS'siz auth) ─────────────────────

  Future<void> saveTotpCredentials({
    required String phone,
    required String secret,
  }) async {
    await _secureStorage.write(key: _totpSecretKey, value: secret);
    await _secureStorage.write(key: _totpPhoneKey, value: phone);
  }

  Future<String?> getTotpSecret() => _secureStorage.read(key: _totpSecretKey);

  Future<String?> getSavedPhone() => _secureStorage.read(key: _totpPhoneKey);

  Future<void> clearTotpCredentials() async {
    await _secureStorage.delete(key: _totpSecretKey);
    await _secureStorage.delete(key: _totpPhoneKey);
  }

  Future<bool> get hasTotpCredentials async =>
      (await getTotpSecret()) != null;
}
