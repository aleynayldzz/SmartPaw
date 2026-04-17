import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'verification_screen.dart';

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

  String? _nameError;
  String? _surnameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;

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

  void _handleFieldChange() {
    if (!mounted) return;
    setState(() {
      _generalError = null;
      _validateFields(showErrors: false);
    });
  }

  bool _validateFields({required bool showErrors}) {
    final name = _nameController.text.trim();
    final surname = _surnameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    String? nameError;
    String? surnameError;
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;

    if (name.isEmpty) {
      nameError = 'Name is required.';
    }

    if (surname.isEmpty) {
      surnameError = 'Surname is required.';
    }

    if (email.isEmpty) {
      emailError = 'Email is required.';
    } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      emailError = 'Email format is invalid.';
    }

    if (password.isEmpty) {
      passwordError = 'Password is required.';
    } else if (password.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      passwordError =
          'Password must be at least 8 characters and include uppercase, lowercase, and a special character.';
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'Confirm Password is required.';
    } else if (confirmPassword != password) {
      confirmPasswordError = 'Confirm Password must match Password.';
    }

    if (showErrors) {
      setState(() {
        _nameError = nameError;
        _surnameError = surnameError;
        _emailError = emailError;
        _passwordError = passwordError;
        _confirmPasswordError = confirmPasswordError;
      });
    }

    return nameError == null &&
        surnameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmPasswordError == null;
  }

  bool get _isFormValid => _validateFields(showErrors: false);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_validateFields(showErrors: true) || _isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _generalError = null;
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
            content: Text('Registration successful. Please verify your email.'),
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

      setState(() {
        _nameError = errors['name']?.toString();
        _surnameError = errors['surname']?.toString();
        _emailError = errors['email']?.toString();
        _passwordError = errors['password']?.toString();
        _confirmPasswordError = errors['confirmPassword']?.toString();
        _generalError =
            body['message']?.toString() ??
            'Something went wrong. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _generalError =
            'Could not connect to the server. Check that the backend is running.';
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
      errorText: switch (hintText) {
        'Ad' => _nameError,
        'Soyad' => _surnameError,
        'E-posta' => _emailError,
        'Şifre' => _passwordError,
        'Şifreyi Onayla' => _confirmPasswordError,
        _ => null,
      },
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
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(hintText: 'Ad'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _surnameController,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(hintText: 'Soyad'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(hintText: 'E-posta'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordController,
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
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (_isFormValid && !_isSubmitting) {
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
                        if (_generalError != null) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _generalError!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
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
                              onPressed: _isFormValid && !_isSubmitting
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
                        if (!_isFormValid && !_isSubmitting)
                          const Padding(
                            padding: EdgeInsets.only(top: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Tüm alanlar geçerli olduğunda Hesap Oluştur düğmesi etkinleştirilecektir.',
                                style: TextStyle(
                                  color: Color(0xFF6B6B6B),
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 6),
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
                onPressed: () => Navigator.of(context).maybePop(),
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
