import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  String? _nameError;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isNameValid => _nameController.text.trim().length >= 2;

  Future<void> _onSubmit() async {
    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() {
        _nameError = 'En az 2 karakter giriniz.';
        _isSaving = false;
      });
      return;
    }

    final phone = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';

    await ref
        .read(authNotifierProvider.notifier)
        .createUserProfile(name, phone);

    if (mounted) setState(() => _isSaving = false);
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
    // State listener
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.step == AuthStep.done) {
        context.go(AppRoutes.home);
      }
      if (next.error != null && next.error != previous?.error) {
        _showErrorSnackBar(next.error!);
      }
    });

    ref.watch(authNotifierProvider);
    final isLoading = _isSaving;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.secondary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Hesabi Tamamla',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              _ProfileIcon(),
              const SizedBox(height: 32),
              _TitleSection(),
              const SizedBox(height: 32),
              _NameInputField(
                controller: _nameController,
                nameError: _nameError,
                onChanged: (_) => setState(() {
                  _nameError = null;
                }),
              ),
              const SizedBox(height: 24),
              _SubmitButton(
                isLoading: isLoading,
                isEnabled: _isNameValid && !isLoading,
                onPressed: _onSubmit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profil ikonu
// ---------------------------------------------------------------------------
class _ProfileIcon extends StatelessWidget {
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
          Icons.person_rounded,
          size: 52,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Baslik bölümü
// ---------------------------------------------------------------------------
class _TitleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Merhaba!',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Sizi tanimak istiyoruz',
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
// Ad Soyad input alani
// ---------------------------------------------------------------------------
class _NameInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? nameError;
  final ValueChanged<String> onChanged;

  const _NameInputField({
    required this.controller,
    required this.nameError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ad Soyad',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Ad Soyad',
            counterText: '',
            errorText: nameError,
            prefixIcon: const Icon(
              Icons.person_outline_rounded,
              color: AppColors.textSecondary,
              size: 20,
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
