import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/core/utils/navigation_guard.dart';
import 'package:nisa_ticaret/core/utils/order_status_helper.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/order_repository.dart';
import 'package:nisa_ticaret/features/orders/domain/entities/order_entity.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  OrderStatus? _filter;

  List<OrderEntity> _applyFilter(List<OrderEntity> orders) {
    if (_filter == null) return orders;
    return orders.where((o) => o.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final ordersAsync = ref.watch(userOrdersProvider);

    // Giriş yapılmamışsa yönlendirme ekranı
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: const Text('Siparişlerim',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
          iconTheme: const IconThemeData(color: AppColors.secondary),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 72, color: AppColors.textHint),
                const SizedBox(height: 16),
                const Text('Siparişleri görmek için\ngiriş yapmanız gerekiyor',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.push(AppRoutes.phoneAuth),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(200, 52)),
                  child: const Text('Giriş Yap'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text(
          'Siparişlerim',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.secondary),
        elevation: 0,
      ),
      body: Column(
        children: [
          _FilterTabs(
            selected: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: ordersAsync.when(
              loading: () => _buildShimmer(),
              error: (e, _) => _buildErrorState(
                onRetry: () => ref.invalidate(userOrdersProvider),
              ),
              data: (orders) {
                final filtered = _applyFilter(orders);
                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async =>
                        ref.invalidate(userOrdersProvider),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.6,
                        child: _EmptyState(isFiltered: _filter != null),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async =>
                      ref.invalidate(userOrdersProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _OrderCard(order: filtered[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          height: 110,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState({required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            const Text(
              'Siparişler yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lütfen internet bağlantınızı kontrol edin.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 32),
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter Tabs
// ---------------------------------------------------------------------------

class _FilterTabs extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onChanged;

  const _FilterTabs({required this.selected, required this.onChanged});

  static const List<({String label, OrderStatus? status})> _tabs = [
    (label: 'Tümü', status: null),
    (label: 'Beklemede', status: OrderStatus.pending),
    (label: 'Hazırlanıyor', status: OrderStatus.preparing),
    (label: 'Yolda', status: OrderStatus.onTheWay),
    (label: 'Teslim Edildi', status: OrderStatus.delivered),
    (label: 'İptal Edildi', status: OrderStatus.cancelled),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SizedBox(
        height: 48,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: _tabs.length,
          itemBuilder: (context, index) {
            final tab = _tabs[index];
            final isSelected = selected == tab.status;
            return GestureDetector(
              onTap: () => onChanged(tab.status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.textWhite
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order Card
// ---------------------------------------------------------------------------

class _OrderCard extends StatelessWidget {
  final OrderEntity order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = orderStatusColor(order.status);
    final previewItems = order.items.take(3).toList();
    final extraCount = order.items.length - previewItems.length;

    return GestureDetector(
      onTap: () => context.safePush(
        AppRoutes.orderDetail.replaceFirst(':id', order.id.toString()),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [AppShadows.sm],
          border: Border(
            left: BorderSide(color: statusColor, width: 4),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kart içeriği
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Üst: sipariş no + status badge
                        Row(
                          children: [
                            Text(
                              'Sipariş #${order.orderNumber}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                            const Spacer(),
                            _StatusBadge(status: order.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Orta: ürün görselleri
                        Row(
                          children: [
                            ...previewItems.map((item) => _ProductThumb(
                                  imageUrl: item.productImageUrl,
                                )),
                            if (extraCount > 0)
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.border,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '+$extraCount',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 10),
                        // Alt: tarih + tutar
                        Row(
                          children: [
                            Text(
                              _formatDate(order.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₺${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String? imageUrl;
  const _ProductThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: AppColors.imageBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Icon(
                  Icons.inventory_2,
                  size: 20,
                  color: AppColors.textHint,
                ),
                errorWidget: (_, __, ___) => const Icon(
                  Icons.inventory_2,
                  size: 20,
                  color: AppColors.textHint,
                ),
              )
            : const Icon(
                Icons.inventory_2,
                size: 20,
                color: AppColors.textHint,
              ),
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
    final color = orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(orderStatusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
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
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isFiltered;
  const _EmptyState({required this.isFiltered});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered
                  ? 'Bu kategoride sipariş yok'
                  : 'Henüz sipariş vermediniz',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Farklı bir filtre seçin veya filtreyi temizleyin.'
                  : 'Ürünleri inceleyin ve ilk siparişinizi verin.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isFiltered)
              OutlinedButton(
                onPressed: () {
                  // Filter parent state'i sıfırlamak için pop + push yerine
                  // Consumer ile değil, buton callback ile yönetiyoruz.
                  // Bu widget stateless olduğundan parent'ı tetikleyemez;
                  // kullanıcı doğrudan tab'a tıklayabilir.
                  context.go(AppRoutes.orders);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                child: const Text('Filtreyi Temizle'),
              )
            else
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                child: const Text('Alışverişe Başla'),
              ),
          ],
        ),
      ),
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
