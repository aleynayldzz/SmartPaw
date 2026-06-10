import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../utils/text_input_config.dart';
import 'login_screen.dart';
import 'reset_password_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  String? _emailError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleFieldChange);
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleFieldChange);
    _emailController.dispose();
    super.dispose();
  }

  void _handleFieldChange() {
    if (!mounted) return;
    setState(() {
      _generalError = null;
      _emailError = null;
    });
  }

  String _normalizeMessage(String? message) {
    if (message == null || message.isEmpty) {
      return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
    return switch (message.trim()) {
      'Account not found' => 'Bu e-posta adresiyle kayıtlı hesap bulunamadı.',
      'Please enter a valid email address' => 'Geçerli bir e-posta adresi girin.',
      'Validation failed.' => 'Lütfen bilgilerinizi kontrol edin.',
      _ => message.trim(),
    };
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting) return;

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailError = 'E-posta gerekli';
        _generalError = null;
      });
      return;
    }

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() {
        _emailError = 'Geçerli bir e-posta adresi girin';
        _generalError = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _emailError = null;
      _generalError = null;
    });

    try {
      final response = await http.post(
        ApiConfig.forgotPasswordUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
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
            _generalError = 'Bir hata oluştu. Lütfen tekrar deneyin.';
          });
          return;
        }
      }

      if (response.statusCode == 200 && body['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifre sıfırlama kodu e-posta adresinize gönderildi.'),
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => ResetPasswordCodeScreen(email: email),
          ),
        );
        return;
      }

      final errors = (body['errors'] as Map?)?.cast<String, dynamic>() ?? {};
      setState(() {
        _emailError = errors['email'] != null
            ? _normalizeMessage(errors['email']?.toString())
            : null;
        _generalError = _normalizeMessage(body['message']?.toString());
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _generalError =
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

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFFFFFBFA);
    const bgBottom = Color(0xFFFFF1F2);
    const borderPink = Color(0xFFE7A1A6);
    const buttonStart = Color(0xFFF3A0A3);
    const buttonEnd = Color(0xFFE38A90);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 18,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Şifremi Unuttum',
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F1F1F),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Kayıtlı e-posta adresinizi girin. Size bir doğrulama kodu göndereceğiz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: Color(0xFF6B6B6B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _SoftTextField(
                          controller: _emailController,
                          hintText: 'E-posta',
                          kind: UserTextInputKind.email,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_isSubmitting) {
                              _submit();
                            }
                          },
                          borderColor: borderPink,
                          errorText: _emailError,
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
                        _GradientButton(
                          text: 'Kod Gönder',
                          start: buttonStart,
                          end: buttonEnd,
                          isLoading: _isSubmitting,
                          onPressed: !_isSubmitting ? _submit : null,
                        ),
                      ],
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftTextField extends StatelessWidget {
  const _SoftTextField({
    required this.controller,
    required this.hintText,
    required this.borderColor,
    this.kind = UserTextInputKind.general,
    this.textInputAction,
    this.onSubmitted,
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final Color borderColor;
  final UserTextInputKind kind;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: UserTextField(
            controller: controller,
            kind: kind,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            cursorColor: borderColor,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF8D7B7C),
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.78),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.redAccent
                      : borderColor.withValues(alpha: 0.65),
                  width: hasError ? 1.4 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: hasError ? Colors.redAccent : borderColor,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.text,
    required this.start,
    required this.end,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final Color start;
  final Color end;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: [start, end]),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
