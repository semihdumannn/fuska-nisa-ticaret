import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';

/// Admin giris noktasi. /admin route'u buraya gelir ve
/// tam admin dashboard'a (/admin/dashboard) yonlendirir.
/// Eğer doğrudan bir geçiş ekranı istenirse bu widget'a içerik eklenebilir.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // /admin/dashboard (AdminHomeScreen) tam dashboard'u gosterir.
    // Bu ekran bir giris kapi gorevindedir; hemen yonlendirir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(AppRoutes.adminHome);
    });

    // Redirect tamamlanana kadar minimal yukleme ekrani goster.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.textWhite,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
