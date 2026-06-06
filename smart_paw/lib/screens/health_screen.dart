import 'package:flutter/material.dart';

import '../models/health_record.dart';
import '../services/cat_api_service.dart';
import '../services/medication_api_service.dart';
import '../services/vaccination_api_service.dart';
import '../services/vet_visit_api_service.dart';
import '../services/weight_history_service.dart';
import '../utils/turkish_date_format.dart';
import '../widgets/health/add_medication_sheet.dart';
import '../widgets/health/add_vaccine_sheet.dart';
import '../widgets/health/add_vet_appointment_sheet.dart';
import '../widgets/health/health_ui.dart';

/// Sağlık sekmesi — aşı, veteriner randevuları ve ilaç takibi.
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key, required this.onBackToHome});

  final VoidCallback onBackToHome;

  @override
  State<HealthScreen> createState() => HealthScreenState();
}

class HealthScreenState extends State<HealthScreen>
    with AutomaticKeepAliveClientMixin {
  /// Ana sayfa kısayolundan aşı ekleme formunu açar.
  Future<void> openAddVaccine() => _openAddVaccine();

  /// Ana sayfa kısayolundan veteriner ziyareti ekleme formunu açar.
  Future<void> openAddVetVisit() => _openVetAppointmentSheet(
        mode: VetSheetMode.create,
      );

  /// Ana sayfa kısayolundan ilaç ekleme formunu açar.
  Future<void> openAddMedication() => _openMedicationSheet(
        mode: MedicationSheetMode.create,
      );

  List<VaccineRecord> _vaccines = [];
  List<VaccineCatOption> _catOptions = [];
  bool _vaccinesLoading = true;
  String? _vaccinesError;
  List<VetAppointmentRecord> _vetAppointments = [];
  bool _vetVisitsLoading = true;
  String? _vetVisitsError;
  List<MedicationRecord> _medications = [];
  bool _medicationsLoading = true;
  String? _medicationsError;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCatOptions();
    _loadVaccines();
    _loadVetVisits();
    _loadMedications();
  }

  Future<void> _loadCatOptions() async {
    try {
      final cats = await CatApiService.fetchMyCats();
      if (!mounted) return;
      setState(() {
        _catOptions = cats
            .map(
              (c) => VaccineCatOption(
                catId: (c['cat_id'] as num).toInt(),
                name: c['name']?.toString() ?? 'Kedi',
              ),
            )
            .toList(growable: false);
      });
    } on CatApiException catch (_) {
      if (!mounted) return;
      setState(() => _catOptions = []);
    } catch (_) {
      if (!mounted) return;
      setState(() => _catOptions = []);
    }
  }

  Future<void> _loadVaccines() async {
    if (mounted) {
      setState(() {
        _vaccinesLoading = true;
        _vaccinesError = null;
      });
    }
    try {
      if (_catOptions.isEmpty) {
        await _loadCatOptions();
      }
      final vaccines = await VaccinationApiService.fetchAll();
      if (!mounted) return;
      setState(() {
        _vaccines = vaccines;
        _vaccinesLoading = false;
        _vaccinesError = null;
      });
    } on VaccinationApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _vaccinesError = e.message;
        _vaccinesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vaccinesError =
            'Aşı kayıtları yüklenemedi. Sunucunun çalıştığından emin olun.';
        _vaccinesLoading = false;
      });
    }
  }

  Future<void> _loadVetVisits() async {
    if (mounted) {
      setState(() {
        _vetVisitsLoading = true;
        _vetVisitsError = null;
      });
    }
    try {
      final visits = await VetVisitApiService.fetchAll();
      if (!mounted) return;
      setState(() {
        _vetAppointments = visits;
        _vetVisitsLoading = false;
        _vetVisitsError = null;
      });
    } on VetVisitApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _vetVisitsError = e.message;
        _vetVisitsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _vetVisitsError =
            'Veteriner kayıtları yüklenemedi. Sunucunun çalıştığından emin olun.';
        _vetVisitsLoading = false;
      });
    }
  }

  Future<void> _openVetAppointmentSheet({
    VetSheetMode mode = VetSheetMode.create,
    VetAppointmentRecord? existing,
  }) async {
    if (_catOptions.isEmpty) {
      await _loadCatOptions();
    }
    if (!mounted) return;

    if (_catOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veteriner kaydı eklemek için önce bir kedi ekleyin.'),
        ),
      );
      return;
    }

    final draft = await showModalBottomSheet<VetAppointmentRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddVetAppointmentSheet(
        cats: _catOptions,
        initial: existing,
        mode: mode,
      ),
    );
    if (draft == null || !mounted) return;
    if (mode == VetSheetMode.view) return;

    final updateId = draft.id ?? existing?.id;
    final isUpdate = mode == VetSheetMode.edit && updateId != null;

    try {
      if (isUpdate) {
        await VetVisitApiService.update(
          visitId: updateId,
          catId: draft.catId,
          visitDate: draft.visitDate,
          weight: draft.weightKg,
          reason: draft.reason,
          doctorNotes: draft.doctorNotes,
          nextVisitDate: draft.nextVisitDate,
        );
      } else {
        await VetVisitApiService.create(
          catId: draft.catId,
          visitDate: draft.visitDate,
          weight: draft.weightKg,
          reason: draft.reason,
          doctorNotes: draft.doctorNotes,
          nextVisitDate: draft.nextVisitDate,
        );
      }
      if (!mounted) return;
      await _loadVetVisits();
      WeightHistoryService.instance.markDirty();
    } on VetVisitApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate
                ? 'Veteriner kaydı güncellenemedi.'
                : 'Veteriner kaydı kaydedilemedi.',
          ),
        ),
      );
    }
  }

  Future<void> _openMedicationSheet({
    MedicationSheetMode mode = MedicationSheetMode.create,
    MedicationRecord? existing,
  }) async {
    if (_catOptions.isEmpty) {
      await _loadCatOptions();
    }
    if (!mounted) return;

    if (_catOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlaç kaydı eklemek için önce bir kedi ekleyin.'),
        ),
      );
      return;
    }

    final draft = await showModalBottomSheet<MedicationDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicationSheet(
        cats: _catOptions,
        initial: existing,
        mode: mode,
      ),
    );
    if (!mounted) return;
    if (mode == MedicationSheetMode.view) return;
    if (draft == null) return;

    final updateId = draft.id ?? existing?.id;
    final isUpdate = existing != null && updateId != null;

    try {
      if (isUpdate) {
        await MedicationApiService.update(
          medicationId: updateId,
          catId: draft.catId,
          medicationName: draft.name,
          dosage: draft.dosage,
          frequency: draft.frequencyKey,
          startDate: draft.startDate,
          endDate: draft.endDate,
          notes: draft.notes,
        );
      } else {
        await MedicationApiService.create(
          catId: draft.catId,
          medicationName: draft.name,
          dosage: draft.dosage,
          frequency: draft.frequencyKey,
          startDate: draft.startDate,
          endDate: draft.endDate,
          notes: draft.notes,
        );
      }
      if (!mounted) return;
      await _loadMedications();
    } on MedicationApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate ? 'İlaç kaydı güncellenemedi.' : 'İlaç kaydı kaydedilemedi.',
          ),
        ),
      );
    }
  }

  Future<void> _loadMedications() async {
    if (mounted) {
      setState(() {
        _medicationsLoading = true;
        _medicationsError = null;
      });
    }
    try {
      final meds = await MedicationApiService.fetchAll();

      if (!mounted) return;
      setState(() {
        _medications = meds;
        _medicationsLoading = false;
        _medicationsError = null;
      });
    } on MedicationApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _medicationsError = e.message;
        _medicationsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _medicationsError =
            'İlaç kayıtları yüklenemedi. Sunucunun çalıştığından emin olun.';
        _medicationsLoading = false;
      });
    }
  }

  Future<void> _openAddVaccine() async {
    await _openVaccineSheet(mode: VaccineSheetMode.create);
  }

  Future<void> _openVaccineSheet({
    required VaccineSheetMode mode,
    VaccineRecord? existing,
  }) async {
    if (_catOptions.isEmpty) {
      await _loadCatOptions();
    }
    if (!mounted) return;

    if (_catOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aşı kaydı eklemek için önce bir kedi ekleyin.'),
        ),
      );
      return;
    }

    final draft = await showModalBottomSheet<VaccineRecord>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddVaccineSheet(
        cats: _catOptions,
        initial: existing,
        mode: mode,
      ),
    );
    if (draft == null || !mounted) return;
    if (mode == VaccineSheetMode.view) return;

    final updateId = draft.id ?? existing?.id;
    final isUpdate = mode == VaccineSheetMode.edit && updateId != null;

    try {
      if (isUpdate) {
        await VaccinationApiService.update(
          vaccinationId: updateId,
          catId: draft.catId,
          vaccineName: draft.name,
          vaccinationDate: draft.vaccinationDate,
          nextDueDate: draft.nextVaccinationDate,
          reminderEnabled: draft.reminderEnabled,
          notes: draft.notes,
        );
      } else {
        await VaccinationApiService.create(
          catId: draft.catId,
          vaccineName: draft.name,
          vaccinationDate: draft.vaccinationDate,
          nextDueDate: draft.nextVaccinationDate,
          reminderEnabled: draft.reminderEnabled,
          notes: draft.notes,
        );
      }
      if (!mounted) return;
      await _loadVaccines();
    } on VaccinationApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate
                ? 'Aşı kaydı güncellenemedi.'
                : 'Aşı kaydı kaydedilemedi.',
          ),
        ),
      );
    }
  }

  List<VaccineRecord> get _sortedVaccines {
    final copy = List<VaccineRecord>.from(_vaccines);
    copy.sort((a, b) => b.vaccinationDate.compareTo(a.vaccinationDate));
    return copy;
  }

  List<VaccineRecord> get _upcomingVaccines {
    final copy = _vaccines.where((v) => v.isUpcoming).toList();
    copy.sort(
      (a, b) =>
          a.nextVaccinationDate!.compareTo(b.nextVaccinationDate!),
    );
    return copy;
  }

  List<VetAppointmentRecord> get _sortedVetAppointments {
    final copy = List<VetAppointmentRecord>.from(_vetAppointments);
    copy.sort((a, b) => b.visitDate.compareTo(a.visitDate));
    return copy;
  }

  List<VetAppointmentRecord> get _upcomingVetVisits {
    final copy = _vetAppointments.where((v) => v.isUpcoming).toList();
    copy.sort(
      (a, b) => a.nextVisitDate!.compareTo(b.nextVisitDate!),
    );
    return copy;
  }

  List<MedicationRecord> get _sortedMedications {
    final copy = List<MedicationRecord>.from(_medications);
    copy.sort((a, b) => b.startDate.compareTo(a.startDate));
    return copy;
  }

  Future<void> _confirmDeleteVaccine(VaccineRecord record) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı sil'),
        content: Text(
          '"${record.name}" kaydını silmek istediğinize emin misiniz?',
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
    if (yes != true || !mounted) return;
    final id = record.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt kimliği bulunamadı. Sayfayı yenileyin.')),
      );
      return;
    }

    try {
      await VaccinationApiService.delete(id);
      if (!mounted) return;
      await _loadVaccines();
    } on VaccinationApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aşı kaydı silinemedi.')),
      );
    }
  }

  Future<void> _confirmDeleteVetAppointment(VetAppointmentRecord record) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı sil'),
        content: Text(
          '${formatTurkishDate(record.visitDate)} randevusunu silmek istediğinize emin misiniz?',
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
    if (yes != true || !mounted) return;
    final id = record.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt kimliği bulunamadı. Sayfayı yenileyin.'),
        ),
      );
      return;
    }

    try {
      await VetVisitApiService.delete(id);
      if (!mounted) return;
      await _loadVetVisits();
    } on VetVisitApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veteriner kaydı silinemedi.')),
      );
    }
  }

  Widget _buildVetVisitSection() {
    if (_vetVisitsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_vetVisitsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _vetVisitsError!,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: HealthUi.muted.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadVetVisits,
            child: const Text('Yeniden dene'),
          ),
        ],
      );
    }

    if (_sortedVetAppointments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Henüz randevu kaydı yok. Sağ üstteki + ile ekleyin.',
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: HealthUi.muted.withValues(alpha: 0.9),
          ),
        ),
      );
    }

    final upcoming = _upcomingVetVisits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (upcoming.isNotEmpty) ...[
          const Text(
            'YAKLAŞAN VETERİNER ZİYARETLERİ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: HealthUi.accentPink,
            ),
          ),
          const SizedBox(height: 8),
          for (final record in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UpcomingVetVisitChip(record: record),
            ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: HealthUi.fieldBorder.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
        ],
        for (final (i, record) in _sortedVetAppointments.indexed) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: HealthUi.fieldBorder.withValues(alpha: 0.6),
            ),
          _VetAppointmentListTile(
            record: record,
            onTap: () => _openVetAppointmentSheet(
              mode: VetSheetMode.view,
              existing: record,
            ),
            onEdit: () => _openVetAppointmentSheet(
              mode: VetSheetMode.edit,
              existing: record,
            ),
            onDelete: () => _confirmDeleteVetAppointment(record),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDeleteMedication(MedicationRecord record) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kaydı sil'),
        content: Text(
          '"${record.displayTitle}" kaydını silmek istediğinize emin misiniz?',
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
    if (yes != true || !mounted) return;
    final id = record.id;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt kimliği bulunamadı. Sayfayı yenileyin.')),
      );
      return;
    }
    try {
      await MedicationApiService.delete(id);
      if (!mounted) return;
      await _loadMedications();
    } on MedicationApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlaç kaydı silinemedi.')),
      );
    }
  }


  Widget _buildVaccineSection() {
    if (_vaccinesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_vaccinesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _vaccinesError!,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: HealthUi.muted.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadVaccines,
            child: const Text('Yeniden dene'),
          ),
        ],
      );
    }

    if (_sortedVaccines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Henüz aşı kaydı yok. Sağ üstteki + ile ekleyin.',
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: HealthUi.muted.withValues(alpha: 0.9),
          ),
        ),
      );
    }

    final upcoming = _upcomingVaccines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (upcoming.isNotEmpty) ...[
          const Text(
            'YAKLAŞAN AŞILAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: HealthUi.accentPink,
            ),
          ),
          const SizedBox(height: 8),
          for (final record in upcoming)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UpcomingVaccineChip(record: record),
            ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: HealthUi.fieldBorder.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
        ],
        for (final (i, record) in _sortedVaccines.indexed) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: HealthUi.fieldBorder.withValues(alpha: 0.6),
            ),
          _VaccineListTile(
            record: record,
            onTap: () => _openVaccineSheet(
              mode: VaccineSheetMode.view,
              existing: record,
            ),
            onEdit: () => _openVaccineSheet(
              mode: VaccineSheetMode.edit,
              existing: record,
            ),
            onDelete: () => _confirmDeleteVaccine(record),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ColoredBox(
      color: HealthUi.pageBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          _HealthPageHeader(onBack: widget.onBackToHome),
          const SizedBox(height: 8),
          _HealthSectionCard(
            title: 'AŞI TAKİBİ',
            onAdd: _vaccinesLoading ? () {} : _openAddVaccine,
            child: _buildVaccineSection(),
          ),
          const SizedBox(height: 16),
          _HealthSectionCard(
            title: 'VETERİNER RANDEVULARI',
            onAdd: _vetVisitsLoading
                ? () {}
                : () => _openVetAppointmentSheet(mode: VetSheetMode.create),
            child: _buildVetVisitSection(),
          ),
          const SizedBox(height: 16),
          _HealthSectionCard(
            title: 'İLAÇ TAKİBİ',
            onAdd: () => _openMedicationSheet(),
            child: _medicationsLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  )
                : _medicationsError != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _medicationsError!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              color: HealthUi.muted.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadMedications,
                            child: const Text('Yeniden dene'),
                          ),
                        ],
                      )
                    : _sortedMedications.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Henüz ilaç kaydı yok. Sağ üstteki + ile ekleyin.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.35,
                                color: HealthUi.muted.withValues(alpha: 0.9),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              for (final (i, record)
                                  in _sortedMedications.indexed) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    color: HealthUi.fieldBorder
                                        .withValues(alpha: 0.6),
                                  ),
                                _MedicationListTile(
                                  record: record,
                                  onTap: () => _openMedicationSheet(
                                    mode: MedicationSheetMode.view,
                                    existing: record,
                                  ),
                                  onEdit: () =>
                                      _openMedicationSheet(
                                    mode: MedicationSheetMode.edit,
                                    existing: record,
                                  ),
                                  onDelete: () =>
                                      _confirmDeleteMedication(record),
                                ),
                              ],
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}

class _HealthPageHeader extends StatelessWidget {
  const _HealthPageHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: HealthUi.titleInk,
              iconSize: 20,
            ),
          ),
          Text(
            'Sağlık',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: HealthUi.titleInk,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _HealthSectionCard extends StatelessWidget {
  const _HealthSectionCard({
    required this.title,
    required this.onAdd,
    required this.child,
  });

  final String title;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HealthUi.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: HealthUi.titleInk,
                  ),
                ),
              ),
              Material(
                color: HealthUi.accentPink,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.add, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _UpcomingVaccineChip extends StatelessWidget {
  const _UpcomingVaccineChip({required this.record});

  final VaccineRecord record;

  @override
  Widget build(BuildContext context) {
    final next = record.nextVaccinationDate!;
    final catLabel = (record.catName?.isNotEmpty ?? false)
        ? ' · ${record.catName}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HealthUi.accentPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HealthUi.accentPink.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_outlined,
            size: 18,
            color: HealthUi.accentPink,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${record.name}$catLabel — ${formatTurkishDate(next)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HealthUi.titleInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingVetVisitChip extends StatelessWidget {
  const _UpcomingVetVisitChip({required this.record});

  final VetAppointmentRecord record;

  @override
  Widget build(BuildContext context) {
    final next = record.nextVisitDate!;
    final catLabel = (record.catName?.isNotEmpty ?? false)
        ? ' · ${record.catName}'
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: HealthUi.accentPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: HealthUi.accentPink.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_outlined,
            size: 18,
            color: HealthUi.accentPink,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${record.reason}$catLabel — ${formatTurkishDate(next)}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HealthUi.titleInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VaccineListTile extends StatelessWidget {
  const _VaccineListTile({
    required this.record,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final VaccineRecord record;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _catNameLabel {
    final n = record.catName?.trim();
    return (n != null && n.isNotEmpty) ? n : 'Kedi';
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      _catNameLabel,
      formatTurkishDate(record.vaccinationDate),
      if (record.nextVaccinationDate != null)
        'Sonraki: ${formatTurkishDate(record.nextVaccinationDate!)}',
    ];
    final notes = record.notes.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: HealthUi.accentPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.vaccines_outlined,
                      color: HealthUi.accentPink,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: HealthUi.titleInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleParts.join(' · '),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: HealthUi.muted,
                          ),
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: HealthUi.muted.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.more_vert,
              size: 22,
              color: HealthUi.muted.withValues(alpha: 0.85),
            ),
            tooltip: 'Düzenle',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: HealthUi.muted.withValues(alpha: 0.85),
            ),
            tooltip: 'Sil',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

class _VetAppointmentListTile extends StatelessWidget {
  const _VetAppointmentListTile({
    required this.record,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final VetAppointmentRecord record;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _catNameLabel {
    final n = record.catName?.trim();
    return (n != null && n.isNotEmpty) ? n : 'Kedi';
  }

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      _catNameLabel,
      formatTurkishDate(record.visitDate),
      '${record.weightKg.toStringAsFixed(1)} kg',
      if (record.nextVisitDate != null)
        'Sonraki: ${formatTurkishDate(record.nextVisitDate!)}',
    ];
    final notes = record.doctorNotes.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: HealthUi.accentPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: HealthUi.accentPink,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.reason,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: HealthUi.titleInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitleParts.join(' · '),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: HealthUi.muted,
                          ),
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            notes,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: HealthUi.muted.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.more_vert,
              size: 22,
              color: HealthUi.muted.withValues(alpha: 0.85),
            ),
            tooltip: 'Düzenle',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: HealthUi.muted.withValues(alpha: 0.85),
            ),
            tooltip: 'Sil',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

class _MedicationListTile extends StatelessWidget {
  const _MedicationListTile({
    required this.record,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final MedicationRecord record;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final active = record.isActive && record.daysRemaining > 0;
    final statusLabel = active ? 'Aktif' : 'Pasif';
    final remainingLabel = record.daysRemaining > 0
        ? 'Kalan: ${record.daysRemaining} Gün'
        : 'Süresi doldu';
    final freqTr = record.frequency == 'daily'
        ? 'Günlük'
        : record.frequency == 'weekly'
            ? 'Haftalık'
            : record.frequency == 'asNeeded'
                ? 'Gerektiğinde'
                : record.frequency;
    final subtitle = '$freqTr · $remainingLabel';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: HealthUi.accentPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medication_outlined,
                      color: HealthUi.accentPink,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.displayTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: HealthUi.titleInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: HealthUi.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              active ? HealthUi.accentPink : HealthUi.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(
              Icons.more_vert,
              size: 22,
              color: HealthUi.muted.withValues(alpha: 0.85),
            ),
            tooltip: 'Düzenle',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 22,
              color: HealthUi.muted.withValues(alpha: 0.85),
            ),
            tooltip: 'Sil',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
