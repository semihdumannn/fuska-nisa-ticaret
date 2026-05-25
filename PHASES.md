# 📅 Flutter Refactor Phases - Detailed Task Breakdown

## 🎯 Phase Execution Model

### Completion Criteria (Every Phase)
- [ ] All tasks completed
- [ ] All tests passing (unit + widget)
- [ ] Code reviewed by @agent-flutter-qa
- [ ] UI validated by @agent-flutter-ux
- [ ] Documentation updated
- [ ] Working demo on emulator/device

### Task Status Icons
- ⏳ Not Started
- 🔄 In Progress  
- ✅ Completed
- ❌ Blocked
- ⚠️ Needs Review

---

## 📦 Phase 0: Infrastructure Setup

**Duration:** 5-7 days
**Goal:** API client, error handling, cache layer
**Deliverable:** Working API connection with auth

### Task 0.1: Project Dependencies
**Agent:** @agent-flutter-developer
**Priority:** P0

#### Subtasks:
- [ ] 0.1.1 Update pubspec.yaml
  ```yaml
  dependencies:
    # Network
    dio: ^5.4.0
    retrofit: ^4.0.3
    pretty_dio_logger: ^1.3.1
    
    # State Management (existing)
    flutter_riverpod: ^3.3.1
    riverpod_annotation: ^4.0.2
    
    # Functional Programming
    dartz: ^0.10.1
    
    # Code Generation
    freezed: ^2.4.6
    freezed_annotation: ^2.4.1
    json_serializable: ^6.7.1
    json_annotation: ^4.8.1
    
    # Cache (existing, keep)
    hive: ^2.2.3
    hive_flutter: ^1.1.0
    
    # Firebase (keep only Auth + FCM)
    firebase_auth: ^6.4.0
    firebase_messaging: ^16.2.0
    
    # Utils
    connectivity_plus: ^7.1.1
    intl: ^0.20.2
    
  dev_dependencies:
    build_runner: ^2.4.8
    riverpod_generator: ^4.0.3
    freezed_codegen: ^2.4.6
    mockito: ^5.4.4
    retrofit_generator: ^8.0.4
  ```

- [ ] 0.1.2 Run build_runner
  ```bash
  flutter pub get
  flutter pub run build_runner build --delete-conflicting-outputs
  ```

- [ ] 0.1.3 Remove unnecessary Firebase dependencies
  ```yaml
  # Remove these:
  # cloud_firestore
  # firebase_storage
  # firebase_remote_config (will use API config)
  ```

**Dependencies:** None
**Testing:** `flutter pub get` succeeds

---

### Task 0.2: Core Network Layer
**Agent:** @agent-flutter-developer
**Priority:** P0

#### Subtasks:
- [ ] 0.2.1 Create API endpoints constants
  ```dart
  // lib/core/network/api_endpoints.dart
  class ApiEndpoints {
    static const baseUrl = 'http://admin.nisaticaret.test/api';
    
    // Auth endpoints
    static const auth = '/auth';
    static const firebaseLogin = '$auth/firebase-login';
    static const logout = '$auth/logout';
    static const me = '$auth/me';
    
    // Product endpoints
    static const products = '/products';
    static String productDetail(int id) => '$products/$id';
    
    // Category endpoints
    static const categories = '/categories';
    
    // Order endpoints
    static const orders = '/orders';
    static String orderDetail(int id) => '$orders/$id';
    
    // Profile endpoints
    static const profile = '/profile';
    static const addresses = '/addresses';
    
    // Config endpoint
    static const config = '/config';
  }
  ```

- [ ] 0.2.2 Create Dio client
  ```dart
  // lib/core/network/api_client.dart
  import 'package:dio/dio.dart';
  import 'package:pretty_dio_logger/pretty_dio_logger.dart';
  
  class ApiClient {
    late final Dio _dio;
    
    ApiClient() {
      _dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      _setupInterceptors();
    }
    
    void _setupInterceptors() {
      _dio.interceptors.addAll([
        AuthInterceptor(),
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
        ),
      ]);
    }
    
    Dio get dio => _dio;
  }
  ```

- [ ] 0.2.3 Create Auth Interceptor
  ```dart
  // lib/core/network/interceptors/auth_interceptor.dart
  class AuthInterceptor extends Interceptor {
    @override
    void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
    ) async {
      // Get token from local storage
      final token = await _getToken();
      
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      
      handler.next(options);
    }
    
    @override
    void onError(
      DioException err,
      ErrorInterceptorHandler handler,
    ) async {
      if (err.response?.statusCode == 401) {
        // Token expired, logout user
        await _handleUnauthorized();
      }
      
      handler.next(err);
    }
  }
  ```

- [ ] 0.2.4 Create generic API response wrapper
  ```dart
  // lib/core/network/api_response.dart
  @freezed
  class ApiResponse<T> with _$ApiResponse<T> {
    const factory ApiResponse.success({
      required T data,
      String? message,
    }) = _Success<T>;
    
    const factory ApiResponse.error({
      required String message,
      int? statusCode,
      Map<String, dynamic>? errors,
    }) = _Error<T>;
  }
  ```

**Dependencies:** Task 0.1
**Testing:** Dio instance created successfully

---

### Task 0.3: Error Handling
**Agent:** @agent-flutter-developer
**Priority:** P0

#### Subtasks:
- [ ] 0.3.1 Create failure classes
  ```dart
  // lib/core/error/failures.dart
  @freezed
  class Failure with _$Failure {
    const factory Failure.server(String message, [int? statusCode]) = ServerFailure;
    const factory Failure.network(String message) = NetworkFailure;
    const factory Failure.cache(String message) = CacheFailure;
    const factory Failure.validation(Map<String, List<String>> errors) = ValidationFailure;
    const factory Failure.unauthorized() = UnauthorizedFailure;
  }
  ```

- [ ] 0.3.2 Create exception handler
  ```dart
  // lib/core/error/exception_handler.dart
  class ExceptionHandler {
    static Failure handleException(Exception exception) {
      if (exception is DioException) {
        return _handleDioException(exception);
      } else if (exception is SocketException) {
        return const Failure.network('No internet connection');
      } else {
        return Failure.server(exception.toString());
      }
    }
    
    static Failure _handleDioException(DioException exception) {
      switch (exception.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return const Failure.network('Connection timeout');
          
        case DioExceptionType.badResponse:
          final statusCode = exception.response?.statusCode;
          
          if (statusCode == 401) {
            return const Failure.unauthorized();
          } else if (statusCode == 422) {
            final errors = exception.response?.data['errors'] as Map<String, dynamic>?;
            return Failure.validation(errors?.map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            ) ?? {});
          } else {
            final message = exception.response?.data['message'] ?? 'Server error';
            return Failure.server(message, statusCode);
          }
          
        default:
          return const Failure.network('Network error');
      }
    }
  }
  ```

**Dependencies:** Task 0.2
**Testing:** Exception handling works correctly

---

### Task 0.4: Cache Layer
**Agent:** @agent-flutter-developer
**Priority:** P0

#### Subtasks:
- [ ] 0.4.1 Create cache manager
  ```dart
  // lib/core/cache/cache_manager.dart
  class CacheManager {
    late Box<String> _tokenBox;
    late Box<dynamic> _dataBox;
    
    Future<void> init() async {
      await Hive.initFlutter();
      
      _tokenBox = await Hive.openBox<String>('auth_tokens');
      _dataBox = await Hive.openBox('cached_data');
    }
    
    // Token methods
    Future<void> saveToken(String token) async {
      await _tokenBox.put('sanctum_token', token);
    }
    
    String? getToken() {
      return _tokenBox.get('sanctum_token');
    }
    
    Future<void> clearToken() async {
      await _tokenBox.delete('sanctum_token');
    }
    
    // Data cache methods
    Future<void> cacheData(
      String key,
      dynamic data, {
      Duration? ttl,
    }) async {
      await _dataBox.put(key, {
        'data': data,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
        'ttl': ttl?.inMilliseconds,
      });
    }
    
    T? getCachedData<T>(String key) {
      final cached = _dataBox.get(key);
      
      if (cached == null) return null;
      
      // Check TTL
      final cachedAt = cached['cachedAt'] as int?;
      final ttl = cached['ttl'] as int?;
      
      if (cachedAt != null && ttl != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - cachedAt > ttl) {
          _dataBox.delete(key);
          return null;
        }
      }
      
      return cached['data'] as T?;
    }
  }
  ```

- [ ] 0.4.2 Create cache keys constants
  ```dart
  // lib/core/cache/cache_keys.dart
  class CacheKeys {
    static const products = 'products_list';
    static String product(int id) => 'product_$id';
    
    static const categories = 'categories_list';
    static const brands = 'brands_list';
    
    static const userProfile = 'user_profile';
    static const addresses = 'addresses_list';
    
    static const appConfig = 'app_config';
  }
  ```

**Dependencies:** Task 0.1
**Testing:** Cache read/write works

---

### Task 0.5: Firebase Auth Integration
**Agent:** @agent-flutter-developer
**Priority:** P0

#### Subtasks:
- [ ] 0.5.1 Create Firebase auth datasource
  ```dart
  // lib/features/auth/data/datasources/firebase_auth_datasource.dart
  class FirebaseAuthDatasource {
    final FirebaseAuth _firebaseAuth;
    
    FirebaseAuthDatasource(this._firebaseAuth);
    
    String? _verificationId;
    
    Future<void> sendOTP(String phoneNumber) async {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) {},
        verificationFailed: (exception) {
          throw ServerException(exception.message ?? 'Verification failed');
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    }
    
    Future<String> verifyOTP(String otp) async {
      if (_verificationId == null) {
        throw const ServerException('Verification ID not found');
      }
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) {
        throw const ServerException('Failed to get Firebase token');
      }
      
      return idToken;
    }
    
    Future<void> signOut() async {
      await _firebaseAuth.signOut();
    }
  }
  ```

**Dependencies:** Task 0.1
**Testing:** Firebase OTP works

---

### Task 0.6: Initial Providers Setup
**Agent:** @agent-flutter-state
**Priority:** P1

#### Subtasks:
- [ ] 0.6.1 Create core providers
  ```dart
  // lib/core/providers/core_providers.dart
  
  // API Client provider
  @riverpod
  ApiClient apiClient(ApiClientRef ref) {
    return ApiClient();
  }
  
  // Cache Manager provider
  @riverpod
  CacheManager cacheManager(CacheManagerRef ref) {
    final cacheManager = CacheManager();
    cacheManager.init();
    return cacheManager;
  }
  
  // Firebase Auth provider
  @riverpod
  FirebaseAuth firebaseAuth(FirebaseAuthRef ref) {
    return FirebaseAuth.instance;
  }
  ```

**Dependencies:** Tasks 0.2, 0.4, 0.5
**Testing:** Providers accessible

---

### Phase 0 Acceptance Criteria
- [x] Dio client configured
- [x] Auth interceptor working
- [x] Error handling implemented
- [x] Hive cache layer ready
- [x] Firebase Auth integrated
- [x] Core providers created
- [x] All tests passing

**Deliverable:** Tag `v1.0.0-refactor-phase0` - Infrastructure Ready

---

## 👤 Phase 1: Auth Module Refactor

**Duration:** 5-7 days
**Goal:** Complete auth flow with API
**Deliverable:** Login/logout working with Laravel API

### Task 1.1: Auth Domain Layer
**Agent:** @agent-flutter-architect
**Priority:** P0

#### Subtasks:
- [ ] 1.1.1 Create User entity
  ```dart
  // lib/features/auth/domain/entities/user.dart
  @freezed
  class User with _$User {
    const factory User({
      required int id,
      required String name,
      required String phone,
      String? email,
      required String role,
      bool? isActive,
      UserProfile? profile,
    }) = _User;
  }
  
  @freezed
  class UserProfile with _$UserProfile {
    const factory UserProfile({
      String? avatarUrl,
      String? companyName,
      double? balance,
      double? creditLimit,
    }) = _UserProfile;
  }
  ```

- [ ] 1.1.2 Create auth repository interface
  ```dart
  // lib/features/auth/domain/repositories/auth_repository.dart
  abstract class AuthRepository {
    Future<Either<Failure, User>> loginWithPhoneOTP({
      required String phone,
      required String otp,
    });
    
    Future<Either<Failure, void>> logout();
    
    Future<Either<Failure, User>> getCurrentUser();
    
    Future<Either<Failure, void>> sendOTP(String phone);
  }
  ```

- [ ] 1.1.3 Create use cases
  ```dart
  // lib/features/auth/domain/usecases/login_usecase.dart
  class LoginUsecase {
    final AuthRepository _repository;
    
    LoginUsecase(this._repository);
    
    Future<Either<Failure, User>> call({
      required String phone,
      required String otp,
    }) async {
      return await _repository.loginWithPhoneOTP(
        phone: phone,
        otp: otp,
      );
    }
  }
  
  // Similarly: LogoutUsecase, SendOTPUsecase, GetCurrentUserUsecase
  ```

**Dependencies:** Phase 0
**Testing:** Unit tests for entities and use cases

---

### Task 1.2: Auth Data Layer
**Agent:** @agent-flutter-developer
**Priority:** P0

#### Subtasks:
- [ ] 1.2.1 Create API models
  ```dart
  // lib/features/auth/data/models/user_model.dart
  @freezed
  class UserModel with _$UserModel {
    const factory UserModel({
      required int id,
      required String name,
      required String phone,
      String? email,
      required String role,
      @JsonKey(name: 'is_active') bool? isActive,
      UserProfileModel? profile,
    }) = _UserModel;
    
    factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
  }
  
  extension UserModelX on UserModel {
    User toEntity() => User(
      id: id,
      name: name,
      phone: phone,
      email: email,
      role: role,
      isActive: isActive,
      profile: profile?.toEntity(),
    );
  }
  ```

- [ ] 1.2.2 Create login response model
  ```dart
  // lib/features/auth/data/models/login_response.dart
  @freezed
  class LoginResponse with _$LoginResponse {
    const factory LoginResponse({
      required String token,
      required UserModel user,
    }) = _LoginResponse;
    
    factory LoginResponse.fromJson(Map<String, dynamic> json) => 
      _$LoginResponseFromJson(json);
  }
  ```

- [ ] 1.2.3 Create remote datasource
  ```dart
  // lib/features/auth/data/datasources/auth_remote_datasource.dart
  abstract class AuthRemoteDatasource {
    Future<LoginResponse> loginWithFirebaseToken(String firebaseToken);
    Future<void> logout();
    Future<UserModel> getCurrentUser();
  }
  
  class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
    final Dio _dio;
    
    AuthRemoteDatasourceImpl(this._dio);
    
    @override
    Future<LoginResponse> loginWithFirebaseToken(String firebaseToken) async {
      try {
        final response = await _dio.post(
          ApiEndpoints.firebaseLogin,
          data: {'firebase_token': firebaseToken},
        );
        
        return LoginResponse.fromJson(response.data['data']);
      } on DioException catch (e) {
        throw ExceptionHandler.handleException(e);
      }
    }
    
    @override
    Future<void> logout() async {
      try {
        await _dio.post(ApiEndpoints.logout);
      } on DioException catch (e) {
        throw ExceptionHandler.handleException(e);
      }
    }
    
    @override
    Future<UserModel> getCurrentUser() async {
      try {
        final response = await _dio.get(ApiEndpoints.me);
        return UserModel.fromJson(response.data['data']);
      } on DioException catch (e) {
        throw ExceptionHandler.handleException(e);
      }
    }
  }
  ```

- [ ] 1.2.4 Create local datasource
  ```dart
  // lib/features/auth/data/datasources/auth_local_datasource.dart
  class AuthLocalDatasource {
    final CacheManager _cacheManager;
    
    AuthLocalDatasource(this._cacheManager);
    
    Future<void> saveToken(String token) async {
      await _cacheManager.saveToken(token);
    }
    
    String? getToken() {
      return _cacheManager.getToken();
    }
    
    Future<void> clearToken() async {
      await _cacheManager.clearToken();
    }
    
    Future<void> saveUser(UserModel user) async {
      await _cacheManager.cacheData(
        CacheKeys.userProfile,
        user.toJson(),
      );
    }
    
    UserModel? getUser() {
      final json = _cacheManager.getCachedData<Map<String, dynamic>>(
        CacheKeys.userProfile,
      );
      
      if (json == null) return null;
      
      return UserModel.fromJson(json);
    }
  }
  ```

- [ ] 1.2.5 Implement repository
  ```dart
  // lib/features/auth/data/repositories/auth_repository_impl.dart
  class AuthRepositoryImpl implements AuthRepository {
    final AuthRemoteDatasource _remoteDatasource;
    final FirebaseAuthDatasource _firebaseDatasource;
    final AuthLocalDatasource _localDatasource;
    
    AuthRepositoryImpl({
      required AuthRemoteDatasource remoteDatasource,
      required FirebaseAuthDatasource firebaseDatasource,
      required AuthLocalDatasource localDatasource,
    })  : _remoteDatasource = remoteDatasource,
          _firebaseDatasource = firebaseDatasource,
          _localDatasource = localDatasource;
    
    @override
    Future<Either<Failure, User>> loginWithPhoneOTP({
      required String phone,
      required String otp,
    }) async {
      try {
        // Step 1: Firebase OTP verification
        final firebaseToken = await _firebaseDatasource.verifyOTP(otp);
        
        // Step 2: Laravel API login
        final loginResponse = await _remoteDatasource.loginWithFirebaseToken(
          firebaseToken,
        );
        
        // Step 3: Save token and user
        await _localDatasource.saveToken(loginResponse.token);
        await _localDatasource.saveUser(loginResponse.user);
        
        return Right(loginResponse.user.toEntity());
      } catch (e) {
        return Left(ExceptionHandler.handleException(e as Exception));
      }
    }
    
    @override
    Future<Either<Failure, void>> logout() async {
      try {
        await _remoteDatasource.logout();
        await _firebaseDatasource.signOut();
        await _localDatasource.clearToken();
        
        return const Right(null);
      } catch (e) {
        return Left(ExceptionHandler.handleException(e as Exception));
      }
    }
    
    @override
    Future<Either<Failure, User>> getCurrentUser() async {
      try {
        // Check cache first
        final cachedUser = _localDatasource.getUser();
        if (cachedUser != null) {
          return Right(cachedUser.toEntity());
        }
        
        // Fetch from API
        final user = await _remoteDatasource.getCurrentUser();
        await _localDatasource.saveUser(user);
        
        return Right(user.toEntity());
      } catch (e) {
        return Left(ExceptionHandler.handleException(e as Exception));
      }
    }
    
    @override
    Future<Either<Failure, void>> sendOTP(String phone) async {
      try {
        await _firebaseDatasource.sendOTP(phone);
        return const Right(null);
      } catch (e) {
        return Left(ExceptionHandler.handleException(e as Exception));
      }
    }
  }
  ```

**Dependencies:** Task 1.1
**Testing:** Unit tests for datasources and repository

---

### Task 1.3: Auth Presentation Layer
**Agent:** @agent-flutter-state
**Priority:** P0

#### Subtasks:
- [ ] 1.3.1 Create auth providers
  ```dart
  // lib/features/auth/presentation/providers/auth_providers.dart
  
  // Repository provider
  @riverpod
  AuthRepository authRepository(AuthRepositoryRef ref) {
    return AuthRepositoryImpl(
      remoteDatasource: ref.watch(authRemoteDatasourceProvider),
      firebaseDatasource: ref.watch(firebaseAuthDatasourceProvider),
      localDatasource: ref.watch(authLocalDatasourceProvider),
    );
  }
  
  // Use case providers
  @riverpod
  LoginUsecase loginUsecase(LoginUsecaseRef ref) {
    return LoginUsecase(ref.watch(authRepositoryProvider));
  }
  
  @riverpod
  LogoutUsecase logoutUsecase(LogoutUsecaseRef ref) {
    return LogoutUsecase(ref.watch(authRepositoryProvider));
  }
  
  @riverpod
  SendOTPUsecase sendOTPUsecase(SendOTPUsecaseRef ref) {
    return SendOTPUsecase(ref.watch(authRepositoryProvider));
  }
  
  // Auth state provider
  @riverpod
  class AuthNotifier extends _$AuthNotifier {
    @override
    AuthState build() {
      _checkAuthStatus();
      return const AuthState.initial();
    }
    
    Future<void> _checkAuthStatus() async {
      final result = await ref.read(getCurrentUserUsecaseProvider)();
      
      result.fold(
        (failure) => state = const AuthState.unauthenticated(),
        (user) => state = AuthState.authenticated(user),
      );
    }
    
    Future<void> sendOTP(String phone) async {
      state = const AuthState.loading();
      
      final result = await ref.read(sendOTPUsecaseProvider)(phone);
      
      result.fold(
        (failure) => state = AuthState.error(failure.toString()),
        (_) => state = const AuthState.otpSent(),
      );
    }
    
    Future<void> verifyOTP(String phone, String otp) async {
      state = const AuthState.loading();
      
      final result = await ref.read(loginUsecaseProvider)(
        phone: phone,
        otp: otp,
      );
      
      result.fold(
        (failure) => state = AuthState.error(failure.toString()),
        (user) => state = AuthState.authenticated(user),
      );
    }
    
    Future<void> logout() async {
      final result = await ref.read(logoutUsecaseProvider)();
      
      result.fold(
        (failure) => state = AuthState.error(failure.toString()),
        (_) => state = const AuthState.unauthenticated(),
      );
    }
  }
  
  @freezed
  class AuthState with _$AuthState {
    const factory AuthState.initial() = _Initial;
    const factory AuthState.loading() = _Loading;
    const factory AuthState.otpSent() = _OtpSent;
    const factory AuthState.authenticated(User user) = _Authenticated;
    const factory AuthState.unauthenticated() = _Unauthenticated;
    const factory AuthState.error(String message) = _Error;
  }
  ```

**Dependencies:** Task 1.2
**Testing:** Provider tests

---

### Task 1.4: Auth UI Update
**Agent:** @agent-flutter-ux
**Priority:** P1

#### Subtasks:
- [ ] 1.4.1 Update LoginScreen to use new providers
  ```dart
  // lib/features/auth/presentation/screens/login_screen.dart
  class LoginScreen extends ConsumerStatefulWidget {
    const LoginScreen({super.key});
    
    @override
    ConsumerState<LoginScreen> createState() => _LoginScreenState();
  }
  
  class _LoginScreenState extends ConsumerState<LoginScreen> {
    final _phoneController = TextEditingController();
    final _otpController = TextEditingController();
    
    @override
    Widget build(BuildContext context) {
      final authState = ref.watch(authNotifierProvider);
      
      ref.listen<AuthState>(authNotifierProvider, (previous, next) {
        next.when(
          initial: () {},
          loading: () {},
          otpSent: () {
            // Show OTP input
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OTP sent to your phone')),
            );
          },
          authenticated: (user) {
            // Navigate to home
            context.go('/home');
          },
          unauthenticated: () {},
          error: (message) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          },
        );
      });
      
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: authState.maybeWhen(
              otpSent: () => _buildOTPInput(),
              orElse: () => _buildPhoneInput(),
            ),
          ),
        ),
      );
    }
    
    Widget _buildPhoneInput() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+90 555 123 45 67',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier)
                .sendOTP(_phoneController.text);
            },
            child: const Text('Send OTP'),
          ),
        ],
      );
    }
    
    Widget _buildOTPInput() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _otpController,
            decoration: const InputDecoration(
              labelText: 'OTP Code',
              hintText: '123456',
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(authNotifierProvider.notifier).verifyOTP(
                _phoneController.text,
                _otpController.text,
              );
            },
            child: const Text('Verify'),
          ),
        ],
      );
    }
  }
  ```

**Dependencies:** Task 1.3
**Testing:** Widget tests

---

### Task 1.5: Auth Module Tests
**Agent:** @agent-flutter-qa
**Priority:** P0

#### Subtasks:
- [ ] 1.5.1 Unit tests for use cases
- [ ] 1.5.2 Unit tests for repository
- [ ] 1.5.3 Widget tests for login screen
- [ ] 1.5.4 Integration tests for auth flow

**Dependencies:** All auth tasks
**Testing:** 80%+ coverage

---

### Phase 1 Acceptance Criteria
- [x] Firebase OTP → Laravel API working
- [x] Sanctum token stored
- [x] User profile cached
- [x] Logout working
- [x] Error handling robust
- [x] UI updated with new flow
- [x] All tests passing

**Deliverable:** Tag `v1.0.0-refactor-phase1` - Auth Complete

---

## 📦 Phase 2-6: Remaining Modules

**(Products, Cart, Orders, Profile, Optimization)**

Each phase follows same structure:
1. Domain layer (entities, repository interface, use cases)
2. Data layer (models, datasources, repository impl)
3. Presentation layer (providers, screens, widgets)
4. Tests (unit, widget, integration)

**Full phase details:**
- Phase 2: Products Module (Week 2)
- Phase 3: Cart Module (Week 2)
- Phase 4: Orders Module (Week 3)
- Phase 5: Profile Module (Week 3)
- Phase 6: Optimization (Week 4)

---

**Version:** 1.0.0
**Last Updated:** 2024-12-20
