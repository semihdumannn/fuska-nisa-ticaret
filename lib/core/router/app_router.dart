import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../constants/asset_paths.dart';

// Screens - Splash
import '../../features/splash/presentation/screens/splash_screen.dart';

// Screens - Auth
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/phone_auth_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';

// Screens - Customer
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/cart/presentation/screens/cart_screen.dart';
import '../../features/orders/presentation/screens/checkout_screen.dart';
import '../../features/orders/presentation/screens/order_success_screen.dart';
import '../../features/orders/presentation/screens/order_list_screen.dart';
import '../../features/orders/presentation/screens/order_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';

// Screens - Field Agent
import '../../features/field_agent/presentation/screens/field_agent_home_screen.dart';
import '../../features/field_agent/presentation/screens/customer_search_screen.dart';
import '../../features/field_agent/presentation/screens/customer_detail_screen.dart';
import '../../features/field_agent/presentation/screens/quick_order_screen.dart';

// Screens - Delivery
import '../../features/delivery/presentation/screens/delivery_home_screen.dart';
import '../../features/delivery/presentation/screens/delivery_detail_screen.dart';

// Screens - Admin
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_home_screen.dart';
import '../../features/admin/presentation/screens/admin_products_screen.dart';
import '../../features/admin/presentation/screens/product_form_screen.dart';
import '../../features/admin/presentation/screens/admin_orders_screen.dart';
import '../../features/admin/presentation/screens/admin_order_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/user_detail_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/admin_terminal_screen.dart';
import '../../features/admin/presentation/screens/category_management_screen.dart';

// Screens - Notifications
import '../../features/notifications/presentation/screens/notifications_screen.dart';

// Screens - FAZ 5
import '../../features/products/presentation/screens/favorites_screen.dart';
import '../../features/orders/presentation/screens/review_screen.dart';
import '../../features/orders/presentation/screens/subscription_screen.dart';
import '../../features/campaigns/presentation/screens/campaigns_screen.dart';
import '../../features/profile/presentation/screens/help_screen.dart';

// Screens - Address
import '../../features/orders/presentation/screens/address_selection_screen.dart';
import '../../features/orders/presentation/screens/address_form_screen.dart';
import '../../features/orders/data/models/address_model.dart';
// Providers
import '../../features/auth/presentation/bloc/auth_provider.dart';
import '../../features/auth/data/models/user_model.dart';
import '../theme/app_theme.dart';

class AppRoutes {
  // Splash
  static const String splash = '/splash';

  // Auth
  static const String onboarding = '/onboarding';
  static const String phoneAuth = '/phone-auth';
  static const String register = '/register';

  // Customer
  static const String home = '/';
  static const String productDetail = '/products/:id';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';

  // Field Agent
  static const String fieldAgentHome = '/field-agent';
  static const String customerSearch = '/field-agent/customer-search';
  static const String customerDetail = '/field-agent/customer/:uid';
  static const String quickOrder = '/field-agent/quick-order';

  // Delivery
  static const String deliveryHome = '/delivery';
  static const String deliveryDetail = '/delivery/:id';

  // Admin
  static const String adminDashboard = '/admin';
  static const String adminHome = '/admin/dashboard';
  static const String productManagement = '/admin/products';
  static const String productNew = '/admin/products/new';
  static const String productEdit = '/admin/products/:id/edit';
  static const String orderManagement = '/admin/orders';
  static const String adminOrderDetail = '/admin/orders/:id';
  static const String adminUsers = '/admin/users';
  static const String adminUserDetail = '/admin/users/:id';
  static const String adminReports = '/admin/reports';
  static const String categoryManagement = '/admin/categories';
  static const String adminTerminal = '/admin/terminal';

  // Notifications
  static const String notifications = '/notifications';

  // Address
  static const String addressSelection = '/addresses';
  static const String addressForm = '/addresses/form';

  // FAZ 5
  static const String favorites = '/favorites';
  static const String subscription = '/subscription';
  static const String campaigns = '/campaigns';
  static const String help = '/help';
  static const String review = '/review';
}

// Root navigator key — ShellRoute içinden push yapılan route'lar için
// parentNavigatorKey: _rootNavKey ile root navigator'a bağlanır.
// Provider dışında tanımlanmalı; her Provider rebuild'inde yeni key oluşmasın.
final _rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // Auth değişimlerini GoRouter'a iletmek için Listenable.
  // ref.watch KULLANILMIYOR — bu sayede router yeniden oluşmaz,
  // sadece redirect yeniden değerlendirilir.
  final notifier = ValueNotifier<int>(0);
  ref.listen<AsyncValue<UserModel?>>(authStateProvider, (_, __) {
    notifier.value++;
  });
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      return authState.when(
        data: (user) {
          final loc = state.matchedLocation;
          final isStaffRoute = loc.startsWith(AppRoutes.adminDashboard) ||
              loc.startsWith(AppRoutes.fieldAgentHome) ||
              loc.startsWith(AppRoutes.deliveryHome);
          // Çıkış sonrası staff rotasında kalınmasın
          if (user == null && isStaffRoute) return AppRoutes.home;
          return null;
        },
        loading: () => null,
        error: (_, __) => null,
      );
    },
    routes: [
      // Onboarding
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth
      GoRoute(
        path: AppRoutes.phoneAuth,
        builder: (context, state) => const PhoneAuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer Shell (bottom nav)
      ShellRoute(
        builder: (context, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => const MaterialPage(
              key: ValueKey('shell-home'),
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.cart,
            pageBuilder: (context, state) => const MaterialPage(
              key: ValueKey('shell-cart'),
              child: CartScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.orders,
            pageBuilder: (context, state) => const MaterialPage(
              key: ValueKey('shell-orders'),
              child: OrderListScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => const MaterialPage(
              key: ValueKey('shell-profile'),
              child: ProfileScreen(),
            ),
          ),
        ],
      ),

      // Profile Edit — ShellRoute içinden push edilir
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.profileEdit,
        builder: (context, state) => const ProfileEditScreen(),
      ),

      // Product Detail (full screen) — ShellRoute içinden push edilir
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.productDetail,
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id']!;
          return MaterialPage(
            key: ValueKey('product-detail-$productId'),
            child: ProductDetailScreen(productId: productId),
          );
        },
      ),

      // Checkout flow — ShellRoute içinden push edilir
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.orderSuccess,
        builder: (context, state) {
          final orderNo = state.extra as String? ?? '';
          return OrderSuccessScreen(orderNo: orderNo);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.orderDetail,
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return MaterialPage(
            key: ValueKey('order-detail-$orderId'),
            child: OrderDetailScreen(orderId: orderId),
          );
        },
      ),

      // Field Agent
      GoRoute(
        path: AppRoutes.fieldAgentHome,
        builder: (context, state) => const FieldAgentHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerSearch,
        builder: (context, state) => const CustomerSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerDetail,
        pageBuilder: (context, state) {
          final customer = state.extra as UserModel;
          return MaterialPage(
            key: ValueKey('customer-detail-${customer.uid}'),
            child: CustomerDetailScreen(customer: customer),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.quickOrder,
        builder: (context, state) {
          final customer = state.extra as UserModel?;
          return QuickOrderScreen(customer: customer);
        },
      ),

      // Delivery
      GoRoute(
        path: AppRoutes.deliveryHome,
        builder: (context, state) => const DeliveryHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.deliveryDetail,
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return MaterialPage(
            key: ValueKey('delivery-detail-$orderId'),
            child: DeliveryDetailScreen(orderId: orderId),
          );
        },
      ),

      // Admin
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.productManagement,
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.productNew,
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.productEdit,
        pageBuilder: (context, state) {
          final productId = state.pathParameters['id'];
          return MaterialPage(
            key: ValueKey('product-edit-$productId'),
            child: ProductFormScreen(productId: productId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderManagement,
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminOrderDetail,
        pageBuilder: (context, state) {
          final orderId = state.pathParameters['id']!;
          return MaterialPage(
            key: ValueKey('admin-order-$orderId'),
            child: AdminOrderDetailScreen(orderId: orderId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUserDetail,
        pageBuilder: (context, state) {
          final userId = state.pathParameters['id']!;
          return MaterialPage(
            key: ValueKey('admin-user-$userId'),
            child: UserDetailScreen(userId: userId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.categoryManagement,
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminTerminal,
        builder: (context, state) => const AdminTerminalScreen(),
      ),

      // Notifications — ShellRoute içinden push edilir
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Address — ShellRoute içinden push edilir
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.addressSelection,
        builder: (context, state) {
          final isSelectionMode =
              state.uri.queryParameters['select'] == 'true';
          return AddressSelectionScreen(isSelectionMode: isSelectionMode);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.addressForm,
        builder: (context, state) {
          final address = state.extra as AddressModel?;
          return AddressFormScreen(address: address);
        },
      ),

      // FAZ 5 — tam sayfa, ShellRoute disinda
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.subscription,
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.campaigns,
        builder: (context, state) => const CampaignsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: AppRoutes.help,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavKey,
        path: '${AppRoutes.review}/:orderId',
        builder: (context, state) {
          final orderId =
              int.tryParse(state.pathParameters['orderId'] ?? '0') ?? 0;
          return ReviewScreen(orderId: orderId);
        },
      ),
    ],
  );
});

// Customer shell with bottom nav
class CustomerShell extends StatelessWidget {
  final Widget child;
  const CustomerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNavWrapper(),
    );
  }
}

class _BottomNavWrapper extends StatelessWidget {
  const _BottomNavWrapper();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.navBg,
        boxShadow: [
          BoxShadow(
            offset: Offset(0, -4),
            blurRadius: 20,
            color: Color(0x0F141E3C),
          ),
        ],
      ),
      child: _BottomNav(),
    );
  }
}

class _BottomNav extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith(AppRoutes.cart)) currentIndex = 1;
    if (location.startsWith(AppRoutes.orders)) currentIndex = 2;
    if (location.startsWith(AppRoutes.profile)) currentIndex = 3;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: AppColors.navBg,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textHint,
      elevation: 0,
      onTap: (index) {
        switch (index) {
          case 0: context.go(AppRoutes.home); break;
          case 1: context.go(AppRoutes.cart); break;
          case 2: context.go(AppRoutes.orders); break;
          case 3: context.go(AppRoutes.profile); break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: _NavIcon(path: AssetPaths.icNavHome, isActive: currentIndex == 0),
          label: 'Ana Sayfa',
        ),
        BottomNavigationBarItem(
          icon: _NavIcon(path: AssetPaths.icNavCart, isActive: currentIndex == 1),
          label: 'Sepet',
        ),
        BottomNavigationBarItem(
          icon: _NavIcon(path: AssetPaths.icNavOrders, isActive: currentIndex == 2),
          label: 'Siparişler',
        ),
        BottomNavigationBarItem(
          icon: _NavIcon(path: AssetPaths.icNavProfile, isActive: currentIndex == 3),
          label: 'Profil',
        ),
      ],
    );
  }
}

/// SVG navigation ikonu — active=primary pembe, inactive=textHint gri
class _NavIcon extends StatelessWidget {
  final String path;
  final bool isActive;

  const _NavIcon({required this.path, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      path,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        isActive ? AppColors.primary : AppColors.textSecondary,
        BlendMode.srcIn,
      ),
    );
  }
}
