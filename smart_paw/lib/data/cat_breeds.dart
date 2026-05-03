/// Sabit kedi ırkı listesi; görseller [assetPath] üzerinden yüklenir (ileride DB ile eşlenebilir).
class CatBreedOption {
  const CatBreedOption({
    required this.slug,
    required this.labelTr,
    required this.assetPath,
  });

  /// Dosya tabanlı kimlik (`ankara`, `british_shorthair`).
  final String slug;

  /// Arayüzde gösterilen Türkçe / yerelleştirilmiş ad.
  final String labelTr;

  final String assetPath;
}

/// Kullanıcı ırk listesi; alfabetik (Türkçe locale yaklaşık).
const List<CatBreedOption> kCatBreeds = [
  CatBreedOption(slug: 'ankara', labelTr: 'Ankara', assetPath: 'assets/images/breeds/ankara.png'),
  CatBreedOption(slug: 'balinese', labelTr: 'Balinese', assetPath: 'assets/images/breeds/balinese.png'),
  CatBreedOption(slug: 'bengal', labelTr: 'Bengal', assetPath: 'assets/images/breeds/bengal.png'),
  CatBreedOption(slug: 'birman', labelTr: 'Birman', assetPath: 'assets/images/breeds/birman.jpeg'),
  CatBreedOption(slug: 'bombay', labelTr: 'Bombay', assetPath: 'assets/images/breeds/bombay.png'),
  CatBreedOption(
    slug: 'british_shorthair',
    labelTr: 'British Shorthair',
    assetPath: 'assets/images/breeds/british_shorthair.png',
  ),
  CatBreedOption(slug: 'cornish_rex', labelTr: 'Cornish Rex', assetPath: 'assets/images/breeds/cornish_rex.png'),
  CatBreedOption(slug: 'devon_rex', labelTr: 'Devon Rex', assetPath: 'assets/images/breeds/devon_rex.png'),
  CatBreedOption(
    slug: 'egzotik_shorthair',
    labelTr: 'Egzotik Shorthair',
    assetPath: 'assets/images/breeds/egzotik_shorthair.png',
  ),
  CatBreedOption(slug: 'habes', labelTr: 'Habeş', assetPath: 'assets/images/breeds/habes.png'),
  CatBreedOption(slug: 'himalayan', labelTr: 'Himalayan', assetPath: 'assets/images/breeds/himalayan.png'),
  CatBreedOption(
    slug: 'japon_kivrik_kuyruk',
    labelTr: 'Japon Kıvrık Kuyruk',
    assetPath: 'assets/images/breeds/japon_kivrik_kuyruk.png',
  ),
  CatBreedOption(slug: 'korat', labelTr: 'Korat', assetPath: 'assets/images/breeds/korat.png'),
  CatBreedOption(slug: 'laperm', labelTr: 'Laperm', assetPath: 'assets/images/breeds/laperm.png'),
  CatBreedOption(slug: 'maine_coon', labelTr: 'Maine Coon', assetPath: 'assets/images/breeds/maine_coon.png'),
  CatBreedOption(slug: 'mavi_rus', labelTr: 'Mavi Rus', assetPath: 'assets/images/breeds/mavi_rus.png'),
  CatBreedOption(
    slug: 'norvec_orman',
    labelTr: 'Norveç Orman',
    assetPath: 'assets/images/breeds/norvec_orman.png',
  ),
  CatBreedOption(slug: 'ocicat', labelTr: 'Ocicat', assetPath: 'assets/images/breeds/ocicat.png'),
  CatBreedOption(
    slug: 'oriental_shorthair',
    labelTr: 'Oriental Shorthair',
    assetPath: 'assets/images/breeds/oriental_shorthair.png',
  ),
  CatBreedOption(slug: 'pixie_bob', labelTr: 'Pixie Bob', assetPath: 'assets/images/breeds/pixie_bob.png'),
  CatBreedOption(slug: 'ragdoll', labelTr: 'Ragdoll', assetPath: 'assets/images/breeds/ragdoll.png'),
  CatBreedOption(
    slug: 'scottish_fold',
    labelTr: 'Scottish Fold',
    assetPath: 'assets/images/breeds/scottish_fold.png',
  ),
  CatBreedOption(slug: 'sfenks', labelTr: 'Sfenks', assetPath: 'assets/images/breeds/sfenks.png'),
  CatBreedOption(slug: 'siam', labelTr: 'Siam', assetPath: 'assets/images/breeds/siam.png'),
  CatBreedOption(slug: 'sibirya', labelTr: 'Sibirya', assetPath: 'assets/images/breeds/sibirya.png'),
  CatBreedOption(slug: 'tekir', labelTr: 'Tekir', assetPath: 'assets/images/breeds/tekir.png'),
  CatBreedOption(slug: 'tonkinese', labelTr: 'Tonkinese', assetPath: 'assets/images/breeds/tonkinese.png'),
  CatBreedOption(slug: 'van', labelTr: 'Van', assetPath: 'assets/images/breeds/van.png'),
  CatBreedOption(slug: 'iran', labelTr: 'İran', assetPath: 'assets/images/breeds/iran.png'),
];

CatBreedOption? breedBySlug(String slug) {
  for (final b in kCatBreeds) {
    if (b.slug == slug) return b;
  }
  return null;
}
