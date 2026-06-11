import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/authenticate_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
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
// ApiAuthNotifier — Laravel API + cihaz-bagli TOTP akisi
// Riverpod 3.x NotifierProvider kullanir.
// ---------------------------------------------------------------------------
class ApiAuthNotifier extends Notifier<ApiAuthState> {
  late final AuthenticateUsecase _authenticateUsecase;
  late final LogoutUsecase _logoutUsecase;
  late final GetCurrentUserUsecase _getCurrentUserUsecase;

  @override
  ApiAuthState build() {
    final repository = ref.read(apiAuthRepositoryProvider);
    _authenticateUsecase = AuthenticateUsecase(repository);
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

  Future<void> authenticate(String phone) async {
    state = const ApiAuthLoading();
    final result = await _authenticateUsecase(phone);
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
// Mevcut authNotifierProvider (TOTP tabanli) ile cakismaz.
// ---------------------------------------------------------------------------
final apiAuthNotifierProvider =
    NotifierProvider<ApiAuthNotifier, ApiAuthState>(ApiAuthNotifier.new);
