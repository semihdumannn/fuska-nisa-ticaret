import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nisa_ticaret/core/utils/navigation_guard.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/admin_user_model.dart';
import '../providers/admin_users_provider.dart';
import '../widgets/admin_sidebar.dart';

const double _kDesktopBreakpoint = 1024.0;
const double _kTabletBreakpoint = 700.0;

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

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

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AdminSidebar(),
          Expanded(child: _UsersContent()),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  const _MobileLayout();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AdminDrawerWrapper(),
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        title: const Text(
          'Kullanici Yonetimi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: const _UsersContent(),
    );
  }
}

// ---------------------------------------------------------------------------
// Ana içerik alani
// ---------------------------------------------------------------------------

class _UsersContent extends ConsumerWidget {
  const _UsersContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return usersAsync.when(
      loading: () => const _UsersShimmer(),
      error: (e, _) => _UsersError(error: e),
      data: (_) => const _UsersBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// Icerik govdesi
// ---------------------------------------------------------------------------

class _UsersBody extends ConsumerWidget {
  const _UsersBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= _kDesktopBreakpoint;
    final isTablet = width >= _kTabletBreakpoint;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 28 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) ...[
            _UsersHeader(isDesktop: isDesktop),
            const SizedBox(height: 24),
          ],
          const _StatsRow(),
          const SizedBox(height: 20),
          const _FiltersRow(),
          const SizedBox(height: 16),
          isTablet
              ? const _UsersDataTable()
              : const _UsersMobileList(),
          const SizedBox(height: 16),
          const _PaginationRow(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _UsersHeader extends StatelessWidget {
  final bool isDesktop;
  const _UsersHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kullanici Yonetimi',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Tum kullanicilari goruntule, filtrele ve yonet',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
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
// Stats satiri
// ---------------------------------------------------------------------------

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= _kTabletBreakpoint;

    final items = [
      _StatItem('Toplam', stats.total, AppColors.secondary, Icons.people_outline),
      _StatItem('Müşteri', stats.customer, AppColors.secondary, Icons.person_outline),
      _StatItem('Saha', stats.fieldAgent, AppColors.primary, Icons.badge_outlined),
      _StatItem('Teslimat', stats.delivery, AppColors.accent, Icons.local_shipping_outlined),
      _StatItem('Admin', stats.admin, AppColors.success, Icons.admin_panel_settings_outlined),
      _StatItem('Engellenmiş', stats.blocked, AppColors.error, Icons.block_outlined),
    ];

    if (isTablet) {
      return Row(
        children: items
            .map((i) => Expanded(child: _StatCard(item: i)))
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: items.map((i) => _StatCard(item: i)).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatItem(this.label, this.count, this.color, this.icon);
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: item.color, size: 18),
            const SizedBox(height: 2),
            Text(
              '${item.count}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: item.color,
              ),
            ),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filtreler
// ---------------------------------------------------------------------------

class _FiltersRow extends ConsumerWidget {
  const _FiltersRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleFilter = ref.watch(userRoleFilterProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= _kTabletBreakpoint;

    final searchField = TextField(
      onChanged: (v) {
        ref.read(userSearchProvider.notifier).set(v);
        ref.read(userPageProvider.notifier).set(0);
      },
      decoration: const InputDecoration(
        hintText: 'Isim veya telefon ara...',
        prefixIcon: Icon(Icons.search_outlined, size: 20),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
    );

    final roleChips = _RoleFilterChips(
      selected: roleFilter,
      onSelected: (role) {
        ref.read(userRoleFilterProvider.notifier).set(role);
        ref.read(userPageProvider.notifier).set(0);
      },
    );

    if (isTablet) {
      return Row(
        children: [
          SizedBox(width: 280, child: searchField),
          const SizedBox(width: 16),
          Expanded(child: roleChips),
        ],
      );
    }

    return Column(
      children: [
        searchField,
        const SizedBox(height: 10),
        roleChips,
      ],
    );
  }
}

class _RoleFilterChips extends StatelessWidget {
  final UserRole? selected;
  final void Function(UserRole?) onSelected;

  const _RoleFilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final roles = [null, UserRole.customer, UserRole.fieldAgent, UserRole.delivery, UserRole.admin];
    final labels = ['Tumu', 'Müşteri', 'Saha', 'Teslimat', 'Admin'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(roles.length, (i) {
          final role = roles[i];
          final isSelected = selected == role;
          final color = role?.roleColor ?? AppColors.textSecondary;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(role),
              backgroundColor: AppColors.surface,
              selectedColor: color,
              checkmarkColor: Colors.white,
              side: BorderSide(color: isSelected ? color : AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kullanici DataTable (tablet / desktop)
// ---------------------------------------------------------------------------

class _UsersDataTable extends ConsumerWidget {
  const _UsersDataTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(pagedUsersProvider);

    if (users.isEmpty) {
      return const _EmptyState();
    }

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
            headingRowColor: WidgetStateProperty.all(
              AppColors.adminBackground,
            ),
            headingTextStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            dataTextStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            dividerThickness: 1,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('KULLANICI')),
              DataColumn(label: Text('TELEFON')),
              DataColumn(label: Text('ROL')),
              DataColumn(label: Text('SIPARIS'), numeric: true),
              DataColumn(label: Text('HARCAMA'), numeric: true),
              DataColumn(label: Text('SON GIRIS')),
              DataColumn(label: Text('DURUM')),
              DataColumn(label: Text('ISLEM')),
            ],
            rows: users.map((user) => _buildRow(context, ref, user)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, WidgetRef ref, AdminUserModel user) {
    return DataRow(
      onSelectChanged: (_) => context.safePush(
        AppRoutes.adminUserDetail.replaceFirst(':id', user.id),
      ),
      cells: [
        // Avatar + isim
        DataCell(_UserAvatarCell(user: user)),
        // Telefon
        DataCell(Text(user.phone)),
        // Rol chip
        DataCell(_RoleChip(role: user.role)),
        // Siparis
        DataCell(Text('${user.totalOrders}')),
        // Harcama
        DataCell(Text(
          NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0)
              .format(user.totalSpent),
        )),
        // Son giris
        DataCell(_LastLoginCell(lastLoginAt: user.lastLoginAt)),
        // Durum
        DataCell(_StatusChip(isBlocked: user.isBlocked)),
        // Islemler
        DataCell(_ActionButtons(user: user, ref: ref)),
      ],
    );
  }
}

class _UserAvatarCell extends StatelessWidget {
  final AdminUserModel user;
  const _UserAvatarCell({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: user.role.roleColor.withValues(alpha: 0.15),
          child: Text(
            user.initials,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: user.role.roleColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (user.email != null)
              Text(
                user.email!,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final UserRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: role.roleColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: role.roleColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        role.displayName,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: role.roleColor,
        ),
      ),
    );
  }
}

class _LastLoginCell extends StatelessWidget {
  final DateTime? lastLoginAt;
  const _LastLoginCell({this.lastLoginAt});

  @override
  Widget build(BuildContext context) {
    if (lastLoginAt == null) {
      return const Text(
        'Hic giris yok',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textHint,
        ),
      );
    }
    final diff = DateTime.now().difference(lastLoginAt!);
    String label;
    if (diff.inMinutes < 60) {
      label = '${diff.inMinutes} dk once';
    } else if (diff.inHours < 24) {
      label = '${diff.inHours} saat once';
    } else {
      label = '${diff.inDays} gun once';
    }
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isBlocked;
  const _StatusChip({required this.isBlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isBlocked
            ? AppColors.error.withValues(alpha: 0.10)
            : AppColors.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isBlocked ? 'Engellenmis' : 'Aktif',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isBlocked ? AppColors.error : AppColors.success,
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AdminUserModel user;
  final WidgetRef ref;

  const _ActionButtons({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 18),
          color: AppColors.secondary,
          tooltip: 'Goruntule',
          onPressed: () => context.safePush(
            AppRoutes.adminUserDetail.replaceFirst(':id', user.id),
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          icon: Icon(
            user.isBlocked
                ? Icons.lock_open_outlined
                : Icons.block_outlined,
            size: 18,
          ),
          color: user.isBlocked ? AppColors.success : AppColors.error,
          tooltip: user.isBlocked ? 'Engeli Kaldir' : 'Engelle',
          onPressed: () =>
              _confirmToggleBlock(context, ref, user),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Future<void> _confirmToggleBlock(
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
          ),
        ),
        content: Text(
          user.isBlocked
              ? '${user.name} adli kullanıcının engelini kaldırmak istediğinizden emin misiniz?'
              : '${user.name} adli kullanıcıyı engellemek istediğinizden emin misiniz? Kullanici giriş yapamayacak.',
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

// ---------------------------------------------------------------------------
// Mobil liste (kart bazli)
// ---------------------------------------------------------------------------

class _UsersMobileList extends ConsumerWidget {
  const _UsersMobileList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(pagedUsersProvider);
    if (users.isEmpty) return const _EmptyState();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _UserMobileCard(user: users[i]),
    );
  }
}

class _UserMobileCard extends ConsumerWidget {
  final AdminUserModel user;
  const _UserMobileCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () => context.safePush(
        AppRoutes.adminUserDetail.replaceFirst(':id', user.id),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: user.role.roleColor.withValues(alpha: 0.15),
              child: Text(
                user.initials,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: user.role.roleColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    user.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _RoleChip(role: user.role),
                      const SizedBox(width: 6),
                      _StatusChip(isBlocked: user.isBlocked),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user.totalOrders} siparis',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: 20,
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
// Sayfalama
// ---------------------------------------------------------------------------

class _PaginationRow extends ConsumerWidget {
  const _PaginationRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(userPageProvider);
    final totalPages = ref.watch(totalUserPagesProvider);
    final filtered = ref.watch(filteredUsersProvider);

    final startItem = page * kUsersPageSize + 1;
    final endItem = ((page + 1) * kUsersPageSize).clamp(0, filtered.length);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${filtered.isEmpty ? 0 : startItem}–$endItem / ${filtered.length} kullanici',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: page > 0
                  ? () => ref.read(userPageProvider.notifier).set(page - 1)
                  : null,
              tooltip: 'Onceki',
              color: page > 0 ? AppColors.secondary : AppColors.textHint,
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
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: page < totalPages - 1
                  ? () => ref.read(userPageProvider.notifier).set(page + 1)
                  : null,
              tooltip: 'Sonraki',
              color: page < totalPages - 1
                  ? AppColors.secondary
                  : AppColors.textHint,
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
            Icon(Icons.people_outline,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'Kullanici bulunamadı',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Arama kriterlerini değiştirmeyi deneyin',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textHint,
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

class _UsersShimmer extends StatelessWidget {
  const _UsersShimmer();

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
              6,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _ShimmerBox(width: double.infinity, height: 60),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ShimmerBox(width: double.infinity, height: 48),
          const SizedBox(height: 16),
          _ShimmerBox(width: double.infinity, height: 400),
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
      builder: (context, _) {
        return Container(
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
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Hata durumu
// ---------------------------------------------------------------------------

class _UsersError extends StatelessWidget {
  final Object error;
  const _UsersError({required this.error});

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
              'Kullanicilar yüklenemedi',
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
          ],
        ),
      ),
    );
  }
}
