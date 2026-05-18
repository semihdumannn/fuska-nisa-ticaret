import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nisa_ticaret/core/constants/app_constants.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      icon: Icons.water_drop,
      title: "Nisa Ticaret'e Hoş Geldiniz",
      subtitle: 'Su ve meşrubatı kapınıza kadar getiriyoruz.',
    ),
    _OnboardingSlide(
      icon: Icons.shopping_cart_checkout,
      title: 'Kolayca Sipariş Verin',
      subtitle: 'Ürünlere göz atın, sepete ekleyin, anında teslimat alın.',
    ),
    _OnboardingSlide(
      icon: Icons.check_circle_outline,
      title: 'Hemen Başlayın',
      subtitle: 'Telefon numaranızla saniyeler içinde üye olun.',
    ),
  ];

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
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
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF2F8),
      body: SafeArea(
        child: Stack(
          children: [
            // PageView — slides
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) =>
                        _SlideContent(slide: _slides[index]),
                  ),
                ),

                // Dot indicator
                _DotIndicator(
                  count: _slides.length,
                  currentIndex: _currentPage,
                ),
                const SizedBox(height: 32),

                // Ana buton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isLastPage
                        ? ElevatedButton(
                            key: const ValueKey('login_btn'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () =>
                                _markSeenAndNavigate(goToAuth: true),
                            child: const Text(
                              'Giriş Yap / Kaydol',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            key: const ValueKey('next_btn'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _nextPage,
                            child: const Text(
                              'Devam',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Alt link: son sayfada "Giriş Yap" yerine yoktur, diğer sayfalarda "Atla"
                SizedBox(
                  height: 40,
                  child: _isLastPage
                      ? const SizedBox.shrink()
                      : TextButton(
                          onPressed: () =>
                              _markSeenAndNavigate(goToAuth: false),
                          child: const Text(
                            'Atla',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),

            // "Atla" — sağ üst köşe (son sayfa hariç)
            if (!_isLastPage)
              Positioned(
                top: 8,
                right: 8,
                child: TextButton(
                  onPressed: () => _markSeenAndNavigate(goToAuth: false),
                  child: const Text(
                    'Atla',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Veri sınıfı
// ---------------------------------------------------------------------------

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

// ---------------------------------------------------------------------------
// Tek bir slide içeriği
// ---------------------------------------------------------------------------

class _SlideContent extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideContent({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              slide.icon,
              size: 60,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nokta indikatörü (animated)
// ---------------------------------------------------------------------------

class _DotIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;

  const _DotIndicator({required this.count, required this.currentIndex});

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
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.primary : AppColors.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
