import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local caching service - Hive + SharedPreferences wrapper
class CacheService {
  static final _instance = CacheService._();
  late Box<String> _box;
  late SharedPreferences _prefs;
  
  factory CacheService() => _instance;
  CacheService._();
  
  /// Initialize caching (main.dart'ta call)
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>('app_cache');
    _prefs = await SharedPreferences.getInstance();
    if (kDebugMode) debugPrint('✅ Cache Service initialized');
  }
  
  // ============ Read ============
  String? getString(String key) {
    try {
      return _box.get(key);
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Cache read error ($key): $e');
      return null;
    }
  }

  // ============ Clear ============
  Future<void> clear(String key) async {
    try {
      await _box.delete(key);
      await _prefs.remove('${key}_time');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Cache clear error ($key): $e');
    }
  }

  /// Prefix ile başlayan tüm anahtarları temizle (örn. 'products_cat_').
  Future<void> clearByPattern(String prefix) async {
    try {
      final keys = _box.keys
          .whereType<String>()
          .where((k) => k.startsWith(prefix))
          .toList();
      for (final k in keys) {
        await _box.delete(k);
        await _prefs.remove('${k}_time');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Cache clearByPattern error ($prefix): $e');
    }
  }

  /// Cache yazım zamanını döndür — DataVersionProvider karşılaştırması için.
  DateTime? getCacheTime(String key) {
    final ts = _prefs.getInt('${key}_time');
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }
}

/// Singleton
final cacheService = CacheService();
