import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_session.dart';

class AuthApiService {
  AuthApiService._();

  /// Kayıtlı profili sunucudan çeker ve [AuthSession] içindeki kullanıcıyı günceller.
  /// Ağ veya 401 durumunda false döner; mevcut önbellek korunur.
  static Future<bool> refreshProfileFromServer() async {
    final token = AuthSession.accessToken;
    if (token == null || token.isEmpty) return false;

    try {
      final res = await http.get(
        ApiConfig.authMeUri(),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) return false;

      Map<String, dynamic> body = {};
      if (res.body.isNotEmpty) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        } else if (decoded is Map) {
          body = decoded.cast<String, dynamic>();
        }
      }

      if (body['ok'] != true) return false;

      final data = body['data'];
      if (data is! Map) return false;

      final userRaw = data['user'];
      if (userRaw is! Map) return false;
      final user = userRaw.cast<String, dynamic>();

      await AuthSession.setSession(
        accessToken: token,
        refreshToken: AuthSession.refreshToken,
        userPayload: user,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
