import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/products/data/providers/favorites_provider.dart';
import 'package:nisa_ticaret/features/products/data/repositories/product_repository.dart';
import 'package:nisa_ticaret/features/home/widgets/product_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favoritesProvider);
    final allAsync = ref.watch(allProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 24),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: const Text('Favorilerim'),
      ),
      body: favAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (_, __) => _EmptyFavorites(onTap: () => context.go(AppRoutes.home)),
        data: (favIds) {
          if (favIds.isEmpty) {
            return _EmptyFavorites(onTap: () => context.go(AppRoutes.home));
          }
          return allAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (_, __) => _EmptyFavorites(onTap: () => context.go(AppRoutes.home)),
            data: (products) {
              final favProducts = products.where((p) => favIds.contains(p.id)).toList();
              if (favProducts.isEmpty) {
                return _EmptyFavorites(onTap: () => context.go(AppRoutes.home));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: favProducts.length,
                itemBuilder: (_, i) => ProductCard(product: favProducts[i]),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyFavorites({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.pinkLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_border, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz favori eklemedin',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Beğendiğin ürünleri favorilere ekle',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: onTap,
              child: const Text('Ürünlere Git'),
            ),
          ),
        ],
      ),
    );
  }
}
