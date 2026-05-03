import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/cat_breeds.dart';

const _kCreamBg = Color(0xFFF9F6F0);
const _kTitleColor = Color(0xFF3E3E3E);
const _kAccentPink = Color(0xFFD88A92);
const _kFieldBorder = Color(0xFF5C5C5C);

/// Yeni oluşturma veya güncelleme sonrası dönen form verisi.
class CatDraft {
  const CatDraft({
    required this.name,
    required this.breed,
    required this.birthDate,
    required this.isFemale,
    required this.isNeutered,
    required this.weightKg,
    this.catId,
  });

  final String name;
  final CatBreedOption breed;
  final DateTime birthDate;
  final bool isFemale;
  final bool isNeutered;
  final double weightKg;

  /// Düzenleme modunda dolu gelir (silme/gelecek API için tutuluyor).
  final int? catId;
}

/// Düzenleme ekranına geçilirken kullanılacak başlangıç verisi.
class CatFormInitial {
  const CatFormInitial({
    required this.catId,
    required this.name,
    required this.breedSlug,
    required this.birthDate,
    required this.isFemale,
    required this.isNeutered,
    required this.weightKg,
  });

  final int catId;
  final String name;
  final String breedSlug;
  final DateTime birthDate;
  final bool isFemale;
  final bool isNeutered;
  final double weightKg;
}

/// `Navigator.push` ile bu ekrandan dönünce taşınan sonuç (kayıt veya silme).
class AddCatNavResult {
  AddCatNavResult.saved(this.draft) : deletedCatId = null;

  AddCatNavResult.deleted(this.deletedCatId) : draft = null;

  final CatDraft? draft;
  final int? deletedCatId;
}

class AddCatScreen extends StatefulWidget {
  const AddCatScreen({super.key, this.initial});

  final CatFormInitial? initial;

  @override
  State<AddCatScreen> createState() => _AddCatScreenState();
}

class _AddCatScreenState extends State<AddCatScreen> {
  final TextEditingController _nameCtrl = TextEditingController();

  CatBreedOption? _breed;
  DateTime? _birth;
  bool? _isFemale;
  bool? _isNeutered;
  double _weightKg = 4.0;

  bool get _isEditing => widget.initial != null;

  static const List<String> _monthsTr = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  @override
  void initState() {
    super.initState();
    final ini = widget.initial;
    if (ini != null) {
      _nameCtrl.text = ini.name;
      _breed = breedBySlug(ini.breedSlug);
      _birth = ini.birthDate;
      _isFemale = ini.isFemale;
      _isNeutered = ini.isNeutered;
      _weightKg = ini.weightKg;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _formatBirth(DateTime d) =>
      '${d.day} ${_monthsTr[d.month]} ${d.year}';

  Future<void> _confirmDelete(BuildContext context) async {
    final id = widget.initial!.catId;
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Profili sil'),
        content: const Text(
          'Bu kedinin profilini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    Navigator.pop(context, AddCatNavResult.deleted(id));
  }

  void _pickBreed(BuildContext context) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final q = searchCtrl.text.trim().toLowerCase();
            final filtered = q.isEmpty
                ? kCatBreeds.toList(growable: false)
                : kCatBreeds
                    .where((b) => b.labelTr.toLowerCase().contains(q))
                    .toList(growable: false);
            final height = MediaQuery.sizeOf(context).height * 0.72;

            return Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 8,
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: height,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Irk seçin',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: _kTitleColor,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: TextField(
                          controller: searchCtrl,
                          onChanged: (_) => setModal(() {}),
                          decoration: InputDecoration(
                            hintText: 'Irka göre ara',
                            prefixIcon: const Icon(Icons.search_rounded),
                            filled: true,
                            fillColor: const Color(0xFFF5F2EC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.88,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final b = filtered[index];
                            final selected =
                                _breed?.slug == b.slug;
                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() => _breed = b);
                              },
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: selected
                                        ? _kAccentPink
                                        : Colors.grey.shade300,
                                    width: selected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        8,
                                        10,
                                        8,
                                        6,
                                      ),
                                      child: Text(
                                        b.labelTr,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: _kTitleColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          12,
                                          0,
                                          12,
                                          12,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: Image.asset(
                                            b.assetPath,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) =>
                                                ColoredBox(
                                              color:
                                                  Colors.grey.shade200,
                                              child: Icon(
                                                Icons.pets_rounded,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(searchCtrl.dispose);
  }

  void _pickGender() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Cinsiyet',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            ListTile(
              title: const Text('Erkek'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isFemale = false);
              },
            ),
            ListTile(
              title: const Text('Kız'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isFemale = true);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _pickNeutered() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Kısırlaştırma durumu',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            ListTile(
              title: const Text('Kısır'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isNeutered = true);
              },
            ),
            ListTile(
              title: const Text('Kısır değil'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _isNeutered = false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBirth() async {
    final now = DateTime.now();
    var temp =
        (_birth ??
            DateTime(now.year - 2, now.month, math.min(now.day, 28)));

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Container(
          color: CupertinoColors.systemBackground.resolveFrom(ctx),
          height: 320 + bottom,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Tarih Seçin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.inactiveGray,
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.date,
                    initialDateTime: temp.isAfter(now)
                        ? now
                        : temp,
                    minimumDate: DateTime(now.year - 35),
                    maximumDate: now,
                    dateOrder: DatePickerDateOrder.dmy,
                    onDateTimeChanged: (d) {
                      temp = d;
                    },
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(ctx),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  onPressed: () {
                    setState(() => _birth = DateTime(temp.year, temp.month, temp.day));
                    Navigator.pop(ctx);
                  },
                ),
                CupertinoButton(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Vazgeç',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: CupertinoColors.activeBlue.resolveFrom(ctx),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickWeight(BuildContext parentContext) async {
    final mq = MediaQuery.sizeOf(parentContext);
    await showModalBottomSheet<void>(
      context: parentContext,
      backgroundColor: _kCreamBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(ctx).bottom + 16,
          ),
          child: _HorizontalWeightPicker(
            width: mq.width,
            initialKg: _weightKg,
            onConfirm: (kg) {
              setState(() => _weightKg = kg);
              Navigator.pop(ctx);
            },
            onCancel: () => Navigator.pop(ctx),
          ),
        );
      },
    );
  }

  String? _nameError(String raw) {
    final t = raw.trim();
    if (t.length < 2 || t.length > 30) {
      return 'İsim 2–30 karakter olmalıdır.';
    }
    return null;
  }

  bool _validate() {
    final ne = _nameError(_nameCtrl.text);
    if (ne != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ne)));
      return false;
    }
    if (_breed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir ırk seçin.')),
      );
      return false;
    }
    if (_birth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doğum tarihini seçin.')),
      );
      return false;
    }
    if (_isFemale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cinsiyet seçin.')),
      );
      return false;
    }
    if (_isNeutered == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kısırlaştırma durumunu seçin.'),
        ),
      );
      return false;
    }
    return true;
  }

  void _save() {
    if (!_validate()) return;
    Navigator.pop(
      context,
      AddCatNavResult.saved(
        CatDraft(
          catId: widget.initial?.catId,
          name: _nameCtrl.text.trim(),
          breed: _breed!,
          birthDate: _birth!,
          isFemale: _isFemale!,
          isNeutered: _isNeutered!,
          weightKg: _weightKg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCreamBg,
      appBar: AppBar(
        backgroundColor: _kCreamBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: _kTitleColor,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Kediyi düzenle' : 'Kedi Ekle',
          style: const TextStyle(
            color: _kTitleColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: _kTitleColor,
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Center(
                child: _AvatarPreview(breed: _breed),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _LabeledField(
                      label: 'İsim',
                      child: TextField(
                        controller: _nameCtrl,
                        maxLength: 30,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          hintText: 'Kedinizin adı',
                          counterText: '',
                        ),
                      ),
                    ),
                    _LabeledField(
                      label: 'Irk',
                      child: _SelectRow(
                        text: _breed?.labelTr ?? 'İrk seç',
                        trailing: Icons.keyboard_arrow_down_rounded,
                        onTap: () => _pickBreed(context),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'Doğum tarihi',
                            child: _SelectRow(
                              text: _birth != null
                                  ? _formatBirth(_birth!)
                                  : 'Tarih seç',
                              trailing: Icons.calendar_today_rounded,
                              dense: true,
                              onTap: _pickBirth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            label: 'Ağırlık',
                            child: _SelectRow(
                              text:
                                  '${_weightKg.toStringAsFixed(1)} kg',
                              trailing: Icons.tune_rounded,
                              dense: true,
                              onTap: () => _pickWeight(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _LabeledField(
                      label: 'Cinsiyet',
                      child: _SelectRow(
                        text: _isFemale == null
                            ? 'Seç'
                            : (_isFemale! ? 'Kız' : 'Erkek'),
                        trailing: Icons.keyboard_arrow_down_rounded,
                        onTap: _pickGender,
                      ),
                    ),
                    _LabeledField(
                      label: 'Kısırlaştırılmış mı?',
                      child: _SelectRow(
                        text: _isNeutered == null
                            ? 'Seç'
                            : (_isNeutered! ? 'Kısır' : 'Kısır değil'),
                        trailing: Icons.keyboard_arrow_down_rounded,
                        onTap: _pickNeutered,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccentPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  OutlineInputBorder _outline() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _kFieldBorder),
      );

  InputDecoration _inputDecoration({
    required String hintText,
    String? counterText,
  }) {
    return InputDecoration(
      hintText: hintText,
      counterText: counterText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: _outline(),
      enabledBorder: _outline(),
      focusedBorder: _outline(),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _kTitleColor,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.text,
    required this.trailing,
    required this.onTap,
    this.dense = false,
  });

  final String text;
  final IconData trailing;
  final VoidCallback onTap;
  final bool dense;

  static const Set<String> _placeholders = {
    'İrk seç',
    'Tarih seç',
    'Seç',
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: dense ? 14 : 16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kFieldBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: dense ? 14 : 15,
                    color: _placeholders.contains(text)
                        ? Colors.grey.shade600
                        : _kTitleColor,
                  ),
                ),
              ),
              Icon(trailing, color: _kTitleColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.breed});

  /// Mockuptaki gibi üstte kompakt kare önizleme.
  static const double _box = 112;

  final CatBreedOption? breed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DottedBorderBox(
          size: _box,
          child: breed == null
              ? Icon(
                  Icons.pets_rounded,
                  size: _box * 0.38,
                  color: const Color(0xFFE8C4C8),
                )
              : Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    breed!.assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.pets_rounded,
                      size: _box * 0.38,
                      color: Colors.grey,
                    ),
                  ),
                ),
        ),
        if (breed != null) ...[
          const SizedBox(height: 6),
          Text(
            breed!.labelTr,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _kTitleColor,
            ),
          ),
        ],
      ],
    );
  }
}

class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.size,
    required this.child,
  });

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedRectPainter(
        color: const Color(0xFFE8B4BC),
        strokeWidth: 2,
        gap: 5,
        dash: 6,
      ),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8EC).withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: child,
        ),
      ),
    );
  }
}

class _DottedRectPainter extends CustomPainter {
  _DottedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
  });

  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      const Radius.circular(24),
    );
    final path = Path()..addRRect(r);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        final next = math.min(d + dash, metric.length);
        final extract = metric.extractPath(d, next);
        canvas.drawPath(extract, paint);
        d = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HorizontalWeightPicker extends StatefulWidget {
  const _HorizontalWeightPicker({
    required this.width,
    required this.initialKg,
    required this.onConfirm,
    required this.onCancel,
  });

  final double width;
  final double initialKg;
  final ValueChanged<double> onConfirm;
  final VoidCallback onCancel;

  @override
  State<_HorizontalWeightPicker> createState() =>
      _HorizontalWeightPickerState();
}

class _HorizontalWeightPickerState extends State<_HorizontalWeightPicker> {
  static const double minKg = 0.5;
  static const double maxKg = 25.0;
  static const double step = 0.1;
  /// Daha geniş tik = parmakla kaydırma daha kolay.
  static const double tickWidth = 16;

  late final ScrollController _controller;
  late int _tickCount;
  late double _displayKg;

  @override
  void initState() {
    super.initState();
    _tickCount = ((maxKg - minKg) / step).round() + 1;
    final idx = _indexForKg(widget.initialKg);
    _displayKg = _kgForIndex(idx);
    final initialOffset = idx * tickWidth;
    _controller = ScrollController(initialScrollOffset: initialOffset);
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_controller.hasClients) return;
      final maxEx = _controller.position.maxScrollExtent;
      final raw = _indexForKg(_displayKg) * tickWidth;
      _controller.jumpTo(raw.clamp(0.0, maxEx));
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  int _indexForKg(double kg) {
    final raw = ((kg - minKg) / step).round();
    return raw.clamp(0, _tickCount - 1);
  }

  double _kgForIndex(int i) {
    final v = minKg + i * step;
    return double.parse(v.toStringAsFixed(1));
  }

  void _onScroll() {
    final i = _indexFromOffset(_controller.offset);
    final kg = _kgForIndex(i);
    if (kg != _displayKg) {
      setState(() => _displayKg = kg);
    }
  }

  int _indexFromOffset(double offset) {
    final i = (offset / tickWidth).round();
    return i.clamp(0, _tickCount - 1);
  }

  void _snap() {
    if (!_controller.hasClients) return;
    final i = _indexFromOffset(_controller.offset);
    final target = i * tickWidth;
    final maxExtent = _controller.position.maxScrollExtent;
    _controller.animateTo(
      target.clamp(0.0, maxExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pad = (widget.width - tickWidth) / 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        const Text(
          'Ağırlık (kg)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _kTitleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '0,5 – 25 kg arası kaydırın',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _displayKg.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: _kTitleColor,
          ),
        ),
        const Text(
          'kg',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _kTitleColor,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 96,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollEndNotification) {
                _snap();
              }
              return false;
            },
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                ListView.builder(
                  controller: _controller,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: pad),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  itemCount: _tickCount,
                  itemBuilder: (context, i) {
                    final kg = _kgForIndex(i);
                    final isWhole = (kg * 10).round() % 10 == 0;
                    return SizedBox(
                      width: tickWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            isWhole ? kg.toStringAsFixed(0) : '',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 1.5,
                            height: isWhole ? 20 : 11,
                            color: isWhole
                                ? _kTitleColor
                                : Colors.grey.shade400,
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 2,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85D5D),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Vazgeç'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => widget.onConfirm(_displayKg),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccentPink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Tamam'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
