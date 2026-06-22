import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/cache/cache_keys.dart';
import 'package:nisa_ticaret/core/providers/core_providers.dart';
import 'package:nisa_ticaret/core/services/notification_service.dart';
import 'package:nisa_ticaret/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:nisa_ticaret/features/auth/data/models/api_user_model.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/auth/domain/repositories/i_auth_repository.dart';
import 'package:nisa_ticaret/features/auth/presentation/providers/auth_datasource_providers.dart';
import 'package:nisa_ticaret/features/auth/presentation/providers/auth_repository_provider.dart';
import 'package:nisa_ticaret/features/profile/data/providers/profile_data_providers.dart';

/// Login sonrası gidilecek route. Cart → phoneAuth akışında '/checkout' set edilir.
class _PostLoginRouteNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void set(String? route) => state = route;
}

final postLoginRouteProvider =
    NotifierProvider<_PostLoginRouteNotifier, String?>(
  _PostLoginRouteNotifier.new,
);

// ---------------------------------------------------------------------------
// authStateProvider — cihaz-bağlı TOTP + backend cache tabanlı.
// Firestore belge kontrolü YOK. Backend (Laravel API) kullanıcı bilgilerinin
// tek kaynağı; oturum varlığı Sanctum token'ın cache'de bulunmasıyla anlaşılır.
//
// authNotifierProvider da izlenir: login/logout sonrası step değişince
// stream yeniden çalışır ve cache'den güncel kullanıcıyı okur.
// ---------------------------------------------------------------------------
// Uygulama session'ında FCM token'ın backend'e kaydedilip kaydedilmediğini izler
bool _fcmTokenRegisteredThisSession = false;

final authStateProvider = StreamProvider<UserModel?>((ref) {
  // authNotifierProvider'ı izle → step değişince (özellikle done) stream yenilenir
  ref.watch(authNotifierProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  final local = ref.watch(authLocalDatasourceProvider);

  if (!local.hasToken) {
    _fcmTokenRegisteredThisSession = false;
    return Stream.value(null);
  }

  final userJson =
      cacheManager.getCachedData<Map<dynamic, dynamic>>(CacheKeys.userProfile);
  if (userJson == null) return Stream.value(null);
  try {
    final apiUser = ApiUserModel.fromJson(
      AuthLocalDatasource.deepStringify(userJson),
    );
    final user = UserModel.fromApiUser(apiUser);
    // Startup'ta mevcut session varsa da FCM token'ı backend'e kaydet (bir kez)
    if (!_fcmTokenRegisteredThisSession) {
      _fcmTokenRegisteredThisSession = true;
      notificationService
          .onUserSignedIn(dio: ref.read(apiClientProvider).dio)
          .ignore();
    }
    return Stream.value(user);
  } catch (e) {
    if (kDebugMode) debugPrint('[authStateProvider] cache parse hatası: $e');
    return Stream.value(null);
  }
});

// ---------------------------------------------------------------------------
// AuthStep — telefon auth akışının adımları
// Kullanıcıya OTP sorulmaz; tüm akış cihazda otomatik yürür.
// ---------------------------------------------------------------------------
enum AuthStep {
  idle,
  authenticating,
  creatingUser,
  done,
}

// ---------------------------------------------------------------------------
// AuthState — immutable durum nesnesi
// ---------------------------------------------------------------------------
@immutable
class AuthState {
  final AuthStep step;
  final String? error;

  const AuthState({
    this.step = AuthStep.idle,
    this.error,
  });

  AuthState copyWith({
    AuthStep? step,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      step: step ?? this.step,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// AuthNotifier — cihaz-bağlı TOTP auth akışı (SMS/OTP YOK)
// ---------------------------------------------------------------------------
class AuthNotifier extends Notifier<AuthState> {
  late final IAuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(apiAuthRepositoryProvider);
    return const AuthState();
  }

  // -------------------------------------------------------------------------
  // Telefon numarası ile sessiz kimlik doğrulama (TOTP)
  // -------------------------------------------------------------------------
  Future<void> authenticate(String phone) async {
    state = state.copyWith(step: AuthStep.authenticating, clearError: true);

    final result = await _repository.authenticateWithPhone(phone);

    result.fold(
      (failure) {
        state = state.copyWith(step: AuthStep.idle, error: failure.message);
      },
      (user) {
        // Backend yeni kullanıcıya varsayılan olarak 'User' ismi atar.
        if (user.name.trim().isEmpty || user.name.trim() == 'User') {
          state = state.copyWith(step: AuthStep.creatingUser, clearError: true);
        } else {
          notificationService
              .onUserSignedIn(dio: ref.read(apiClientProvider).dio)
              .ignore();
          state = state.copyWith(step: AuthStep.done, clearError: true);
        }
      },
    );
  }

  // -------------------------------------------------------------------------
  // Yeni kullanıcı profili oluştur — backend API'ye yazar (Firestore değil)
  // -------------------------------------------------------------------------
  Future<void> createUserProfile(String name, String phone) async {
    try {
      // 1. Profil güncelle — PUT /v1/profile
      final profileDs = ref.read(profileRemoteDatasourceProvider);
      await profileDs.updateProfile(name: name);

      // 2. /me ile güncel kullanıcıyı çek — backend phone fallback ile
      //    staff user bağlandıysa gerçek rolü buradan okuruz.
      final local = ref.read(authLocalDatasourceProvider);
      final remote = ref.read(authRemoteDatasourceProvider);
      try {
        final freshUser = await remote.getCurrentUser();
        await local.saveUser(freshUser);
        if (kDebugMode) debugPrint('[Auth] Register sonrası rol: ${freshUser.role}');
      } catch (_) {
        // /me başarısız olursa eski cache'i name ile güncelle
        final existing = local.getUser();
        if (existing != null) {
          await local.saveUser(ApiUserModel(
            id: existing.id,
            name: name,
            phone: phone,
            email: existing.email,
            role: existing.role,
            isActive: existing.isActive,
            profile: existing.profile,
          ));
        }
      }

      final dio = ref.read(apiClientProvider).dio;
      notificationService.onUserSignedIn(dio: dio).ignore();
      state = state.copyWith(step: AuthStep.done, clearError: true);
    } catch (e) {
      state = state.copyWith(
        step: AuthStep.idle,
        error: 'Profil oluşturulamadı. Tekrar deneyin.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Çıkış
  // -------------------------------------------------------------------------
  Future<void> signOut() async {
    await notificationService.onUserSignedOut();

    // Backend logout + Sanctum token/cache temizle (TOTP secret cihazda kalır
    // — aynı telefonla tekrar girişte sessiz totp-login yapılabilsin).
    await _repository.logout();

    // Kullanıcıya özel tüm cache'leri temizle
    final cache = ref.read(cacheManagerProvider);
    await Future.wait([
      cache.invalidateByPrefix(CacheKeys.addresses),
      cache.invalidate(CacheKeys.orders),
      cache.invalidate(CacheKeys.userProfile),
      cache.invalidate(CacheKeys.notifications),
      cache.invalidate(CacheKeys.notificationsUnreadCount),
    ]);

    state = const AuthState();
  }

  // -------------------------------------------------------------------------
  // State'i sıfırla (yeni akış için)
  // -------------------------------------------------------------------------
  void reset() {
    state = const AuthState();
  }
}

// ---------------------------------------------------------------------------
// authNotifierProvider — global erişim noktası (public API korunuyor)
// ---------------------------------------------------------------------------
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
