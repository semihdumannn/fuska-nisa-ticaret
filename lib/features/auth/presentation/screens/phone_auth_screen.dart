import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isPhoneValid {
    final text = _controller.text.trim();
    return RegExp(r'^5\d{9}$').hasMatch(text);
  }

  Future<void> _onSubmit() async {
    setState(() => _validationError = null);

    if (!_isPhoneValid) {
      setState(() => _validationError = '5 ile başlayan 10 haneli numara girin.');
      return;
    }

    final phone = '+90${_controller.text.trim()}';
    await ref.read(authNotifierProvider.notifier).authenticate(phone);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.textWhite,
            fontSize: 14,
          ),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.step == AuthStep.creatingUser) {
        context.push(AppRoutes.register);
      }
      if (next.step == AuthStep.done) {
        final postLoginRoute = ref.read(postLoginRouteProvider);
        if (postLoginRoute != null) {
          ref.read(postLoginRouteProvider.notifier).set(null);
          context.go(postLoginRoute);
        } else if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      }
      if (next.error != null && next.error != previous?.error) {
        _showErrorSnackBar(next.error!);
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.step == AuthStep.authenticating;
    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: canPop ? 16 : 48),
                if (canPop) _BackButton(),
                SizedBox(height: canPop ? 16 : 0),
                _LogoSection(),
                const SizedBox(height: 40),
                _TitleSection(),
                const SizedBox(height: 32),
                _PhoneInputField(
                  controller: _controller,
                  validationError: _validationError,
                  onChanged: (_) => setState(() => _validationError = null),
                ),
                const SizedBox(height: 24),
                _SubmitButton(
                  isLoading: isLoading,
                  isEnabled: _isPhoneValid && !isLoading,
                  onPressed: _onSubmit,
                ),
                const SizedBox(height: 16),
                _GuestButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Geri butonu
// ---------------------------------------------------------------------------
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.navBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo bölümü
// ---------------------------------------------------------------------------
class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 180,
        height: 120,
        child: Image.asset(
          'assets/images/app_icon.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Başlık bölümü
// ---------------------------------------------------------------------------
class _TitleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tekrar hoş geldin 👋',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Devam etmek için telefon numaranı gir',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF7E879A),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Telefon input alanı
// ---------------------------------------------------------------------------
class _PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? validationError;
  final ValueChanged<String> onChanged;

  const _PhoneInputField({
    required this.controller,
    required this.validationError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            fillColor: AppColors.inputBg,
            filled: true,
            hintText: '5XX XXX XX XX',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppColors.textHint,
              fontSize: 15,
            ),
            errorText: validationError,
            errorStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
            prefixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 16),
                Text(
                  '🇹🇷',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  '+90',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 22,
                  color: AppColors.border,
                ),
                const SizedBox(width: 10),
              ],
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Devam Et butonu — gradient + shadow
// ---------------------------------------------------------------------------
class _SubmitButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(46),
          boxShadow: isEnabled ? const [AppShadows.primary] : null,
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(46),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.textWhite,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  'Devam Et',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textWhite,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Misafir olarak devam butonu
// ---------------------------------------------------------------------------
class _GuestButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        minimumSize: const Size(double.infinity, 48),
      ),
      child: Text(
        'Misafir olarak devam et',
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
