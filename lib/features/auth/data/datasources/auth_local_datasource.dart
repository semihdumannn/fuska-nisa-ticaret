import '../../../../core/cache/cache_keys.dart';
import '../../../../core/cache/cache_manager.dart';
import '../models/api_user_model.dart';

class AuthLocalDatasource {
  final CacheManager _cacheManager;

  AuthLocalDatasource(this._cacheManager);

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
    return ApiUserModel.fromJson(
        json.map((k, v) => MapEntry(k.toString(), v)));
  }

  Future<void> clearUser() async {
    await _cacheManager.invalidate(CacheKeys.userProfile);
  }
}
