import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/orders/data/models/order_model.dart';
import 'package:nisa_ticaret/features/orders/data/repositories/order_repository.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Teslimatciya atanmis aktif siparisler (on_the_way veya assignedTo eslesimi)
final deliveryOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref
      .watch(orderRepositoryProvider)
      .watchActiveOrders()
      .map((orders) => orders
          .where((o) =>
              o.assignedTo == user.uid ||
              o.status == OrderStatus.onTheWay)
          .toList());
});

// ---------------------------------------------------------------------------
// Ana ekran
// ---------------------------------------------------------------------------

class DeliveryHomeScreen extends ConsumerStatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  ConsumerState<DeliveryHomeScreen> createState() =>
      _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends ConsumerState<DeliveryHomeScreen> {
  // -----------------------------------------------------------------------
  // Harici Maps aç
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // Teslim et — onay dialog + Firestore güncelleme
  // -----------------------------------------------------------------------
  Future<void> _deliverOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Teslim Edildi mi?'),
        content: Text(
          '#${order.orderNo} numaralı sipariş teslim edildi olarak işaretlensin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Teslim Edildi'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(
            orderId: order.id,
            newStatus: OrderStatus.delivered,
            updatedBy: user.uid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('#${order.orderNo} teslim edildi.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Güncelleme başarısız. Tekrar deneyin.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // -----------------------------------------------------------------------
  // Mesafe hesapla (koordinatsız durum için infinity döner)
  // -----------------------------------------------------------------------
  double _calcDistance(OrderModel order) {
    if (order.deliveryAddress.lat == null ||
        order.deliveryAddress.lng == null) {
      return double.infinity;
    }
    // Konum bilgisi olmadan sıralama için koordinat varlığına göre sıralanır
    return 0.0;
  }

  // -----------------------------------------------------------------------
  // Google Maps navigation başlat
  // -----------------------------------------------------------------------
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

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(deliveryOrdersProvider);
    final user = ref.watch(authStateProvider).value;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teslimat Rotam',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (user != null)
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined,
                color: AppColors.secondary),
            tooltip: 'Müşteri Görünümü',
            onPressed: () => context.go(AppRoutes.productList),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined,
                color: AppColors.secondary),
            tooltip: 'Profil',
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: isTablet
          ? _buildTabletLayout(context, ordersAsync)
          : _buildPhoneLayout(context, ordersAsync),
    );
  }

  // -----------------------------------------------------------------------
  // Tablet layout: stats sol, liste sağ
  // -----------------------------------------------------------------------
  Widget _buildTabletLayout(
    BuildContext context,
    AsyncValue<List<OrderModel>> ordersAsync,
  ) {
    return Row(
      children: [
        // Sol: Stats
        SizedBox(
          width: 240,
          child: Column(
            children: [
              _RouteStatsBar(ordersAsync: ordersAsync, vertical: true),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        // Sag: Siparis listesi
        Expanded(
          child: _TodayOrdersSection(
            ordersAsync: ordersAsync,
            calcDistance: _calcDistance,
            onOpenMaps: _openInMaps,
            onDeliver: _deliverOrder,
            onNavigate: _launchNavigation,
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Telefon layout: dikey
  // -----------------------------------------------------------------------
  Widget _buildPhoneLayout(
    BuildContext context,
    AsyncValue<List<OrderModel>> ordersAsync,
  ) {
    return Column(
      children: [
        _RouteStatsBar(ordersAsync: ordersAsync, vertical: false),
        Expanded(
          child: _TodayOrdersSection(
            ordersAsync: ordersAsync,
            calcDistance: _calcDistance,
            onOpenMaps: _openInMaps,
            onDeliver: _deliverOrder,
            onNavigate: _launchNavigation,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// [1] Stats Bar
// ---------------------------------------------------------------------------

class _RouteStatsBar extends StatelessWidget {
  final AsyncValue<List<OrderModel>> ordersAsync;
  final bool vertical;

  const _RouteStatsBar({
    required this.ordersAsync,
    required this.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final orders = ordersAsync.value ?? [];
    final total = orders.length;
    final remaining = orders
        .where((o) =>
            o.status != OrderStatus.delivered &&
            o.status != OrderStatus.cancelled)
        .length;
    final delivered =
        orders.where((o) => o.status == OrderStatus.delivered).length;
    final estimatedMinutes = remaining * 15;
    final estimatedLabel = estimatedMinutes >= 60
        ? '${(estimatedMinutes / 60).floor()} sa ${estimatedMinutes % 60} dk'
        : '$estimatedMinutes dk';

    final cards = [
      _StatCard(
        icon: Icons.receipt_long,
        iconColor: AppColors.secondary,
        value: '$total',
        label: 'Toplam',
        bgColor: AppColors.secondary.withAlpha(20),
      ),
      _StatCard(
        icon: Icons.pending_outlined,
        iconColor: AppColors.warning,
        value: '$remaining',
        label: 'Kalan',
        bgColor: AppColors.warning.withAlpha(20),
      ),
      _StatCard(
        icon: Icons.check_circle_outline,
        iconColor: AppColors.success,
        value: '$delivered',
        label: 'Teslim',
        bgColor: AppColors.success.withAlpha(20),
      ),
      _StatCard(
        icon: Icons.access_time_outlined,
        iconColor: AppColors.accent,
        value: remaining == 0 ? '0 dk' : estimatedLabel,
        label: 'Tahmini',
        bgColor: AppColors.accent.withAlpha(20),
      ),
    ];

    if (vertical) {
      return Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cards
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: c,
                  ))
              .toList(),
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            cards[0],
            const SizedBox(width: 10),
            cards[1],
            const SizedBox(width: 10),
            cards[2],
            const SizedBox(width: 10),
            cards[3],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48, minWidth: 80),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// [2] Bugünün siparişleri listesi
// ---------------------------------------------------------------------------

class _TodayOrdersSection extends StatelessWidget {
  final AsyncValue<List<OrderModel>> ordersAsync;
  final double Function(OrderModel) calcDistance;
  final Future<void> Function(DeliveryAddress) onOpenMaps;
  final Future<void> Function(OrderModel) onDeliver;
  final Future<void> Function(DeliveryAddress) onNavigate;

  const _TodayOrdersSection({
    required this.ordersAsync,
    required this.calcDistance,
    required this.onOpenMaps,
    required this.onDeliver,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(
            children: [
              const Text(
                'Siparişler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(AppRoutes.orders),
                child: const Text('Tümü'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ordersAsync.when(
            loading: () => _buildShimmer(),
            error: (e, _) => _buildErrorState(e),
            data: (orders) {
              if (orders.isEmpty) return _buildEmptyState();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _DeliveryOrderCard(
                  order: orders[i],
                  onOpenMaps: () => onOpenMaps(orders[i].deliveryAddress),
                  onDeliver: () => onDeliver(orders[i]),
                  onNavigate: () => onNavigate(orders[i].deliveryAddress),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _OrderCardShimmer(),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Siparişler yüklenemedi.',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.success,
            ),
            SizedBox(height: 16),
            Text(
              'Tüm siparişler tamamlandı!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Harika iş, bugünlük rotanız bitti.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Siparis kartı
// ---------------------------------------------------------------------------

class _DeliveryOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onOpenMaps;
  final VoidCallback onDeliver;
  final VoidCallback onNavigate;

  const _DeliveryOrderCard({
    required this.order,
    required this.onOpenMaps,
    required this.onDeliver,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final addr = order.deliveryAddress;
    final canDeliver = order.status == OrderStatus.onTheWay;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: status badge + sipariş no
            Row(
              children: [
                _StatusBadge(status: order.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '#${order.orderNo}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Musteri adi + telefon
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.phone_outlined,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order.customerPhone,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Adres
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${addr.fullAddress}, ${addr.district}, ${addr.city}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // Notlar (varsa)
            if (addr.notes != null && addr.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      addr.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            // Alt butonlar
            Row(
              children: [
                // Haritada Gor — harici Maps aç
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: onOpenMaps,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text(
                      'Haritada Gör',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Navigate — Google Maps navigation baslat
                OutlinedButton.icon(
                  onPressed: order.deliveryAddress.lat != null ||
                          order.deliveryAddress.fullAddress.isNotEmpty
                      ? onNavigate
                      : null,
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text('Yol Tarifi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                // Teslim Et
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canDeliver
                          ? AppColors.success
                          : AppColors.border,
                      foregroundColor: canDeliver
                          ? AppColors.textWhite
                          : AppColors.textSecondary,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: canDeliver ? onDeliver : null,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text(
                      'Teslim Et',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _badgeColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _badgeColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.onTheWay:
        return AppColors.statusOnTheWay;
      case OrderStatus.delivered:
        return AppColors.statusDelivered;
      case OrderStatus.preparing:
        return AppColors.statusPreparing;
      case OrderStatus.confirmed:
        return AppColors.statusConfirmed;
      case OrderStatus.cancelled:
        return AppColors.statusCancelled;
      default:
        return AppColors.statusPending;
    }
  }
}

// ---------------------------------------------------------------------------
// Shimmer kart (yukleme durumu)
// ---------------------------------------------------------------------------

class _OrderCardShimmer extends StatelessWidget {
  const _OrderCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 156,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ShimmerBox(width: 120, height: 18),
            const SizedBox(height: 10),
            _ShimmerBox(width: double.infinity, height: 14),
            const SizedBox(height: 8),
            _ShimmerBox(width: 200, height: 14),
            const SizedBox(height: 8),
            _ShimmerBox(width: double.infinity, height: 14),
            const Spacer(),
            Row(
              children: [
                Expanded(child: _ShimmerBox(width: double.infinity, height: 40)),
                const SizedBox(width: 10),
                Expanded(child: _ShimmerBox(width: double.infinity, height: 40)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
    _animation = Tween<double>(begin: 0.4, end: 0.9).animate(_controller);
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
          color: AppColors.textHint.withAlpha((_animation.value * 120).round()),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

