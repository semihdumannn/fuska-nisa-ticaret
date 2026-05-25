import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../cache/cache_manager.dart';
import '../network/api_client.dart';
import '../../features/auth/data/datasources/firebase_auth_datasource.dart';

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

/// Firebase Auth instance
final firebaseAuthInstanceProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firebase Auth Datasource
final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource(ref.watch(firebaseAuthInstanceProvider));
});
