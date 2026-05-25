# 📱 Nisa Ticaret Flutter - API Refactor Project

> **Production-grade Flutter app migration from Firebase to Laravel API**
> 
> **Mission:** Migrate existing Flutter app from Firebase-only to Laravel API-first architecture while maintaining Firebase for Auth & FCM
> **Target:** Claude Code autonomous execution with agent system

---

## 🎯 Project Overview

### Current State (Firebase-Only)
```
Flutter App
    ↓
Firebase Services
    ├── Firestore (Database) ❌ Migrate to API
    ├── Auth (Phone OTP) ✅ Keep
    ├── Storage (Images) ❌ Migrate to MinIO
    ├── FCM (Push) ✅ Keep
    └── Remote Config ❌ Migrate to API
```

### Target State (API-First)
```
Flutter App
    ↓
┌─────────────────────────────────┐
│     API Client Layer            │
│     (Dio + Interceptors)        │
└──────────┬──────────────────────┘
           │
    ┌──────┴──────┐
    ↓             ↓
┌─────────┐   ┌──────────┐
│Laravel  │   │Firebase  │
│API      │   │Services  │
│(Sanctum)│   │(OTP+FCM) │
└─────────┘   └──────────┘
    ↓
PostgreSQL
MinIO
Redis
```

---

## 🏗️ Architecture Principles

### Core Principles
1. ✅ **Feature-First Modular Design** - Not layered, feature-based
2. ✅ **Clean Architecture** - Domain, Data, Presentation layers
3. ✅ **Repository Pattern** - Abstract data sources
4. ✅ **State Management** - Riverpod (existing, enhance)
5. ✅ **Offline-First** - Hive cache + sync strategy
6. ✅ **API-First** - Backend is source of truth
7. ✅ **Type-Safe** - Strong typing, code generation
8. ✅ **Test-Driven** - Unit, Widget, Integration tests

### Flutter-Specific Principles
- **No business logic in widgets** - Keep widgets dumb
- **Single Responsibility** - Small, focused classes
- **Immutable state** - Use freezed for data classes
- **Error handling** - Either pattern (dartz) for error flow
- **Navigation** - go_router (existing, enhance)
- **Dependency Injection** - Riverpod providers
- **Code generation** - json_serializable, freezed, riverpod_generator

---

## 📐 Architecture Design

### Feature-First Structure
```
lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart         # Dio instance
│   │   ├── api_endpoints.dart      # Base URL + endpoints
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── logging_interceptor.dart
│   │   │   └── error_interceptor.dart
│   │   ├── api_response.dart       # Generic response wrapper
│   │   └── network_exception.dart  # Custom exceptions
│   │
│   ├── cache/
│   │   ├── cache_manager.dart      # Hive wrapper
│   │   ├── cache_strategy.dart     # Cache policies
│   │   └── adapters/               # Hive type adapters
│   │
│   ├── config/
│   │   ├── app_config.dart         # API config (from backend)
│   │   └── env_config.dart         # Environment variables
│   │
│   ├── router/
│   │   └── app_router.dart         # go_router (enhanced)
│   │
│   ├── theme/
│   │   └── app_theme.dart          # Fuska branding (existing)
│   │
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── cache_keys.dart
│   │   └── app_constants.dart      # Existing
│   │
│   └── utils/
│       ├── error_handler.dart
│       ├── validators.dart
│       └── helpers.dart
│
├── features/
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart       # Domain model (freezed)
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart  # Abstract
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       └── logout_usecase.dart
│   │   │
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart       # API DTO
│   │   │   │   └── login_response.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository_impl.dart
│   │   │   └── datasources/
│   │   │       ├── auth_remote_datasource.dart  # API calls
│   │   │       ├── auth_local_datasource.dart   # Hive cache
│   │   │       └── firebase_auth_datasource.dart # Firebase OTP
│   │   │
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart    # Riverpod
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   └── otp_screen.dart
│   │       └── widgets/
│   │           └── phone_input_widget.dart
│   │
│   ├── products/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── product.dart
│   │   │   │   ├── category.dart
│   │   │   │   └── brand.dart
│   │   │   ├── repositories/
│   │   │   │   └── product_repository.dart
│   │   │   └── usecases/
│   │   │       ├── get_products_usecase.dart
│   │   │       └── get_product_detail_usecase.dart
│   │   │
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── product_model.dart
│   │   │   │   ├── category_model.dart
│   │   │   │   └── brand_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── product_repository_impl.dart
│   │   │   └── datasources/
│   │   │       ├── product_remote_datasource.dart
│   │   │       └── product_local_datasource.dart
│   │   │
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── products_provider.dart
│   │       │   └── product_detail_provider.dart
│   │       ├── screens/
│   │       │   ├── products_screen.dart
│   │       │   └── product_detail_screen.dart
│   │       └── widgets/
│   │           ├── product_card.dart
│   │           └── product_filter.dart
│   │
│   ├── cart/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── cart_item.dart
│   │   │   ├── repositories/
│   │   │   │   └── cart_repository.dart
│   │   │   └── usecases/
│   │   │       ├── add_to_cart_usecase.dart
│   │   │       └── remove_from_cart_usecase.dart
│   │   │
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── cart_item_model.dart
│   │   │   ├── repositories/
│   │   │   │   └── cart_repository_impl.dart
│   │   │   └── datasources/
│   │   │       └── cart_local_datasource.dart  # Local only
│   │   │
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── cart_provider.dart
│   │       ├── screens/
│   │       │   └── cart_screen.dart
│   │       └── widgets/
│   │           └── cart_item_widget.dart
│   │
│   ├── orders/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   ├── profile/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │
│   └── home/
│       ├── domain/
│       ├── data/
│       └── presentation/
│
└── main.dart
```

---

## 🔄 Migration Strategy

### Phase-by-Phase Migration
```
Current Firebase → Gradual API Migration → Full API

Phase 1: Infrastructure
├── API client setup
├── Auth flow (Firebase OTP → Sanctum)
├── Error handling
└── Cache layer

Phase 2: Read Operations (Safe)
├── Products (Firebase → API)
├── Categories (Firebase → API)
├── Brands (Firebase → API)
└── Config (Remote Config → API)

Phase 3: Write Operations (Critical)
├── Orders (Firebase → API)
├── Profile updates (Firebase → API)
└── Address management (Firebase → API)

Phase 4: Cleanup & Optimization
├── Remove Firebase dependencies
├── Optimize cache strategy
├── Performance tuning
└── Final testing
```

### Feature Flags (Gradual Rollout)
```dart
// Remote config from API
class FeatureFlags {
  static bool useApiForProducts = true;    // Phase 2
  static bool useApiForOrders = false;     // Phase 3
  static bool useApiForProfile = false;    // Phase 3
}
```

---

## 🔐 Authentication Flow

### Hybrid Auth (Firebase + Laravel API)
```
1. User enters phone number
   ↓
2. Firebase sends OTP
   ↓
3. User enters OTP
   ↓
4. Firebase verifies OTP
   ↓
5. Firebase generates custom token
   ↓
6. Flutter sends token to Laravel API
   POST /api/v1/auth/firebase-login
   {
     "firebase_token": "..."
   }
   ↓
7. Laravel verifies Firebase token
   ↓
8. Laravel creates/gets user
   ↓
9. Laravel generates Sanctum token
   {
     "token": "1|abc123...",
     "user": { ... }
   }
   ↓
10. Flutter stores Sanctum token
    ↓
11. All API calls use Sanctum token
    Authorization: Bearer 1|abc123...
```

### Implementation
```dart
// 1. Firebase OTP
class FirebaseAuthDatasource {
  Future<String> signInWithPhoneOTP(String phone, String otp) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final idToken = await userCredential.user!.getIdToken();
    
    return idToken; // Firebase custom token
  }
}

// 2. Laravel API login
class AuthRemoteDatasource {
  Future<LoginResponse> loginWithFirebaseToken(String firebaseToken) async {
    final response = await _apiClient.post(
      '/auth/firebase-login',
      data: {'firebase_token': firebaseToken},
    );
    
    return LoginResponse.fromJson(response.data);
  }
}

// 3. Store Sanctum token
class AuthRepository {
  Future<User> login(String phone, String otp) async {
    // Step 1: Firebase OTP
    final firebaseToken = await _firebaseDatasource.signInWithPhoneOTP(phone, otp);
    
    // Step 2: Laravel API
    final loginResponse = await _remoteDatasource.loginWithFirebaseToken(firebaseToken);
    
    // Step 3: Store token
    await _localDatasource.saveToken(loginResponse.token);
    await _localDatasource.saveUser(loginResponse.user);
    
    return loginResponse.user.toEntity();
  }
}
```

---

## 🌐 API Client Architecture

### Dio Setup with Interceptors
```dart
// core/network/api_client.dart
class ApiClient {
  static const baseUrl = 'http://admin.nisaticaret.test/api';
  
  late final Dio _dio;
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    _dio.interceptors.addAll([
      AuthInterceptor(),      // Add Sanctum token
      LoggingInterceptor(),   // Log requests/responses
      ErrorInterceptor(),     // Handle errors
      CacheInterceptor(),     // Cache responses
    ]);
  }
  
  Future<Response<T>> get<T>(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return _dio.get<T>(path, 
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  Future<Response<T>> post<T>(String path, {
    dynamic data,
    Options? options,
  }) async {
    return _dio.post<T>(path,
      data: data,
      options: options,
    );
  }
}
```

### Auth Interceptor
```dart
// core/network/interceptors/auth_interceptor.dart
class AuthInterceptor extends Interceptor {
  final LocalDatasource _localDatasource;
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _localDatasource.getToken();
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized (token expired)
    if (err.response?.statusCode == 401) {
      // Refresh token or logout
      await _handleTokenExpired();
    }
    
    handler.next(err);
  }
}
```

### Error Handling
```dart
// core/network/network_exception.dart
sealed class NetworkException implements Exception {
  const NetworkException();
}

class ServerException extends NetworkException {
  final String message;
  final int? statusCode;
  
  const ServerException(this.message, [this.statusCode]);
}

class NetworkConnectionException extends NetworkException {
  final String message;
  
  const NetworkConnectionException(this.message);
}

class UnauthorizedException extends NetworkException {}

class ValidationException extends NetworkException {
  final Map<String, List<String>> errors;
  
  const ValidationException(this.errors);
}
```

---

## 💾 Cache Strategy

### Tiered Caching
```dart
// core/cache/cache_strategy.dart
enum CacheStrategy {
  // Network first, cache fallback
  networkFirst,
  
  // Cache first, network fallback
  cacheFirst,
  
  // Stale-while-revalidate (show cache, fetch new)
  staleWhileRevalidate,
  
  // Network only (no cache)
  networkOnly,
  
  // Cache only (no network)
  cacheOnly,
}

class CachePolicy {
  final CacheStrategy strategy;
  final Duration ttl;
  
  const CachePolicy({
    required this.strategy,
    required this.ttl,
  });
  
  // Predefined policies
  static const categories = CachePolicy(
    strategy: CacheStrategy.cacheFirst,
    ttl: Duration(hours: 24),
  );
  
  static const products = CachePolicy(
    strategy: CacheStrategy.staleWhileRevalidate,
    ttl: Duration(hours: 6),
  );
  
  static const orders = CachePolicy(
    strategy: CacheStrategy.networkFirst,
    ttl: Duration(minutes: 5),
  );
  
  static const userProfile = CachePolicy(
    strategy: CacheStrategy.staleWhileRevalidate,
    ttl: Duration(hours: 1),
  );
}
```

### Hive Implementation
```dart
// core/cache/cache_manager.dart
class CacheManager {
  static const _productsBox = 'products';
  static const _categoriesBox = 'categories';
  static const _userBox = 'user';
  
  late Box<dynamic> _productsBox;
  late Box<dynamic> _categoriesBox;
  late Box<dynamic> _userBox;
  
  Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(ProductModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    
    // Open boxes
    _productsBox = await Hive.openBox(_productsBox);
    _categoriesBox = await Hive.openBox(_categoriesBox);
    _userBox = await Hive.openBox(_userBox);
  }
  
  Future<T?> get<T>(String key, String box) async {
    final data = await _getBox(box).get(key);
    
    if (data == null) return null;
    
    // Check TTL
    final cachedAt = data['cached_at'] as int?;
    final ttl = data['ttl'] as int?;
    
    if (cachedAt != null && ttl != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - cachedAt > ttl) {
        // Expired
        await delete(key, box);
        return null;
      }
    }
    
    return data['value'] as T?;
  }
  
  Future<void> put<T>(
    String key,
    T value,
    String box, {
    Duration? ttl,
  }) async {
    await _getBox(box).put(key, {
      'value': value,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
      'ttl': ttl?.inMilliseconds,
    });
  }
}
```

---

## 📊 State Management (Riverpod)

### Provider Architecture
```dart
// features/products/presentation/providers/products_provider.dart

// 1. Repository provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(
    remoteDatasource: ref.watch(productRemoteDatasourceProvider),
    localDatasource: ref.watch(productLocalDatasourceProvider),
  );
});

// 2. Use case providers
final getProductsUsecaseProvider = Provider((ref) {
  return GetProductsUsecase(ref.watch(productRepositoryProvider));
});

// 3. State notifier provider (for complex state)
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier(ref.watch(getProductsUsecaseProvider));
});

// State class
@freezed
class ProductsState with _$ProductsState {
  const factory ProductsState.initial() = _Initial;
  const factory ProductsState.loading() = _Loading;
  const factory ProductsState.loaded(List<Product> products) = _Loaded;
  const factory ProductsState.error(String message) = _Error;
}

// Notifier
class ProductsNotifier extends StateNotifier<ProductsState> {
  final GetProductsUsecase _getProductsUsecase;
  
  ProductsNotifier(this._getProductsUsecase) : super(const ProductsState.initial());
  
  Future<void> fetchProducts({
    String? category,
    String? brand,
  }) async {
    state = const ProductsState.loading();
    
    final result = await _getProductsUsecase(
      category: category,
      brand: brand,
    );
    
    result.fold(
      (failure) => state = ProductsState.error(failure.message),
      (products) => state = ProductsState.loaded(products),
    );
  }
}
```

---

## 🧪 Testing Strategy

### Test Pyramid
```
         /\
        /  \  E2E (5%)
       /────\
      /      \  Widget (15%)
     /────────\
    /          \  Unit (80%)
   /────────────\
```

### Test Structure
```
test/
├── unit/
│   ├── core/
│   │   ├── network/
│   │   │   └── api_client_test.dart
│   │   └── cache/
│   │       └── cache_manager_test.dart
│   │
│   └── features/
│       ├── auth/
│       │   ├── domain/
│       │   │   └── usecases/
│       │   │       └── login_usecase_test.dart
│       │   └── data/
│       │       ├── models/
│       │       │   └── user_model_test.dart
│       │       └── repositories/
│       │           └── auth_repository_impl_test.dart
│       │
│       └── products/
│           └── ...
│
├── widget/
│   └── features/
│       ├── auth/
│       │   └── presentation/
│       │       └── screens/
│       │           └── login_screen_test.dart
│       └── products/
│           └── ...
│
└── integration/
    ├── auth_flow_test.dart
    ├── product_flow_test.dart
    └── order_flow_test.dart
```

### Test Example
```dart
// test/unit/features/auth/domain/usecases/login_usecase_test.dart
void main() {
  late LoginUsecase usecase;
  late MockAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAuthRepository();
    usecase = LoginUsecase(mockRepository);
  });
  
  group('LoginUsecase', () {
    test('should return User when login succeeds', () async {
      // Arrange
      final expectedUser = User(id: 1, name: 'Test User');
      when(mockRepository.login(any, any))
          .thenAnswer((_) async => Right(expectedUser));
      
      // Act
      final result = await usecase(phone: '+905551234567', otp: '123456');
      
      // Assert
      expect(result, Right(expectedUser));
      verify(mockRepository.login('+905551234567', '123456'));
      verifyNoMoreInteractions(mockRepository);
    });
    
    test('should return Failure when login fails', () async {
      // Arrange
      when(mockRepository.login(any, any))
          .thenAnswer((_) async => Left(ServerFailure('Invalid OTP')));
      
      // Act
      final result = await usecase(phone: '+905551234567', otp: 'wrong');
      
      // Assert
      expect(result, Left(ServerFailure('Invalid OTP')));
    });
  });
}
```

---

## 📋 Development Phases

### Phase 0: Infrastructure Setup (Week 1)
**Goal:** API client, auth flow, error handling
**Deliverable:** Working API connection + Sanctum auth

### Phase 1: Auth Module (Week 1)
**Goal:** Complete authentication flow
**Deliverable:** Login/logout working with API

### Phase 2: Products Module (Week 2)
**Goal:** Product catalog from API
**Deliverable:** Products, categories, brands from API

### Phase 3: Cart Module (Week 2)
**Goal:** Local cart with API sync
**Deliverable:** Cart management working

### Phase 4: Orders Module (Week 3)
**Goal:** Order creation and tracking
**Deliverable:** Full order flow with API

### Phase 5: Profile Module (Week 3)
**Goal:** User profile management
**Deliverable:** Profile CRUD + address management

### Phase 6: Optimization (Week 4)
**Goal:** Performance, offline mode, testing
**Deliverable:** Production-ready app

---

## 🎯 Agent System

### 5 Specialized Flutter Agents

#### @agent-flutter-architect
- Design app architecture
- Define data flow
- Create state management structure
- Review code organization

#### @agent-flutter-developer
- Implement features
- Write business logic
- Create UI widgets
- Handle API integration

#### @agent-flutter-state
- Riverpod providers
- State management
- Data flow
- Reactive patterns

#### @agent-flutter-qa
- Write unit tests
- Write widget tests
- Integration tests
- Code review

#### @agent-flutter-ux
- UI/UX implementation
- Widget composition
- Animations
- Responsive design

---

**Version:** 1.0.0
**API Base URL:** `http://admin.nisaticaret.test/api`
**Target:** Production-ready Flutter app with Laravel API
