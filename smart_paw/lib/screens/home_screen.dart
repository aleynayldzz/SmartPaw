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
  final int _completedDailyTasks = 5;
  final int _totalDailyTasks = 7;

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
                    ? _HomeGreetingScroll(
                        greetingName: _profileGreetingName,
                        completed: _completedDailyTasks,
                        total: _totalDailyTasks,
                      )
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
  const _HomeGreetingScroll({
    required this.greetingName,
    required this.completed,
    required this.total,
  });

  final String greetingName;
  final int completed;
  final int total;

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
          const SizedBox(height: 14),
          _DailyProgressHeader(completed: completed, total: total),
        ],
      ),
    );
  }
}

class _DailyProgressHeader extends StatelessWidget {
  const _DailyProgressHeader({required this.completed, required this.total});

  final int completed;
  final int total;

  static const Color _textColor = Color(0xFF2C2825);
  static const Color _counterColor = Color(0xFF3C3430);
  static const Color _track = Color(0xFFF2D7D4); // pastel pink track (was yellow-ish in ref)
  static const Color _fill = Color(0xFFE5A09B); // primary pink fill
  static const double _barHeight = 8;

  double get _ratio {
    final t = total <= 0 ? 0 : total;
    if (t == 0) return 0;
    final r = completed / t;
    return r.clamp(0.0, 1.0);
  }

  String get _subtitle {
    final pct = (_ratio * 100).round();
    if (pct <= 0) return 'Start your day! ✨';
    if (pct >= 100) return 'All tasks done! Great job! 🐾';
    return 'You’re almost done for today ✨';
  }

  @override
  Widget build(BuildContext context) {
    final counter = '$completed of $total tasks completed';

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              counter,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _counterColor,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                // Reference bar is not full-bleed; keep it compact.
                final barW = constraints.maxWidth * 0.92;
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _ratio),
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    final fillW = (barW * value).clamp(0.0, barW);
                    final dotSize = 10.0;
                    final dotLeft = (fillW - (dotSize / 2)).clamp(0.0, barW - dotSize);
                    return SizedBox(
                      width: barW,
                      child: Stack(
                        children: [
                          Container(
                            height: _barHeight,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: _track,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Container(
                            height: _barHeight,
                            width: fillW,
                            decoration: BoxDecoration(
                              color: _fill,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Positioned(
                            left: dotLeft,
                            top: (_barHeight - dotSize) / 2,
                            child: Container(
                              height: dotSize,
                              width: dotSize,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: _fill, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 10),
            Text(
              _subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
