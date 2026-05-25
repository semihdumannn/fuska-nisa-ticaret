# 📱 Flutter App Refactor - API Migration Guide

> **Mission:** Migrate Nisa Ticaret Flutter app from Firebase-only to Laravel API-first architecture
> 
> **Target:** Production-grade, Claude Code ready
> **API:** `http://admin.nisaticaret.test/api`

---

## 🎯 What This Refactor Achieves

### Before (Firebase-Only)
```
Flutter App → Firebase (Firestore, Storage, Auth, FCM)
```
- ❌ Firebase Spark Plan limits (50K reads/day)
- ❌ Aggressive caching needed
- ❌ Complex queries difficult
- ❌ No web admin panel
- ❌ Limited business logic

### After (API-First)
```
Flutter App → Laravel API (Primary)
            → Firebase (Auth OTP + FCM only)
```
- ✅ Unlimited API calls
- ✅ Powerful PostgreSQL queries
- ✅ Filament admin panel
- ✅ Business logic in backend
- ✅ Better offline support

---

## 📦 Project Structure

### Clean Architecture (Feature-First)
```
lib/
├── core/
│   ├── network/          # API client, interceptors
│   ├── cache/            # Hive cache manager
│   ├── config/           # App configuration
│   ├── router/           # go_router
│   └── utils/            # Helpers, validators
│
└── features/
    ├── auth/
    │   ├── domain/       # Entities, use cases
    │   ├── data/         # Models, repositories, datasources
    │   └── presentation/ # Providers, screens, widgets
    │
    ├── products/
    ├── cart/
    ├── orders/
    └── profile/
```

---

## 🚀 Quick Start (For Claude Code)

### Step 1: Prepare Existing Project
```bash
# Navigate to your existing Flutter project
cd ~/Flutter/fuska_nisa_ticaret

# Create a new branch for refactor
git checkout -b api-refactor
```

### Step 2: Add This Documentation
```bash
# Copy refactor docs to project
cp -r flutter-refactor-complete/* .
```

### Step 3: Let Claude Code Do The Work
```
Open in Claude Code and say:
"Start Phase 0: Infrastructure Setup"
```

Claude Code will:
1. ✅ Update pubspec.yaml
2. ✅ Create network layer
3. ✅ Setup error handling
4. ✅ Configure Hive cache
5. ✅ Integrate Firebase Auth (OTP only)
6. ✅ Create core providers

---

## 📋 Refactor Phases

| Phase | Module | Duration | What Changes |
|-------|--------|----------|--------------|
| **0** | Infrastructure | 5-7 days | API client, auth interceptor, cache |
| **1** | Auth | 5-7 days | Firebase OTP → Laravel API login |
| **2** | Products | 7-10 days | Firestore → API (read-only safe) |
| **3** | Cart | 5-7 days | Local + API sync |
| **4** | Orders | 7-10 days | Firestore → API (write operations) |
| **5** | Profile | 5-7 days | User management via API |
| **6** | Optimization | 7-10 days | Testing, performance, cleanup |

**Total:** 6-8 weeks

---

## 🔄 Migration Strategy

### Gradual, Safe Migration
```
Step 1: Build API client (Phase 0) → No breaking changes
Step 2: Add auth flow (Phase 1) → Works alongside Firebase
Step 3: Migrate reads (Phase 2) → Products, categories (safe)
Step 4: Migrate writes (Phase 4) → Orders (critical, tested)
Step 5: Cleanup (Phase 6) → Remove Firebase dependencies
```

### Feature Flags
```dart
// Control migration with flags from API
class FeatureFlags {
  static bool useApiForProducts = true;   // Phase 2
  static bool useApiForOrders = false;    // Phase 4
  static bool useApiForProfile = false;   // Phase 5
}
```

---

## 🏗️ Key Architecture Changes

### 1. Network Layer (New)
```dart
// Before: Direct Firebase calls
final snapshot = await FirebaseFirestore.instance
    .collection('products')
    .get();

// After: API client with interceptors
final response = await apiClient.get('/products');
final products = (response.data['data'] as List)
    .map((e) => Product.fromJson(e))
    .toList();
```

### 2. Authentication Flow
```dart
// Step 1: Firebase OTP (unchanged)
await firebaseAuth.verifyPhoneNumber(...);

// Step 2: NEW - Get Firebase token
final firebaseToken = await user.getIdToken();

// Step 3: NEW - Laravel API login
final response = await apiClient.post('/auth/firebase-login', {
  'firebase_token': firebaseToken,
});

// Step 4: NEW - Store Sanctum token
await cacheManager.saveToken(response.data['token']);

// Step 5: All API calls use Sanctum token
// Authorization: Bearer {token}
```

### 3. Repository Pattern
```dart
// Domain layer (abstract)
abstract class ProductRepository {
  Future<Either<Failure, List<Product>>> getProducts();
}

// Data layer (implementation)
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDatasource _remoteDatasource;
  final ProductLocalDatasource _localDatasource;
  
  @override
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      // Try cache first
      final cached = await _localDatasource.getCachedProducts();
      if (cached != null) return Right(cached);
      
      // Fetch from API
      final products = await _remoteDatasource.getProducts();
      
      // Cache for next time
      await _localDatasource.cacheProducts(products);
      
      return Right(products);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
```

### 4. State Management (Enhanced Riverpod)
```dart
// Before: Direct Firebase stream
final productsProvider = StreamProvider<List<Product>>((ref) {
  return FirebaseFirestore.instance
      .collection('products')
      .snapshots()
      .map((snapshot) => ...);
});

// After: Use case + state notifier
final productsProvider = StateNotifierProvider<ProductsNotifier, ProductsState>((ref) {
  return ProductsNotifier(ref.watch(getProductsUsecaseProvider));
});

class ProductsNotifier extends StateNotifier<ProductsState> {
  Future<void> fetchProducts() async {
    state = const ProductsState.loading();
    
    final result = await _getProductsUsecase();
    
    result.fold(
      (failure) => state = ProductsState.error(failure.message),
      (products) => state = ProductsState.loaded(products),
    );
  }
}
```

---

## 🔐 Security Changes

### Old: Firebase Security Rules
```javascript
// Firestore rules (client-side)
match /products/{productId} {
  allow read: if true;
  allow write: if request.auth.token.role == 'admin';
}
```

### New: Laravel API Guards
```php
// Server-side (more secure)
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/products', [ProductController::class, 'index']);
    
    Route::middleware('role:admin')->group(function () {
        Route::post('/products', [ProductController::class, 'store']);
    });
});
```

---

## 📦 Dependencies Changes

### Add These Packages
```yaml
dependencies:
  # Network
  dio: ^5.4.0
  
  # Functional Programming
  dartz: ^0.10.1
  
  # Code Generation
  freezed: ^2.4.6
  json_serializable: ^6.7.1
```

### Remove These (Gradual)
```yaml
# Phase 6: After full migration
# cloud_firestore: ^6.3.0      # Remove
# firebase_storage: ^13.3.0     # Remove
# firebase_remote_config: ^6.4.0 # Remove (use API config)

# Keep these:
# firebase_auth: ^6.4.0         # Keep (for OTP)
# firebase_messaging: ^16.2.0   # Keep (for FCM)
```

---

## 🧪 Testing Strategy

### Test Coverage Goals
- Unit Tests: 80%+
- Widget Tests: 60%+
- Integration Tests: Critical flows

### Test Structure
```
test/
├── unit/
│   ├── core/
│   │   └── network/
│   │       └── api_client_test.dart
│   └── features/
│       └── auth/
│           ├── domain/
│           ├── data/
│           └── presentation/
│
├── widget/
│   └── features/
│       └── auth/
│           └── screens/
│               └── login_screen_test.dart
│
└── integration/
    ├── auth_flow_test.dart
    └── order_flow_test.dart
```

---

## 🎯 Claude Code Agent System

### 5 Specialized Agents

1. **@agent-flutter-architect**
   - Design app structure
   - Define data flow
   - Architecture decisions

2. **@agent-flutter-developer**
   - Implement features
   - Write business logic
   - API integration

3. **@agent-flutter-state**
   - Riverpod providers
   - State management
   - Reactive patterns

4. **@agent-flutter-qa**
   - Write tests
   - Code review
   - Quality assurance

5. **@agent-flutter-ux**
   - UI/UX implementation
   - Widget composition
   - Responsive design

---

## 🔄 Workflow Example

### How Claude Code Works

```
You: "Start Phase 0"
     ↓
Claude Code reads FLUTTER_PROJECT.md
     ↓
@agent-flutter-architect designs network layer
     ↓
@agent-flutter-developer implements Dio client
     ↓
@agent-flutter-state creates providers
     ↓
@agent-flutter-qa writes tests
     ↓
All tests pass ✅
     ↓
Phase 0 complete → Ready for Phase 1
```

---

## 📊 Performance Expectations

### Before (Firebase)
- 50K read limit/day
- Aggressive 24-48h caching
- Slow complex queries
- No offline mode

### After (API + Cache)
- Unlimited API calls
- Smart 6h caching
- Fast SQL queries
- True offline-first

---

## 🎓 Best Practices

### 1. Never Mix Firebase and API Data
```dart
// ❌ Bad: Mixed data sources
final productsFromFirebase = await getFromFirestore();
final ordersFromAPI = await getFromAPI();

// ✅ Good: Single source of truth
final products = await productRepository.getProducts();
final orders = await orderRepository.getOrders();
```

### 2. Always Use Repository Pattern
```dart
// ❌ Bad: Direct API call in UI
onPressed: () async {
  final response = await dio.get('/products');
  setState(() => products = response.data);
}

// ✅ Good: Through repository
onPressed: () async {
  ref.read(productsProvider.notifier).fetchProducts();
}
```

### 3. Handle Errors Gracefully
```dart
// ✅ Good: User-friendly + developer-friendly
result.fold(
  (failure) {
    // User-friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load products')),
    );
    
    // Developer log
    print('Error: ${failure.toString()}');
  },
  (products) => state = ProductsState.loaded(products),
);
```

---

## 🚨 Common Pitfalls

### 1. Token Expiration
```dart
// Handle 401 Unauthorized in interceptor
if (response.statusCode == 401) {
  // Clear token
  await cacheManager.clearToken();
  
  // Navigate to login
  navigatorKey.currentState?.pushReplacementNamed('/login');
}
```

### 2. Offline Support
```dart
// Always check connectivity
final hasConnection = await connectivity.checkConnectivity();

if (hasConnection != ConnectivityResult.none) {
  // Fetch from API
} else {
  // Use cached data
}
```

### 3. Cache Invalidation
```dart
// Invalidate cache on create/update/delete
await productRepository.createProduct(product);
await cacheManager.clearCache('products');
ref.invalidate(productsProvider); // Refresh UI
```

---

## ✅ Acceptance Criteria

### Phase 0 Complete When:
- [x] Dio client configured
- [x] Auth interceptor working
- [x] Error handling robust
- [x] Hive cache operational
- [x] Firebase Auth (OTP only) integrated

### Phase 1 Complete When:
- [x] Firebase OTP → Laravel API working
- [x] Sanctum token stored & used
- [x] Logout functional
- [x] User profile cached
- [x] Error handling tested

### Final Refactor Complete When:
- [x] All modules migrated to API
- [x] Firebase dependencies removed (except Auth + FCM)
- [x] 80%+ test coverage
- [x] Performance optimized
- [x] Production deployment ready

---

## 📞 Support

### Questions During Refactor?
```
Ask Claude Code:
"Why did this test fail?"
"Show me the data flow for products"
"Explain the auth interceptor"
```

### Debugging Tips
```
1. Check network logs (PrettyDioLogger)
2. Verify token in Hive
3. Test API endpoint in Postman
4. Check error interceptor logs
```

---

## 🎯 Next Steps

1. **Read** FLUTTER_PROJECT.md (full overview)
2. **Read** PHASES.md (detailed tasks)
3. **Open** your Flutter project in Claude Code
4. **Say** "Start Phase 0"
5. **Watch** agents refactor your app!

---

**Good luck with the refactor! 🚀**

**Version:** 1.0.0  
**API Base:** `http://admin.nisaticaret.test/api`  
**Target:** Production-ready Flutter app
