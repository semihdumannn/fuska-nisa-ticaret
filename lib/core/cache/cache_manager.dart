import 'package:hive_flutter/hive_flutter.dart';

/// Sanctum token ve veri caching yoneten manager.
/// CacheService (Firestore icin) ile paralel calisir — bu sinif
/// Laravel API token'larini ve API yanitlarini yonetir.
class CacheManager {
  static const String _tokenBoxName = 'auth_tokens';
  static const String _dataBoxName = 'cached_data';
  static const String _tokenKey = 'sanctum_token';

  late Box<String> _tokenBox;
  late Box<dynamic> _dataBox;
  bool _initialized = false;

  /// Hive.initFlutter() onceden cagirilmis olmali (CacheService.init icinde yapilir).
  Future<void> init() async {
    if (_initialized) return;
    _tokenBox = await Hive.openBox<String>(_tokenBoxName);
    _dataBox = await Hive.openBox<dynamic>(_dataBoxName);
    _initialized = true;
  }

  // ============ Token methods ============

  Future<void> saveToken(String token) async {
    await _tokenBox.put(_tokenKey, token);
  }

  String? getToken() {
    if (!_initialized) return null;
    return _tokenBox.get(_tokenKey);
  }

  Future<void> clearToken() async {
    await _tokenBox.delete(_tokenKey);
  }

  bool get hasToken {
    final token = getToken();
    return token != null && token.isNotEmpty;
  }

  // ============ Data cache methods ============

  Future<void> cacheData(String key, dynamic data, {Duration? ttl}) async {
    await _dataBox.put(key, {
      'data': data,
      'cachedAt': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttl?.inMilliseconds,
    });
  }

  T? getCachedData<T>(String key) {
    if (!_initialized) return null;
    final cached = _dataBox.get(key) as Map?;
    if (cached == null) return null;

    final cachedAt = cached['cachedAt'] as int?;
    final ttl = cached['ttl'] as int?;

    if (cachedAt != null && ttl != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - cachedAt > ttl) {
        _dataBox.delete(key);
        return null;
      }
    }

    return cached['data'] as T?;
  }

  Future<void> invalidate(String key) async {
    await _dataBox.delete(key);
  }

  /// Verilen prefix ile başlayan tüm cache key'lerini siler.
  Future<void> invalidateByPrefix(String prefix) async {
    final keysToDelete = _dataBox.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
        .toList();
    await _dataBox.deleteAll(keysToDelete);
  }

}
