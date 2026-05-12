import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/auth_session.dart';
import '../widgets/main_bottom_nav.dart';
import 'add_cat_screen.dart';
import 'add_vet_visit_screen.dart';
import 'notifications_screen.dart';
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
  late final List<_DailyTaskItem> _dailyTasks = const [
    _DailyTaskItem(title: 'Malt Takviyesi Ver'),
    _DailyTaskItem(title: 'Mama ve Suyu Tazele'),
    _DailyTaskItem(title: 'Tüylerini Tara'),
    _DailyTaskItem(
      title: 'Kulak, Burun ve Göz Temizliği',
    ),
    _DailyTaskItem(title: 'İlacını Ver'),
    _DailyTaskItem(title: 'Kum Kabını Temizle'),
    _DailyTaskItem(title: 'Oyun Zamanı'),
  ];

  late final List<bool> _dailyTaskDone =
      List<bool>.filled(_dailyTasks.length, false);

  int get _completedDailyTasks => _dailyTaskDone.where((x) => x).length;
  int get _totalDailyTasks => _dailyTasks.length;

  static const Color _quickActionPink = Color(0xFFFFDEE4);
  static const Color _bgTop = Color(0xFFFFF7F8);
  static const Color _bgBottom = Color(0xFFFFEEF1);

  /// Registered profile name: first token for a short greeting (e.g. "Aleyna 👋").
  String get _profileGreetingName {
    final raw = AuthSession.user?['name']?.toString().trim();
    if (raw == null || raw.isEmpty) return 'Misafir';
    return raw.split(RegExp(r'\s+')).first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.showLoginSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Giriş başarılı.')),
        );
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

  void _openQuickAddCat() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AddCatScreen()),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openAddVetVisit() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const AddVetVisitScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  colors: [_bgTop, _bgBottom],
                ),
              ),
              child: SafeArea(
                child: _navIndex == 0
                    ? _HomeGreetingScroll(
                        greetingName: _profileGreetingName,
                        completed: _completedDailyTasks,
                        total: _totalDailyTasks,
                        tasks: _dailyTasks,
                        taskDone: _dailyTaskDone,
                        onToggleTask: (i) => setState(() {
                          _dailyTaskDone[i] = !_dailyTaskDone[i];
                        }),
                        quickActionBg: _quickActionPink,
                        onQuickAddCat: _openQuickAddCat,
                        onQuickNotifications: _openNotifications,
                        onQuickAddVetVisit: _openAddVetVisit,
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
    required this.tasks,
    required this.taskDone,
    required this.onToggleTask,
    required this.quickActionBg,
    required this.onQuickAddCat,
    required this.onQuickNotifications,
    required this.onQuickAddVetVisit,
  });

  final String greetingName;
  final int completed;
  final int total;
  final List<_DailyTaskItem> tasks;
  final List<bool> taskDone;
  final ValueChanged<int> onToggleTask;
  final Color quickActionBg;
  final VoidCallback onQuickAddCat;
  final VoidCallback onQuickNotifications;
  final VoidCallback onQuickAddVetVisit;

  static const Color _headingColor = Color(0xFF2C2825);

  /// Ana vurgu: turuncunun karşılığı koyu pembe.
  static const Color _accentPink = Color(0xFFD47A85);

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
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
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
          const SizedBox(height: 12),
          _DailyProgressHeader(completed: completed, total: total),
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Günlük Bakım ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _headingColor,
                    letterSpacing: -0.2,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 1),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 22,
                      color: _accentPink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _DailyTaskList(
            tasks: tasks,
            done: taskDone,
            onToggle: onToggleTask,
          ),
          const SizedBox(height: 20),
          const Text(
            'Hızlı İşlemler',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _headingColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          _QuickActionsRow(
            cardBg: quickActionBg,
            onAddCat: onQuickAddCat,
            onNotifications: onQuickNotifications,
            onAddVetVisit: onQuickAddVetVisit,
          ),
        ],
      ),
    );
  }
}

/// Üç kompakt kare kart (referans ölçülerine yakın).
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.cardBg,
    required this.onAddCat,
    required this.onNotifications,
    required this.onAddVetVisit,
  });

  final Color cardBg;
  final VoidCallback onAddCat;
  final VoidCallback onNotifications;
  final VoidCallback onAddVetVisit;

  static const Color _ink = Color(0xFF2C2825);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final maxW = constraints.maxWidth;
        final cardSize = math.min(86.0, (maxW - gap * 2) / 3).clamp(72.0, 88.0);
        final iconBox = cardSize * 0.38;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionCard(
              size: cardSize,
              onTap: onAddCat,
              cardBg: cardBg,
              label: 'Kedi Ekle',
              icon: SizedBox(
                height: iconBox,
                width: iconBox,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.pets_outlined, color: _ink, size: iconBox * 0.88),
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        color: _ink,
                        size: iconBox * 0.42,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _QuickActionCard(
              size: cardSize,
              onTap: onNotifications,
              cardBg: cardBg,
              label: 'Bildirimler',
              icon: Icon(Icons.notifications_outlined, color: _ink, size: iconBox * 0.95),
            ),
            _QuickActionCard(
              size: cardSize,
              onTap: onAddVetVisit,
              cardBg: cardBg,
              label: 'Veteriner\nziyareti',
              icon: Icon(Icons.medical_services_outlined, color: _ink, size: iconBox * 0.88),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.size,
    required this.onTap,
    required this.cardBg,
    required this.label,
    required this.icon,
  });

  final double size;
  final VoidCallback onTap;
  final Color cardBg;
  final String label;
  final Widget icon;

  static const Color _label = Color(0xFF4A4543);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(6, size * 0.12, 6, size * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                SizedBox(height: size * 0.08),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: math.max(10.5, size * 0.135),
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: _label,
                  ),
                ),
              ],
            ),
          ),
        ),
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
  static const Color _track = Color(0xFFF2D0D5); // açık pembe iz (bej yerine)
  static const Color _fill = Color(0xFFD47A85); // koyu vurgu pembe (turuncu karşılığı)
  static const double _barHeight = 8;

  double get _ratio {
    final t = total <= 0 ? 0 : total;
    if (t == 0) return 0;
    final r = completed / t;
    return r.clamp(0.0, 1.0);
  }

  String get _subtitle {
    final pct = (_ratio * 100).round();
    if (pct <= 0) return 'Kedinizin bakım rutinine başlayın! 🐱';
    if (pct >= 100) return 'Tüm görevler tamamlandı! Harikasın! 😸🎉';
    return 'Bugünkü işiniz neredeyse bitti! 🐈‍⬛🐾';
  }

  @override
  Widget build(BuildContext context) {
    final counter = '$completed / $total görev tamamlandı';

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
                  tween: Tween<double>(end: _ratio),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: _textColor.withValues(alpha: 0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyTaskList extends StatelessWidget {
  const _DailyTaskList({
    required this.tasks,
    required this.done,
    required this.onToggle,
  });

  final List<_DailyTaskItem> tasks;
  final List<bool> done;
  final ValueChanged<int> onToggle;

  static const Color _text = Color(0xFF2C2825);
  static const Color _doneText = Color(0xFF9A8E88);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(tasks.length, (i) {
        final t = tasks[i];
        final isDone = done[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onToggle(i),
            child: Row(
              children: [
                _SoftCheckbox(value: isDone),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.title,
                    style: TextStyle(
                      fontSize: 15.5,
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                      color: isDone ? _doneText : _text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _SoftCheckbox extends StatelessWidget {
  const _SoftCheckbox({required this.value});

  final bool value;

  static const Color _pink = Color(0xFFE9A5A1);
  static const Color _uncheckedBorder = Color(0xFFB9A6A2);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 22,
      width: 22,
      decoration: BoxDecoration(
        color: value ? _pink : Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: value ? _pink : _uncheckedBorder,
          width: value ? 2 : 1.5,
        ),
      ),
      child: value
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

class _DailyTaskItem {
  const _DailyTaskItem({required this.title});

  final String title;
}
