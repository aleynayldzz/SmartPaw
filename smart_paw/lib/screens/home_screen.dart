import 'package:flutter/material.dart';

import '../services/auth_session.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showLoginSuccess = false});

  final bool showLoginSuccess;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.showLoginSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFFFFFBFA);
    const bgBottom = Color(0xFFFFF1F2);
    const titleColor = Color(0xFF3E3E3E);

    final name = AuthSession.user?['name']?.toString();
    final greeting = (name != null && name.isNotEmpty) ? 'Merhaba, $name' : 'Ana Sayfa';

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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/patilogo.png',
                    height: 88,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    greeting,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Giriş başarılı. Akıllı bakım özellikleri burada geliştirilecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

