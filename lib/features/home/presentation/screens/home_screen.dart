import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../products/data/repositories/category_repository.dart' show rootCategoriesProvider;
import '../../../products/data/repositories/product_repository.dart';
import '../../../cart/presentation/bloc/cart_provider.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../../notifications/presentation/bloc/notification_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.asData?.value;
    final userId = user?.uid;
    final unreadCount =
        userId != null ? ref.watch(unreadCountProvider(userId)) : 0;
    final isStaff = user?.isStaff ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Image.asset(
              'assets/images/app_icon.png',
              height: 52,
              fit: BoxFit.contain,
            ),
            titleSpacing: 8,
            actions: [
              // Panele Dön — sadece staff rollerinde görünür
              if (isStaff)
                _PanelBackButton(user: user!),
              // Notification badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push(AppRoutes.notifications),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount > 99
                              ? '99+'
                              : unreadCount.toString(),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Cart badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.go(AppRoutes.cart),
                  ),
                  if (cart.totalItems > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          cart.totalItems.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: GestureDetector(
                    onTap: () => context.go('${AppRoutes.productList}?search=true'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppColors.textHint, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Ürün ara...',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Announcement Banner
                const _AnnouncementBanner(),

                const SizedBox(height: 24),

                // Categories
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kategoriler',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.productList),
                        child: const Text('Tümü'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),
                const _CategoriesRow(),

                const SizedBox(height: 24),

                // Featured Products
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Öne Çıkan Ürünler',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const _FeaturedProductsGrid(),

                const SizedBox(height: 24),

                // All Products
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Tüm Ürünler',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const _AllProductsGrid(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBanner extends ConsumerWidget {
  const _AnnouncementBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nisa Ticaret\'e Hoş Geldiniz!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Temiz su, hızlı teslimat',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => context.go(AppRoutes.productList),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(100, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  child: const Text('Sipariş Ver'),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.water_drop,
            size: 64,
            color: Colors.white24,
          ),
        ],
      ),
    );
  }
}

class _CategoriesRow extends ConsumerWidget {
  const _CategoriesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(rootCategoriesProvider);

    return SizedBox(
      height: 96,
      child: categoriesAsync.when(
        loading: () => _buildShimmer(),
        error: (error, _) => _ErrorRow(
          message: 'Kategoriler yüklenemedi',
          onRetry: () => ref.invalidate(rootCategoriesProvider),
        ),
        data: (categories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CategoryCard(
                category: category,
                onTap: () => context.go(
                  '${AppRoutes.productList}?categoryId=${category.id}',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          width: 72,
          height: 96,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _FeaturedProductsGrid extends ConsumerWidget {
  const _FeaturedProductsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(featuredProductsProvider);

    return productsAsync.when(
      loading: () => _buildShimmer(),
      error: (error, _) => _ErrorRow(
        message: 'Öne çıkan ürünler yüklenemedi',
        onRetry: () => ref.invalidate(featuredProductsProvider),
      ),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 160,
                  child: ProductCard(product: products[index]),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return SizedBox(
      height: 220,
      child: Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.surface,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => Container(
            width: 160,
            height: 220,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _AllProductsGrid extends ConsumerWidget {
  const _AllProductsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(allProductsProvider);

    return productsAsync.when(
      loading: () => _buildShimmer(context),
      error: (error, _) => _ErrorRow(
        message: 'Ürünler yüklenemedi',
        onRetry: () => ref.invalidate(allProductsProvider),
      ),
      data: (products) {
        final isTablet = MediaQuery.of(context).size.width >= 600;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isTablet ? 3 : 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            return ProductCard(product: products[index]);
          },
        );
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: isTablet ? 6 : 4,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.surface,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorRow({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tekrar Dene'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// Panel geri dönüş butonu — sadece staff rollerinde görünür
class _PanelBackButton extends StatelessWidget {
  final UserModel user;
  const _PanelBackButton({required this.user});

  String get _panelRoute {
    switch (user.role) {
      case UserRole.admin:
        return AppRoutes.adminHome;
      case UserRole.fieldAgent:
        return AppRoutes.fieldAgentHome;
      case UserRole.delivery:
        return AppRoutes.deliveryHome;
      case UserRole.customer:
        return AppRoutes.home;
    }
  }

  String get _panelLabel {
    switch (user.role) {
      case UserRole.admin:
        return 'Yönetim';
      case UserRole.fieldAgent:
        return 'Terminal';
      case UserRole.delivery:
        return 'Teslimat';
      case UserRole.customer:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.go(_panelRoute),
      icon: const Icon(Icons.arrow_back_ios_new, size: 14),
      label: Text(_panelLabel, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
