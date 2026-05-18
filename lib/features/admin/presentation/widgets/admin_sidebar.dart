import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_provider.dart';

// Aktif sidebar item state'i
class _ActiveSidebarNotifier extends Notifier<String> {
  @override
  String build() => 'dashboard';

  void setActive(String id) => state = id;
}

final activeSidebarItemProvider =
    NotifierProvider<_ActiveSidebarNotifier, String>(_ActiveSidebarNotifier.new);

class AdminSidebarItem {
  final String id;
  final String label;
  final IconData icon;
  final IconData iconFilled;
  final String route;

  const AdminSidebarItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.iconFilled,
    required this.route,
  });
}

const List<AdminSidebarItem> _kSidebarItems = [
  AdminSidebarItem(
    id: 'dashboard',
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    iconFilled: Icons.dashboard,
    route: AppRoutes.adminHome,
  ),
  AdminSidebarItem(
    id: 'products',
    label: 'Urunler',
    icon: Icons.inventory_2_outlined,
    iconFilled: Icons.inventory_2,
    route: AppRoutes.productManagement,
  ),
  AdminSidebarItem(
    id: 'categories',
    label: 'Kategoriler',
    icon: Icons.category_outlined,
    iconFilled: Icons.category,
    route: AppRoutes.categoryManagement,
  ),
  AdminSidebarItem(
    id: 'orders',
    label: 'Siparisler',
    icon: Icons.receipt_long_outlined,
    iconFilled: Icons.receipt_long,
    route: AppRoutes.orderManagement,
  ),
  AdminSidebarItem(
    id: 'customers',
    label: 'Musteriler',
    icon: Icons.people_outline,
    iconFilled: Icons.people,
    route: AppRoutes.adminUsers,
  ),
  AdminSidebarItem(
    id: 'reports',
    label: 'Raporlar',
    icon: Icons.bar_chart_outlined,
    iconFilled: Icons.bar_chart,
    route: AppRoutes.adminReports,
  ),
  AdminSidebarItem(
    id: 'settings',
    label: 'Ayarlar',
    icon: Icons.settings_outlined,
    iconFilled: Icons.settings,
    route: AppRoutes.adminDashboard, // TODO: ayarlar route
  ),
];

class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = ref.watch(activeSidebarItemProvider);

    return Container(
      width: 240,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _SidebarHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              children: _kSidebarItems.map((item) {
                return _SidebarNavItem(
                  item: item,
                  isActive: activeId == item.id,
                  onTap: () {
                    ref.read(activeSidebarItemProvider.notifier).setActive(item.id);
                    context.go(item.route);
                  },
                );
              }).toList(),
            ),
          ),
          _SidebarFooter(),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'NT',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Yonetim Paneli',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 11,
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

class _SidebarNavItem extends StatelessWidget {
  final AdminSidebarItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? item.iconFilled : item.icon,
                  color: isActive
                      ? AppColors.primary
                      : const Color(0xAAFFFFFF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.textWhite
                        : const Color(0xAAFFFFFF),
                    fontSize: 14,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Yonetici',
                  style: TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: Color(0x99FFFFFF),
              size: 18,
            ),
            onPressed: () =>
                ref.read(authNotifierProvider.notifier).signOut(),
            tooltip: 'Cikis Yap',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// Drawer sarmalayici (mobil/tablet icin)
class AdminDrawerWrapper extends ConsumerWidget {
  const AdminDrawerWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Drawer(
      width: 240,
      child: AdminSidebar(),
    );
  }
}
