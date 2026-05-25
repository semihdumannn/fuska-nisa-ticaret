import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/exceptions.dart';

class FirebaseAuthDatasource {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthDatasource(this._firebaseAuth);

  String? _verificationId;

  Future<void> sendOTP(String phoneNumber) async {
    final completer = Completer<void>();

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-verification (Android only)
      },
      verificationFailed: (FirebaseAuthException exception) {
        if (!completer.isCompleted) {
          completer.completeError(
            ServerException(exception.message ?? 'OTP dogrulama basarisiz'),
          );
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );

    return completer.future;
  }

  Future<String> verifyOTP(String otp) async {
    if (_verificationId == null) {
      throw const ServerException(
          'Dogrulama ID bulunamadi. Once OTP gonderin.');
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final idToken = await userCredential.user?.getIdToken();

    if (idToken == null) {
      throw const ServerException('Firebase token alinamadi');
    }

    return idToken;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    _verificationId = null;
  }

  String? get currentUserId => _firebaseAuth.currentUser?.uid;
  bool get isSignedIn => _firebaseAuth.currentUser != null;
}
