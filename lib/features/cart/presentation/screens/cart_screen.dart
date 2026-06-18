import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/core/widgets/error_display_widget.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/cart/data/models/cart_model.dart';
import 'package:nisa_ticaret/features/cart/presentation/bloc/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context, ref, cart),
      body: cart.isEmpty ? _buildEmptyState(context) : _buildCartContent(context, ref, cart),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref, CartModel cart) {
    return AppBar(
      backgroundColor: AppColors.surface,
      leading: context.canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => context.pop(),
            )
          : null,
      title: Row(
        children: [
          const Text('Sepetim'),
          if (!cart.isEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${cart.totalItems}',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!cart.isEmpty)
          TextButton(
            onPressed: () => _showClearConfirmDialog(context, ref),
            child: const Text(
              'Temizle',
              style: TextStyle(color: AppColors.error),
            ),
          ),
      ],
    );
  }

  Widget _buildCartContent(BuildContext context, WidgetRef ref, CartModel cart) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            itemCount: cart.items.length,
            itemBuilder: (context, index) {
              return _CartItemCard(item: cart.items[index]);
            },
          ),
        ),
        _CartSummary(cart: cart),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.shopping_cart_outlined,
      title: 'Sepetiniz boş',
      subtitle: 'Ürünleri keşfetmek için ana sayfaya dön',
      ctaLabel: 'Ürünleri Keşfet',
      onCta: () => context.go(AppRoutes.home),
    );
  }

  void _showClearConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_sweep_outlined,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              // Başlık
              const Text(
                'Sepeti Temizle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Açıklama
              const Text(
                'Sepetteki tüm ürünler kaldırılacak.\nBu işlem geri alınamaz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // Butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Vazgeç',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).clear();
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Temizle',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CartItemCard
// ---------------------------------------------------------------------------

class _CartItemCard extends ConsumerWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  /// Varyant adi, urun adiyla ayni/birebir tekrar ediyorsa ikinci kez
  /// gosterilmez (UI'da anlamsiz tekrar olusmasin diye).
  bool _showVariantLabel(CartItem item) {
    final variant = item.variant;
    if (variant == null || variant.name.trim().isEmpty) return false;

    final variantName = variant.name.trim().toLowerCase();
    final productName = item.product.name.trim().toLowerCase();

    if (variantName == productName) return false;
    if (productName.contains(variantName)) return false;

    return true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final product = item.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Urun gorseli
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60,
              height: 60,
              child: _ProductImage(imageUrl: product.allImages.isNotEmpty ? product.allImages.first : null),
            ),
          ),

          const SizedBox(width: 12),

          // Urun bilgisi + miktar + fiyat
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (_showVariantLabel(item))
                  Text(
                    item.variant!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  '${_formatPrice(item.unitPrice)} / ${item.variant?.unit ?? product.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyControl(item: item),
                    const Spacer(),
                    Text(
                      _formatPrice(item.total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Sil butonu
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () =>
                notifier.removeItem(product.id, variantId: item.variant?.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProductImage
// ---------------------------------------------------------------------------

class _ProductImage extends StatelessWidget {
  final String? imageUrl;

  const _ProductImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: AppColors.border,
        child: const Icon(
          Icons.water_drop_outlined,
          color: AppColors.textHint,
          size: 28,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.border,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: AppColors.border,
        child: const Icon(
          Icons.water_drop_outlined,
          color: AppColors.textHint,
          size: 28,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _QtyControl
// ---------------------------------------------------------------------------

class _QtyControl extends ConsumerWidget {
  final CartItem item;

  const _QtyControl({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cartProvider.notifier);
    final product = item.product;
    final variant = item.variant;
    final qty = item.quantity;
    final effectiveMaxQty = variant?.maxOrderQty ?? product.maxOrderQty;
    final effectiveStock = variant?.stock ?? product.stock;
    final canIncrease = qty < effectiveMaxQty && qty < effectiveStock;
    final variantId = variant?.id;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Azalt veya sil
          _QtyButton(
            onPressed: () async {
              if (qty == 1) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    title: const Text('Ürünü Kaldır',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    content: Text(
                      '${product.name} sepetten kaldırılsın mı?',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Kaldır',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  notifier.decreaseItem(product.id, variantId: variantId);
                }
              } else {
                notifier.decreaseItem(product.id, variantId: variantId);
              }
            },
            child: Icon(
              qty == 1 ? Icons.delete_outline : Icons.remove,
              size: 16,
              color: qty == 1 ? AppColors.error : AppColors.primary,
            ),
          ),

          // Miktar
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Text(
              '$qty',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Artir
          _QtyButton(
            onPressed: canIncrease
                ? () => notifier.updateQuantity(
                      product.id,
                      qty + 1,
                      variantId: variantId,
                    )
                : null,
            child: Icon(
              Icons.add,
              size: 16,
              color: canIncrease ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _QtyButton({required this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Center(child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CartSummary
// ---------------------------------------------------------------------------

class _CartSummary extends ConsumerWidget {
  final CartModel cart;

  const _CartSummary({required this.cart});

  double get _totalDiscount {
    return cart.items.fold(0.0, (sum, item) {
      final v = item.variant;
      if (v != null && v.hasDiscount) {
        return sum + (v.price - v.effectivePrice) * item.quantity;
      }
      return sum;
    });
  }

  bool get _hasProductDiscounts {
    return cart.items.any((item) => item.variant?.hasDiscount ?? false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discount = _totalDiscount;
    final hasDiscount = _hasProductDiscounts;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ara toplam
              _SummaryRow(
                label: 'Ara Toplam',
                value: _formatPrice(cart.subtotal),
              ),

              // Indirim (varsa)
              if (hasDiscount) ...[
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Indirim',
                  value: '-${_formatPrice(discount)}',
                  valueColor: AppColors.success,
                ),
              ],

              const Divider(color: AppColors.divider, height: 24),

              // Toplam
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toplam',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatPrice(cart.total),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Siparis tamamla butonu
              ElevatedButton(
                onPressed: () => _onCheckout(ref, context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textWhite,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Siparişi Tamamla',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCheckout(WidgetRef ref, BuildContext context) {
    final userAsync = ref.read(authStateProvider);
    userAsync.when(
      data: (user) {
        if (user == null) {
          // Login sonrası checkout'a dön
          ref.read(postLoginRouteProvider.notifier).set(AppRoutes.checkout);
          context.push(AppRoutes.phoneAuth);
        } else {
          context.push(AppRoutes.checkout);
        }
      },
      loading: () {},
      error: (_, __) {
        ref.read(postLoginRouteProvider.notifier).set(AppRoutes.checkout);
        context.push(AppRoutes.phoneAuth);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _SummaryRow
// ---------------------------------------------------------------------------

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Yardimci
// ---------------------------------------------------------------------------

String _formatPrice(double price) => '${price.toStringAsFixed(2)} TL';
