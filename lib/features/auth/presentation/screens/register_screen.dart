import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';
import 'package:nisa_ticaret/features/auth/presentation/providers/auth_datasource_providers.dart';

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

    final local = ref.read(authLocalDatasourceProvider);
    final phone = await local.getSavedPhone() ?? '';

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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _BackButton(),
              const SizedBox(height: 32),
              _ProfileIconSection(),
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
// Profil ikonu bölümü
// ---------------------------------------------------------------------------
class _ProfileIconSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: const [AppShadows.primary],
        ),
        child: const Icon(
          Icons.person_rounded,
          size: 48,
          color: AppColors.textWhite,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Neredeyse tamam! 🎉',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Seni tanımak için adını öğrenebilir miyiz?',
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
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: 50,
          textCapitalization: TextCapitalization.words,
          onChanged: onChanged,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            fillColor: AppColors.inputBg,
            filled: true,
            hintText: 'Adınızı girin',
            hintStyle: GoogleFonts.plusJakartaSans(
              color: AppColors.textHint,
              fontSize: 15,
            ),
            counterText: '',
            errorText: nameError,
            errorStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
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
// Devam Et butonu — solid primary
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
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          disabledBackgroundColor: AppColors.primary,
          elevation: 0,
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
                'Hesabı Tamamla',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textWhite,
                ),
              ),
      ),
    );
  }
}
