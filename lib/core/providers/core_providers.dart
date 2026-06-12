import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/cache_manager.dart';
import '../network/api_client.dart';
import '../services/totp_service.dart';

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
