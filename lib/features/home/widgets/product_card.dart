import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation_guard.dart';
import '../../cart/presentation/bloc/cart_provider.dart';
import '../../products/data/models/product_model.dart';
import '../../products/data/providers/favorites_provider.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  final bool showAddButton;

  const ProductCard({
    super.key,
    required this.product,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final koliVariant = product.koliVariant;
    // select(): sadece bu ürünün miktarı değişince rebuild — liste N kart içeriyor.
    final qty = ref.watch(
      cartProvider.select(
        (c) => c.quantityOf(product.id, variantId: koliVariant?.id),
      ),
    );

    // Gösterilecek fiyat: koli varsa koli fiyatı, yoksa product fallback
    final displayPrice =
        koliVariant?.effectivePrice ?? product.effectivePrice;
    final originalPrice = koliVariant?.price ?? product.price;
    final showDiscount = koliVariant?.hasDiscount ?? product.hasDiscount;
    final discountPct =
        koliVariant?.discountPercent ?? product.discountPercent;
    final isInStock = koliVariant?.inStock ?? product.inStock;

    return GestureDetector(
      onTap: () =>
          context.safePush(AppRoutes.productDetail.replaceFirst(':id', product.id)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [AppShadows.sm],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — grid hücresinin kalan yüksekliğini doldurur
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.imageBg,
                      padding: const EdgeInsets.all(8),
                      child: product.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: product.imageUrl!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child: Icon(
                                  Icons.water_drop_outlined,
                                  color: AppColors.accent,
                                  size: 40,
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.water_drop_outlined,
                                  color: AppColors.accent,
                                  size: 40,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.water_drop_outlined,
                                color: AppColors.accent,
                                size: 40,
                              ),
                            ),
                    ),
                  ),
                  // Featured badge — sol üst
                  if (product.isFeatured)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.tealLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YENİ',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Discount badge — sol üst (featured badge'in altına)
                  if (showDiscount)
                    Positioned(
                      top: product.isFeatured ? 36 : 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.pinkLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '%-${discountPct.toInt()}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Favori butonu — sağ üst (her zaman görünür)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => ref.read(favoritesProvider.notifier).toggle(product.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [AppShadows.sm],
                        ),
                        child: ref.watch(favoritesProvider).when(
                          data: (ids) => Icon(
                            ids.contains(product.id) ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: ids.contains(product.id) ? AppColors.primary : AppColors.textHint,
                          ),
                          loading: () => const Icon(Icons.favorite_border, size: 16, color: AppColors.textHint),
                          error: (_, __) => const Icon(Icons.favorite_border, size: 16, color: AppColors.textHint),
                        ),
                      ),
                    ),
                  ),
                  // Out of stock overlay
                  if (!isInStock)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Container(
                          color: Colors.black26,
                          child: const Center(
                            child: Text(
                              'Stok Yok',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info — sabit yükseklik, taşmaz
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDiscount)
                            Text(
                              '₺${originalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            displayPrice > 0
                                ? '₺${displayPrice.toStringAsFixed(2)}'
                                : 'Fiyat yok',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: displayPrice > 0
                                  ? AppColors.primary
                                  : AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                      if (showAddButton && isInStock)
                        qty == 0
                            ? _AddButton(
                                product: product,
                                koliVariantId: koliVariant?.id,
                              )
                            : _QtyControl(
                                product: product,
                                qty: qty,
                                koliVariantId: koliVariant?.id,
                              ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends ConsumerWidget {
  final ProductModel product;
  final String? koliVariantId;

  const _AddButton({required this.product, this.koliVariantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final koliVariant = product.koliVariant;
        if (koliVariant != null) {
          ref.read(cartProvider.notifier).addItem(product, variant: koliVariant);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} sepete eklendi'),
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          context.safePush(
              AppRoutes.productDetail.replaceFirst(':id', product.id));
        }
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}

class _QtyControl extends ConsumerWidget {
  final ProductModel product;
  final int qty;
  final String? koliVariantId;

  const _QtyControl({
    required this.product,
    required this.qty,
    this.koliVariantId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => ref
                .read(cartProvider.notifier)
                .decreaseItem(product.id, variantId: koliVariantId),
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.remove, size: 16, color: AppColors.primary),
            ),
          ),
          Text(
            qty.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
          GestureDetector(
            onTap: () {
              final koliVariant = product.koliVariant;
              ref
                  .read(cartProvider.notifier)
                  .addItem(product, variant: koliVariant);
            },
            child: const SizedBox(
              width: 32,
              height: 32,
              child: Icon(Icons.add, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
