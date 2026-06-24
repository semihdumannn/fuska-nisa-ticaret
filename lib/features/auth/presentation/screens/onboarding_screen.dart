import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  int _currentPage = 0;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.water_drop_rounded,
      color: AppColors.primary,
      bgColor: Color(0xFFFDE8F4),
      title: 'Fuska Kalitesi\nKapınızda',
      subtitle:
          'Doğal kaynak suyu ve meşrubatlarımızı aynı gün teslimat ile sipariş edin.',
      bullets: ['Aynı gün teslimat', 'Güvenilir kalite', 'Geniş ürün yelpazesi'],
    ),
    _OnboardingSlide(
      icon: Icons.shopping_bag_outlined,
      color: AppColors.secondary,
      bgColor: Color(0xFFE8EDF5),
      title: 'Saniyeler İçinde\nSipariş',
      subtitle:
          'Ürünlere göz atın, sepete ekleyin. Teslimat durumunu anlık takip edin.',
      bullets: ['Kolay sepet yönetimi', 'Anlık sipariş takibi', 'Adrese teslimat'],
    ),
    _OnboardingSlide(
      icon: Icons.phone_iphone_rounded,
      color: AppColors.accent,
      bgColor: Color(0xFFDFF5F5),
      title: 'Üyelik?\n30 Saniye!',
      subtitle:
          'Sadece telefon numaranızla üye olun. Şifre yok, uzun form yok.',
      bullets: ['Sadece telefon numarası', 'Şifre gerekmez', 'Anlık aktivasyon'],
    ),
  ];

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale =
        CurvedAnimation(parent: _iconController, curve: Curves.elasticOut);
    _iconController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _markSeenAndNavigate({required bool goToAuth}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingSeen, true);
    if (!mounted) return;
    if (goToAuth) {
      context.go(AppRoutes.phoneAuth);
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _iconController.reset();
    _iconController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            slide.bgColor,
            slide.bgColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Ust: Atla butonu
            Align(
              alignment: Alignment.topRight,
              child: AnimatedOpacity(
                opacity: _isLastPage ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: TextButton(
                  onPressed: _isLastPage
                      ? null
                      : () => _markSeenAndNavigate(goToAuth: false),
                  child: Text(
                    'Atla',
                    style: GoogleFonts.plusJakartaSans(
                      color: slide.color.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),

            // Slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) => _SlideContent(
                  slide: _slides[index],
                  iconScale: _iconScale,
                  isActive: index == _currentPage,
                ),
              ),
            ),

            // Dot indicator
            _DotIndicator(
              count: _slides.length,
              currentIndex: _currentPage,
              activeColor: slide.color,
            ),
            const SizedBox(height: 28),

            // Ana buton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isLastPage
                    ? _PrimaryButton(
                        key: const ValueKey('login_btn'),
                        label: 'Giriş Yap / Kaydol',
                        onPressed: () => _markSeenAndNavigate(goToAuth: true),
                      )
                    : _PrimaryButton(
                        key: const ValueKey('next_btn'),
                        label: 'Devam Et',
                        trailingIcon: Icons.arrow_forward_rounded,
                        onPressed: _nextPage,
                      ),
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Solid primary butonu
// ---------------------------------------------------------------------------
class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? trailingIcon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    super.key,
    required this.label,
    this.trailingIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(46),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textWhite,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 6),
            Icon(trailingIcon, size: 20, color: AppColors.textWhite),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Veri sınıfı
// ---------------------------------------------------------------------------
class _OnboardingSlide {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;
  final String subtitle;
  final List<String> bullets;

  const _OnboardingSlide({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.bullets,
  });
}

// ---------------------------------------------------------------------------
// Slide içeriği
// ---------------------------------------------------------------------------
class _SlideContent extends StatelessWidget {
  final _OnboardingSlide slide;
  final Animation<double> iconScale;
  final bool isActive;

  const _SlideContent({
    required this.slide,
    required this.iconScale,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustrasyon alani
          ScaleTransition(
            scale: isActive ? iconScale : const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    slide.color.withValues(alpha: 0.18),
                    slide.color.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: slide.color.withValues(alpha: 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slide.color.withValues(alpha: 0.10),
                    ),
                  ),
                  Icon(slide.icon, size: 72, color: slide.color),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),

          // Baslik
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: slide.color == AppColors.primary
                  ? AppColors.secondary
                  : slide.color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),

          // Alt baslik
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 24),

          // Özellik noktalari
          Column(
            children: slide.bullets
                .map(
                  (b) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: slide.color,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          b,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: slide.color == AppColors.primary
                                ? AppColors.secondary
                                : slide.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nokta indikatoru
// ---------------------------------------------------------------------------
class _DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color activeColor;

  const _DotIndicator({
    required this.count,
    required this.currentIndex,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : activeColor.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
