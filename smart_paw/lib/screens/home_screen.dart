import 'package:flutter/material.dart';

import '../services/auth_session.dart';
import '../widgets/main_bottom_nav.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showLoginSuccess = false});

  final bool showLoginSuccess;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _profileTabIndex = 4;

  int _navIndex = 0;

  /// Registered profile name: first token for a short greeting (e.g. "Aleyna 👋").
  String get _profileGreetingName {
    final raw = AuthSession.user?['name']?.toString().trim();
    if (raw == null || raw.isEmpty) return 'Friend';
    return raw.split(RegExp(r'\s+')).first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.showLoginSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful')));
      }

      final isVerified = AuthSession.user?['is_verified'];
      if (isVerified == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hesabınız doğrulanmadı. Yine de giriş yaptınız; lütfen e-postanızı doğrulayın.',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFFFFFBFA);
    const bgBottom = Color(0xFFFFF1F2);
    const titleColor = Color(0xFF3E3E3E);

    return Scaffold(
      appBar: _navIndex == _profileTabIndex || _navIndex == 0
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'SmartPaw',
                style: TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _navIndex,
        onSelect: (i) => setState(() => _navIndex = i),
      ),
      body: _navIndex == _profileTabIndex
          ? const ProfileScreen()
          : Container(
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
                child: _navIndex == 0
                    ? _HomeGreetingScroll(greetingName: _profileGreetingName)
                    : Center(
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
                              const Text(
                                'Akıllı bakım özellikleri burada geliştirilecek.',
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

/// Scrollable dashboard shell; greeting sits at the top (user story 1).
class _HomeGreetingScroll extends StatelessWidget {
  const _HomeGreetingScroll({required this.greetingName});

  final String greetingName;

  static const Color _headingColor = Color(0xFF2C2825);

  @override
  Widget build(BuildContext context) {
    const greetingStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      height: 1.15,
      letterSpacing: -0.6,
      color: _headingColor,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(26, 8, 26, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: greetingStyle,
              children: [
                const TextSpan(text: 'Merhaba '),
                TextSpan(text: '$greetingName 👋'),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
