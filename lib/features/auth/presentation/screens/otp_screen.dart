import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nisa_ticaret/core/router/app_router.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';
import 'package:nisa_ticaret/features/auth/presentation/bloc/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const int _otpLength = 6;
  static const int _timerDuration = 28;

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  late Timer _timer;
  int _seconds = _timerDuration;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Timer yönetimi
  // -------------------------------------------------------------------------
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_seconds == 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _resetTimer() {
    _timer.cancel();
    setState(() {
      _seconds = _timerDuration;
      _canResend = false;
    });
    _startTimer();
  }

  String get _timerText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // -------------------------------------------------------------------------
  // OTP kutu input yönetimi
  // -------------------------------------------------------------------------
  void _onChanged(String value, int index) {
    if (value.length > 1) {
      // Paste durumu — birden fazla karakter yapıştırıldı
      _handlePaste(value, index);
      return;
    }

    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    _checkAutoSubmit();
  }

  void _handlePaste(String value, int startIndex) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < digits.length && startIndex + i < _otpLength; i++) {
      _controllers[startIndex + i].text = digits[i];
    }
    final nextIndex = (startIndex + digits.length).clamp(0, _otpLength - 1);
    _focusNodes[nextIndex].requestFocus();
    _checkAutoSubmit();
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
    }
  }

  void _checkAutoSubmit() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == _otpLength) {
      _verify(code);
    }
  }

  // -------------------------------------------------------------------------
  // OTP doğrulama
  // -------------------------------------------------------------------------
  Future<void> _verify(String code) async {
    await ref.read(authNotifierProvider.notifier).verifyOTP(code);
  }

  // -------------------------------------------------------------------------
  // Kodu temizle
  // -------------------------------------------------------------------------
  void _clearOtp() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  // -------------------------------------------------------------------------
  // Hata SnackBar
  // -------------------------------------------------------------------------
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

  // -------------------------------------------------------------------------
  // Yeniden gönder
  // -------------------------------------------------------------------------
  Future<void> _resend() async {
    if (!_canResend) return;
    _clearOtp();
    _resetTimer();
    await ref
        .read(authNotifierProvider.notifier)
        .sendPhoneCode(widget.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    // State listener
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.step == AuthStep.done) {
        context.go(AppRoutes.home);
      }
      if (next.step == AuthStep.creatingUser) {
        context.push(AppRoutes.register);
      }
      if (next.error != null && next.error != previous?.error) {
        _showErrorSnackBar(next.error!);
        _clearOtp();
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.step == AuthStep.verifyingCode ||
        authState.step == AuthStep.sendingCode;

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
          'Dogrulama',
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
              const SizedBox(height: 32),
              _PhoneHeader(phoneNumber: widget.phoneNumber),
              const SizedBox(height: 40),
              _OtpBoxRow(
                controllers: _controllers,
                focusNodes: _focusNodes,
                onChanged: _onChanged,
                onKeyEvent: _onKeyEvent,
                isLoading: isLoading,
              ),
              const SizedBox(height: 32),
              _TimerSection(
                timerText: _timerText,
                canResend: _canResend,
                isLoading: isLoading,
                onResend: _resend,
              ),
              const SizedBox(height: 32),
              _VerifyButton(
                isLoading: isLoading,
                onPressed: () {
                  final code = _controllers.map((c) => c.text).join();
                  if (code.length == _otpLength) _verify(code);
                },
                isEnabled: !isLoading,
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
// Telefon numarası başlık bölümü
// ---------------------------------------------------------------------------
class _PhoneHeader extends StatelessWidget {
  final String phoneNumber;

  const _PhoneHeader({required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.sms_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Koda gonderildi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            children: [
              const TextSpan(text: 'SMS dogrulama kodu\n'),
              TextSpan(
                text: phoneNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(text: '\nnumarasina gonderildi.'),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 6 OTP kutusu satiri
// ---------------------------------------------------------------------------
class _OtpBoxRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String, int) onChanged;
  final void Function(KeyEvent, int) onKeyEvent;
  final bool isLoading;

  const _OtpBoxRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKeyEvent,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        controllers.length,
        (index) => _OtpBox(
          controller: controllers[index],
          focusNode: focusNodes[index],
          onChanged: (v) => onChanged(v, index),
          onKeyEvent: (e) => onKeyEvent(e, index),
          isLoading: isLoading,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tek OTP kutusu
// ---------------------------------------------------------------------------
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;
  final bool isLoading;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
    required this.isLoading,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isFilled = widget.controller.text.isNotEmpty;
    final isFocused = widget.focusNode.hasFocus;

    Color borderColor;
    double borderWidth;
    if (isFilled || isFocused) {
      borderColor = AppColors.primary;
      borderWidth = 2;
    } else {
      borderColor = AppColors.border;
      borderWidth = 1.5;
    }

    return SizedBox(
      width: 48,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: widget.onKeyEvent,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: !widget.isLoading,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2, // 2 -> paste sırasında _handlePaste devreye girer
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: borderWidth),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.border, width: 1.5),
            ),
            filled: true,
            fillColor: isFilled
                ? AppColors.primary.withValues(alpha: 0.05)
                : AppColors.surface,
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Geri sayim ve yeniden gonder bölümü
// ---------------------------------------------------------------------------
class _TimerSection extends StatelessWidget {
  final String timerText;
  final bool canResend;
  final bool isLoading;
  final VoidCallback onResend;

  const _TimerSection({
    required this.timerText,
    required this.canResend,
    required this.isLoading,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!canResend) ...[
          Text(
            'Kod bekleniyor...',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            timerText,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
        TextButton(
          onPressed: canResend && !isLoading ? onResend : null,
          child: Text(
            'Kodu Tekrar Gonder',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: canResend ? AppColors.primary : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dogrula butonu
// ---------------------------------------------------------------------------
class _VerifyButton extends StatelessWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _VerifyButton({
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
              'Dogrula',
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
