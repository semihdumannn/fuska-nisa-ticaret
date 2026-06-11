import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_order_model.dart';
import '../providers/admin_orders_provider.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/order_timeline.dart';

const double _kDesktopBreakpoint = 1024.0;

// ---------------------------------------------------------------------------
// Ekran koku
// ---------------------------------------------------------------------------

class AdminOrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const AdminOrderDetailScreen({required this.orderId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Row(
          children: [
            const AdminSidebar(),
            Expanded(
              child: _DetailContent(
                orderAsync: orderAsync,
                isDesktop: true,
                orderId: orderId,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: const AdminDrawerWrapper(),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: const Text(
          'Sipariş Detayı',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
          onPressed: () => context.canPop() ? context.pop() : context.go('/admin/orders'),
        ),
      ),
      body: _DetailContent(
        orderAsync: orderAsync,
        isDesktop: false,
        orderId: orderId,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icerik alanı
// ---------------------------------------------------------------------------

class _DetailContent extends ConsumerWidget {
  final AsyncValue<AdminOrderModel> orderAsync;
  final bool isDesktop;
  final String orderId;

  const _DetailContent({
    required this.orderAsync,
    required this.isDesktop,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return orderAsync.when(
      loading: () => const _DetailShimmer(),
      error: (e, _) => _DetailError(error: e),
      data: (order) => isDesktop
          ? _DesktopDetailLayout(order: order)
          : _MobileDetailLayout(order: order),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop: 3 esit kolon
// ---------------------------------------------------------------------------

class _DesktopDetailLayout extends StatelessWidget {
  final AdminOrderModel order;
  const _DesktopDetailLayout({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Geri butonu + baslik
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.textSecondary),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/admin/orders'),
                tooltip: 'Geri',
              ),
              const SizedBox(width: 4),
              Text(
                'Siparis ${order.orderNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _SummaryColumn(order: order)),
                const SizedBox(width: 16),
                Expanded(child: _ItemsColumn(order: order)),
                const SizedBox(width: 16),
                Expanded(child: _AssignmentNotesColumn(order: order)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobil: alt alta kolonlar
// ---------------------------------------------------------------------------

class _MobileDetailLayout extends StatelessWidget {
  final AdminOrderModel order;
  const _MobileDetailLayout({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SummaryColumn(order: order),
          const SizedBox(height: 16),
          _ItemsColumn(order: order),
          const SizedBox(height: 16),
          _AssignmentNotesColumn(order: order),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kolon 1: Ozet bilgiler
// ---------------------------------------------------------------------------

class _SummaryColumn extends ConsumerStatefulWidget {
  final AdminOrderModel order;
  const _SummaryColumn({required this.order});

  @override
  ConsumerState<_SummaryColumn> createState() => _SummaryColumnState();
}

class _SummaryColumnState extends ConsumerState<_SummaryColumn> {
  AdminOrderStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    _selectedStatus ??= order.status;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baslik + tarih
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMMM yyyy HH:mm', 'tr_TR')
                          .format(order.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Durum satiri
          const Text(
            'Sipariş Durumu',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StatusBadge(status: order.status),
              const Spacer(),
              _StatusChangeDropdown(order: order),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline
          const Text(
            'Sipariş Süreci',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          OrderTimeline(
            currentStatus: order.status,
            order: order,
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),

          // Müşteri bilgileri
          const Text(
            'Müşteri Bilgileri',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Ad Soyad',
            value: order.customerName,
            isLink: true,
            onTap: () => context.push(
                '/admin/users/${order.customerId}'),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Telefon',
            value: order.customerPhone,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Adres',
            value: order.deliveryAddress,
            trailing: IconButton(
              icon: const Icon(Icons.map_outlined,
                  color: AppColors.accent, size: 20),
              tooltip: 'Google Maps\'te Gör',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () async {
                final q = Uri.encodeComponent(order.deliveryAddress);
                final uri = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=$q');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
          ),
          if (order.cancellationReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_outlined,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'İptal Sebebi',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order.cancellationReason!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChangeDropdown extends ConsumerWidget {
  final AdminOrderModel order;
  const _StatusChangeDropdown({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DropdownButtonHideUnderline(
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButton<AdminOrderStatus>(
          value: order.status,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppColors.textSecondary),
          items: AdminOrderStatus.values
              .map(
                (s) => DropdownMenuItem<AdminOrderStatus>(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.displayName,
                        style: const TextStyle(
                            fontSize: 13, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (newStatus) async {
            if (newStatus == null || newStatus == order.status) return;
            final confirmed = await showModalBottomSheet<bool>(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) => _StatusChangeSheet(
                currentStatus: order.status,
                newStatus: newStatus,
                orderNumber: order.orderNumber,
              ),
            );
            if (confirmed == true && context.mounted) {
              try {
                await ref
                    .read(adminOrdersProvider.notifier)
                    .updateStatus(order.id, newStatus);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Durum "${newStatus.displayName}" olarak güncellendi'),
                      backgroundColor: newStatus.color,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceFirst('Exception: ', '')),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            }
          },
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kolon 2: Urunler + fiyat ozeti
// ---------------------------------------------------------------------------

class _ItemsColumn extends StatelessWidget {
  final AdminOrderModel order;
  const _ItemsColumn({required this.order});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
        locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sipariş Detayı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),

          // Urun listesi
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                // Baslik satiri
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: const [
                      Expanded(
                          flex: 5,
                          child: Text(
                            'URUN',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                          )),
                      SizedBox(
                          width: 40,
                          child: Text(
                            'ADET',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.center,
                          )),
                      SizedBox(
                          width: 64,
                          child: Text(
                            'BIRIM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.right,
                          )),
                      SizedBox(
                          width: 72,
                          child: Text(
                            'TOPLAM',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'Poppins',
                            ),
                            textAlign: TextAlign.right,
                          )),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...order.items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final isLast = entry.key == order.items.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(
                              width: 64,
                              child: Text(
                                currencyFmt.format(item.unitPrice),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'Poppins',
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: 72,
                              child: Text(
                                currencyFmt.format(item.total),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                  color: AppColors.textPrimary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast) const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fiyat ozeti
          _PriceSummaryRow(label: 'Ara toplam', value: order.subtotal),
          const SizedBox(height: 4),
          _PriceSummaryRow(label: 'Teslimat', value: order.deliveryFee),
          if (order.discount > 0) ...[
            const SizedBox(height: 4),
            _PriceSummaryRow(
              label: 'Indirim',
              value: -order.discount,
              color: AppColors.success,
            ),
          ],
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOPLAM',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                currencyFmt.format(order.total),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ödeme yontemi
          Row(
            children: [
              const Text(
                'Ödeme:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(order.paymentMethod.icon,
                        size: 13, color: AppColors.accent),
                    const SizedBox(width: 5),
                    Text(
                      order.paymentMethod.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceSummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final Color? color;

  const _PriceSummaryRow({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final display = NumberFormat.currency(
            locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
        .format(value.abs());
    final prefix = value < 0 ? '-' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        Text(
          '$prefix$display',
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            color: color ?? AppColors.textSecondary,
            fontWeight: color != null ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kolon 3: Atama + notlar + tehlikeli aksiyonlar
// ---------------------------------------------------------------------------

class _AssignmentNotesColumn extends ConsumerStatefulWidget {
  final AdminOrderModel order;
  const _AssignmentNotesColumn({required this.order});

  @override
  ConsumerState<_AssignmentNotesColumn> createState() =>
      _AssignmentNotesColumnState();
}

class _AssignmentNotesColumnState
    extends ConsumerState<_AssignmentNotesColumn> {
  String? _selectedAgentId;
  String? _selectedAgentName;
  String? _selectedDeliveryId;
  String? _selectedDeliveryName;
  final _noteController = TextEditingController();
  bool _addingNote = false;
  bool _assigningAgent = false;
  bool _assigningDelivery = false;

  @override
  void initState() {
    super.initState();
    _selectedAgentId = widget.order.assignedAgentId;
    _selectedAgentName = widget.order.assignedAgentName;
    _selectedDeliveryId = widget.order.assignedDeliveryId;
    _selectedDeliveryName = widget.order.assignedDeliveryName;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(fieldAgentsProvider);
    final deliveryAsync = ref.watch(deliveryPersonsProvider);
    final order = widget.order;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------- Saha Gorevlisi -----------
          _AssignmentSection(
            title: 'Saha Görevlisi',
            icon: Icons.badge_outlined,
            assignedName: order.assignedAgentName,
            personsAsync: agentsAsync,
            selectedId: _selectedAgentId,
            onChanged: (id, name) {
              setState(() {
                _selectedAgentId = id;
                _selectedAgentName = name;
              });
            },
            onAssign: _assigningAgent
                ? null
                : () async {
                    if (_selectedAgentId == null) return;
                    setState(() => _assigningAgent = true);
                    await ref.read(adminOrdersProvider.notifier).assignAgent(
                          order.id,
                          _selectedAgentId!,
                          _selectedAgentName!,
                        );
                    setState(() => _assigningAgent = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saha gorevlisi atandi'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 16),

          // ----------- Teslimat Gorevlisi -----------
          _AssignmentSection(
            title: 'Teslimat Görevlisi',
            icon: Icons.local_shipping_outlined,
            assignedName: order.assignedDeliveryName,
            personsAsync: deliveryAsync,
            selectedId: _selectedDeliveryId,
            onChanged: (id, name) {
              setState(() {
                _selectedDeliveryId = id;
                _selectedDeliveryName = name;
              });
            },
            onAssign: _assigningDelivery
                ? null
                : () async {
                    if (_selectedDeliveryId == null) return;
                    setState(() => _assigningDelivery = true);
                    await ref
                        .read(adminOrdersProvider.notifier)
                        .assignDelivery(
                          order.id,
                          _selectedDeliveryId!,
                          _selectedDeliveryName!,
                        );
                    setState(() => _assigningDelivery = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Teslimat gorevlisi atandi'),
                          backgroundColor: AppColors.success,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // ----------- Ic Notlar -----------
          const Text(
            'Ic Notlar',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),

          if (order.notes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Henuz ic not yok.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),
            )
          else
            ...order.notes.map((note) => _NoteCard(note: note)),

          const SizedBox(height: 10),

          // Not ekleme alanı
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Not ekle...',
              contentPadding: EdgeInsets.all(12),
              isDense: true,
            ),
            style:
                const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addingNote
                  ? null
                  : () async {
                      final content = _noteController.text.trim();
                      if (content.isEmpty) return;
                      setState(() => _addingNote = true);
                      await ref
                          .read(adminOrdersProvider.notifier)
                          .addNote(order.id, content);
                      _noteController.clear();
                      setState(() => _addingNote = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Not eklendi'),
                            backgroundColor: AppColors.success,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
              icon: _addingNote
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textWhite),
                    )
                  : const Icon(Icons.add_comment_outlined, size: 16),
              label: const Text('Not Ekle',
                  style: TextStyle(fontSize: 13, fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 40),
                backgroundColor: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // ----------- Tehlikeli Aksiyonlar -----------
          const Text(
            'Aksiyonlar',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),

          // Iptal butonu
          if (order.status != AdminOrderStatus.cancelled &&
              order.status != AdminOrderStatus.refunded &&
              order.status != AdminOrderStatus.delivered)
            _DangerButton(
              icon: Icons.cancel_outlined,
              label: 'Siparisi İptal Et',
              color: AppColors.error,
              onTap: () => _showCancelDialog(context, ref, order),
            ),

          if ((order.status == AdminOrderStatus.delivered ||
                  order.status == AdminOrderStatus.onTheWay) &&
              order.status != AdminOrderStatus.refunded) ...[
            const SizedBox(height: 8),
            _DangerButton(
              icon: Icons.replay_outlined,
              label: 'Iade Baslatı',
              color: AppColors.warning,
              onTap: () => _showRefundDialog(context, ref, order),
            ),
          ],

          if (order.status == AdminOrderStatus.cancelled ||
              order.status == AdminOrderStatus.refunded ||
              order.status == AdminOrderStatus.delivered)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Bu sipariş için aksiyon alinabilecek durum yok.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    AdminOrderModel order,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Siparisi İptal Et',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${order.orderNumber} siparişini iptal etmek istediğinizden emin misiniz?',
              style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'İptal Sebebi (zorunlu)',
                hintText: 'İptal sebebini yazın...',
              ),
              style:
                  const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('İptal Et'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(adminOrdersProvider.notifier).cancelOrder(
            order.id,
            reasonController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Siparis iptal edildi'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    reasonController.dispose();
  }

  Future<void> _showRefundDialog(
    BuildContext context,
    WidgetRef ref,
    AdminOrderModel order,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Iade Baslatı',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          '${order.orderNumber} siparişi için iade süreci baslatilacak. Devam etmek istiyor musunuz?',
          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Iade Baslatı'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(adminOrdersProvider.notifier).initiateRefund(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Iade sureci baslatildi'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Atama bolumu (generic)
// ---------------------------------------------------------------------------

class _AssignmentSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? assignedName;
  final AsyncValue<List<({String id, String name})>> personsAsync;
  final String? selectedId;
  final void Function(String id, String name) onChanged;
  final VoidCallback? onAssign;

  const _AssignmentSection({
    required this.title,
    required this.icon,
    required this.assignedName,
    required this.personsAsync,
    required this.selectedId,
    required this.onChanged,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            if (assignedName != null) ...[
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  assignedName!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: personsAsync.when(
                loading: () => const SizedBox(
                  height: 36,
                  child: Center(
                    child: LinearProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                error: (e, _) => Text(
                  'Yuklenemedi',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                      fontFamily: 'Poppins'),
                ),
                data: (persons) => DropdownButtonHideUnderline(
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButton<String>(
                      value: selectedId,
                      isExpanded: true,
                      isDense: true,
                      hint: const Text(
                        'Secin...',
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            color: AppColors.textHint),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          size: 16, color: AppColors.textSecondary),
                      items: persons
                          .map(
                            (p) => DropdownMenuItem<String>(
                              value: p.id,
                              child: Text(
                                p.name,
                                style: const TextStyle(
                                    fontSize: 13, fontFamily: 'Poppins'),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) {
                        if (id == null) return;
                        final person =
                            persons.firstWhere((p) => p.id == id);
                        onChanged(id, person.name);
                      },
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: onAssign,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(56, 36),
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text(
                'Ata',
                style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Not karti
// ---------------------------------------------------------------------------

class _NoteCard extends StatelessWidget {
  final InternalNote note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                note.authorName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd/MM HH:mm').format(note.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note.content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tehlikeli aksiyon butonu
// ---------------------------------------------------------------------------

class _DangerButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DangerButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(
              fontSize: 13, fontFamily: 'Poppins', color: color),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.6)),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bilgi satiri
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                  fontFamily: 'Poppins',
                ),
              ),
              isLink
                  ? GestureDetector(
                      onTap: onTap,
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondary,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final AdminOrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status.color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section karti sarmalayici
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer
// ---------------------------------------------------------------------------

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: Column(
        children: [
          _ShimmerBox(width: double.infinity, height: 32),
          const SizedBox(height: 20),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _ShimmerBox(width: double.infinity, height: 400)),
                const SizedBox(width: 16),
                Expanded(
                    child: _ShimmerBox(width: double.infinity, height: 400)),
                const SizedBox(width: 16),
                Expanded(
                    child: _ShimmerBox(width: double.infinity, height: 400)),
              ],
            )
          else
            Column(
              children: [
                _ShimmerBox(width: double.infinity, height: 300),
                const SizedBox(height: 16),
                _ShimmerBox(width: double.infinity, height: 300),
                const SizedBox(height: 16),
                _ShimmerBox(width: double.infinity, height: 200),
              ],
            ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerBox({
    required this.width,
    required this.height,
  });

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
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment(_animation.value - 1, 0),
            end: Alignment(_animation.value, 0),
            colors: const [
              Color(0xFFEEEEEE),
              Color(0xFFF5F5F5),
              Color(0xFFEEEEEE),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hata durumu
// ---------------------------------------------------------------------------

class _DetailError extends StatelessWidget {
  final Object error;
  const _DetailError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Siparis yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/orders'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Siparislere Don'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Change Bottom Sheet
// ---------------------------------------------------------------------------

class _StatusChangeSheet extends StatelessWidget {
  final AdminOrderStatus currentStatus;
  final AdminOrderStatus newStatus;
  final String? orderNumber;

  const _StatusChangeSheet({
    required this.currentStatus,
    required this.newStatus,
    this.orderNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Sipariş Durumu Güncelle',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          if (orderNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              orderNumber!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatusChip(status: currentStatus),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              _StatusChip(status: newStatus, isNew: true),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              child: const Text('Güncelle'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              minimumSize: const Size(double.infinity, 44),
            ),
            child: const Text(
              'Vazgeç',
              style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AdminOrderStatus status;
  final bool isNew;

  const _StatusChip({required this.status, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: isNew ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.color.withValues(alpha: isNew ? 0.5 : 0.2),
          width: isNew ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isNew ? FontWeight.w700 : FontWeight.w500,
              color: status.color,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
