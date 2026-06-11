import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/cache_manager.dart';
import '../cache/cache_keys.dart';
import '../network/api_client.dart';
import '../services/totp_service.dart';
import '../../features/auth/data/models/api_user_model.dart';

/// CacheManager - main.dart'ta override edilir
final cacheManagerProvider = Provider<CacheManager>((ref) {
  throw UnimplementedError(
      'CacheManager main.dart icinde override edilmeli');
});

/// Dio API Client
final apiClientProvider = Provider<ApiClient>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return ApiClient(cacheManager);
});

/// TOTP servisi — cihaz-bağlı OTP'siz auth için kod üretimi.
final totpServiceProvider = Provider<TotpService>((ref) {
  final dio = ref.watch(apiClientProvider).dio;
  return TotpService(dio);
});

/// Backend (Laravel API) kullanıcı rolü — login sonrası cache'den okunur.
/// null → henüz giriş yapılmamış veya token exchange başarısız.
final backendUserRoleProvider = Provider<String?>((ref) {
  final cache = ref.watch(cacheManagerProvider);
  final userJson = cache.getCachedData<Map<dynamic, dynamic>>(CacheKeys.userProfile);
  if (userJson == null) return null;
  try {
    final user = ApiUserModel.fromJson(userJson.map((k, v) => MapEntry(k.toString(), v)));
    return user.role;
  } catch (_) {
    return null;
  }
});
