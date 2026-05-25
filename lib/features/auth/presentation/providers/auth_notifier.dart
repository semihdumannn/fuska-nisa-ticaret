import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/send_otp_usecase.dart';
import 'auth_repository_provider.dart';

// ---------------------------------------------------------------------------
// Api Auth State — Laravel API tabanli auth akisinin durumu
// ---------------------------------------------------------------------------
sealed class ApiAuthState {
  const ApiAuthState();
}

class ApiAuthInitial extends ApiAuthState {
  const ApiAuthInitial();
}

class ApiAuthLoading extends ApiAuthState {
  const ApiAuthLoading();
}

class ApiAuthOtpSent extends ApiAuthState {
  final String phone;
  const ApiAuthOtpSent(this.phone);
}

class ApiAuthAuthenticated extends ApiAuthState {
  final UserEntity user;
  const ApiAuthAuthenticated(this.user);
}

class ApiAuthUnauthenticated extends ApiAuthState {
  const ApiAuthUnauthenticated();
}

class ApiAuthError extends ApiAuthState {
  final String message;
  const ApiAuthError(this.message);
}

// ---------------------------------------------------------------------------
// ApiAuthNotifier — Laravel API + Firebase OTP akisi
// Riverpod 3.x NotifierProvider kullanir.
// ---------------------------------------------------------------------------
class ApiAuthNotifier extends Notifier<ApiAuthState> {
  late final SendOtpUsecase _sendOtpUsecase;
  late final LoginUsecase _loginUsecase;
  late final LogoutUsecase _logoutUsecase;
  late final GetCurrentUserUsecase _getCurrentUserUsecase;

  @override
  ApiAuthState build() {
    final repository = ref.read(apiAuthRepositoryProvider);
    _sendOtpUsecase = SendOtpUsecase(repository);
    _loginUsecase = LoginUsecase(repository);
    _logoutUsecase = LogoutUsecase(repository);
    _getCurrentUserUsecase = GetCurrentUserUsecase(repository);

    // Token var mi kontrol et
    _checkAuthStatus();

    return const ApiAuthInitial();
  }

  Future<void> _checkAuthStatus() async {
    final result = await _getCurrentUserUsecase();
    result.fold(
      (failure) => state = const ApiAuthUnauthenticated(),
      (user) => state = ApiAuthAuthenticated(user),
    );
  }

  Future<void> sendOTP(String phone) async {
    state = const ApiAuthLoading();
    final result = await _sendOtpUsecase(phone);
    result.fold(
      (failure) => state = ApiAuthError(failure.message),
      (_) => state = ApiAuthOtpSent(phone),
    );
  }

  Future<void> verifyOTP({required String phone, required String otp}) async {
    state = const ApiAuthLoading();
    final result = await _loginUsecase(phone: phone, otp: otp);
    result.fold(
      (failure) => state = ApiAuthError(failure.message),
      (user) => state = ApiAuthAuthenticated(user),
    );
  }

  Future<void> logout() async {
    final result = await _logoutUsecase();
    result.fold(
      (failure) => state = ApiAuthError(failure.message),
      (_) => state = const ApiAuthUnauthenticated(),
    );
  }
}

// ---------------------------------------------------------------------------
// Provider — apiAuthNotifierProvider
// Mevcut authNotifierProvider (Firestore tabanli) ile cakismaz.
// ---------------------------------------------------------------------------
final apiAuthNotifierProvider =
    NotifierProvider<ApiAuthNotifier, ApiAuthState>(ApiAuthNotifier.new);
