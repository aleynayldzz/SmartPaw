import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_session.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_handleFieldChange);
    _passwordController.addListener(_handleFieldChange);
  }

  @override
  void dispose() {
    _emailController.removeListener(_handleFieldChange);
    _passwordController.removeListener(_handleFieldChange);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleFieldChange() {
    if (!mounted) return;
    setState(() {
      _generalError = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  bool get _fieldsFilled {
    final email = _emailController.text.trim();
    return email.isNotEmpty && _passwordController.text.isNotEmpty;
  }

  String _normalizeMessage(String? message) {
    if (message == null || message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    final trimmed = message.trim();
    if (trimmed == 'Email or password is incorrect.') {
      return 'Email or password is incorrect';
    }
    return trimmed;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _emailError = email.isEmpty ? 'E-posta gerekli' : null;
        _passwordError = password.isEmpty ? 'Şifre gerekli' : null;
        _generalError = null;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    try {
      final response = await http.post(
        ApiConfig.loginUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
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
            _generalError = 'Something went wrong. Please try again.';
          });
          return;
        }
      }

      if (response.statusCode == 200 && body['ok'] == true) {
        final data = (body['data'] as Map?)?.cast<String, dynamic>();
        final accessToken =
            data?['accessToken']?.toString() ?? data?['token']?.toString();
        if (accessToken == null || accessToken.isEmpty) {
          setState(() {
            _generalError = 'Something went wrong. Please try again.';
          });
          return;
        }

        final refreshToken = data?['refreshToken']?.toString();
        final user = (data?['user'] as Map?)?.cast<String, dynamic>();
        await AuthSession.setSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userPayload: user,
        );

        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const HomeScreen(showLoginSuccess: true),
          ),
          (route) => false,
        );
        return;
      }

      final errors = (body['errors'] as Map?)?.cast<String, dynamic>() ?? {};
      setState(() {
        _emailError = errors['email']?.toString();
        _passwordError = errors['password']?.toString();
        _generalError = _normalizeMessage(body['message']?.toString());
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

  //Login_Screen Frontend Tasarımı başlıyor.(166-458)
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/patilogo.png',
                      height: 92,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 34),
                    _SoftTextField(
                      controller: _emailController,
                      hintText: 'E-posta',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      borderColor: borderPink,
                      errorText: _emailError,
                    ),
                    const SizedBox(height: 14),
                    _SoftTextField(
                      controller: _passwordController,
                      hintText: 'Şifre',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (_fieldsFilled && !_isSubmitting) {
                          _submit();
                        }
                      },
                      borderColor: borderPink,
                      errorText: _passwordError,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF9D8C8D),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF3E3E3E),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Şifremi unuttum?'),
                      ),
                    ),
                    if (_generalError != null) ...[
                      const SizedBox(height: 6),
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
                    const SizedBox(height: 10),
                    _GradientButton(
                      text: 'Giriş Yap',
                      start: buttonStart,
                      end: buttonEnd,
                      isLoading: _isSubmitting,
                      onPressed: _fieldsFilled && !_isSubmitting
                          ? _submit
                          : null,
                    ),
                  ],
                ),
              ),
            ),
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
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
    this.errorText,
  });

  final TextEditingController controller;
  final String hintText;
  final Color borderColor;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final Widget? suffix;
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
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
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
              suffixIcon: suffix,
              errorStyle: const TextStyle(height: 0, fontSize: 0),
              errorText: null,
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
