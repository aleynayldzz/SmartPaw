import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/password_validation.dart';
import '../utils/text_input_config.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  String? _submitWarning;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_handleFieldChange);
    _confirmPasswordController.addListener(_handleFieldChange);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _allFieldsFilled {
    return _passwordController.text.isNotEmpty &&
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
      'Invalid or expired reset code.' => 'Kod geçersiz veya süresi dolmuş.',
      'Password must be at least 8 characters long and include uppercase, lowercase, and a special character.' =>
        PasswordValidation.formatHint,
      'Confirm Password must match Password.' => 'Şifreler eşleşmiyor.',
      _ => message.trim(),
    };
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_allFieldsFilled || _isSubmitting) return;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!PasswordValidation.isValid(password)) {
      setState(() {
        _submitWarning = PasswordValidation.formatHint;
      });
      return;
    }

    if (confirmPassword != password) {
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
      final response = await http.post(
        ApiConfig.resetPasswordUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email.trim(),
          'code': widget.code,
          'password': _passwordController.text,
          'confirmPassword': _confirmPasswordController.text,
        }),
      );

      if (!mounted) return;

      Map<String, dynamic> body = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            body = decoded;
          }
        } on FormatException {
          setState(() {
            _submitWarning = 'Bir hata oluştu. Lütfen tekrar deneyin.';
          });
          return;
        }
      }

      if (response.statusCode == 200 && body['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifreniz başarıyla güncellendi.')),
        );

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }

      final errors = (body['errors'] as Map?)?.cast<String, dynamic>() ?? {};
      final rawWarning = errors['password']?.toString() ??
          errors['confirmPassword']?.toString() ??
          body['message']?.toString();

      setState(() {
        _submitWarning = _normalizeMessage(rawWarning);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitWarning =
            'Sunucuya bağlanılamadı. Backend\'in çalıştığından emin olun.';
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
                          'Yeni Şifre Belirle',
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
                          'Yeni şifrenizi girin ve tekrar onaylayın.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFF6B6B6B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 22),
                        UserTextField(
                          controller: _passwordController,
                          kind: UserTextInputKind.password,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            hintText: 'Yeni Şifre',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: const Color(0xFF6B6B6B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        UserTextField(
                          controller: _confirmPasswordController,
                          kind: UserTextInputKind.password,
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
          ],
        ),
      ),
    );
  }
}
