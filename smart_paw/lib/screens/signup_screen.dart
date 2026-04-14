import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
                        TextField(
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(hintText: 'Ad'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(hintText: 'Soyad'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(hintText: 'E-posta'),
                        ),
                        const SizedBox(height: 14),
                        TextField(
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
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
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
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {},
                              child: const Text(
                                'Hesap Oluştur',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
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
