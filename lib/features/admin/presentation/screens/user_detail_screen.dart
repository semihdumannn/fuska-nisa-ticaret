import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/models/order_summary_model.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_sidebar.dart';

const double _kDesktopBreakpoint = 1024.0;

class UserDetailScreen extends ConsumerWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userDetailProvider(userId));
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Row(
          children: [
            const AdminSidebar(),
            Expanded(
              child: _DetailContent(
                userId: userId,
                userAsync: userAsync,
                isDesktop: true,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.secondary,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        title: userAsync.when(
          data: (user) => Text(
            user.name,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          loading: () => const Text(
            'Kullanici Detayi',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          error: (_, __) => const Text(
            'Hata',
            style: TextStyle(color: AppColors.textWhite),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined),
          onPressed: () => context.pop(),
        ),
      ),
      body: _DetailContent(
        userId: userId,
        userAsync: userAsync,
        isDesktop: false,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Icerik
// ---------------------------------------------------------------------------

class _DetailContent extends StatelessWidget {
  final String userId;
  final AsyncValue<AdminUserModel> userAsync;
  final bool isDesktop;

  const _DetailContent({
    required this.userId,
    required this.userAsync,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return userAsync.when(
      loading: () => const _DetailShimmer(),
      error: (e, _) => _DetailError(error: e),
      data: (user) => _DetailBody(user: user, isDesktop: isDesktop),
    );
  }
}

// ---------------------------------------------------------------------------
// Govde (2-kolon desktop / tek kolon mobil)
// ---------------------------------------------------------------------------

class _DetailBody extends ConsumerWidget {
  final AdminUserModel user;
  final bool isDesktop;

  const _DetailBody({required this.user, required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            _DetailHeader(user: user),
            const SizedBox(height: 24),
          ],
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 340,
                  child: _UserInfoCard(user: user),
                ),
                const SizedBox(width: 20),
                Expanded(child: _OrdersCard(userId: user.id)),
              ],
            )
          else ...[
            _UserInfoCard(user: user),
            const SizedBox(height: 16),
            _OrdersCard(userId: user.id),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop header
// ---------------------------------------------------------------------------

class _DetailHeader extends StatelessWidget {
  final AdminUserModel user;
  const _DetailHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_outlined, size: 20),
          onPressed: () => context.pop(),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kullanici Detayi — ${user.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                user.phone,
                style: const TextStyle(
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
// Sol kart: kullanici bilgileri
// ---------------------------------------------------------------------------

class _UserInfoCard extends ConsumerStatefulWidget {
  final AdminUserModel user;
  const _UserInfoCard({required this.user});

  @override
  ConsumerState<_UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends ConsumerState<_UserInfoCard> {
  late UserRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Engellendi uyarisi
          if (user.isBlocked) _BlockedBanner(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar + bilgiler
                _AvatarSection(user: user),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Engel / Aktif Switch
                _BlockToggleSection(user: user),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Rol degistir
                _RoleChangeSection(
                  user: user,
                  selectedRole: _selectedRole,
                  onRoleChanged: (r) => setState(() => _selectedRole = r),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.block_outlined, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Bu kullanici engellenmiştir ve uygulamaya giris yapamaz.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final AdminUserModel user;
  const _AvatarSection({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: user.role.roleColor.withValues(alpha: 0.15),
            child: Text(
              user.initials,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: user.role.roleColor,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            user.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            user.phone,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        if (user.email != null) ...[
          const SizedBox(height: 2),
          Center(
            child: Text(
              user.email!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Info satirlari
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: 'Kayit Tarihi',
          value: DateFormat('dd MMM yyyy', 'tr_TR').format(user.createdAt),
        ),
        if (user.lastLoginAt != null)
          _InfoRow(
            icon: Icons.access_time_outlined,
            label: 'Son Giris',
            value: DateFormat('dd MMM yyyy, HH:mm', 'tr_TR')
                .format(user.lastLoginAt!),
          ),
        if (user.address != null)
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Adres',
            value: user.address!,
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockToggleSection extends ConsumerWidget {
  final AdminUserModel user;
  const _BlockToggleSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.isBlocked
                    ? 'Kullanici Engellenmis'
                    : 'Kullanici Aktif',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: user.isBlocked ? AppColors.error : AppColors.success,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.isBlocked
                    ? 'Engeli kaldirmak icin toglle kapatin'
                    : 'Kullaniciyi engellemek icin toggle acin',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: user.isBlocked,
          activeThumbColor: AppColors.error,
          activeTrackColor: AppColors.error.withValues(alpha: 0.4),
          inactiveThumbColor: AppColors.success,
          inactiveTrackColor: AppColors.success.withValues(alpha: 0.3),
          onChanged: (val) => _confirmToggle(context, ref, user),
        ),
      ],
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    WidgetRef ref,
    AdminUserModel user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          user.isBlocked ? 'Engeli Kaldir' : 'Kullaniciyi Engelle',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          user.isBlocked
              ? '${user.name} adli kullanıcının engelini kaldırmak istediğinizden emin misiniz?'
              : '${user.name} adli kullanıcıyı engellemek istediğinizden emin misiniz?',
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
              backgroundColor:
                  user.isBlocked ? AppColors.success : AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            child: Text(user.isBlocked ? 'Engeli Kaldir' : 'Engelle'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(adminUsersProvider.notifier).toggleBlock(user.id);
    }
  }
}

class _RoleChangeSection extends ConsumerWidget {
  final AdminUserModel user;
  final UserRole selectedRole;
  final void Function(UserRole) onRoleChanged;

  const _RoleChangeSection({
    required this.user,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rol Degistir',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<UserRole>(
          initialValue: selectedRole,
          decoration: const InputDecoration(
            labelText: 'Kullanici Rolu',
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Poppins',
            color: AppColors.textPrimary,
          ),
          items: UserRole.values.map((role) {
            return DropdownMenuItem<UserRole>(
              value: role,
              child: Row(
                children: [
                  Icon(role.roleIcon, size: 16, color: role.roleColor),
                  const SizedBox(width: 8),
                  Text(
                    role.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (role) {
            if (role != null) onRoleChanged(role);
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: selectedRole == user.role
                ? null
                : () => _confirmRoleUpdate(context, ref),
            icon: const Icon(Icons.check_outlined, size: 16),
            label: const Text('Rolu Güncelle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              disabledBackgroundColor: AppColors.border,
              minimumSize: const Size(double.infinity, 44),
              textStyle: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmRoleUpdate(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Rol Degistir',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Poppins',
              color: AppColors.textPrimary,
            ),
            children: [
              TextSpan(text: '${user.name} '),
              const TextSpan(text: 'kullanicisinin rolunu '),
              TextSpan(
                text: user.role.displayName,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: ' -> '),
              TextSpan(
                text: selectedRole.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selectedRole.roleColor,
                ),
              ),
              const TextSpan(text: ' olarak değiştirmek istiyor musunuz?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(80, 40),
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref
          .read(adminUsersProvider.notifier)
          .updateUserRole(user.id, selectedRole);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rol güncellendi: ${selectedRole.displayName}'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Sag kart: siparis gecmisi
// ---------------------------------------------------------------------------

class _OrdersCard extends ConsumerWidget {
  final String userId;
  const _OrdersCard({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider(userId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _OrdersCardHeader(ordersAsync: ordersAsync),
          const Divider(height: 1),
          ordersAsync.when(
            loading: () => const _OrdersLoadingState(),
            error: (e, _) => _OrdersErrorState(error: e),
            data: (orders) => orders.isEmpty
                ? const _OrdersEmptyState()
                : _OrdersList(orders: orders),
          ),
        ],
      ),
    );
  }
}

class _OrdersCardHeader extends StatelessWidget {
  final AsyncValue<List<OrderSummaryModel>> ordersAsync;
  const _OrdersCardHeader({required this.ordersAsync});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Siparis Gecmisi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
          ordersAsync.when(
            data: (orders) {
              if (orders.isEmpty) return const SizedBox.shrink();
              final total = orders.fold<double>(0, (s, o) => s + o.amount);
              return Row(
                children: [
                  Text(
                    '${orders.length} siparis',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      NumberFormat.currency(
                              locale: 'tr_TR',
                              symbol: '₺',
                              decimalDigits: 0)
                          .format(total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final List<OrderSummaryModel> orders;
  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (_, i) => _OrderSummaryTile(order: orders[i]),
    );
  }
}

class _OrderSummaryTile extends StatelessWidget {
  final OrderSummaryModel order;
  const _OrderSummaryTile({required this.order});

  Color get _statusColor {
    switch (order.status) {
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push(
          AppRoutes.orderManagement,
          // TODO: Navigate to specific order detail when route is available
          // context.push(AppRoutes.adminOrderDetail.replaceFirst(':id', order.id));
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Siparis no + tarih
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNo,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(order.date),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            // Urun sayisi
            Text(
              '${order.itemCount} urun',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 12),
            // Tutar
            Text(
              NumberFormat.currency(
                      locale: 'tr_TR', symbol: '₺', decimalDigits: 0)
                  .format(order.amount),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 10),
            // Durum chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 40,
              color: AppColors.textHint,
            ),
            SizedBox(height: 8),
            Text(
              'Henuz siparis yok',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersLoadingState extends StatelessWidget {
  const _OrdersLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _OrdersErrorState extends StatelessWidget {
  final Object error;
  const _OrdersErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Siparisler yüklenemedi: ${error.toString()}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.error,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer yukleme
// ---------------------------------------------------------------------------

class _DetailShimmer extends StatelessWidget {
  const _DetailShimmer();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(width: 300, height: 28),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(width: 340, height: 500),
              const SizedBox(width: 20),
              Expanded(child: _ShimmerBox(width: double.infinity, height: 400)),
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
// Hata
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
              'Kullanici yüklenemedi',
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
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_outlined, size: 16),
              label: const Text('Geri Don'),
            ),
          ],
        ),
      ),
    );
  }
}
