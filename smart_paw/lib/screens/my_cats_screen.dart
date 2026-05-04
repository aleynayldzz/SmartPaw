import 'package:flutter/material.dart';

import '../models/cat_profile.dart';
import '../services/cat_api_service.dart';
import 'add_cat_screen.dart';

/// Kullanıcı kedilerini listeler; oluşturma ve düzenleme [AddCatScreen] ile.
class MyCatsScreen extends StatefulWidget {
  const MyCatsScreen({super.key});

  @override
  State<MyCatsScreen> createState() => _MyCatsScreenState();
}

class _MyCatsScreenState extends State<MyCatsScreen> {
  static const Color _creamBg = Color(0xFFFFFBF7);
  static const Color _titleColor = Color(0xFF3E3E3E);

  List<Map<String, dynamic>> _cats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCats();
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
        _cats = rows;
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

  String _subtitle(Map<String, dynamic> c) {
    final bn = c['breed_name']?.toString() ?? '';
    final w = c['weight'];
    final wg = w is num ? w.toDouble() : double.tryParse(w?.toString() ?? '');
    final wStr = wg != null ? '${wg.toStringAsFixed(1)} kg' : '';
    if (bn.isEmpty) return wStr;
    return wStr.isEmpty ? bn : '$bn · $wStr';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamBg,
      appBar: AppBar(
        backgroundColor: _creamBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Kedilerim',
          style: TextStyle(
            color: _titleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: _titleColor,
            onPressed: _openAdd,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        backgroundColor: const Color(0xFFD88A92),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.pets_rounded),
        label: const Text(
          'Kedi ekle',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _titleColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextButton(
                          onPressed: _loadCats,
                          child: const Text('Yeniden dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFD88A92),
                  onRefresh: _loadCats,
                  child: _cats.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Text(
                                'Henüz kedi eklenmemiş.',
                                style: TextStyle(
                                  color: _titleColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                          itemCount: _cats.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: Colors.grey.shade300),
                          itemBuilder: (context, i) {
                            final c = _cats[i];
                            final slug = c['slug']?.toString() ?? '';
                            final asset = CatApiService.assetPathForServer(
                              c['avatar_url']?.toString(),
                              slug,
                            );
                            final name = c['name']?.toString() ?? 'İsimsiz';
                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              leading: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: ClipOval(
                                    child: Image.asset(
                                      asset,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Icon(
                                              Icons.pets_rounded,
                                              color:
                                                  Colors.grey.shade600,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _titleColor,
                                ),
                              ),
                              subtitle: Text(
                                _subtitle(c),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: _titleColor,
                              ),
                              onTap: () => _openEdit(c),
                            );
                          },
                        ),
                ),
    );
  }
}
