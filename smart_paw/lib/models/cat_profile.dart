import '../data/cat_breeds.dart';

/// Kayıttan sonra veya güncelleme sonrası kullanıcıya gösterilen özet.
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
  final int? catId;
}

/// Sunucudan gelen kediyi düzenleme ekranına aktarmak için.
class CatFormInitial {
  const CatFormInitial({
    required this.catId,
    required this.name,
    required this.breedId,
    required this.breedSlug,
    required this.breedLabel,
    required this.birthDate,
    required this.isFemale,
    required this.isNeutered,
    required this.weightKg,
    this.avatarUrl,
  });

  final int catId;
  final String name;
  final int breedId;
  final String breedSlug;
  final String breedLabel;

  /// API `avatar_url` (mobilde `assets/...`).
  final String? avatarUrl;
  final DateTime birthDate;
  final bool isFemale;
  final bool isNeutered;
  final double weightKg;
}

/// [Navigator.pop] ile dönüş.
class AddCatNavResult {
  AddCatNavResult.saved(this.draft) : deletedCatId = null;

  AddCatNavResult.deleted(this.deletedCatId) : draft = null;

  final CatDraft? draft;
  final int? deletedCatId;
}
