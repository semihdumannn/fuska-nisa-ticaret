import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/order_repository.dart';

// ---------------------------------------------------------------------------
// DeliveryDetailScreen
// ---------------------------------------------------------------------------

class DeliveryDetailScreen extends ConsumerWidget {
  final String orderId;
  const DeliveryDetailScreen({super.key, required this.orderId});

  // -------------------------------------------------------------------------
  // Google Maps navigasyon
  // -------------------------------------------------------------------------
  Future<void> _launchNavigation(DeliveryAddress address) async {
    final lat = address.lat;
    final lng = address.lng;

    Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    } else {
      final encoded = Uri.encodeComponent(
        '${address.fullAddress}, ${address.district}, ${address.city}',
      );
      uri = Uri.parse('google.navigation:q=$encoded&mode=d');
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    final webUri = lat != null && lng != null
        ? Uri.parse(
            'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${address.fullAddress}, ${address.city}')}');

    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  // -------------------------------------------------------------------------
  // Harici Maps aç
  // -------------------------------------------------------------------------
  Future<void> _openInMaps(DeliveryAddress address) async {
    final lat = address.lat;
    final lng = address.lng;
    final Uri uri;
    if (lat != null && lng != null) {
      uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    } else {
      final q = Uri.encodeComponent(
          '${address.fullAddress}, ${address.district}, ${address.city}');
      uri =
          Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // -------------------------------------------------------------------------
  // Teslim et
  // -------------------------------------------------------------------------
  Future<void> _deliver(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Teslim Edildi mi?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#${order.orderNo} numaralı sipariş müşteriye teslim edildi olarak işaretlensin mi?',
            ),
            const SizedBox(height: 8),
            const Text(
              'İmza / Fotoğraf doğrulaması Faz 6\'da eklenecek.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Teslim Edildi'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      await ref.read(orderRepositoryProvider).updateOrderStatus(
            orderId: order.id,
            newStatus: OrderStatus.delivered,
            updatedBy: user.uid,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Sipariş teslim edildi olarak işaretlendi.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Güncelleme başarısız: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderStreamProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        title: orderAsync.when(
          loading: () => const Text(
            'Teslimat Detayı',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          error: (_, __) => const Text(
            'Teslimat Detayı',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          data: (order) => order == null
              ? const Text(
                  'Teslimat Detayı',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.orderNo}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Teslimat Detayı',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          if (orderAsync.value != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _StatusBadge(status: orderAsync.value!.status),
            ),
          ],
        ],
      ),
      body: orderAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => _buildErrorState(context, e),
        data: (order) {
          if (order == null) {
            return _buildErrorState(
              context,
              'Sipariş bulunamadı.',
            );
          }
          return _buildContent(context, ref, order);
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Ana içerik
  // -------------------------------------------------------------------------
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    OrderModel order,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                _CustomerCard(order: order),
                const SizedBox(height: 12),
                _AddressCard(
                  order: order,
                  onNavigate: () =>
                      _launchNavigation(order.deliveryAddress),
                  onOpenMaps: () =>
                      _openInMaps(order.deliveryAddress),
                ),
                const SizedBox(height: 12),
                _ProductsCard(order: order),
                const SizedBox(height: 12),
                _PaymentCard(order: order),
                if (order.notes != null &&
                    order.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _NotesCard(notes: order.notes!),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _DeliverBottomBar(
          order: order,
          onDeliver: () => _deliver(context, ref, order),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Loading shimmer
  // -------------------------------------------------------------------------
  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBox(width: 140, height: 16),
                  const SizedBox(height: 12),
                  _ShimmerBox(width: double.infinity, height: 14),
                  const SizedBox(height: 8),
                  _ShimmerBox(width: 200, height: 14),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Hata durumu
  // -------------------------------------------------------------------------
  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sipariş yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Geri Dön'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
// [1] Müşteri Kartı
// ---------------------------------------------------------------------------

class _CustomerCard extends StatelessWidget {
  final OrderModel order;
  const _CustomerCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                order.customerName.isNotEmpty
                    ? order.customerName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // İsim + telefon
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.customerPhone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Ara butonu
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              icon: const Icon(
                Icons.call_outlined,
                color: AppColors.success,
              ),
              tooltip: 'Ara',
              onPressed: () async {
                final uri =
                    Uri.parse('tel:${order.customerPhone}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// [2] Adres Kartı
// ---------------------------------------------------------------------------

class _AddressCard extends ConsumerWidget {
  final OrderModel order;
  final VoidCallback onNavigate;
  final VoidCallback onOpenMaps;

  const _AddressCard({
    required this.order,
    required this.onNavigate,
    required this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addr = order.deliveryAddress;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baslik
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Teslimat Adresi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Adres detay
          Text(
            addr.fullAddress,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${addr.district}, ${addr.city}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (addr.notes != null && addr.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              addr.notes!,
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Aksiyon butonlar
          Row(
            children: [
              // Haritada Gor
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                    side: const BorderSide(
                        color: AppColors.secondary, width: 1.5),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: onOpenMaps,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text(
                    'Haritada Gör',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Navigate
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.textWhite,
                    minimumSize: const Size(0, 48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined,
                      size: 18),
                  label: const Text(
                    'Navigate',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// [3] Ürünler Kartı
// ---------------------------------------------------------------------------

class _ProductsCard extends StatelessWidget {
  final OrderModel order;
  const _ProductsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baslik
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                'Ürünler (${order.totalItems} adet)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Ürün satırları
          ...order.items.map(
            (item) => Column(
              children: [
                _ProductRow(item: item),
                if (item != order.items.last)
                  const Divider(height: 16),
              ],
            ),
          ),
          // Ozet
          const Divider(height: 20),
          _buildSummary(),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      children: [
        if (order.discount > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ara Toplam',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '₺${order.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'İndirim',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.success,
                ),
              ),
              Text(
                '-₺${order.discount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Toplam',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '₺${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ürün satır widget'i
// ---------------------------------------------------------------------------

class _ProductRow extends StatelessWidget {
  final OrderItem item;
  const _ProductRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gorsel
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.imageUrl != null && item.imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _imagePlaceholder(),
                  errorWidget: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),
        const SizedBox(width: 10),
        // Urun adi + birim fiyat
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '₺${item.unitPrice.toStringAsFixed(2)}/adet',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Adet + toplam fiyat
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '×${item.qty}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '₺${item.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.imageBg,
      child: const Icon(
        Icons.water_drop_outlined,
        color: AppColors.accent,
        size: 24,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// [4] Ödeme Kartı
// ---------------------------------------------------------------------------

class _PaymentCard extends StatelessWidget {
  final OrderModel order;
  const _PaymentCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final isPaid = order.status == OrderStatus.delivered;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baslik
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Ödeme Bilgisi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Odeme yontemi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ödeme Yöntemi',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.secondary.withAlpha(60),
                  ),
                ),
                child: Text(
                  order.paymentMethod.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Odeme durumu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ödeme Durumu',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              _PaymentStatusPill(isPaid: isPaid),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusPill extends StatelessWidget {
  final bool isPaid;
  const _PaymentStatusPill({required this.isPaid});

  @override
  Widget build(BuildContext context) {
    final color = isPaid ? AppColors.success : AppColors.warning;
    final label = isPaid ? 'Ödendi' : 'Bekliyor';
    final icon = isPaid ? Icons.check_circle_outline : Icons.schedule;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// [5] Siparis Notu Kartı
// ---------------------------------------------------------------------------

class _NotesCard extends StatelessWidget {
  final String notes;
  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              const Text(
                'Sipariş Notu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            notes,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// [6] Teslim Et Alt Bar
// ---------------------------------------------------------------------------

class _DeliverBottomBar extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onDeliver;

  const _DeliverBottomBar({
    required this.order,
    required this.onDeliver,
  });

  @override
  Widget build(BuildContext context) {
    final canDeliver = order.status == OrderStatus.onTheWay;
    final isDelivered = order.status == OrderStatus.delivered;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Durum satiri
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Durum:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          // Teslim butonu
          ElevatedButton.icon(
            onPressed: canDeliver ? onDeliver : null,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Teslim Edildi Olarak İşaretle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDelivered
                  ? AppColors.success.withValues(alpha: 0.5)
                  : AppColors.success,
              foregroundColor: AppColors.textWhite,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor:
                  AppColors.success.withValues(alpha: 0.4),
              disabledForegroundColor:
                  AppColors.textWhite.withValues(alpha: 0.7),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Teslim tarih bilgisi
          if (isDelivered) ...[
            const SizedBox(height: 4),
            Text(
              'Teslim tarihi: ${_formatDate(order.updatedAt)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
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
// Status Badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(status);

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _badgeColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.statusPending;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.onTheWay:
        return AppColors.statusOnTheWay;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }
}

// ---------------------------------------------------------------------------
// Yardımcı fonksiyon
// ---------------------------------------------------------------------------

String _formatDate(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final y = dt.year;
  final h = dt.hour.toString().padLeft(2, '0');
  final min = dt.minute.toString().padLeft(2, '0');
  return '$d.$m.$y $h:$min';
}

// ---------------------------------------------------------------------------
// Shimmer Box (animasyonlu yukleme kutusu)
// ---------------------------------------------------------------------------

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerBox({required this.width, required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: 0.4, end: 0.9).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.textHint
              .withAlpha((_animation.value * 120).round()),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
