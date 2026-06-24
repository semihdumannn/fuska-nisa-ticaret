import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nisa_ticaret/core/config/app_config.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/core/error/failures.dart';
import 'package:nisa_ticaret/features/cart/presentation/bloc/cart_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/address_model.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/address_repository.dart';
import 'package:nisa_ticaret/features/orders/domain/usecases/create_order_usecase.dart';
import 'package:nisa_ticaret/features/orders/presentation/providers/api_orders_provider.dart';
import 'package:nisa_ticaret/features/products/data/models/variant_model.dart';
import 'package:nisa_ticaret/features/products/data/providers/product_data_providers.dart'
    show apiProductRepositoryProvider;

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  AddressModel? _selectedAddress;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String _note = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final defaultAddr = ref.read(defaultAddressProvider);
      if (_selectedAddress == null && defaultAddr != null) {
        setState(() => _selectedAddress = defaultAddr);
      }
    });
  }

  /// Sipariş öncesi variant fiyatlarını Firestore'dan tazeler.
  /// Fiyat değişmişse kullanıcıya dialog gösterir.
  /// true → devam et, false → kullanıcı iptal etti.
  Future<bool> _validatePrices() async {
    final cart = ref.read(cartProvider);
    final productRepo = ref.read(apiProductRepositoryProvider);

    final productIds = cart.items
        .where((i) => i.variant != null)
        .map((i) => i.product.id)
        .toSet();

    if (productIds.isEmpty) return true;

    final Map<String, VariantModel> updatedVariants = {};
    final List<_PriceChange> changes = [];

    for (final productId in productIds) {
      final result = await productRepo.getProductDetail(productId);
      final freshVariants = result.fold(
        (_) => <dynamic>[],
        (entity) => entity.variants,
      );

      for (final item
          in cart.items.where((i) => i.product.id == productId && i.variant != null)) {
        final matching = freshVariants.where((v) => v.id == item.variant!.id);
        if (matching.isEmpty) continue;
        final freshEntity = matching.first;
        final fresh = VariantModel(
          id: freshEntity.id,
          productId: freshEntity.productId,
          name: freshEntity.name,
          price: freshEntity.price,
          salePrice: freshEntity.salePrice,
          unit: freshEntity.unit,
          stock: freshEntity.stock,
          minOrderQty: freshEntity.minOrderQty,
          maxOrderQty: freshEntity.maxOrderQty,
          packageQty: freshEntity.packageQty,
          isActive: freshEntity.isActive,
          sku: freshEntity.sku,
          barcode: freshEntity.barcode,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        updatedVariants[fresh.id] = fresh;
        if ((fresh.effectivePrice - item.unitPrice).abs() > 0.001) {
          changes.add(_PriceChange(
            productName: item.product.name,
            variantName: item.variant!.name,
            oldPrice: item.unitPrice,
            newPrice: fresh.effectivePrice,
          ));
        }
      }
    }

    if (changes.isEmpty) return true;

    if (!mounted) return false;
    final confirmed = await _showPriceChangedDialog(changes);
    if (confirmed == true) {
      ref.read(cartProvider.notifier).updateVariants(updatedVariants);
      return true;
    }
    return false;
  }

  Future<bool?> _showPriceChangedDialog(List<_PriceChange> changes) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.price_change_outlined, color: AppColors.warning),
            SizedBox(width: 8),
            Text(
              'Fiyat Değişikliği',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sepetinizdeki bazı ürünlerin fiyatı güncellendi:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: changes.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${c.productName} — ${c.variantName}',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${c.oldPrice.toStringAsFixed(2)} TL',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textHint,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            Text(
                              '${c.newPrice.toStringAsFixed(2)} TL',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Yeni Fiyatla Devam Et'),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);
    try {
      // Minimum sipariş tutarı kontrolü
      final cart = ref.read(cartProvider);
      final minAmount = AppConfig.instance.minOrderAmount;
      if (cart.total < minAmount) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Minimum sipariş tutarı ${minAmount.toStringAsFixed(0)} TL\'dir. '
            'Sepetiniz: ${cart.total.toStringAsFixed(2)} TL',
          ),
          backgroundColor: AppColors.error,
        ));
        setState(() => _isLoading = false);
        return;
      }

      final canProceed = await _validatePrices();
      if (!canProceed) {
        setState(() => _isLoading = false);
        return;
      }

      // Adres ID'si — API'den gelen adresin integer ID'si
      final addressId = int.tryParse(_selectedAddress!.id);
      if (addressId == null || addressId <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geçerli bir teslimat adresi seçin.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      // Items'ı API formatına çevir — doğrudan order body'sine gönderilir
      final items = cart.items.map((item) => {
        'product_id': int.tryParse(item.product.id) ?? 0,
        if (item.variant != null)
          'variant_id': int.tryParse(item.variant!.id),
        'quantity': item.quantity,
      }).toList();

      final input = CreateOrderInput(
        items: items,
        addressId: addressId,
        paymentMethod: _paymentMethod.value,
        notes: _note.isEmpty ? null : _note,
        couponCode: null,
      );

      final notifier = ref.read(apiOrdersNotifierProvider.notifier);
      final createdOrder = await notifier.createOrder(input);

      if (createdOrder != null) {
        ref.read(cartProvider.notifier).clear();
        if (mounted) {
          context.go(AppRoutes.orderSuccess, extra: createdOrder.orderNumber);
        }
      }
    } catch (e) {
      if (mounted) {
        final message = e is Failure
            ? e.message
            : 'Sipariş oluşturulamadı. Lütfen tekrar deneyin.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stream ilk değer emit edince _selectedAddress null ise otomatik doldur.
    // Kullanıcı farklı adres seçtiyse (_selectedAddress != null) dokunma.
    ref.listen<AddressModel?>(defaultAddressProvider, (_, next) {
      if (_selectedAddress == null && next != null) {
        setState(() => _selectedAddress = next);
      }
    });

    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 8,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.secondary, size: 24),
          onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.cart),
        ),
        title: const Text(
          'Ödeme',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.secondary),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  // 1. Sipariş Özeti
                  _SectionCard(
                    title: 'Sipariş Özeti',
                    child: Column(
                      children: [
                        ...cart.items.map(
                          (item) => Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.quantity} x '
                                  '${item.unitPrice.toStringAsFixed(2)} TL',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.total.toStringAsFixed(2)} TL',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        _SummaryRow(
                          label: 'Ara Toplam',
                          value:
                              '${cart.subtotal.toStringAsFixed(2)} TL',
                        ),
                        const SizedBox(height: 4),
                        _SummaryRow(
                          label: 'Toplam',
                          value: '${cart.total.toStringAsFixed(2)} TL',
                          valueFontSize: 18,
                          valueWeight: FontWeight.w700,
                          valueColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),

                  // 2. Teslimat Adresi
                  _SectionCard(
                    title: 'Teslimat Adresi',
                    trailing: TextButton(
                      onPressed: () async {
                        final result =
                            await context.push<AddressModel?>(
                          '${AppRoutes.addressSelection}?select=true',
                        );
                        if (result != null) {
                          setState(() => _selectedAddress = result);
                        }
                      },
                      child: const Text('Değiştir'),
                    ),
                    child: _selectedAddress != null
                        ? _AddressDisplay(address: _selectedAddress!)
                        : _NoAddressWidget(
                            onAdd: () => context.push(
                              '${AppRoutes.addressSelection}?select=true',
                            ),
                          ),
                  ),

                  // 3. Ödeme Yontemi
                  _SectionCard(
                    title: 'Ödeme Yontemi',
                    child: Column(
                      children: [
                        _PaymentOption(
                          label: 'Kapıda Nakit',
                          icon: Icons.payments_outlined,
                          value: PaymentMethod.cash,
                          groupValue: _paymentMethod,
                          onChanged: (v) =>
                              setState(() => _paymentMethod = v!),
                        ),
                        _PaymentOption(
                          label: 'Kapıda Kredi Kartı',
                          icon: Icons.credit_card_outlined,
                          value: PaymentMethod.cardOnDelivery,
                          groupValue: _paymentMethod,
                          onChanged: (v) =>
                              setState(() => _paymentMethod = v!),
                        ),
                        _PaymentOption(
                          label: 'Diğer Kredi Kartı',
                          icon: Icons.account_balance_outlined,
                          value: PaymentMethod.onlineCard,
                          groupValue: _paymentMethod,
                          onChanged: null,
                          badge: 'Yakında',
                        ),
                      ],
                    ),
                  ),

                  // 4. Sipariş Notu
                  _SectionCard(
                    title: 'Sipariş Notu (Opsiyonel)',
                    child: TextField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Ozel istek veya not ekleyin...',
                      ),
                      onChanged: (v) => setState(() => _note = v),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // 5. Alt ozet + buton
          _BottomBar(
            total: cart.total,
            isLoading: _isLoading,
            isAddressSelected: _selectedAddress != null,
            onConfirm: _placeOrder,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionCard
// ---------------------------------------------------------------------------
class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [AppShadows.sm],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SummaryRow
// ---------------------------------------------------------------------------
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final double valueFontSize;
  final FontWeight valueWeight;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueFontSize = 14,
    this.valueWeight = FontWeight.w500,
    this.valueColor = AppColors.textPrimary,
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
            fontSize: valueFontSize,
            fontWeight: valueWeight,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _AddressDisplay
// ---------------------------------------------------------------------------
class _AddressDisplay extends StatelessWidget {
  final AddressModel address;

  const _AddressDisplay({required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            address.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          address.fullAddress,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${address.district}, ${address.city}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _NoAddressWidget
// ---------------------------------------------------------------------------
class _NoAddressWidget extends StatelessWidget {
  final VoidCallback onAdd;

  const _NoAddressWidget({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Teslimat adresi seçilmedi',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Yeni adres ekle',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _PaymentOption
// ---------------------------------------------------------------------------
class _PaymentOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final PaymentMethod value;
  final PaymentMethod groupValue;
  final ValueChanged<PaymentMethod?>? onChanged;
  final String? badge;

  const _PaymentOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onChanged == null;
    final isSelected = value == groupValue && !isDisabled;

    return GestureDetector(
      onTap: isDisabled ? null : () => onChanged?.call(value),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.pinkLight
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Manuel radio circle — Radio widget'in deprecated API'sinden kacinmak icin
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isDisabled ? AppColors.textHint : AppColors.textSecondary),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              size: 20,
              color: isDisabled
                  ? AppColors.textHint
                  : (isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDisabled
                      ? AppColors.textHint
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _BottomBar
// ---------------------------------------------------------------------------
class _BottomBar extends StatelessWidget {
  final double total;
  final bool isLoading;
  final bool isAddressSelected;
  final VoidCallback onConfirm;

  const _BottomBar({
    required this.total,
    required this.isLoading,
    required this.isAddressSelected,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Toplam',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${total.toStringAsFixed(2)} TL',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: (isLoading || !isAddressSelected) ? 0.55 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: ElevatedButton(
              onPressed: (isLoading || !isAddressSelected) ? null : onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                disabledBackgroundColor: AppColors.primary,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(46),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.textWhite,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Onayla ve Tamamla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          if (!isAddressSelected) ...[
            const SizedBox(height: 8),
            const Text(
              'Lutfen teslimat adresi secin',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PriceChange — fiyat değişikliği veri taşıyıcısı
// ---------------------------------------------------------------------------
class _PriceChange {
  final String productName;
  final String variantName;
  final double oldPrice;
  final double newPrice;

  const _PriceChange({
    required this.productName,
    required this.variantName,
    required this.oldPrice,
    required this.newPrice,
  });
}
