import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../utils/password_validation.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  String? _submitWarning;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _currentPasswordController,
      _newPasswordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_handleFieldChange);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _allFieldsFilled {
    return _currentPasswordController.text.isNotEmpty &&
        _newPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty;
  }

  void _handleFieldChange() {
    if (!mounted) return;
    setState(() {
      _submitWarning = null;
    });
  }

  String _normalizeMessage(String? message) {
    if (message == null || message.isEmpty) {
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
    return switch (message.trim()) {
      'Current password is incorrect.' => 'Mevcut şifre hatalı.',
      'Password must be at least 8 characters long and include uppercase, lowercase, and a special character.' =>
        PasswordValidation.formatHint,
      'Confirm Password must match Password.' => 'Şifreler eşleşmiyor.',
      'Unauthorized. Sign in with a valid access token.' =>
        'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.',
      _ => message.trim(),
    };
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_allFieldsFilled || _isSubmitting) return;

    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!PasswordValidation.isValid(newPassword)) {
      setState(() {
        _submitWarning = PasswordValidation.formatHint;
      });
      return;
    }

    if (confirmPassword != newPassword) {
      setState(() {
        _submitWarning = 'Şifreler eşleşmiyor.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitWarning = null;
    });

    try {
      final result = await AuthApiService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (!mounted) return;

      if (result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifreniz başarıyla güncellendi.')),
        );
        Navigator.of(context).pop();
        return;
      }

      final rawWarning = result.fieldErrors['newPassword'] ??
          result.fieldErrors['confirmPassword'] ??
          result.fieldErrors['currentPassword'] ??
          result.message;

      setState(() {
        _submitWarning = _normalizeMessage(rawWarning);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  InputDecoration _decoration({required String hintText, Widget? suffixIcon}) {
    const borderColor = Color(0xFFE9A5A1);

    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF6B6B6B),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor, width: 1.4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor, width: 1.4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderColor, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFF7F2);
    const titleColor = Color(0xFF1F1F1F);
    const buttonTop = Color(0xFFE9A5A1);
    const buttonBottom = Color(0xFFD98F8B);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Şifreyi Değiştir',
                          style: TextStyle(
                            fontSize: 34,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Mevcut şifrenizi girin ve yeni şifrenizi belirleyin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFF6B6B6B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            hintText: 'Mevcut Şifre',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(
                                  () => _obscureCurrentPassword =
                                      !_obscureCurrentPassword,
                                );
                              },
                              icon: Icon(
                                _obscureCurrentPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF6B6B6B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            hintText: 'Yeni Şifre',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(
                                  () =>
                                      _obscureNewPassword = !_obscureNewPassword,
                                );
                              },
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF6B6B6B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (_allFieldsFilled && !_isSubmitting) {
                              _submit();
                            }
                          },
                          decoration: _decoration(
                            hintText: 'Yeni Şifre Tekrar',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(
                                  () => _obscureConfirmPassword =
                                      !_obscureConfirmPassword,
                                );
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF6B6B6B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        PasswordValidation.warningAboveButton(_submitWarning),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [buttonTop, buttonBottom],
                              ),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                disabledBackgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white70,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                elevation: 0,
                              ),
                              onPressed: (_allFieldsFilled && !_isSubmitting)
                                  ? _submit
                                  : null,
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Şifreyi Güncelle',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                tooltip: 'Geri',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: titleColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
