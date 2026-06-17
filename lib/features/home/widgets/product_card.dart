import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/navigation_guard.dart';
import '../../cart/presentation/bloc/cart_provider.dart';
import '../../products/data/models/product_model.dart';

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
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
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
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YENİ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // Discount badge — sağ üst
                  if (showDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '%${discountPct.toInt()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
                                fontSize: 10,
                                color: AppColors.textHint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            displayPrice > 0
                                ? '₺${displayPrice.toStringAsFixed(2)}'
                                : 'Fiyat yok',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
          ref
              .read(cartProvider.notifier)
              .addItem(product, variant: koliVariant);
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
          // Koli varyantı yok → detay sayfasına git
          context.push(
              AppRoutes.productDetail.replaceFirst(':id', product.id));
        }
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 18),
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
        border: Border.all(color: AppColors.secondary, width: 1.5),
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
              child: Icon(Icons.remove, size: 16, color: AppColors.secondary),
            ),
          ),
          Text(
            qty.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.secondary,
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
              child: Icon(Icons.add, size: 16, color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
