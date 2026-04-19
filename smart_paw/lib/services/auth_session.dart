import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

enum AuthRestoreOutcome {
  /// Depoda oturum yoktu veya erişim token’ı yoktu.
  noSession,

  /// Access token geçerli; kullanıcı ve tokenlar yüklendi.
  validSession,

  /// Access token süresi dolmuş veya JWT okunamadı; depo temizlendi.
  clearedExpiredSession,
}

class AuthSession {
  AuthSession._();

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user_json';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? user;

  /// Same as [accessToken]; kept for older call sites.
  static String? get token => _accessToken;

  static String? get accessToken => _accessToken;

  static String? get refreshToken => _refreshToken;

  static Future<AuthRestoreOutcome> restore() async {
    _accessToken = await _storage.read(key: _kAccess);
    _refreshToken = await _storage.read(key: _kRefresh);
    final userJson = await _storage.read(key: _kUser);

    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson);
        if (decoded is Map<String, dynamic>) {
          user = decoded;
        } else if (decoded is Map) {
          user = decoded.cast<String, dynamic>();
        } else {
          user = null;
        }
      } catch (_) {
        user = null;
      }
    } else {
      user = null;
    }

    final access = _accessToken;
    if (access == null || access.isEmpty) {
      await clear();
      return AuthRestoreOutcome.noSession;
    }

    try {
      if (JwtDecoder.isExpired(access)) {
        await clear();
        return AuthRestoreOutcome.clearedExpiredSession;
      }
    } catch (_) {
      await clear();
      return AuthRestoreOutcome.clearedExpiredSession;
    }

    return AuthRestoreOutcome.validSession;
  }

  static Future<void> setSession({
    required String accessToken,
    String? refreshToken,
    Map<String, dynamic>? userPayload,
  }) async {
    _accessToken = accessToken;
    _refreshToken = (refreshToken != null && refreshToken.isNotEmpty)
        ? refreshToken
        : null;
    user = userPayload;

    await _storage.write(key: _kAccess, value: accessToken);
    if (_refreshToken != null) {
      await _storage.write(key: _kRefresh, value: _refreshToken!);
    } else {
      await _storage.delete(key: _kRefresh);
    }
    if (userPayload != null) {
      await _storage.write(key: _kUser, value: jsonEncode(userPayload));
    } else {
      await _storage.delete(key: _kUser);
    }
  }

  static Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    user = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kUser);
  }
}
