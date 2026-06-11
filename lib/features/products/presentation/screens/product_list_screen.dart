import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/cart/presentation/bloc/cart_provider.dart';
import 'package:nisa_ticaret/features/home/widgets/product_card.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';
import 'package:nisa_ticaret/features/products/data/repositories/category_repository.dart' show categoriesProvider, rootCategoriesProvider, subCategoriesProvider;
import 'package:nisa_ticaret/features/products/data/repositories/product_repository.dart'
    show productsPageProvider;
import 'package:nisa_ticaret/features/products/presentation/bloc/product_list_provider.dart';
import 'package:nisa_ticaret/features/products/presentation/providers/api_products_provider.dart' show apiProductsByCategoryProvider, apiSearchResultsProvider;

class ProductListScreen extends ConsumerStatefulWidget {
  final String? categoryId;

  const ProductListScreen({super.key, this.categoryId});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.categoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(productListProvider.notifier)
            .setCategory(widget.categoryId);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(productListProvider);
    final cart = ref.watch(cartProvider);
    final user = ref.watch(authStateProvider).asData?.value;

    final searchQuery = listState.searchQuery.trim();

    // Arama modunda API search kullan
    if (searchQuery.isNotEmpty) {
      final searchAsync = ref.watch(apiSearchResultsProvider(searchQuery))
          .whenData((e) => e.map((x) => x.toProductModel()).toList());
      return _buildScrollView(
        context, cart.totalItems, user, listState,
        productsAsync: searchAsync,
        isSearchMode: true,
      );
    }

    // Kategori seçiliyken server-side filtreleme yap — client-side filtreleme
    // sadece yüklü ürünlere uygulandığından kategori ürünleri eksik görünür.
    final selectedCategoryId = listState.selectedCategoryId;
    if (selectedCategoryId != null) {
      final categoryAsync = ref
          .watch(apiProductsByCategoryProvider(selectedCategoryId))
          .whenData((e) => e.map((x) => x.toProductModel()).toList());
      return _buildScrollView(
        context, cart.totalItems, user, listState,
        productsAsync: categoryAsync,
        serverFiltered: true,
      );
    }

    final pageState = ref.watch(productsPageProvider);
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            _scrollController.position.extentAfter < 200) {
          ref.read(productsPageProvider.notifier).loadMore();
        }
        return false;
      },
      child: _buildScrollView(
        context, cart.totalItems, user, listState,
        productsAsync: pageState.whenData((s) => s.products),
        isLoadingMore: pageState.value?.isLoadingMore ?? false,
        hasServerMore: pageState.value?.hasMore ?? false,
      ),
    );
  }

  Widget _buildScrollView(
    BuildContext context,
    int cartCount,
    UserModel? user,
    ProductListState listState, {
    required AsyncValue<List<ProductModel>> productsAsync,
    bool isSearchMode = false,
    bool isLoadingMore = false,
    bool hasServerMore = false,
    bool serverFiltered = false,
  }) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(context, cartCount, user),
        SliverToBoxAdapter(
          child: _CategorySection(
            selectedCategoryId: listState.selectedCategoryId,
          ),
        ),
        SliverToBoxAdapter(
          child: _SortRow(currentSort: listState.sortOption),
        ),
        productsAsync.when(
          loading: () => _buildShimmerGrid(context),
          error: (e, _) => SliverToBoxAdapter(
            child: _ErrorState(
              onRetry: () => ref.invalidate(productsPageProvider),
            ),
          ),
          data: (all) {
            // serverFiltered=true ise API zaten kategoriyle filtreledi,
            // tekrar client-side kategori filtresi uygulanmaz.
            final filtered = serverFiltered
                ? listState.sortedAndSearchFiltered(all)
                : listState.allFilteredProducts(all);
            if (filtered.isEmpty) {
              return SliverToBoxAdapter(
                child: _EmptyState(
                  onReset: () {
                    _searchController.clear();
                    ref.read(productListProvider.notifier).reset();
                  },
                ),
              );
            }
            return _ProductGrid(
              products: filtered,
              hasMore: false, // sunucu tarafı lazy loading yönetiyor
            );
          },
        ),
        // Daha fazla yükleniyor göstergesi
        if (isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, int cartCount, UserModel? user) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      title: Text(
        'Ürünler',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      actions: [
        if (user != null && user.isStaff)
          _PanelBackButton(user: user),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => context.go(AppRoutes.cart),
            ),
            if (cartCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      cartCount > 99 ? '99+' : '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchController,
            onChanged: (v) =>
                ref.read(productListProvider.notifier).setSearch(v),
            decoration: InputDecoration(
              hintText: 'Ürün ara...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textHint,
                size: 20,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      color: AppColors.textHint,
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(productListProvider.notifier)
                            .setSearch('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Category chips section
// ─────────────────────────────────────────────

class _CategorySection extends ConsumerWidget {
  final String? selectedCategoryId;

  const _CategorySection({
    required this.selectedCategoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rootAsync = ref.watch(rootCategoriesProvider);
    final listState = ref.watch(productListProvider);
    final isRootSelected = listState.hasRootCategorySelected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 48,
          child: rootAsync.when(
            loading: () => _buildShimmerChips(),
            error: (_, __) => const SizedBox.shrink(),
            data: (roots) => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'Tümünü',
                  isSelected: selectedCategoryId == null,
                  onTap: () =>
                      ref.read(productListProvider.notifier).setCategory(null),
                ),
                ...roots.map((cat) => _CategoryChip(
                      label: cat.name,
                      isSelected: selectedCategoryId == cat.id,
                      onTap: () => _selectRoot(ref, cat.id),
                    )),
              ],
            ),
          ),
        ),
        // Alt kategori satırı — kök seçiliyse ve alt kategori varsa
        if (selectedCategoryId != null)
          _SubCategoryRow(
            parentId: selectedCategoryId!,
            isRootSelected: isRootSelected,
          ),
      ],
    );
  }

  void _selectRoot(WidgetRef ref, String rootId) {
    // Alt kategorileri anında al — categoriesProvider zaten yüklü
    final allCats = ref.read(categoriesProvider).value ?? [];
    final subIds = allCats
        .where((c) => c.parentId == rootId)
        .map((c) => c.id)
        .toList();
    if (subIds.isNotEmpty) {
      ref.read(productListProvider.notifier).setRootCategory(rootId, subIds);
    } else {
      ref.read(productListProvider.notifier).setCategory(rootId);
    }
  }

  Widget _buildShimmerChips() {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Container(
          width: 80,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _SubCategoryRow extends ConsumerWidget {
  final String parentId;
  final bool isRootSelected;

  const _SubCategoryRow({
    required this.parentId,
    required this.isRootSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subAsync = ref.watch(subCategoriesProvider(parentId));

    return subAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (subs) {
        if (subs.isEmpty) return const SizedBox.shrink();

        // İlk yüklemede kök+alt kategorileri birlikte filtrele
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final state = ref.read(productListProvider);
          if (state.categoryFilterIds == null && state.selectedCategoryId == parentId) {
            ref.read(productListProvider.notifier).setRootCategory(
              parentId,
              subs.map((s) => s.id).toList(),
            );
          }
        });

        final listState = ref.watch(productListProvider);
        final selectedSubId = (!isRootSelected) ? listState.selectedCategoryId : null;

        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            children: [
              _CategoryChip(
                label: 'Tümü',
                isSelected: selectedSubId == null || selectedSubId == parentId,
                onTap: () => ref.read(productListProvider.notifier).setRootCategory(
                  parentId,
                  subs.map((s) => s.id).toList(),
                ),
              ),
              ...subs.map((sub) => _CategoryChip(
                    label: sub.name,
                    isSelected: selectedSubId == sub.id,
                    onTap: () => ref
                        .read(productListProvider.notifier)
                        .setCategory(sub.id),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Sort row
// ─────────────────────────────────────────────

class _SortRow extends ConsumerWidget {
  final SortOption currentSort;

  const _SortRow({required this.currentSort});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Text(
            'Sırala:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: SortOption.values.map((option) {
                  final isSelected = currentSort == option;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => ref
                          .read(productListProvider.notifier)
                          .setSortOption(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          _sortLabel(option),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(SortOption option) {
    switch (option) {
      case SortOption.nameAsc:
        return 'A-Z';
      case SortOption.nameDesc:
        return 'Z-A';
      case SortOption.priceAsc:
        return 'Ucuzdan Pahalıya';
      case SortOption.priceDesc:
        return 'Pahalıdan Ucuza';
      case SortOption.popularity:
        return 'Popüler';
    }
  }
}

// ─────────────────────────────────────────────
// Product grid
// ─────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final bool hasMore;

  const _ProductGrid({required this.products, required this.hasMore});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == products.length) {
              return _LoadingMoreIndicator(hasMore: hasMore);
            }
            return ProductCard(product: products[index]);
          },
          childCount: products.length + (hasMore ? 1 : 0),
        ),
      ),
    );
  }
}

class _LoadingMoreIndicator extends StatelessWidget {
  final bool hasMore;

  const _LoadingMoreIndicator({required this.hasMore});

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Shimmer loading grid
// ─────────────────────────────────────────────

Widget _buildShimmerGrid(BuildContext context) {
  final isTablet = MediaQuery.of(context).size.width >= 600;
  return SliverPadding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
    sliver: SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isTablet ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      delegate: SliverChildBuilderDelegate(
        (_, __) => Shimmer.fromColors(
          baseColor: AppColors.border,
          highlightColor: AppColors.surface,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        childCount: isTablet ? 6 : 4,
      ),
    ),
  );
}

// ─────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Ürünler yüklenemedi',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'İnternet bağlantınızı kontrol edin',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: onRetry,
              child: const Text('Tekrar Dene'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onReset;

  const _EmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_outlined,
            size: 64,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'Ürün bulunamadı',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Arama kriterlerinizi değiştirmeyi deneyin',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onReset,
            child: const Text('Filtreleri Temizle'),
          ),
        ],
      ),
    );
  }
}

class _PanelBackButton extends StatelessWidget {
  final UserModel user;
  const _PanelBackButton({required this.user});

  String get _route => switch (user.role) {
        UserRole.admin => AppRoutes.adminHome,
        UserRole.fieldAgent => AppRoutes.fieldAgentHome,
        UserRole.delivery => AppRoutes.deliveryHome,
        UserRole.customer => AppRoutes.home,
      };

  String get _label => switch (user.role) {
        UserRole.admin => 'Yönetim',
        UserRole.fieldAgent => 'Terminal',
        UserRole.delivery => 'Teslimat',
        UserRole.customer => '',
      };

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context.go(_route),
      icon: const Icon(Icons.arrow_back_ios_new, size: 14),
      label: Text(_label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}
