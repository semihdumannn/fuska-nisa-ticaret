import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/services/whatsapp_service.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/cart/presentation/bloc/cart_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/order_repository.dart';
import 'package:nisa_ticaret/features/products/data/models/product_model.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderStreamProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Sipariş Detayı',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
        elevation: 0,
        actions: [
          orderAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (order) {
              if (order == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.support_agent_outlined),
                tooltip: 'WhatsApp Destek',
                onPressed: () => whatsappService.supportForOrder(
                  orderNo: order.orderNo.isNotEmpty ? order.orderNo : order.id,
                ),
              );
            },
          ),
        ],
      ),
      body: orderAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => _buildError(context),
        data: (order) {
          if (order == null) return _buildNotFound(context);
          return _buildContent(context, order);
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Main content
  // -------------------------------------------------------------------------

  Widget _buildContent(BuildContext context, OrderModel order) {
    final canCancel = order.status == OrderStatus.pending ||
        order.status == OrderStatus.confirmed;
    final canReorder = order.status == OrderStatus.delivered ||
        order.status == OrderStatus.cancelled;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusHeader(order: order),
          const SizedBox(height: 12),
          _TimelineSection(order: order),
          _ProductsSection(order: order),
          _AddressSection(order: order),
          _PaymentSection(order: order),
          if (canReorder) _ReorderButton(order: order),
          if (canCancel) _CancelOrderButton(order: order),
          _WhatsAppSupportButton(orderNo: order.orderNo),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Shimmer
  // -------------------------------------------------------------------------

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < 3; i++) ...[
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Error / Not found
  // -------------------------------------------------------------------------

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.textHint),
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
            const Text(
              'Lütfen internet bağlantınızı kontrol edip tekrar deneyin.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
              child: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Sipariş bulunamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bu sipariş silinmiş veya erişim izniniz olmayabilir.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
              child: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Header
// ---------------------------------------------------------------------------

class _StatusHeader extends StatelessWidget {
  final OrderModel order;
  const _StatusHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _LargeStatusBadge(status: order.status),
          const SizedBox(height: 16),
          Text(
            '#${order.orderNo}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(order.createdAt),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (order.estimatedDelivery != null) ...[
            const SizedBox(height: 4),
            Text(
              'Tahmini: ${_formatDate(order.estimatedDelivery!)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.accent,
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
// Large Status Badge
// ---------------------------------------------------------------------------

class _LargeStatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _LargeStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Section — Stepper UI
// ---------------------------------------------------------------------------

class _TimelineSection extends StatelessWidget {
  final OrderModel order;
  const _TimelineSection({required this.order});

  static const List<OrderStatus> _mainFlow = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.onTheWay,
    OrderStatus.delivered,
  ];

  DateTime? _timestampFor(OrderModel order, OrderStatus status) {
    try {
      return order.statusHistory
          .lastWhere((h) => h.status == status)
          .timestamp;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == OrderStatus.cancelled;

    return _SectionCard(
      title: 'Sipariş Durumu',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(_mainFlow.length, (index) {
            final status = _mainFlow[index];
            final isLast = index == _mainFlow.length - 1;
            final timestamp = _timestampFor(order, status);
            final inHistory = timestamp != null;

            // Durumu belirle: done / active / upcoming
            final String stepState;
            if (inHistory) {
              stepState = order.status == status ? 'active' : 'done';
            } else {
              stepState = isCancelled ? 'upcoming' : (order.status == status ? 'active' : 'upcoming');
            }

            // next adımın done olup olmadığını bul (connector rengi için)
            final bool nextIsDone = !isLast &&
                _timestampFor(order, _mainFlow[index + 1]) != null;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol kolon: dot + connector
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      _StepDot(state: stepState),
                      if (!isLast) _ConnectorLine(isDone: nextIsDone),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Sağ kolon: label + tarih
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isLast ? 0 : 8,
                      top: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: stepState == 'done'
                                ? AppColors.textPrimary
                                : stepState == 'active'
                                    ? AppColors.primary
                                    : AppColors.textHint,
                          ),
                        ),
                        if (timestamp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (stepState == 'active' &&
                            order.estimatedDelivery != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Tahmini: ${_formatDate(order.estimatedDelivery!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
          // İptal adımı
          if (isCancelled) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      _StepDot(state: 'cancelled'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'İptal Edildi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        Builder(builder: (context) {
                          final ts = _timestampFor(order, OrderStatus.cancelled);
                          if (ts == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _formatDate(ts),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Dot
// ---------------------------------------------------------------------------

class _StepDot extends StatelessWidget {
  final String state; // 'done' | 'active' | 'upcoming' | 'cancelled'

  const _StepDot({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == 'done') {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.textWhite,
          size: 20,
        ),
      );
    }

    if (state == 'active') {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
          ),
        ),
      );
    }

    if (state == 'cancelled') {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.error,
        ),
        child: const Icon(
          Icons.close_rounded,
          color: AppColors.textWhite,
          size: 20,
        ),
      );
    }

    // upcoming
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(color: AppColors.divider, width: 2),
      ),
      child: Center(
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.divider,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Connector Line
// ---------------------------------------------------------------------------

class _ConnectorLine extends StatelessWidget {
  final bool isDone;

  const _ConnectorLine({required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 32,
      color: isDone ? AppColors.success : AppColors.divider,
    );
  }
}

// ---------------------------------------------------------------------------
// Cancel Order Button
// ---------------------------------------------------------------------------

class _CancelOrderButton extends ConsumerStatefulWidget {
  final OrderModel order;
  const _CancelOrderButton({required this.order});

  @override
  ConsumerState<_CancelOrderButton> createState() => _CancelOrderButtonState();
}

class _CancelOrderButtonState extends ConsumerState<_CancelOrderButton> {
  bool _isLoading = false;

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Siparişi İptal Et',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'Bu siparişi iptal etmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(
              'İptal Et',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final uid = ref.read(authStateProvider).value?.uid ?? 'customer';
      await ref.read(orderRepositoryProvider).updateOrderStatus(
            orderId: widget.order.id,
            newStatus: OrderStatus.cancelled,
            updatedBy: uid,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş iptal edildi.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş iptal edilemedi. Tekrar deneyin.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: OutlinedButton(
        onPressed: _isLoading ? null : _cancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.error,
                ),
              )
            : const Text(
                'Sipariş İptal Et',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Products Section
// ---------------------------------------------------------------------------

class _ProductsSection extends StatelessWidget {
  final OrderModel order;
  const _ProductsSection({required this.order});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Ürünler (${order.totalItems} adet)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.qty} x ₺${item.unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '₺${item.totalPrice.toStringAsFixed(2)}',
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
          const Divider(color: AppColors.divider, height: 24),
          _SummaryRow(
            label: 'Ara Toplam',
            value: '₺${order.subtotal.toStringAsFixed(2)}',
          ),
          if (order.discount > 0) ...[
            const SizedBox(height: 4),
            _SummaryRow(
              label: 'İndirim',
              value: '-₺${order.discount.toStringAsFixed(2)}',
              valueColor: AppColors.success,
            ),
          ],
          const SizedBox(height: 4),
          _SummaryRow(
            label: 'Toplam',
            value: '₺${order.total.toStringAsFixed(2)}',
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            valueStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Address Section
// ---------------------------------------------------------------------------

class _AddressSection extends StatelessWidget {
  final OrderModel order;
  const _AddressSection({required this.order});

  @override
  Widget build(BuildContext context) {
    final addr = order.deliveryAddress;
    final hasCoords = addr.lat != null && addr.lng != null;
    return _SectionCard(
      title: 'Teslimat Adresi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addr.fullAddress,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                    if (addr.district.isNotEmpty || addr.city.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [addr.district, addr.city].where((s) => s.isNotEmpty).join(', '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (addr.notes != null && addr.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.textHint, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(addr.notes!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final Uri uri;
              if (hasCoords) {
                uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${addr.lat},${addr.lng}');
              } else {
                final q = Uri.encodeComponent(addr.fullAddress);
                uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
              }
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
            icon: const Icon(Icons.map_outlined, size: 16),
            label: const Text('Haritada Gör', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              minimumSize: const Size(double.infinity, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Payment & Notes Section
// ---------------------------------------------------------------------------

class _PaymentSection extends StatelessWidget {
  final OrderModel order;
  const _PaymentSection({required this.order});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Ödeme & Diğer',
      child: Column(
        children: [
          _InfoRow(
            label: 'Ödeme Yöntemi',
            value: order.paymentMethod.displayName,
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(label: 'Sipariş Notu', value: order.notes!),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable sub-widgets
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: labelStyle ??
              const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
        ),
        Text(
          value,
          style: valueStyle ??
              TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _formatDate(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}

Color _statusColor(OrderStatus status) {
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

IconData _statusIcon(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return Icons.access_time_outlined;
    case OrderStatus.confirmed:
      return Icons.check_circle_outline;
    case OrderStatus.preparing:
      return Icons.inventory_2_outlined;
    case OrderStatus.onTheWay:
      return Icons.local_shipping_outlined;
    case OrderStatus.delivered:
      return Icons.done_all_rounded;
    case OrderStatus.cancelled:
      return Icons.cancel_outlined;
  }
}

// ---------------------------------------------------------------------------
// Tekrar Sipariş Ver
// ---------------------------------------------------------------------------

class _ReorderButton extends ConsumerWidget {
  final OrderModel order;
  const _ReorderButton({required this.order});

  @override
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ElevatedButton.icon(
        onPressed: () {
          final now = DateTime.now();
          final cartNotifier = ref.read(cartProvider.notifier);

          // Sepeti temizle, önceki ürünleri silme — sadece ekle
          for (final item in order.items) {
            // OrderItem verilerinden minimal ProductModel yap
            final product = ProductModel(
              id: item.productId,
              name: item.productName,
              description: '',
              categoryIds: const [],
              imageUrl: item.imageUrl,
              createdAt: now,
              updatedAt: now,
            );
            cartNotifier.addItem(product, quantity: item.qty);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${order.items.length} ürün sepete eklendi.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Sepete Git',
                textColor: AppColors.textWhite,
                onPressed: () => context.go(AppRoutes.cart),
              ),
            ),
          );
        },
        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
        label: const Text('Tekrar Sipariş Ver',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textWhite,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WhatsApp Destek
// ---------------------------------------------------------------------------

class _WhatsAppSupportButton extends StatelessWidget {
  final String orderNo;
  const _WhatsAppSupportButton({required this.orderNo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: OutlinedButton.icon(
        onPressed: () => whatsappService.supportForOrder(orderNo: orderNo),
        icon: const Icon(Icons.chat_outlined, size: 18),
        label: const Text('WhatsApp ile Destek Al',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF25D366),
          side: const BorderSide(color: Color(0xFF25D366)),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
