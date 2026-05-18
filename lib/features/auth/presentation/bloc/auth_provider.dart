import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nisa_ticaret/core/services/notification_service.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/auth/data/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// authRepositoryProvider — singleton repository
// ---------------------------------------------------------------------------
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ---------------------------------------------------------------------------
// authStateProvider — mevcut, korunuyor
// Artık doğrudan Firebase yerine repository stream'ini kullanıyor.
// ---------------------------------------------------------------------------
final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).userStream;
});

// ---------------------------------------------------------------------------
// AuthStep — telefon auth akışının adımları
// ---------------------------------------------------------------------------
enum AuthStep {
  idle,
  sendingCode,
  codeSent,
  verifyingCode,
  creatingUser,
  done,
}

// ---------------------------------------------------------------------------
// AuthState — immutable durum nesnesi
// ---------------------------------------------------------------------------
@immutable
class AuthState {
  final AuthStep step;
  final String? verificationId;
  final String? error;

  const AuthState({
    this.step = AuthStep.idle,
    this.verificationId,
    this.error,
  });

  AuthState copyWith({
    AuthStep? step,
    String? verificationId,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      step: step ?? this.step,
      verificationId: verificationId ?? this.verificationId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ---------------------------------------------------------------------------
// AuthNotifier — tüm telefon auth işlemleri (Firebase çağrısı YOK)
// ---------------------------------------------------------------------------
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.read(authRepositoryProvider);
    return const AuthState();
  }

  // -------------------------------------------------------------------------
  // Telefon numarasına SMS kodu gönder
  // -------------------------------------------------------------------------
  Future<void> sendPhoneCode(String phone) async {
    state = state.copyWith(step: AuthStep.sendingCode, clearError: true);

    try {
      await _repository.sendVerificationCode(
        phone: phone,
        onCodeSent: (verificationId, _) {
          state = state.copyWith(
            step: AuthStep.codeSent,
            verificationId: verificationId,
            clearError: true,
          );
        },
        onError: (error) {
          state = state.copyWith(step: AuthStep.idle, error: error);
        },
        onAutoVerified: (credential) {
          _handleAutoVerify(credential);
        },
      );
    } on AuthException catch (e) {
      state = state.copyWith(step: AuthStep.idle, error: e.message);
    } catch (_) {
      state = state.copyWith(
        step: AuthStep.idle,
        error: 'Bir hata oluştu. Tekrar deneyin.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Kullanıcının girdiği SMS kodunu doğrula
  // -------------------------------------------------------------------------
  Future<void> verifyOTP(String smsCode) async {
    if (state.verificationId == null) return;

    state = state.copyWith(step: AuthStep.verifyingCode, clearError: true);

    try {
      final result = await _repository.verifyOTP(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );

      _handleUserCheckResult(result);
    } on AuthException catch (e) {
      state = state.copyWith(step: AuthStep.idle, error: e.message);
    } catch (_) {
      state = state.copyWith(
        step: AuthStep.idle,
        error: 'Bir hata oluştu. Tekrar deneyin.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // Yeni kullanıcı profili oluştur
  // -------------------------------------------------------------------------
  Future<void> createUserProfile(String name, String phone) async {
    final uid = _repository.currentUser?.uid;
    if (uid == null) {
      state = state.copyWith(
        step: AuthStep.idle,
        error: 'Oturum bulunamadı. Tekrar giriş yapın.',
      );
      return;
    }

    try {
      await _repository.createUserProfile(
        uid: uid,
        name: name,
        phone: phone,
      );
      // Profil oluşturulunca FCM token'ı Firestore'a kaydet
      notificationService.onUserSignedIn().ignore();
      state = state.copyWith(step: AuthStep.done, clearError: true);
    } on AuthException catch (e) {
      state = state.copyWith(step: AuthStep.idle, error: e.message);
    } catch (_) {
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
    // Çıkış yapmadan önce FCM token'ı temizle
    await notificationService.onUserSignedOut();

    try {
      await _repository.signOut();
    } on AuthException catch (e) {
      state = state.copyWith(error: e.message);
      return;
    } catch (_) {
      // Sessizce devam et
    }
    state = const AuthState();
  }

  // -------------------------------------------------------------------------
  // State'i sıfırla (yeni akış için)
  // -------------------------------------------------------------------------
  void reset() {
    state = const AuthState();
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  /// Android otomatik doğrulama: credential geldiğinde repository'ye ilet
  void _handleAutoVerify(PhoneAuthCredential credential) {
    _repository.signInWithCredential(credential).then((result) {
      _handleUserCheckResult(result);
    }).catchError((e) {
      final message = e is AuthException
          ? e.message
          : 'Otomatik doğrulama başarısız.';
      state = state.copyWith(step: AuthStep.idle, error: message);
    });
  }

  /// Repository'den dönen UserCheckResult'e göre state'i ayarla
  void _handleUserCheckResult(UserCheckResult result) {
    switch (result) {
      case UserCheckResult.existingUser:
        // Giriş başarılı — FCM token'ı yenile (token rotasyonu için)
        notificationService.onUserSignedIn().ignore();
        state = state.copyWith(step: AuthStep.done, clearError: true);
      case UserCheckResult.newUser:
        state = state.copyWith(step: AuthStep.creatingUser, clearError: true);
    }
  }
}

// ---------------------------------------------------------------------------
// authNotifierProvider — global erişim noktası (public API korunuyor)
// ---------------------------------------------------------------------------
final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
