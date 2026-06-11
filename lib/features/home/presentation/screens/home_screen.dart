import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../products/data/repositories/category_repository.dart' show rootCategoriesProvider, subCategoriesProvider;
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../products/presentation/bloc/product_list_provider.dart';
import '../../../products/presentation/providers/api_products_provider.dart' show apiProductsByCategoryProvider;
import '../../../cart/presentation/bloc/cart_provider.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';
import '../../../notifications/presentation/bloc/notification_provider.dart';
import '../../../campaigns/presentation/providers/campaigns_provider.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../orders/data/repositories/address_repository.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();
  final _productsKey = GlobalKey();
  bool _searchActive = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollToProducts() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _productsKey.currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _clearFilter() {
    ref.read(productListProvider.notifier).reset();
    _searchController.clear();
    setState(() => _searchActive = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final userAsync = ref.watch(authStateProvider);
    final user = userAsync.asData?.value;
    final userId = user?.uid;
    final unreadCount =
        userId != null ? ref.watch(unreadCountProvider(userId)) : 0;
    final isStaff = user?.isStaff ?? false;
    final filterState = ref.watch(productListProvider);
    final hasFilter = filterState.selectedCategoryId != null ||
        filterState.searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            title: _searchActive
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Ürün ara...',
                      hintStyle:
                          const TextStyle(color: AppColors.textHint, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textHint, size: 20),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (v) {
                      ref
                          .read(productListProvider.notifier)
                          .setSearch(v);
                      if (v.isNotEmpty) _scrollToProducts();
                    },
                  )
                : Image.asset(
                    'assets/images/app_icon.png',
                    height: 52,
                    fit: BoxFit.contain,
                  ),
            titleSpacing: 8,
            actions: [
              if (_searchActive)
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () {
                    ref.read(productListProvider.notifier).setSearch('');
                    _searchController.clear();
                    setState(() => _searchActive = false);
                  },
                )
              else ...[
              if (isStaff) _PanelBackButton(user: user!),
              IconButton(
                icon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondary),
                onPressed: () => setState(() => _searchActive = true),
              ),
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
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
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
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Teslimat Adresi Bar
                _DeliveryAddressBar(user: user),

                const SizedBox(height: 16),

                // Campaign Carousel — sadece filtre yokken
                if (!hasFilter) ...[
                  const _CampaignCarousel(),
                  const SizedBox(height: 24),
                ],

                // Categories Section
                _SectionHeader(
                  title: 'Kategoriler',
                  icon: Icons.grid_view_rounded,
                  actionLabel: hasFilter ? 'Temizle' : null,
                  onAction: hasFilter ? _clearFilter : null,
                ),
                const SizedBox(height: 4),
                _CategoriesRow(
                  onCategorySelected: _scrollToProducts,
                ),

                const SizedBox(height: 24),

                // Featured Products — sadece filtre yokken
                if (!hasFilter) ...[
                  _SectionHeader(
                    title: 'Öne Çıkanlar',
                    icon: Icons.star_outline_rounded,
                    actionLabel: 'Tümünü Gör',
                    onAction: _scrollToProducts,
                  ),
                  const SizedBox(height: 12),
                  const _FeaturedProductsGrid(),
                  const SizedBox(height: 24),
                ],

                // All Products
                _SectionHeader(
                  key: _productsKey,
                  title: hasFilter ? _filterTitle(filterState) : 'Tüm Ürünler',
                  icon: Icons.inventory_2_outlined,
                ),
                const SizedBox(height: 12),
                _AllProductsGrid(),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _filterTitle(ProductListState state) {
    if (state.searchQuery.isNotEmpty) {
      return '"${state.searchQuery}" Sonuçları';
    }
    return 'Ürünler';
  }
}

// ---------------------------------------------------------------------------
// _DeliveryAddressBar
// ---------------------------------------------------------------------------
class _DeliveryAddressBar extends ConsumerWidget {
  final UserModel? user;
  const _DeliveryAddressBar({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const SizedBox.shrink();

    final defaultAddress = ref.watch(defaultAddressProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        onTap: () async {
          await context.push('${AppRoutes.addressSelection}?select=true');
          await ref.read(cacheManagerProvider).invalidateByPrefix(CacheKeys.addresses);
          ref.invalidate(addressesProvider);
        },
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Teslimat Adresi',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        defaultAddress != null
                            ? defaultAddress.fullAddress
                            : 'Teslimat adresi ekleyin',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (defaultAddress != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      defaultAddress.label,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionHeader
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.secondary),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CampaignCarousel
// ---------------------------------------------------------------------------
class _CampaignCarousel extends ConsumerStatefulWidget {
  const _CampaignCarousel();

  @override
  ConsumerState<_CampaignCarousel> createState() => _CampaignCarouselState();
}

class _CampaignCarouselState extends ConsumerState<_CampaignCarousel> {
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients) return;
      final next = (_currentPage + 1) % count;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(activeCampaignsProvider);

    return campaignsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (campaigns) {
        if (campaigns.isEmpty) return const SizedBox.shrink();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startAutoScroll(campaigns.length);
        });

        return Column(
          children: [
            SizedBox(
              height: 150,
              child: PageView.builder(
                controller: _controller,
                itemCount: campaigns.length,
                onPageChanged: (index) {
                  if (mounted) setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _CampaignBannerPage(campaign: campaigns[index]);
                },
              ),
            ),
            if (campaigns.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(campaigns.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 8 : 6,
                    height: isActive ? 8 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.30),
                    ),
                  );
                }),
              ),
            ],
          ],
        );
      },
    );
  }

}

class _CampaignBannerPage extends StatelessWidget {
  final dynamic campaign;

  const _CampaignBannerPage({required this.campaign});

  @override
  Widget build(BuildContext context) {
    final imageUrl = campaign.imageUrl as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildGradientBanner(),
              errorWidget: (_, __, ___) => _buildGradientBanner(),
            )
          : _buildGradientBanner(),
    );
  }

  Widget _buildGradientBanner() {
    final value = campaign.formattedValue as String;
    final name = campaign.name as String;
    final description = campaign.description as String?;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CategoriesRow — kategori seçimi ile inline filtreleme
// ---------------------------------------------------------------------------
class _CategoriesRow extends ConsumerWidget {
  final VoidCallback onCategorySelected;

  const _CategoriesRow({required this.onCategorySelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(rootCategoriesProvider);
    final filterState = ref.watch(productListProvider);
    final selectedId = filterState.selectedCategoryId;

    return SizedBox(
      height: 112,
      child: categoriesAsync.when(
        loading: () => _buildShimmer(),
        error: (error, _) => _ErrorRow(
          message: 'Kategoriler yüklenemedi',
          onRetry: () => ref.invalidate(rootCategoriesProvider),
        ),
        data: (categories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category.id == selectedId;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CategoryCard(
                category: category,
                isSelected: isSelected,
                onTap: () async {
                  if (isSelected) {
                    ref.read(productListProvider.notifier).setCategory(null);
                  } else {
                    // Alt kategorileri de dahil et (setRootCategory)
                    final subCats = await ref
                        .read(subCategoriesProvider(category.id).future);
                    final subIds = subCats.map((c) => c.id).toList();
                    ref
                        .read(productListProvider.notifier)
                        .setRootCategory(category.id, subIds);
                    onCategorySelected();
                  }
                },
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
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          width: 72,
          height: 88,
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

// ---------------------------------------------------------------------------
// _FeaturedProductsGrid
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// _AllProductsGrid — kategori seçiliyken server-side, seçilmezken allProducts
// ---------------------------------------------------------------------------
class _AllProductsGrid extends ConsumerWidget {
  const _AllProductsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(productListProvider);
    final selectedCategoryId = filterState.selectedCategoryId;

    // Kategori seçiliyken server-side filtrele — tüm ürünleri çekip
    // client-side filtrelemek yerine API'ye category_id gönder.
    // (allProductsProvider 168 ürünü çekmek için birden fazla sayfa yapar
    // ve cache kirlenince yanlış sayfalanmış sonuç dönebilir.)
    if (selectedCategoryId != null) {
      final categoryAsync =
          ref.watch(apiProductsByCategoryProvider(selectedCategoryId));
      return categoryAsync.when(
        loading: () => _buildShimmer(context),
        error: (_, __) => _ErrorRow(
          message: 'Ürünler yüklenemedi',
          onRetry: () =>
              ref.invalidate(apiProductsByCategoryProvider(selectedCategoryId)),
        ),
        data: (entities) {
          final products = entities.map((e) => e.toProductModel()).toList();
          // Sıralama + arama uygula, kategori filtresi server'da yapıldı
          final sorted = filterState.sortedAndSearchFiltered(products);
          if (sorted.isEmpty) return _buildEmpty(filterState);
          return _buildGrid(context, sorted);
        },
      );
    }

    // Kategori seçili değil — sayfalanmış ilk 50 ürünü göster.
    // allProductsProvider yerine productsPageProvider kullanılır:
    // tüm 168 ürünü sıralı çekmek (2×API = ~10s) yerine ilk sayfa anında.
    final pageAsync = ref.watch(productsPageProvider);
    return pageAsync.when(
      loading: () => _buildShimmer(context),
      error: (error, _) => _ErrorRow(
        message: 'Ürünler yüklenemedi',
        onRetry: () => ref.invalidate(productsPageProvider),
      ),
      data: (pageState) {
        final filtered =
            filterState.sortedAndSearchFiltered(pageState.products);
        if (filtered.isEmpty) {
          return _buildEmpty(filterState);
        }
        return _buildGrid(context, filtered);
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<ProductModel> products) {
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
  }

  Widget _buildEmpty(ProductListState state) {
    final isSearch = state.searchQuery.isNotEmpty;
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.category_outlined,
                size: 38,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch
                  ? '"${state.searchQuery}" için ürün bulunamadı'
                  : 'Bu kategoride ürün yok',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearch
                  ? 'Farklı bir arama terimi deneyin'
                  : 'Yakında eklenecek ürünler için takipte kalın',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
