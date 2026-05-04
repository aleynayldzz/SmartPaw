import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../data/cat_breeds.dart';
import '../models/cat_profile.dart';
import 'auth_session.dart';

class CatApiException implements Exception {
  CatApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class CatApiService {
  CatApiService._();

  static Map<String, String> _headers({bool auth = false}) {
    final t = auth ? AuthSession.accessToken : null;
    return {
      'Content-Type': 'application/json',
      if (auth && t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  /// Yerel paketteki dosya yolu — önce [slug] ile `kCatBreeds` eşlemesi (en güvenilir).
  ///
  /// API’den gelen `avatar_url` yolu ile aynı olsa bile, web’de boş slug veya
  /// yanlış string yüzünden görünmeyebiliyordu; slug’a göre sabit liste öncelikli.
  static String assetPathForServer(String? avatarUrl, String slug) {
    final s = slug.trim();
    if (s.isNotEmpty) {
      final fromSlug = breedBySlug(s)?.assetPath;
      if (fromSlug != null) return fromSlug;
    }
    final a = avatarUrl?.trim();
    if (a != null && a.isNotEmpty) {
      if (a.startsWith('assets/')) return a;
      if (a.startsWith('/')) return a.replaceFirst(RegExp(r'^/+'), '');
    }
    return 'assets/images/breeds/ankara.png';
  }

  static CatBreedOption breedOptionFromJson(Map<String, dynamic> j) {
    final slug = j['slug']?.toString() ?? '';
    final name = j['breed_name']?.toString() ?? slug;
    final id = j['breed_id'];
    final bid = id is num ? id.toInt() : int.tryParse(id?.toString() ?? '');
    return CatBreedOption(
      breedId: bid,
      slug: slug,
      labelTr: name,
      assetPath: assetPathForServer(j['avatar_url']?.toString(), slug),
    );
  }

  static Future<List<CatBreedOption>> fetchBreeds() async {
    final res = await http.get(ApiConfig.catBreedsUri());
    final body = _decodeBody(res.body);
    if (res.statusCode != 200 || body['ok'] != true) {
      throw CatApiException(
        body['message']?.toString() ?? 'Irklar yüklenemedi.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map) {
      throw CatApiException('Geçersiz yanıt.', res.statusCode);
    }
    final list = data['breeds'];
    if (list is! List) {
      throw CatApiException('Irk listesi yok.', res.statusCode);
    }
    return list
        .whereType<Map>()
        .map((e) => breedOptionFromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  static Future<List<Map<String, dynamic>>> fetchMyCats() async {
    final res = await http.get(
      ApiConfig.catsUri(),
      headers: _headers(auth: true),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw CatApiException('Oturum süresi doldu veya giriş gerekli.', 401);
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw CatApiException(
        body['message']?.toString() ?? 'Kediler yüklenemedi.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['cats'] is! List) {
      return [];
    }
    return (data['cats'] as List)
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList(growable: false);
  }

  static Future<Map<String, dynamic>> createCat({
    required String name,
    required int breedId,
    required String birthDateIso,
    required bool isFemale,
    required double weightKg,
    required bool isNeutered,
  }) async {
    final res = await http.post(
      ApiConfig.catsUri(),
      headers: _headers(auth: true),
      body: jsonEncode({
        'name': name,
        'breed_id': breedId,
        'birth_date': birthDateIso,
        'gender': isFemale ? 'female' : 'male',
        'weight': weightKg,
        'is_neutered': isNeutered,
      }),
    );
    return _expectCatResponse(res);
  }

  static Future<Map<String, dynamic>> updateCatWeight(
    int catId,
    double weightKg,
  ) async {
    final res = await http.patch(
      ApiConfig.catUri(catId),
      headers: _headers(auth: true),
      body: jsonEncode({'weight': weightKg}),
    );
    return _expectCatResponse(res);
  }

  static Future<void> deleteCat(int catId) async {
    final res = await http.delete(
      ApiConfig.catUri(catId),
      headers: _headers(auth: true),
    );
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw CatApiException('Oturum süresi doldu veya giriş gerekli.', 401);
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw CatApiException(
        body['message']?.toString() ?? 'Silinemedi.',
        res.statusCode,
      );
    }
  }

  static Map<String, dynamic> _decodeBody(String raw) {
    if (raw.isEmpty) return {};
    try {
      final d = jsonDecode(raw);
      if (d is Map<String, dynamic>) return d;
      if (d is Map) return d.cast<String, dynamic>();
    } catch (_) {}
    return {};
  }

  static Map<String, dynamic> _expectCatResponse(http.Response res) {
    final body = _decodeBody(res.body);
    if (res.statusCode == 401) {
      throw CatApiException('Oturum süresi doldu veya giriş gerekli.', 401);
    }
    if (res.statusCode != 200 || body['ok'] != true) {
      throw CatApiException(
        body['message']?.toString() ?? 'İşlem başarısız.',
        res.statusCode,
      );
    }
    final data = body['data'];
    if (data is! Map || data['cat'] is! Map) {
      throw CatApiException('Geçersiz yanıt.', res.statusCode);
    }
    return (data['cat'] as Map).cast<String, dynamic>();
  }

  static DateTime parseBirthDate(dynamic raw) {
    if (raw == null) return DateTime(DateTime.now().year - 1, 6, 15);
    if (raw is DateTime) return DateTime(raw.year, raw.month, raw.day);
    final s = raw.toString();
    final iso = DateTime.tryParse(s);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    if (m != null) {
      final y = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final d = int.parse(m.group(3)!);
      return DateTime(y, mo, d);
    }
    return DateTime(DateTime.now().year - 1, 6, 15);
  }

  static CatFormInitial catToFormInitial(Map<String, dynamic> c) {
    final cid = (c['cat_id'] as num?)?.toInt() ??
        int.tryParse(c['cat_id']?.toString() ?? '') ??
        0;
    final bid = (c['breed_id'] as num?)?.toInt() ??
        int.tryParse(c['breed_id']?.toString() ?? '') ??
        0;
    final slug = c['slug']?.toString() ?? '';
    final gender = c['gender']?.toString().toLowerCase();
    final weight =
        (c['weight'] is num) ? (c['weight'] as num).toDouble() : double.tryParse(c['weight']?.toString() ?? '') ?? 4.0;
    return CatFormInitial(
      catId: cid,
      name: c['name']?.toString() ?? '',
      breedId: bid,
      breedSlug: slug,
      breedLabel: c['breed_name']?.toString() ?? slug,
      avatarUrl: c['avatar_url']?.toString(),
      birthDate: parseBirthDate(c['birth_date']),
      isFemale: gender == 'female',
      isNeutered: c['is_neutered'] == true,
      weightKg: weight,
    );
  }

  static CatDraft catMapToDraft(Map<String, dynamic> c) {
    final slug = c['slug']?.toString() ?? '';
    final breed = CatBreedOption(
      breedId: (c['breed_id'] as num?)?.toInt(),
      slug: slug,
      labelTr: c['breed_name']?.toString() ?? slug,
      assetPath: assetPathForServer(c['avatar_url']?.toString(), slug),
    );
    return CatDraft(
      catId: (c['cat_id'] as num?)?.toInt(),
      name: c['name']?.toString() ?? '',
      breed: breed,
      birthDate: parseBirthDate(c['birth_date']),
      isFemale: c['gender']?.toString().toLowerCase() == 'female',
      isNeutered: c['is_neutered'] == true,
      weightKg: (c['weight'] is num)
          ? (c['weight'] as num).toDouble()
          : double.tryParse(c['weight']?.toString() ?? '') ?? 4.0,
    );
  }
}
