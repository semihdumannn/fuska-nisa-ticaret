import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';

// ---------------------------------------------------------------------------
// AuthException — tüm auth katmanı hataları bu tip üzerinden iletilir
// ---------------------------------------------------------------------------
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => 'AuthException($code): $message';
}

// ---------------------------------------------------------------------------
// UserCheckResult — verifyOTP sonrası kullanıcı tipi
// ---------------------------------------------------------------------------
enum UserCheckResult { existingUser, newUser }

// ---------------------------------------------------------------------------
// AuthRepository — tüm Firebase Auth + Firestore kullanıcı işlemleri
// ---------------------------------------------------------------------------
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Stream ────────────────────────────────────────────────────────────────

  /// Firebase Auth token değişimlerini UserModel stream'ine dönüştürür.
  /// FirebaseAuth SDK token'ı otomatik persist ettiğinden (Android:
  /// SharedPreferences, iOS: Keychain) ek bir kayıt gerekmez.
  Stream<UserModel?> get userStream {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      try {
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(firebaseUser.uid)
            .get();
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      } catch (e) {
        debugPrint('AuthRepository.userStream: profil çekilemedi: $e');
        return null;
      }
    });
  }

  // ── Session bilgisi ───────────────────────────────────────────────────────

  /// Mevcut Firebase Auth kullanıcısı (null = oturum yok)
  User? get currentUser => _auth.currentUser;

  /// Firebase Auth oturumu açık mı?
  bool get isSignedIn => _auth.currentUser != null;

  /// App açılışında kalıcı oturum mevcut mu?
  /// Firebase Auth kendi token'ını persist ettiğinden bu yalnızca bilgi amaçlı.
  bool get hasPersistedSession => _auth.currentUser != null;

  // ── Phone Auth ────────────────────────────────────────────────────────────

  /// Telefon numarasına SMS doğrulama kodu gönderir.
  ///
  /// Callback'ler constructor yerine parametre olarak alınır, böylece
  /// [AuthNotifier] state güncellemelerini kendi içinde yapabilir ve
  /// test ortamında mock callback geçilebilir.
  Future<void> sendVerificationCode({
    required String phone,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String error) onError,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          // Android otomatik doğrulama (SMS izni ile)
          onAutoVerified(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('🔴 Firebase verificationFailed — code: ${e.code} | message: ${e.message}');
          onError(_mapFirebaseError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout: verificationId geçerli kalmaya devam eder,
          // bildirim gerekmez.
        },
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      throw const AuthException('SMS gönderilemedi. Tekrar deneyin.');
    }
  }

  /// Kullanıcının girdiği OTP kodunu doğrular ve Firebase'e giriş yapar.
  ///
  /// Döner: Firestore'da kayıt varsa [UserCheckResult.existingUser],
  /// yoksa [UserCheckResult.newUser].
  ///
  /// Hata durumunda [AuthException] fırlatır.
  Future<UserCheckResult> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      return doc.exists ? UserCheckResult.existingUser : UserCheckResult.newUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      throw const AuthException('Doğrulama başarısız. Tekrar deneyin.');
    }
  }

  /// OTP doğrulamasında Android otomatik credential geldiğinde kullanılır.
  /// [verifyOTP] ile aynı iş mantığını işler, farklı credential kaynağı.
  Future<UserCheckResult> signInWithCredential(
    PhoneAuthCredential credential,
  ) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final uid = userCredential.user!.uid;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      return doc.exists ? UserCheckResult.existingUser : UserCheckResult.newUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      throw const AuthException('Giriş başarısız. Tekrar deneyin.');
    }
  }

  // ── User Profile ──────────────────────────────────────────────────────────

  /// Yeni kullanıcı profilini Firestore'a yazar.
  ///
  /// `users/{uid}` dokümanı `set` ile oluşturulur. Firestore security rule'da
  /// `allow create: if isOwner(userId)` tanımlı olduğundan kullanıcı kendi
  /// dokümanını oluşturabilir.
  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String phone,
  }) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set({
        'name': name,
        'phone': phone,
        'role': UserRole.customer.value,
        'isActive': true,
        'totalOrders': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e), code: e.code);
    } catch (e) {
      throw const AuthException(
        'Profil oluşturulamadı. Tekrar deneyin.',
        code: 'profile-create-failed',
      );
    }
  }

  /// Mevcut kullanıcı profilini Firestore'dan çeker.
  ///
  /// Kullanıcı bulunamazsa veya doküman yoksa null döner.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw const AuthException(
        'Profil yüklenemedi.',
        code: 'profile-fetch-failed',
      );
    }
  }

  /// FCM token'ını kullanıcı dokümanına günceller.
  ///
  /// Firestore'da `updatedAt` field'ı da güncellenir.
  Future<void> updateFcmToken(String uid, String token) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // FCM token güncelleme kritik değil; sessizce logla
      debugPrint('AuthRepository.updateFcmToken: token kaydedilemedi: $e');
    }
  }

  // ── Session ───────────────────────────────────────────────────────────────

  /// Mevcut oturumu kapatır.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw const AuthException(
        'Çıkış yapılamadı. Tekrar deneyin.',
        code: 'sign-out-failed',
      );
    }
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// Firebase hata kodlarını Türkçe kullanıcı mesajlarına dönüştürür.
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası.';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin.';
      case 'invalid-verification-code':
        return 'Hatalı kod. Tekrar deneyin.';
      case 'session-expired':
        return 'Kodun süresi doldu. Yeniden gönderin.';
      case 'quota-exceeded':
        return 'SMS limiti aşıldı. Daha sonra deneyin.';
      case 'network-request-failed':
        return 'Bağlantı hatası. İnternet bağlantınızı kontrol edin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'app-not-authorized':
      case 'missing-client-identifier':
      case 'invalid-app-credential':
      case 'missing-app-credential':
        return 'Uygulama doğrulaması başarısız. Firebase SHA-1 ayarlarını kontrol edin. (${e.code})';
      case 'captcha-check-failed':
        return 'Güvenlik doğrulaması başarısız. Tekrar deneyin.';
      case 'billing-not-enabled':
        return 'Firebase SMS servisi aktif değil. Blaze planı gerekiyor.';
      case 'missing-phone-number':
        return 'Telefon numarası girilmedi.';
      case 'rejected-credential':
        return 'Kimlik bilgisi reddedildi. Tekrar deneyin.';
      default:
        debugPrint('AuthRepository: bilinmeyen Firebase hata kodu: ${e.code} — ${e.message}');
        return 'SMS gönderilemedi (${e.code}). Tekrar deneyin.';
    }
  }
}
