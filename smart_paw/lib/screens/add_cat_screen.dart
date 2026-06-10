import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/cat_breeds.dart';
import '../models/cat_profile.dart';
import '../services/cat_api_service.dart';
import '../utils/text_input_config.dart';
import '../widgets/health/health_ui.dart';

const _kCreamBg = Color(0xFFFFF9F1);
const _kTitleColor = Color(0xFF3E3E3E);
const _kAccentPink = Color(0xFFD88A92);

class AddCatScreen extends StatefulWidget {
  const AddCatScreen({
    super.key,
    this.initial,
    this.knownCats,
    this.isFirstCat = false,
  });

  final CatFormInitial? initial;

  /// Kedilerim ekranından gelen güncel liste; isim çakışması kontrolü için.
  final List<Map<String, dynamic>>? knownCats;

  /// Yeni kullanıcının ilk kedisi; geri dönüş kapatılır, kayıttan sonra Kedilerim açılır.
  final bool isFirstCat;

  @override
  State<AddCatScreen> createState() => _AddCatScreenState();
}

class _AddCatScreenState extends State<AddCatScreen> {
  final TextEditingController _nameCtrl = TextEditingController();

  CatBreedOption? _breed;
  DateTime? _birth;
  bool? _isFemale;
  bool? _isNeutered;
  double? _weightKg;
  String? _formError;

  List<CatBreedOption> _breedOptions = [];
  bool _breedsLoading = true;
  String? _breedsLoadError;
  bool _saving = false;

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
      _breed = CatBreedOption(
        breedId: ini.breedId,
        slug: ini.breedSlug,
        labelTr: ini.breedLabel,
        assetPath: CatApiService.assetPathForServer(ini.avatarUrl, ini.breedSlug),
      );
      _birth = ini.birthDate;
      _isFemale = ini.isFemale;
      _isNeutered = ini.isNeutered;
      _weightKg = ini.weightKg;
      _breedsLoading = false;
    }
    _loadBreeds();
  }

  Future<void> _loadBreeds() async {
    if (widget.initial == null && mounted) {
      setState(() {
        _breedsLoading = true;
        _breedsLoadError = null;
      });
    }
    try {
      final list = await CatApiService.fetchBreeds();
      if (!mounted) return;
      setState(() {
        _breedOptions = list;
        _breedsLoadError = null;
        _breedsLoading = false;
      });
    } on CatApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _breedOptions = [];
        _breedsLoadError = e.message;
        _breedsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _breedOptions = [];
        _breedsLoadError = 'Irklar yüklenemedi.';
        _breedsLoading = false;
      });
    }
  }

  String _birthIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
    try {
      await CatApiService.deleteCat(id);
      if (!context.mounted) return;
      Navigator.pop(context, AddCatNavResult.deleted(id));
    } on CatApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _pickBreed(BuildContext context) {
    if (_breedOptions.isEmpty) return;
    final searchCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final q = searchCtrl.text.trim().toLowerCase();
            final source = _breedOptions;
            final filtered = q.isEmpty
                ? source.toList(growable: false)
                : source
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
                        child: UserTextField(
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
    var temp = _birth ?? DateTime(now.year, now.month, now.day);

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
    final initial = (_weightKg ?? 4.0).clamp(
      _HorizontalWeightPicker.minKg,
      _HorizontalWeightPicker.maxKg,
    );
    final picked = await showModalBottomSheet<double>(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: HealthUi.cardBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: _HorizontalWeightPicker(initialKg: initial),
              ),
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() => _weightKg = picked);
  }

  String? _nameError(String raw) {
    final t = raw.trim();
    if (t.length < 2 || t.length > 30) {
      return 'İsim 2–30 karakter olmalıdır.';
    }
    return null;
  }

  bool _hasAllRequiredFields() {
    return _breed?.breedId != null &&
        _nameCtrl.text.trim().isNotEmpty &&
        _birth != null &&
        _isFemale != null &&
        _isNeutered != null &&
        _weightKg != null;
  }

  bool _validate() {
    if (!_hasAllRequiredFields()) {
      setState(() => _formError = 'Zorunlu alanları doldurunuz.');
      return false;
    }

    final nameErr = _nameError(_nameCtrl.text);
    if (nameErr != null) {
      setState(() => _formError = nameErr);
      return false;
    }

    setState(() => _formError = null);
    return true;
  }

  Future<bool> _confirmDuplicateNameIfNeeded() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return true;

    List<Map<String, dynamic>> cats = widget.knownCats ?? const [];
    if (cats.isEmpty) {
      try {
        cats = await CatApiService.fetchMyCats();
      } on CatApiException catch (e) {
        if (!mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        return false;
      }
    }

    final excludeCatId = _isEditing ? widget.initial!.catId : null;
    final hasDuplicate = CatApiService.hasDuplicateCatName(
      cats,
      name,
      excludeCatId: excludeCatId,
    );

    if (!hasDuplicate) return true;
    if (!mounted) return false;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bu isim zaten kayıtlı'),
        content: Text(
          _isEditing
              ? '«$name» adında başka bir kedi profiliniz bulunuyor. '
                  'Bu kediyi aynı isimle kaydetmeye devam etmek istiyor musunuz?'
              : '«$name» adında bir kedi profiliniz zaten var. '
                  'Aynı isimle ikinci bir profil oluşturmak istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, kaydet'),
          ),
        ],
      ),
    );

    return proceed == true;
  }

  Future<Map<String, dynamic>> _persistCat() {
    final payload = (
      name: _nameCtrl.text.trim(),
      breedId: _breed!.breedId!,
      birthDateIso: _birthIso(_birth!),
      isFemale: _isFemale!,
      weightKg: _weightKg!,
      isNeutered: _isNeutered!,
    );

    if (_isEditing) {
      return CatApiService.updateCat(
        catId: widget.initial!.catId,
        name: payload.name,
        breedId: payload.breedId,
        birthDateIso: payload.birthDateIso,
        isFemale: payload.isFemale,
        weightKg: payload.weightKg,
        isNeutered: payload.isNeutered,
      );
    }

    return CatApiService.createCat(
      name: payload.name,
      breedId: payload.breedId,
      birthDateIso: payload.birthDateIso,
      isFemale: payload.isFemale,
      weightKg: payload.weightKg,
      isNeutered: payload.isNeutered,
    );
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final canProceed = await _confirmDuplicateNameIfNeeded();
    if (!canProceed || !mounted) return;

    setState(() => _saving = true);
    try {
      final map = await _persistCat();
      if (!mounted) return;
      Navigator.pop(
        context,
        AddCatNavResult.saved(CatApiService.catMapToDraft(map)),
      );
    } on CatApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.isFirstCat,
      child: Scaffold(
      backgroundColor: _kCreamBg,
      appBar: AppBar(
        backgroundColor: _kCreamBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: widget.isFirstCat
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: _kTitleColor,
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.isFirstCat,
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
        child: !_isEditing && _breedsLoading
            ? const Center(child: CircularProgressIndicator())
            : !_isEditing && !_breedsLoading && _breedOptions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _breedsLoadError ?? 'Irklar yüklenemedi.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _kTitleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextButton(
                            onPressed: () => _loadBreeds(),
                            child: const Text('Yeniden dene'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
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
                      child: UserTextField(
                        controller: _nameCtrl,
                        maxLength: 30,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _kTitleColor,
                        ),
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
                        trailing: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _kTitleColor,
                          size: 22,
                        ),
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
                              trailing: HealthUi.calendarIcon(size: 20),
                              dense: true,
                              onTap: _pickBirth,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            label: 'Kilo',
                            child: InkWell(
                              onTap: () => _pickWeight(context),
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: _weightFieldDecoration(
                                  hint: 'Kilo seçin',
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _weightKg != null
                                            ? '${_weightKg!.toStringAsFixed(1)} kg'
                                            : 'Kilo seçin',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _weightKg != null
                                              ? _kTitleColor
                                              : HealthUi.muted.withValues(
                                                  alpha: 0.7,
                                                ),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.swap_horiz_rounded,
                                      size: 22,
                                      color: HealthUi.muted.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                        trailing: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _kTitleColor,
                          size: 22,
                        ),
                        onTap: _pickGender,
                      ),
                    ),
                    _LabeledField(
                      label: 'Kısırlaştırılmış mı?',
                      child: _SelectRow(
                        text: _isNeutered == null
                            ? 'Seç'
                            : (_isNeutered! ? 'Kısır' : 'Kısır değil'),
                        trailing: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _kTitleColor,
                          size: 22,
                        ),
                        onTap: _pickNeutered,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                children: [
                  if (_formError != null) ...[
                    Text(
                      _formError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: HealthUi.accentPink,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccentPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Kaydet',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  OutlineInputBorder _outline({Color? color, double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: color ?? HealthUi.fieldBorder,
          width: width,
        ),
      );

  InputDecoration _inputDecoration({
    required String hintText,
    String? counterText,
    bool fillMuted = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: HealthUi.muted.withValues(alpha: 0.7)),
      counterText: counterText,
      filled: true,
      fillColor: fillMuted ? const Color(0xFFF0EEEB) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: _outline(),
      enabledBorder: _outline(),
      focusedBorder: _outline(color: HealthUi.accentPink, width: 1.5),
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
  final Widget trailing;
  final VoidCallback onTap;
  final bool dense;

  static const Set<String> _placeholders = {
    'İrk seç',
    'Tarih seç',
    'Seç',
  };

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: dense ? 14 : 16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: HealthUi.fieldBorder),
        color: Colors.white,
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
                    ? HealthUi.muted.withValues(alpha: 0.7)
                    : _kTitleColor,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: child,
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

InputDecoration _weightFieldDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: HealthUi.muted.withValues(alpha: 0.7)),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: HealthUi.fieldBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: HealthUi.fieldBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: HealthUi.accentPink, width: 1.5),
    ),
  );
}

class _HorizontalWeightPicker extends StatefulWidget {
  const _HorizontalWeightPicker({required this.initialKg});

  final double initialKg;

  static const double minKg = 0.5;
  static const double maxKg = 25.0;
  static const double step = 0.1;

  @override
  State<_HorizontalWeightPicker> createState() => _HorizontalWeightPickerState();
}

class _HorizontalWeightPickerState extends State<_HorizontalWeightPicker> {
  static const double _tickWidth = 14.0;

  late final ScrollController _controller;
  late final int _tickCount;
  late double _displayKg;
  bool _snapping = false;

  @override
  void initState() {
    super.initState();
    _tickCount =
        ((_HorizontalWeightPicker.maxKg - _HorizontalWeightPicker.minKg) /
                    _HorizontalWeightPicker.step)
                .round() +
            1;
    _displayKg = _kgForIndex(_indexForKg(widget.initialKg));
    _controller = ScrollController(initialScrollOffset: _offsetForKg(_displayKg));
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final idx =
        (_controller.offset / _tickWidth).round().clamp(0, _tickCount - 1);
    final kg = _kgForIndex(idx);
    if (kg != _displayKg) setState(() => _displayKg = kg);
  }

  int _indexForKg(double kg) {
    final raw =
        ((kg - _HorizontalWeightPicker.minKg) / _HorizontalWeightPicker.step)
            .round();
    return raw.clamp(0, _tickCount - 1);
  }

  double _kgForIndex(int i) {
    final v =
        _HorizontalWeightPicker.minKg + i * _HorizontalWeightPicker.step;
    return double.parse(v.toStringAsFixed(1));
  }

  double _offsetForKg(double kg) => _indexForKg(kg) * _tickWidth;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Kilo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: HealthUi.titleInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kaydırarak seçin (${_HorizontalWeightPicker.minKg.toStringAsFixed(1)}–${_HorizontalWeightPicker.maxKg.toStringAsFixed(0)} kg)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: HealthUi.muted.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _displayKg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: HealthUi.titleInk,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'kg',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: HealthUi.muted.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 86,
            child: Stack(
              alignment: Alignment.center,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final sidePad = (w / 2 - _tickWidth / 2).clamp(0.0, 9999.0);

                    return NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (_snapping) return false;
                        if (n is ScrollEndNotification) {
                          final idx = (_controller.offset / _tickWidth)
                              .round()
                              .clamp(0, _tickCount - 1);
                          final target = idx * _tickWidth;
                          _snapping = true;
                          _controller
                              .animateTo(
                                target,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                              )
                              .whenComplete(() => _snapping = false);
                        }
                        return false;
                      },
                      child: ListView.builder(
                        controller: _controller,
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: sidePad),
                        itemCount: _tickCount,
                        itemBuilder: (_, i) {
                          final kg = _kgForIndex(i);
                          final isWhole = (kg * 10).round() % 10 == 0;
                          return SizedBox(
                            width: _tickWidth,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 2,
                                  height: isWhole ? 26 : 16,
                                  decoration: BoxDecoration(
                                    color: isWhole
                                        ? HealthUi.accentPink
                                        : HealthUi.fieldBorder.withValues(
                                            alpha: 0.9,
                                          ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isWhole ? kg.toStringAsFixed(0) : '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: HealthUi.muted.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: HealthUi.accentPink,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, _displayKg),
              style: FilledButton.styleFrom(
                backgroundColor: HealthUi.accentPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Seç',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
