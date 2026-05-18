import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    // Önceki oturumun hata/step state'ini temizle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Telefon numarası validasyonu: 5 ile başlayan 10 hane
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
    await ref.read(authNotifierProvider.notifier).sendPhoneCode(phone);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontFamily: 'Poppins',
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
    // State listener — navigasyon ve hata yönetimi
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.step == AuthStep.codeSent) {
        final phone = '+90${_controller.text.trim()}';
        context.push(AppRoutes.otp, extra: phone);
      }
      if (next.error != null && next.error != previous?.error) {
        _showErrorSnackBar(next.error!);
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.step == AuthStep.sendingCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 64),
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
                const SizedBox(height: 12),
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
// Logo bölümü
// ---------------------------------------------------------------------------
class _LogoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.water_drop_rounded,
          size: 52,
          color: AppColors.primary,
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Hos Geldiniz',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Telefon numaranizi girin',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
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
        Text(
          'Telefon Numarasi',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: '5XX XXX XX XX',
            prefixText: '+90 ',
            prefixStyle: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            errorText: validationError,
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
// Devam Et butonu
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
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
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
          : const Text(
              'Devam Et',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
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
    return OutlinedButton(
      onPressed: () {
        // Sepet ekranından push ile geldiyse geri dön, yoksa home'a git
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: const Text(
        'Misafir Olarak Devam',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
