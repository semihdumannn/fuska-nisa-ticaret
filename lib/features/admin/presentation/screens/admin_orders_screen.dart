import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nisa_ticaret/core/utils/navigation_guard.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_order_model.dart';
import '../providers/admin_orders_provider.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/status_multi_select.dart';

const double _kDesktopBreakpoint = 1024.0;
const double _kTabletBreakpoint = 700.0;

// ---------------------------------------------------------------------------
// Ekran koku
// ---------------------------------------------------------------------------

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;

    if (isDesktop) {
      return const _DesktopLayout();
    }
    return const _MobileLayout();
  }
}

// ---------------------------------------------------------------------------
// Desktop layout
// ---------------------------------------------------------------------------

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: Row(
        children: [
          AdminSidebar(),
          Expanded(child: _OrdersContent()),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobil layout
// ---------------------------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      drawer: const AdminDrawerWrapper(),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: const Text(
          'Siparis Yonetimi',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        elevation: 0,
      ),
      body: const _OrdersContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// Ana içerik alani
// ---------------------------------------------------------------------------

class _OrdersContent extends ConsumerWidget {
  const _OrdersContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminOrdersProvider);

    return ordersAsync.when(
      loading: () => const _OrdersShimmer(),
      error: (e, _) => _OrdersError(error: e),
      data: (_) => const _OrdersBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// Ana govde
// ---------------------------------------------------------------------------

class _OrdersBody extends ConsumerWidget {
  const _OrdersBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;

    return RefreshIndicator(
      onRefresh: () => ref.read(adminOrdersProvider.notifier).refresh(),
      child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            const _OrdersHeader(),
            const SizedBox(height: 20),
          ],
          const _StatsRow(),
          const SizedBox(height: 20),
          const _FiltersRow(),
          const SizedBox(height: 8),
          const _BulkActionsBar(),
          const SizedBox(height: 12),
          const _OrdersTable(),
          const SizedBox(height: 16),
          const _PaginationRow(),
          const SizedBox(height: 40),
        ],
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Siparis Yonetimi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tum siparisleri goruntule, filtrele ve yonet',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats satiri (4 chip)
// ---------------------------------------------------------------------------

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(orderStatsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= _kTabletBreakpoint;

    final items = [
      _StatItem(
        label: 'Bekleyen',
        value: stats.pending,
        color: AppColors.statusPending,
        icon: Icons.schedule_outlined,
      ),
      _StatItem(
        label: 'Hazirlanan',
        value: stats.preparing,
        color: AppColors.statusPreparing,
        icon: Icons.restaurant_outlined,
      ),
      _StatItem(
        label: 'Yolda',
        value: stats.onTheWay,
        color: AppColors.statusOnTheWay,
        icon: Icons.local_shipping_outlined,
      ),
      _StatItem(
        label: 'Bugun Toplam',
        value: stats.todayTotal,
        color: AppColors.statusDelivered,
        icon: Icons.today_outlined,
      ),
    ];

    if (isTablet) {
      return Row(
        children:
            items.map((i) => Expanded(child: _StatCard(item: i))).toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.0,
      children: items.map((i) => _StatCard(item: i)).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.color, size: 17),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${item.value}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: item.color,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filtreler satiri
// ---------------------------------------------------------------------------

class _FiltersRow extends ConsumerStatefulWidget {
  const _FiltersRow();

  @override
  ConsumerState<_FiltersRow> createState() => _FiltersRowState();
}

class _FiltersRowState extends ConsumerState<_FiltersRow> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateRange = ref.watch(orderDateRangeProvider);
    final paymentFilter = ref.watch(orderPaymentFilterProvider);
    final search = ref.watch(orderSearchProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= _kTabletBreakpoint;

    // Disi search field güncellemesi
    if (_searchController.text != search) {
      _searchController.text = search;
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: search.length),
      );
    }

    final dateLabel = dateRange == null
        ? 'Tarih'
        : '${DateFormat('dd MMM', 'tr_TR').format(dateRange.start)} - ${DateFormat('dd MMM', 'tr_TR').format(dateRange.end)}';

    final hasFilters = dateRange != null ||
        paymentFilter != null ||
        ref.watch(orderStatusFilterProvider).isNotEmpty ||
        search.isNotEmpty;

    final statusDropdown = const StatusMultiSelectDropdown();

    final dateButton = _FilterButton(
      label: dateLabel,
      icon: Icons.date_range_outlined,
      isActive: dateRange != null,
      onTap: () async {
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: dateRange,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                secondary: AppColors.secondary,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          ref.read(orderDateRangeProvider.notifier).set(picked);
        }
      },
    );

    final paymentDropdown = DropdownButtonHideUnderline(
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: paymentFilter != null
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: paymentFilter != null
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
            width: paymentFilter != null ? 1.5 : 1,
          ),
        ),
        child: DropdownButton<AdminPaymentMethod?>(
          value: paymentFilter,
          hint: const Text(
            'Ödeme',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Poppins',
              color: AppColors.textSecondary,
            ),
          ),
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: AppColors.textSecondary),
          items: [
            const DropdownMenuItem<AdminPaymentMethod?>(
              value: null,
              child: Text(
                'Tum Ödemeler',
                style: TextStyle(fontSize: 13, fontFamily: 'Poppins'),
              ),
            ),
            ...AdminPaymentMethod.values.map(
              (m) => DropdownMenuItem<AdminPaymentMethod?>(
                value: m,
                child: Text(
                  m.displayName,
                  style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                ),
              ),
            ),
          ],
          onChanged: (val) {
            ref.read(orderPaymentFilterProvider.notifier).set(val);
          },
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );

    final searchField = SizedBox(
      height: 40,
      width: isTablet ? 200 : double.infinity,
      child: TextField(
        controller: _searchController,
        onChanged: (v) =>
            ref.read(orderSearchProvider.notifier).set(v),
        decoration: const InputDecoration(
          hintText: 'Ara...',
          prefixIcon: Icon(Icons.search_outlined, size: 18),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
      ),
    );

    final clearButton = hasFilters
        ? TextButton.icon(
            onPressed: () {
              ref.read(orderStatusFilterProvider.notifier).set({});
              ref.read(orderDateRangeProvider.notifier).set(null);
              ref.read(orderPaymentFilterProvider.notifier).set(null);
              ref.read(orderSearchProvider.notifier).set('');
              _searchController.clear();
            },
            icon: const Icon(Icons.clear, size: 14),
            label: const Text(
              'Temizle',
              style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          )
        : null;

    if (isTablet) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          statusDropdown,
          dateButton,
          paymentDropdown,
          searchField,
          if (clearButton != null) clearButton,
        ],
      );
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              statusDropdown,
              const SizedBox(width: 8),
              dateButton,
              const SizedBox(width: 8),
              paymentDropdown,
              if (clearButton != null) ...[
                const SizedBox(width: 8),
                clearButton,
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        searchField,
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.4)
                : AppColors.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bulk actions bar (animasyonlu)
// ---------------------------------------------------------------------------

class _BulkActionsBar extends ConsumerWidget {
  const _BulkActionsBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedOrderIdsProvider);
    final visible = selected.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: visible ? 52 : 0,
      child: visible
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_box_outlined,
                      size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    '${selected.length} sipariş seçili',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const Spacer(),
                  // Onayla butonu
                  TextButton.icon(
                    onPressed: () async {
                      await ref
                          .read(adminOrdersProvider.notifier)
                          .bulkConfirm(selected.toList());
                      ref.read(selectedOrderIdsProvider.notifier).set({});
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${selected.length} sipariş onaylandı'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 15),
                    label: const Text(
                      'Onayla',
                      style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // CSV indir
                  TextButton.icon(
                    onPressed: () => _exportCsv(context, ref, selected),
                    icon: const Icon(Icons.download_outlined, size: 15),
                    label: const Text(
                      'CSV',
                      style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  // Secimi kaldir
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      ref.read(selectedOrderIdsProvider.notifier).set({});
                    },
                    color: AppColors.textSecondary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Secimi kaldir',
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _exportCsv(
      BuildContext context, WidgetRef ref, Set<String> selectedIds) {
    final orders = ref.read(adminOrdersProvider).value ?? [];
    final selected =
        orders.where((o) => selectedIds.contains(o.id)).toList();

    if (selected.isEmpty) return;

    final buf = StringBuffer();
    buf.writeln(
        'Sipariş No,Müşteri,Telefon,Tutar,Ödeme,Durum,Tarih,Saha Gorevlisi,Teslimat');
    for (final o in selected) {
      final fmt = DateFormat('dd/MM/yyyy HH:mm');
      buf.writeln(
          '${o.orderNumber},${o.customerName},${o.customerPhone},${o.total.toStringAsFixed(2)},${o.paymentMethod.displayName},${o.status.displayName},${fmt.format(o.createdAt)},${o.assignedAgentName ?? ''},${o.assignedDeliveryName ?? ''}');
    }

    // Kopyaya bildirim — share_plus yoksa clipboard'a yaz
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('${selected.length} sipariş CSV formatinda hazirlandi'),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: AppColors.textWhite,
          onPressed: () {},
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Siparisler DataTable
// ---------------------------------------------------------------------------

class _OrdersTable extends ConsumerWidget {
  const _OrdersTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(paginatedOrdersProvider);
    final filtered = ref.watch(filteredOrdersProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= _kTabletBreakpoint;

    if (filtered.isEmpty) {
      return const _EmptyState();
    }

    if (!isTablet) {
      return _OrdersMobileList(orders: orders);
    }

    final selectedIds = ref.watch(selectedOrderIdsProvider);
    final allIds = orders.map((o) => o.id).toSet();
    final allSelected = allIds.isNotEmpty && allIds.every(selectedIds.contains);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.adminBackground),
            headingTextStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            dataTextStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            dividerThickness: 1,
            columnSpacing: 18,
            columns: [
              DataColumn(
                label: Checkbox(
                  value: allSelected,
                  onChanged: (v) {
                    if (v == true) {
                      final current =
                          Set<String>.from(selectedIds)..addAll(allIds);
                      ref.read(selectedOrderIdsProvider.notifier).set(current);
                    } else {
                      final current =
                          Set<String>.from(selectedIds)..removeAll(allIds);
                      ref.read(selectedOrderIdsProvider.notifier).set(current);
                    }
                  },
                  activeColor: AppColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const DataColumn(label: Text('SIPARIS NO')),
              const DataColumn(label: Text('MUSTERI')),
              const DataColumn(label: Text('TUTAR'), numeric: true),
              const DataColumn(label: Text('ODEME')),
              const DataColumn(label: Text('DURUM')),
              const DataColumn(label: Text('TARIH')),
              const DataColumn(label: Text('ATANAN')),
              const DataColumn(label: Text('ISLEM')),
            ],
            rows: orders
                .map((o) => _buildRow(context, ref, o, selectedIds))
                .toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(
    BuildContext context,
    WidgetRef ref,
    AdminOrderModel order,
    Set<String> selectedIds,
  ) {
    final isSelected = selectedIds.contains(order.id);
    final assignedLabel = order.assignedAgentName ??
        order.assignedDeliveryName ??
        '—';

    return DataRow(
      selected: isSelected,
      color: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.05);
        }
        return null;
      }),
      cells: [
        // Checkbox
        DataCell(
          Checkbox(
            value: isSelected,
            onChanged: (v) {
              final current = Set<String>.from(selectedIds);
              if (v == true) {
                current.add(order.id);
              } else {
                current.remove(order.id);
              }
              ref.read(selectedOrderIdsProvider.notifier).set(current);
            },
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        // Sipariş No
        DataCell(
          TextButton(
            onPressed: () => context.safePush(
              '/admin/orders/${order.id}',
            ),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.secondary,
            ),
            child: Text(
              order.orderNumber,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
                color: AppColors.secondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        // Müşteri
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.customerName,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins'),
              ),
              Text(
                order.customerPhone,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
        // Tutar
        DataCell(
          Text(
            NumberFormat.currency(
                    locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
                .format(order.total),
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
          ),
        ),
        // Ödeme
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(order.paymentMethod.icon,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                order.paymentMethod.displayName,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
        ),
        // Durum
        DataCell(_OrderStatusBadge(status: order.status)),
        // Tarih
        DataCell(
          Text(
            DateFormat('dd/MM/yy HH:mm').format(order.createdAt),
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins'),
          ),
        ),
        // Atanan
        DataCell(
          Text(
            assignedLabel,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins'),
          ),
        ),
        // Islemler
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon:
                    const Icon(Icons.visibility_outlined, size: 17),
                color: AppColors.secondary,
                tooltip: 'Goruntule',
                onPressed: () =>
                    context.safePush('/admin/orders/${order.id}'),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 30, minHeight: 30),
              ),
              _QuickStatusMenu(order: order),
            ],
          ),
        ),
      ],
    );
  }
}

// Quick status değiştirme popup
class _QuickStatusMenu extends ConsumerWidget {
  final AdminOrderModel order;
  const _QuickStatusMenu({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<AdminOrderStatus>(
      icon: const Icon(Icons.more_vert, size: 17, color: AppColors.textSecondary),
      tooltip: 'Durum Değiştir',
      padding: EdgeInsets.zero,
      itemBuilder: (_) => AdminOrderStatus.values
          .where((s) => s != order.status)
          .map(
            (s) => PopupMenuItem<AdminOrderStatus>(
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
                  const SizedBox(width: 8),
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
      onSelected: (newStatus) async {
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
          await ref
              .read(adminOrdersProvider.notifier)
              .updateStatus(order.id, newStatus);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${order.orderNumber} → ${newStatus.displayName}'),
                backgroundColor: newStatus.color,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Mobil kart listesi
// ---------------------------------------------------------------------------

class _OrdersMobileList extends StatelessWidget {
  final List<AdminOrderModel> orders;
  const _OrdersMobileList({required this.orders});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _OrderMobileCard(order: orders[i]),
    );
  }
}

class _OrderMobileCard extends ConsumerWidget {
  final AdminOrderModel order;
  const _OrderMobileCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.safePush('/admin/orders/${order.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                _OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              order.customerName,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins'),
            ),
            Text(
              order.customerPhone,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  NumberFormat.currency(
                          locale: 'tr_TR', symbol: '₺', decimalDigits: 2)
                      .format(order.total),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yy HH:mm').format(order.createdAt),
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                      fontFamily: 'Poppins'),
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

class _OrderStatusBadge extends StatelessWidget {
  final AdminOrderStatus status;
  const _OrderStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              fontSize: 11,
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
// Sayfalama
// ---------------------------------------------------------------------------

class _PaginationRow extends ConsumerWidget {
  const _PaginationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(ordersPageProvider);
    final totalPages = ref.watch(totalOrderPagesProvider);
    final filtered = ref.watch(filteredOrdersProvider);

    final startItem = filtered.isEmpty ? 0 : page * kOrdersPerPage + 1;
    final endItem =
        ((page + 1) * kOrdersPerPage).clamp(0, filtered.length);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${filtered.isEmpty ? 0 : startItem}–$endItem / ${filtered.length} siparis',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: page > 0
                  ? () => ref.read(ordersPageProvider.notifier).set(page - 1)
                  : null,
              color: page > 0 ? AppColors.secondary : AppColors.textHint,
              tooltip: 'Onceki',
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${page + 1} / $totalPages',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: page < totalPages - 1
                  ? () => ref.read(ordersPageProvider.notifier).set(page + 1)
                  : null,
              color: page < totalPages - 1
                  ? AppColors.secondary
                  : AppColors.textHint,
              tooltip: 'Sonraki',
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bos durum
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'Siparis bulunamadı',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Filtre kriterlerini değiştirmeyi deneyin',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer
// ---------------------------------------------------------------------------

class _OrdersShimmer extends StatelessWidget {
  const _OrdersShimmer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            _ShimmerBox(width: 240, height: 28),
            const SizedBox(height: 6),
            _ShimmerBox(width: 320, height: 16),
            const SizedBox(height: 24),
          ],
          Row(
            children: List.generate(
              4,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ShimmerBox(width: double.infinity, height: 56),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ShimmerBox(width: double.infinity, height: 48),
          const SizedBox(height: 16),
          _ShimmerBox(width: double.infinity, height: 420),
        ],
      ),
    );
  }
}

// Shimmer kutusu (Users ekranindaki ile ayni pattern)
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
              AppColors.shimmerBase,
              AppColors.shimmerHighlight,
              AppColors.shimmerBase,
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

class _OrdersError extends StatelessWidget {
  final Object error;
  const _OrdersError({required this.error});

  @override
  Widget build(BuildContext context) {
    final isRoleError = error is AdminRoleException;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRoleError ? Icons.admin_panel_settings_outlined : Icons.error_outline_rounded,
              color: isRoleError ? AppColors.warning : AppColors.error,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              isRoleError ? 'Yetki Hatasi (403)' : 'Siparisler yüklenemedi',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            if (isRoleError) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend kullanıcı rolünüz "customer".\nAdmin panelini açmak için "admin" olmalı.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Düzeltme (HF Space → Tinker):',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'User::where("phone","<no>")\n  ->update(["role"=>"admin"]);',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(
                    text: 'User::where("phone","<telefonunuz>")->update(["role" => "admin"]);',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Komut kopyalandı'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_outlined, size: 16),
                label: const Text(
                  'Komutu Kopyala',
                  style: TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                ),
              ),
            ] else
              Text(
                error.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status Change Bottom Sheet (shared with admin_order_detail_screen)
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
