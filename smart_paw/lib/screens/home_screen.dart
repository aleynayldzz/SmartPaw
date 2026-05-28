import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/auth_api_service.dart';
import '../services/auth_session.dart';
import '../services/daily_routine_api_service.dart';
import '../widgets/main_bottom_nav.dart';
import 'add_cat_screen.dart';
import 'health_screen.dart';
import 'my_cats_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.showLoginSuccess = false});

  final bool showLoginSuccess;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const int _healthTabIndex = 1;
  static const int _profileTabIndex = 4;

  int _navIndex = 0;

  // Günlük bakım maddeleri artık API'den gelir (GET/PUT /api/daily-routine).
  // Eski yerel liste (_dailyTasks + _dailyTaskDone) kaldırıldı.
  bool _routineLoading = true;
  String? _routineError;
  String _routineDate = DailyRoutineApiService.todayLocalDateString();
  List<DailyRoutineTask> _routineTasks = [];
  int _routineCompleted = 0;
  int _routineTotal = 0;
  static const Color _pageBackground = Color(0xFFFFF9F1);

  /// Profil adı: kayıtlı `name` alanından kısa selamlama (ör. "Hello Aleyna 👋").
  String get _profileGreetingName {
    final raw = AuthSession.user?['name']?.toString().trim();
    if (raw == null || raw.isEmpty) return 'Misafir';
    return raw.split(RegExp(r'\s+')).first;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final profileOk = await AuthApiService.refreshProfileFromServer();
      await _loadDailyRoutine();
      if (profileOk && mounted) setState(() {});

      if (!mounted) return;

      if (widget.showLoginSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Giriş başarılı.')));
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
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDailyRoutine();
    }
  }

  Future<void> _loadDailyRoutine() async {
    if (mounted) {
      setState(() {
        _routineLoading = true;
        _routineError = null;
      });
    }

    try {
      final snap = await DailyRoutineApiService.fetchToday();
      if (!mounted) return;
      setState(() {
        _routineDate = snap.date;
        _routineTasks = snap.tasks;
        _routineCompleted = snap.completedCount;
        _routineTotal = snap.totalApplicable;
        _routineLoading = false;
        _routineError = null;
      });
    } on DailyRoutineApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _routineError = e.message;
        _routineLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _routineError =
            'Günlük bakım yüklenemedi. Sunucunun çalıştığından emin olun.';
        _routineLoading = false;
      });
    }
  }

  Future<void> _toggleRoutineTask(String taskKey) async {
    if (_routineLoading) return;

    final index = _routineTasks.indexWhere((t) => t.key == taskKey);
    if (index < 0) return;

    final previous = _routineTasks[index];
    final newDone = !previous.isDone;

    setState(() {
      final next = List<DailyRoutineTask>.from(_routineTasks);
      next[index] = previous.copyWith(isDone: newDone);
      _routineTasks = next;
      _routineCompleted += newDone ? 1 : -1;
    });

    try {
      final snap = await DailyRoutineApiService.setTaskDone(
        date: _routineDate,
        taskKey: taskKey,
        isDone: newDone,
      );
      if (!mounted) return;
      setState(() {
        _routineDate = snap.date;
        _routineTasks = snap.tasks;
        _routineCompleted = snap.completedCount;
        _routineTotal = snap.totalApplicable;
      });
    } catch (e) {
      if (!mounted) return;
      await _loadDailyRoutine();
      if (!mounted) return;
      final msg = e is DailyRoutineApiException
          ? e.message
          : 'Görev kaydedilemedi.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _openQuickAddCat() {
    Navigator.of(
      context,
    ).push<void>(MaterialPageRoute<void>(builder: (_) => const AddCatScreen()));
  }

  void _openNotifications() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openMyCats() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const MyCatsScreen()),
    );
  }

  void _showComingSoon(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label çok yakında.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titleColor = Color(0xFF3E3E3E);

    return Scaffold(
      appBar: _navIndex == _profileTabIndex ||
              _navIndex == 0 ||
              _navIndex == _healthTabIndex
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
        onSelect: (i) {
          if (i == 0 && _navIndex != 0) {
            _loadDailyRoutine();
          }
          setState(() => _navIndex = i);
        },
      ),
      backgroundColor: _pageBackground,
      body: _navIndex == _profileTabIndex
          ? const ProfileScreen()
          : SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: SafeArea(
                child: IndexedStack(
                  index: _navIndex.clamp(0, 3),
                  children: [
                    _HomeGreetingScroll(
                      greetingName: _profileGreetingName,
                      completed: _routineCompleted,
                      total: _routineTotal,
                      routineLoading: _routineLoading,
                      routineError: _routineError,
                      onRetryRoutine: _loadDailyRoutine,
                      tasks: _routineTasks,
                      onToggleTask: _toggleRoutineTask,
                      onQuickMyCats: _openMyCats,
                      onQuickAddCat: _openQuickAddCat,
                      onQuickNotifications: _openNotifications,
                      onQuickAddVetVisit: () {
                        setState(() => _navIndex = _healthTabIndex);
                      },
                      onQuickVaccine: () {
                        setState(() => _navIndex = _healthTabIndex);
                      },
                      onQuickMedication: () {
                        setState(() => _navIndex = _healthTabIndex);
                      },
                    ),
                    HealthScreen(
                      onBackToHome: () {
                        setState(() => _navIndex = 0);
                        _loadDailyRoutine();
                      },
                    ),
                    const _NavPlaceholderTab(),
                    const _NavPlaceholderTab(),
                  ],
                ),
              ),
            ),
    );
  }
}

class _NavPlaceholderTab extends StatelessWidget {
  const _NavPlaceholderTab();

  @override
  Widget build(BuildContext context) {
    return Center(
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
    );
  }
}

/// Scrollable dashboard shell; greeting sits at the top (user story 1).
class _HomeGreetingScroll extends StatelessWidget {
  const _HomeGreetingScroll({
    required this.greetingName,
    required this.completed,
    required this.total,
    required this.routineLoading,
    required this.routineError,
    required this.onRetryRoutine,
    required this.tasks,
    required this.onToggleTask,
    required this.onQuickMyCats,
    required this.onQuickAddCat,
    required this.onQuickNotifications,
    required this.onQuickAddVetVisit,
    required this.onQuickVaccine,
    required this.onQuickMedication,
  });

  final String greetingName;
  final int completed;
  final int total;
  final bool routineLoading;
  final String? routineError;
  final VoidCallback onRetryRoutine;
  final List<DailyRoutineTask> tasks;
  final ValueChanged<String> onToggleTask;
  final VoidCallback onQuickMyCats;
  final VoidCallback onQuickAddCat;
  final VoidCallback onQuickNotifications;
  final VoidCallback onQuickAddVetVisit;
  final VoidCallback onQuickVaccine;
  final VoidCallback onQuickMedication;

  static const Color _headingColor = Color(0xFF2C2825);
  static const Color _accentYellow = Color(0xFFE9B23F);

  @override
  Widget build(BuildContext context) {
    const greetingStyle = TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w900,
      height: 1.1,
      letterSpacing: -0.6,
      color: _headingColor,
    );

    const sectionTitleStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w800,
      color: _headingColor,
      letterSpacing: -0.3,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 28, 22, 14),
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
          const SizedBox(height: 26),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Günlük Bakım ', style: sectionTitleStyle),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 4),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 24,
                      color: _accentYellow,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (routineLoading && tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (routineError != null && tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routineError!,
                    style: const TextStyle(
                      color: Color(0xFF8B4513),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onRetryRoutine,
                    child: const Text('Yeniden dene'),
                  ),
                ],
              ),
            )
          else
            _DailyTaskList(tasks: tasks, onToggle: onToggleTask),
          const SizedBox(height: 28),
          const Text('Hızlı İşlemler', style: sectionTitleStyle),
          const SizedBox(height: 16),
          _QuickActionsGrid(
            onMyCats: onQuickMyCats,
            onAddCat: onQuickAddCat,
            onNotifications: onQuickNotifications,
            onVetVisit: onQuickAddVetVisit,
            onVaccine: onQuickVaccine,
            onMedication: onQuickMedication,
          ),
        ],
      ),
    );
  }
}

/// 3×2 hızlı işlemler (yalnızca bu bölüm yeni ızgara düzeni).
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onMyCats,
    required this.onAddCat,
    required this.onNotifications,
    required this.onVetVisit,
    required this.onVaccine,
    required this.onMedication,
  });

  final VoidCallback onMyCats;
  final VoidCallback onAddCat;
  final VoidCallback onNotifications;
  final VoidCallback onVetVisit;
  final VoidCallback onVaccine;
  final VoidCallback onMedication;

  static const Color _ink = Color(0xFF2C2825);
  /// Referans #E39695 tonunda açık kart zemini
  static const Color _tileBg = Color(0xFFF5DADA);

  static const double _kIconSize = 36;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final w = constraints.maxWidth;
        final cellW = (w - gap * 2) / 3;
        final cellH = math.max(118.0, cellW * 1.14);

        Widget tile({
          required String label,
          required Widget icon,
          required VoidCallback onTap,
        }) {
          return _QuickActionCard(
            width: cellW,
            height: cellH,
            onTap: onTap,
            cardBg: _tileBg,
            label: label,
            icon: icon,
          );
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                tile(
                  label: 'Kedilerim',
                  icon: _TwoCatsIcon(color: _ink, iconSize: _kIconSize),
                  onTap: onMyCats,
                ),
                tile(
                  label: 'Kedi Ekle',
                  icon: _PawWithPlusIcon(color: _ink, iconSize: _kIconSize),
                  onTap: onAddCat,
                ),
                tile(
                  label: 'Bildirimler',
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: _ink,
                    size: _kIconSize,
                  ),
                  onTap: onNotifications,
                ),
              ],
            ),
            const SizedBox(height: gap),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                tile(
                  label: 'Veteriner\nziyareti ekle',
                  icon: Icon(
                    Icons.medical_services_outlined,
                    color: _ink,
                    size: _kIconSize,
                  ),
                  onTap: onVetVisit,
                ),
                tile(
                  label: 'Aşı Ekle',
                  icon: Icon(
                    Icons.vaccines_outlined,
                    color: _ink,
                    size: _kIconSize,
                  ),
                  onTap: onVaccine,
                ),
                tile(
                  label: 'İlaç Ekle',
                  icon: Icon(
                    Icons.medication_liquid_outlined,
                    color: _ink,
                    size: _kIconSize,
                  ),
                  onTap: onMedication,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TwoCatsIcon extends StatelessWidget {
  const _TwoCatsIcon({required this.color, required this.iconSize});

  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final pet = iconSize * 0.72;
    final w = iconSize * 1.05;
    final h = iconSize * 0.88;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: pet * 0.2,
            child: Icon(Icons.pets_outlined, color: color, size: pet),
          ),
          Positioned(
            left: pet * 0.48,
            top: 0,
            child: Icon(Icons.pets_outlined, color: color, size: pet),
          ),
        ],
      ),
    );
  }
}

/// Pati + üst köşede artı ikonu (referans "Add Cat" karteıdaki gibi).
class _PawWithPlusIcon extends StatelessWidget {
  const _PawWithPlusIcon({required this.color, required this.iconSize});

  final Color color;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final paw = iconSize * 0.92;
    final plus = iconSize * 0.48;
    return SizedBox(
      width: iconSize * 1.05,
      height: iconSize * 1.05,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Icon(Icons.pets_outlined, color: color, size: paw),
          Positioned(
            right: -2,
            bottom: -1,
            child: Icon(
              Icons.add_circle_outline_rounded,
              color: color,
              size: plus,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.width,
    required this.height,
    required this.onTap,
    required this.cardBg,
    required this.label,
    required this.icon,
  });

  final double width;
  final double height;
  final VoidCallback onTap;
  final Color cardBg;
  final String label;
  final Widget icon;

  static const Color _labelColor = Color(0xFF3A302D);
  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(_radius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 10),
            child: Column(
              children: [
                Expanded(child: Center(child: icon)),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: _labelColor,
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
  static const Color _track = Color(0xFFF6DDE0);
  static const Color _fill = Color(0xFFE89AA3);
  static const double _barHeight = 14;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            counter,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _counterColor,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final barW = constraints.maxWidth;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(end: _ratio),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  final fillW = (barW * value).clamp(0.0, barW);
                  const dotSize = 18.0;
                  final dotLeft = (fillW - (dotSize / 2)).clamp(
                    0.0,
                    barW - dotSize,
                  );
                  return SizedBox(
                    width: barW,
                    child: Stack(
                      clipBehavior: Clip.none,
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
                              border: Border.all(color: _fill, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: _fill.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
          const SizedBox(height: 14),
          Text(
            _subtitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTaskList extends StatelessWidget {
  const _DailyTaskList({required this.tasks, required this.onToggle});

  final List<DailyRoutineTask> tasks;
  final ValueChanged<String> onToggle;

  static const Color _text = Color(0xFF2C2825);
  static const Color _doneText = Color(0xFF9A8E88);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final t in tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onToggle(t.key),
              child: Row(
                children: [
                  _SoftCheckbox(value: t.isDone),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      t.title,
                      style: TextStyle(
                        fontSize: 17.5,
                        height: 1.22,
                        fontWeight: FontWeight.w700,
                        color: t.isDone ? _doneText : _text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SoftCheckbox extends StatelessWidget {
  const _SoftCheckbox({required this.value});

  final bool value;

  static const Color _pink = Color(0xFFE89AA3);
  static const Color _uncheckedBorder = Color(0xFFC9B3AE);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      height: 24,
      width: 24,
      decoration: BoxDecoration(
        color: value ? _pink : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: value ? _pink : _uncheckedBorder,
          width: value ? 2 : 1.6,
        ),
      ),
      child: value
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : null,
    );
  }
}
