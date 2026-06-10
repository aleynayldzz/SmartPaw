import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/password_validation.dart';
import '../utils/text_input_config.dart';
import 'verification_screen.dart';
import 'welcome_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  String? _submitWarning;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _surnameController,
      _emailController,
      _passwordController,
      _confirmPasswordController,
    ]) {
      controller.addListener(_handleFieldChange);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _allFieldsFilled {
    return _nameController.text.trim().isNotEmpty &&
        _surnameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
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
      'Password must be at least 8 characters long and include uppercase, lowercase, and a special character.' =>
        PasswordValidation.formatHint,
      'Confirm Password must match Password.' => 'Şifreler eşleşmiyor.',
      'Email format is invalid.' => 'Geçerli bir e-posta adresi girin.',
      'Email already exists.' ||
      'An account with this email already exists.' =>
        'Bu e-posta adresi zaten kayıtlı.',
      _ => message.trim(),
    };
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_allFieldsFilled || _isSubmitting) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() {
        _submitWarning = 'Geçerli bir e-posta adresi girin.';
      });
      return;
    }

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
        ApiConfig.signupUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'confirmPassword': _confirmPasswordController.text,
        }),
      );

      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Kayıt başarılı. Lütfen e-postanızı doğrulayın.',
            ),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                VerificationScreen(email: _emailController.text.trim()),
          ),
        );
        return;
      }

      final errors = (body['errors'] as Map?)?.cast<String, dynamic>() ?? {};
      final rawWarning = errors['password']?.toString() ??
          errors['confirmPassword']?.toString() ??
          errors['email']?.toString() ??
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
                          'Kayıt Ol',
                          style: TextStyle(
                            fontSize: 34,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 22),
                        UserTextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(hintText: 'Ad'),
                        ),
                        const SizedBox(height: 14),
                        UserTextField(
                          controller: _surnameController,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(hintText: 'Soyad'),
                        ),
                        const SizedBox(height: 14),
                        UserTextField(
                          controller: _emailController,
                          kind: UserTextInputKind.email,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(hintText: 'E-posta'),
                        ),
                        const SizedBox(height: 14),
                        UserTextField(
                          controller: _passwordController,
                          kind: UserTextInputKind.password,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                            hintText: 'Şifre',
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
                            hintText: 'Şifreyi Onayla',
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
                                      'Hesap Oluştur',
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
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(
                      builder: (_) => const WelcomeScreen(),
                    ),
                    (route) => false,
                  );
                },
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
