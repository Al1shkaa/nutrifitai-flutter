import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_button.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  const VerifyScreen({super.key, required this.email});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _authService = AuthService();
  final _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 60;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCooldown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 0) {
        t.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _onCompleted(String code) async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final ok = await _authService.verify(widget.email, code);

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email подтверждён"),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (route) => false);
    } else {
      setState(() => _error = "Неверный или истёкший код");
      _codeController.clear();
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);

    final ok = await _authService.resendCode(widget.email);

    if (!mounted) return;
    setState(() => _isResending = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Код отправлен повторно")),
      );
      _startResendTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Не удалось отправить код"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Подтверждение email",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              const Text(
                "Введите код подтверждения",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Мы отправили 6-значный код на",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _codeController,
                keyboardType: TextInputType.number,
                autoFocus: true,
                onCompleted: _onCompleted,
                onChanged: (val) {
                  if (_error != null) setState(() => _error = null);
                },
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  activeFillColor: AppColors.card,
                  selectedFillColor: AppColors.card,
                  inactiveFillColor: AppColors.card,
                ),
                enableActiveFill: true,
                cursorColor: AppColors.primary,
                animationType: AnimationType.fade,
                animationDuration: const Duration(milliseconds: 200),
                textStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                backgroundColor: Colors.transparent,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              if (_isVerifying)
                const CircularProgressIndicator(color: AppColors.primary)
              else
                AppButton(
                  title: "Подтвердить",
                  onPressed: () {
                    if (_codeController.text.length == 6) {
                      _onCompleted(_codeController.text);
                    }
                  },
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Не получили код? ",
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  TextButton(
                    onPressed: _resendCooldown > 0 || _isResending ? null : _resendCode,
                    child: Text(
                      _resendCooldown > 0
                          ? "Повторно через 0:${_resendCooldown.toString().padLeft(2, '0')}"
                          : "Отправить заново",
                      style: TextStyle(
                        color: _resendCooldown > 0
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
