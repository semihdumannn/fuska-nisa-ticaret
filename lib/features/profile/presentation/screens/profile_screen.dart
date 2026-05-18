import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/services/whatsapp_service.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/data/models/user_model.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';

// ---------------------------------------------------------------------------
// _packageInfoProvider — uygulama versiyonunu bir kez cekip cache'ler
// ---------------------------------------------------------------------------
final _packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

// ---------------------------------------------------------------------------
// _MenuItem — menü kalemini tutan basit veri sinifi
// ---------------------------------------------------------------------------
class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

// ---------------------------------------------------------------------------
// ProfileScreen
// ---------------------------------------------------------------------------
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Bir hata olustu.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      data: (user) => _ProfileContent(user: user),
    );
  }
}

// ---------------------------------------------------------------------------
// _ProfileContent — kullanici null olmadigi garantiyle render edilir
// ---------------------------------------------------------------------------
class _ProfileContent extends ConsumerWidget {
  final UserModel? user;
  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Giriş yapılmamış → login ekranı göster
    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: Text('Profilim',
              style: Theme.of(context).textTheme.headlineSmall),
          scrolledUnderElevation: 1,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Hesabınıza giriş yapın',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Profilinizi görüntülemek ve siparişlerinizi takip etmek için giriş yapın.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.push(AppRoutes.phoneAuth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Giriş Yap',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final packageInfoAsync = ref.watch(_packageInfoProvider);
    final String appVersion = packageInfoAsync.when(
      data: (info) => '${info.version} (${info.buildNumber})',
      loading: () => '...',
      error: (_, __) => '-',
    );
    final menuItems = _buildMenuItems(context, user!, appVersion);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('Profilim',
            style: Theme.of(context).textTheme.headlineSmall),
        scrolledUnderElevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _HeaderCard(user: user),
          const SizedBox(height: 20),
          if (menuItems.isNotEmpty) ...[
            _MenuSection(items: menuItems),
            const SizedBox(height: 24),
          ],
          _SignOutButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<_MenuItem> _buildMenuItems(
    BuildContext context,
    UserModel user,
    String appVersion,
  ) {
    switch (user.role) {
      case UserRole.customer:
        return _customerMenuItems(context, appVersion);
      case UserRole.admin:
        return _adminMenuItems(context, appVersion);
      case UserRole.fieldAgent:
        return _fieldAgentMenuItems(context, appVersion);
      case UserRole.delivery:
        return _deliveryMenuItems(context, appVersion);
    }
  }

  List<_MenuItem> _customerMenuItems(
      BuildContext context, String appVersion) {
    return [
      _MenuItem(
        icon: Icons.location_on_outlined,
        title: 'Adreslerim',
        onTap: () => context.push(AppRoutes.addressSelection),
      ),
      _MenuItem(
        icon: Icons.shopping_bag_outlined,
        title: 'Siparişlerim',
        onTap: () => context.push(AppRoutes.orders),
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Bildirimler',
        onTap: () => context.push(AppRoutes.notifications),
      ),
      _MenuItem(
        icon: Icons.support_agent_outlined,
        title: 'WhatsApp Destek',
        onTap: () => whatsappService.contactSupport(
          message: 'Merhaba! Uygulama hakkında yardım almak istiyorum.',
        ),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: 'Uygulama Hakkında (v$appVersion)',
        onTap: () {},
      ),
    ];
  }

  List<_MenuItem> _adminMenuItems(
      BuildContext context, String appVersion) {
    return [
      _MenuItem(
        icon: Icons.dashboard_outlined,
        title: 'Yönetim Paneli',
        onTap: () => context.go(AppRoutes.adminHome),
      ),
      _MenuItem(
        icon: Icons.inventory_2_outlined,
        title: 'Ürün Yönetimi',
        onTap: () => context.push(AppRoutes.productManagement),
      ),
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Sipariş Yönetimi',
        onTap: () => context.push(AppRoutes.orderManagement),
      ),
      _MenuItem(
        icon: Icons.group_outlined,
        title: 'Kullanıcılar',
        onTap: () => context.push(AppRoutes.adminUsers),
      ),
      _MenuItem(
        icon: Icons.bar_chart_outlined,
        title: 'Raporlar',
        onTap: () => context.push(AppRoutes.adminReports),
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Bildirimler',
        onTap: () => context.push(AppRoutes.notifications),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: 'Uygulama Hakkında (v$appVersion)',
        onTap: () {},
      ),
    ];
  }

  List<_MenuItem> _fieldAgentMenuItems(
      BuildContext context, String appVersion) {
    return [
      _MenuItem(
        icon: Icons.home_outlined,
        title: 'Saha Terminali',
        onTap: () => context.go(AppRoutes.fieldAgentHome),
      ),
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Siparişlerim',
        onTap: () => context.push(AppRoutes.orders),
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Bildirimler',
        onTap: () => context.push(AppRoutes.notifications),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: 'Uygulama Hakkında (v$appVersion)',
        onTap: () {},
      ),
    ];
  }

  List<_MenuItem> _deliveryMenuItems(
      BuildContext context, String appVersion) {
    return [
      _MenuItem(
        icon: Icons.local_shipping_outlined,
        title: 'Teslimat Paneli',
        onTap: () => context.go(AppRoutes.deliveryHome),
      ),
      _MenuItem(
        icon: Icons.receipt_long_outlined,
        title: 'Siparişlerim',
        onTap: () => context.push(AppRoutes.orders),
      ),
      _MenuItem(
        icon: Icons.notifications_outlined,
        title: 'Bildirimler',
        onTap: () => context.push(AppRoutes.notifications),
      ),
      _MenuItem(
        icon: Icons.info_outline,
        title: 'Uygulama Hakkında (v$appVersion)',
        onTap: () {},
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// _HeaderCard — kullanici profil karti
// ---------------------------------------------------------------------------
class _HeaderCard extends StatelessWidget {
  final UserModel? user;
  const _HeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final String initials = _initials(user?.name);
    final String displayName =
        (user?.name.isNotEmpty == true) ? user!.name : 'Kullanici';
    final String phone = user?.phone ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          _Avatar(initials: initials),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                if (user != null) _RoleBadge(role: user!.role),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// _Avatar
// ---------------------------------------------------------------------------
class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: initials == '?'
          ? const Icon(Icons.person, color: AppColors.textWhite, size: 32)
          : Text(
              initials,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textWhite,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RoleBadge — rol bazli renk ve etiket
// ---------------------------------------------------------------------------
class _RoleBadge extends StatelessWidget {
  final UserRole role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final Color bg = _badgeColor.withValues(alpha: 0.15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _badgeLabel,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _badgeColor,
        ),
      ),
    );
  }

  String get _badgeLabel {
    switch (role) {
      case UserRole.customer:
        return 'Müşteri';
      case UserRole.admin:
        return 'Yönetici';
      case UserRole.fieldAgent:
        return 'Saha Ekibi';
      case UserRole.delivery:
        return 'Teslimat';
    }
  }

  Color get _badgeColor {
    switch (role) {
      case UserRole.customer:
        return AppColors.accent;
      case UserRole.admin:
        return AppColors.secondary;
      case UserRole.fieldAgent:
        return AppColors.primary;
      case UserRole.delivery:
        return AppColors.success;
    }
  }
}

// ---------------------------------------------------------------------------
// _MenuSection — menü kalemlerinin listesi
// ---------------------------------------------------------------------------
class _MenuSection extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _MenuTile(item: item),
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 52,
                  endIndent: 16,
                  color: AppColors.divider,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MenuTile — tekil menü kalemi
// ---------------------------------------------------------------------------
class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(item.icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SignOutButton — cikis butonu + onay dialog'u
// ---------------------------------------------------------------------------
class _SignOutButton extends ConsumerWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmSignOut(context, ref),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: const Icon(Icons.logout, size: 20),
        label: const Text('Çıkış Yap'),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Çıkış yapmak istediğinizden emin misiniz?',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textWhite,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) context.go(AppRoutes.home);
    }
  }
}
