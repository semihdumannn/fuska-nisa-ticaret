import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CacheStrategy {
  /// Offline olması halinde cache, online ise network
  cacheFirst,
  
  /// Network'ten çek, başarısızsa cache'den
  networkFirst,
  
  /// Her seferinde network'ten
  networkOnly,
  
  /// Cache göster, arka planda network'ten güncelle
  staleWhileRevalidate,
}

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
    debugPrint('✅ Cache Service initialized');
  }
  
  // ============ Write ============
  Future<void> setString(String key, String value) async {
    try {
      await _box.put(key, value);
    } catch (e) {
      debugPrint('❌ Cache write error ($key): $e');
    }
  }
  
  Future<void> setJson<T>(String key, T value) async {
    try {
      final json = jsonEncode(value);
      await _box.put(key, json);
      _setCacheTime(key);
    } catch (e) {
      debugPrint('❌ Cache JSON write error ($key): $e');
    }
  }
  
  Future<void> setList<T>(String key, List<T> values) async {
    try {
      final json = jsonEncode(values);
      await _box.put(key, json);
      _setCacheTime(key);
    } catch (e) {
      debugPrint('❌ Cache list write error ($key): $e');
    }
  }
  
  // ============ Read ============
  String? getString(String key) {
    try {
      return _box.get(key);
    } catch (e) {
      debugPrint('❌ Cache read error ($key): $e');
      return null;
    }
  }
  
  T? getJson<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final json = _box.get(key);
      if (json == null) return null;
      return fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('❌ Cache JSON read error ($key): $e');
      return null;
    }
  }
  
  List<T>? getList<T>(String key, T Function(Map<String, dynamic>) fromJson) {
    try {
      final json = _box.get(key);
      if (json == null) return null;
      final list = jsonDecode(json) as List;
      return list.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('❌ Cache list read error ($key): $e');
      return null;
    }
  }
  
  // ============ TTL (Time To Live) ============
  void _setCacheTime(String key) {
    _prefs.setInt('${key}_time', DateTime.now().millisecondsSinceEpoch);
  }
  
  bool isExpired(String key, Duration ttl) {
    final timestamp = _prefs.getInt('${key}_time');
    if (timestamp == null) return true;
    
    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cachedTime) > ttl;
  }
  
  bool isFresh(String key, Duration ttl) => !isExpired(key, ttl);
  
  // ============ Clear ============
  Future<void> clear(String key) async {
    try {
      await _box.delete(key);
      await _prefs.remove('${key}_time');
    } catch (e) {
      debugPrint('❌ Cache clear error ($key): $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _box.clear();
      await _prefs.clear();
    } catch (e) {
      debugPrint('❌ Cache clear all error: $e');
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
      debugPrint('❌ Cache clearByPattern error ($prefix): $e');
    }
  }

  // ============ Utility ============
  bool exists(String key) => _box.containsKey(key);

  int get cacheSize => _box.length;

  /// Cache yazım zamanını döndür — DataVersionProvider karşılaştırması için.
  DateTime? getCacheTime(String key) {
    final ts = _prefs.getInt('${key}_time');
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }
}

/// Singleton
final cacheService = CacheService();
