import 'package:flutter/material.dart';

import '../models/cat_profile.dart';
import '../services/cat_api_service.dart';
import 'add_cat_screen.dart';

/// Kullanıcı kedilerini listeler; oluşturma ve düzenleme [AddCatScreen] ile.
class MyCatsScreen extends StatefulWidget {
  const MyCatsScreen({super.key});

  static const Color creamBackground = Color(0xFFFFF9F1);
  static const Color titleColor = Color(0xFF3D2F2F);
  static const Color primaryRose = Color(0xFFE59A9A);

  /// Kart zemini: [primaryRose] tonundan daha açık, tek pastel pembe.
  static const Color cardPastelPink = Color(0xFFF9E4E4);

  @override
  State<MyCatsScreen> createState() => _MyCatsScreenState();
}

class _MyCatsScreenState extends State<MyCatsScreen> {
  List<Map<String, dynamic>> _cats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  /// En yaşlı kedi önce: doğum tarihi en eski olandan yeniye.
  static List<Map<String, dynamic>> _sortedOldestFirst(
    List<Map<String, dynamic>> rows,
  ) {
    final copy = List<Map<String, dynamic>>.from(rows);
    copy.sort((a, b) {
      final da = CatApiService.parseBirthDate(a['birth_date']);
      final db = CatApiService.parseBirthDate(b['birth_date']);
      final byBirth = da.compareTo(db);
      if (byBirth != 0) return byBirth;
      final ida = (a['cat_id'] as num?)?.toInt() ?? 0;
      final idb = (b['cat_id'] as num?)?.toInt() ?? 0;
      return ida.compareTo(idb);
    });
    return copy;
  }

  Future<void> _loadCats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await CatApiService.fetchMyCats();
      if (!mounted) return;
      setState(() {
        _cats = _sortedOldestFirst(rows);
        _loading = false;
      });
    } on CatApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _cats = [];
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cats = [];
        _error = 'Kediler alınamadı.';
        _loading = false;
      });
    }
  }

  Future<void> _openAdd() async {
    final result = await Navigator.of(context).push<AddCatNavResult?>(
      MaterialPageRoute(builder: (_) => const AddCatScreen()),
    );
    if (!mounted) return;
    if (result?.draft != null || result?.deletedCatId != null) {
      await _loadCats();
    }
    if (!mounted || result == null) return;
    if (result.draft != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedildi: ${result.draft!.name}')),
      );
    }
    if (result.deletedCatId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil silindi.')),
      );
    }
  }

  Future<void> _openEdit(Map<String, dynamic> cat) async {
    final ini = CatApiService.catToFormInitial(cat);
    final result = await Navigator.of(context).push<AddCatNavResult?>(
      MaterialPageRoute(builder: (_) => AddCatScreen(initial: ini)),
    );
    if (!mounted) return;
    if (result?.draft != null || result?.deletedCatId != null) {
      await _loadCats();
    }
    if (!mounted || result == null) return;
    if (result.draft != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kilo güncellendi.')),
      );
    }
    if (result.deletedCatId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil silindi.')),
      );
    }
  }

  /// Doğum tarihine göre yaş metni (tam yıl veya ay).
  String _ageLabel(Map<String, dynamic> c) {
    final birth = CatApiService.parseBirthDate(c['birth_date']);
    final now = DateTime.now();
    var years = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years--;
    }
    if (years >= 1) {
      return 'Yaş: $years';
    }
    if (birth.isAfter(now)) {
      return 'Yaş: 0 ay';
    }
    var months = (now.year - birth.year) * 12 + now.month - birth.month;
    if (now.day < birth.day) {
      months--;
    }
    months = months.clamp(0, 11);
    return 'Yaş: $months ay';
  }

  String _weightLabel(Map<String, dynamic> c) {
    final w = c['weight'];
    final kg = w is num ? w.toDouble() : double.tryParse(w?.toString() ?? '');
    if (kg == null) return 'Ağırlık: —';
    return 'Ağırlık: ${kg.toStringAsFixed(1)} kg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyCatsScreen.creamBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _ErrorBody(
                          message: _error!,
                          onRetry: _loadCats,
                        )
                      : RefreshIndicator(
                          color: MyCatsScreen.primaryRose,
                          onRefresh: _loadCats,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                sliver: _cats.isEmpty
                                    ? SliverFillRemaining(
                                        hasScrollBody: false,
                                        child: Center(
                                          child: Text(
                                            'Henüz kedi eklenmemiş.',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: MyCatsScreen.titleColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      )
                                    : SliverGrid(
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 14,
                                          crossAxisSpacing: 14,
                                          // Kare görsel + metin sığsın; pembe sadece içerik kadar (üstte hizalı).
                                          childAspectRatio: 0.70,
                                        ),
                                        delegate: SliverChildBuilderDelegate(
                                          (context, i) {
                                            final c = _cats[i];
                                            return _CatCard(
                                              cat: c,
                                              ageLabel: _ageLabel(c),
                                              weightLabel: _weightLabel(c),
                                              onTap: () => _openEdit(c),
                                            );
                                          },
                                          childCount: _cats.length,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _openAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: MyCatsScreen.primaryRose,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Kedi ekle'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: MyCatsScreen.titleColor,
              iconSize: 20,
            ),
          ),
          Text(
            'Kedilerim',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: MyCatsScreen.titleColor,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MyCatsScreen.titleColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: onRetry,
              child: const Text('Yeniden dene'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatCard extends StatelessWidget {
  const _CatCard({
    required this.cat,
    required this.ageLabel,
    required this.weightLabel,
    required this.onTap,
  });

  /// Yaş / ağırlık: kalın değil, siyah ton (pembe üzerinde okunaklı).
  static const Color _detailText = Color(0xFF1A1A1A);

  final Map<String, dynamic> cat;
  final String ageLabel;
  final String weightLabel;
  final VoidCallback onTap;

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    final slug = cat['slug']?.toString() ?? '';
    final asset = CatApiService.assetPathForServer(
      cat['avatar_url']?.toString(),
      slug,
    );
    final name = cat['name']?.toString() ?? 'İsimsiz';

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_radius),
          child: Ink(
            decoration: BoxDecoration(
              color: MyCatsScreen.cardPastelPink,
              borderRadius: BorderRadius.circular(_radius),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ColoredBox(
                        color: Colors.white.withValues(alpha: 0.5),
                        child: Image.asset(
                          asset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.pets_rounded,
                              size: 36,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: MyCatsScreen.titleColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        ageLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                          color: _detailText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weightLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.25,
                          color: _detailText,
                        ),
                      ),
                    ],
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
