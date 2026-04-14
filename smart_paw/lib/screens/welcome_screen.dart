import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFF7F2);
    const titleColor = Color(0xFF1F1F1F);
    const subtitleColor = Color(0xFF6B6B6B);
    const primary = Color(0xFFE9A5A1);
    const outline = Color(0xFFE9A5A1);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/images/welcomelogo.png',
                      width: 260,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    "SmartPaw'a\nHoş Geldiniz!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dostlarınız İçin Akıllı Bakım',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: titleColor,
                        side: const BorderSide(color: outline, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Hesap Oluştur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
