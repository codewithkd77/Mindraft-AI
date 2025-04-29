import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _sessionKey = 'supabase_session';
  static const _refreshTokenKey = 'supabase_refresh_token';

  static Future<void> saveSession(Session session) async {
    print('Saving session: ${session.toJson()}');
    final sessionData = {
      'access_token': session.accessToken,
      'user': session.user.toJson(),
    };
    final sessionJson = jsonEncode(sessionData);
    print('Encoded session: $sessionJson');
    await _storage.write(key: _sessionKey, value: sessionJson);

    // Store refresh token separately
    if (session.refreshToken != null) {
      print('Saving refresh token');
      await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
    }
    print('Session saved successfully');
  }

  static Future<Session?> getSession() async {
    print('Attempting to get saved session...');
    final sessionString = await _storage.read(key: _sessionKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    print('Retrieved session string: $sessionString');
    print('Retrieved refresh token: $refreshToken');

    if (sessionString == null) {
      print('No saved session found');
      return null;
    }

    try {
      final sessionMap = jsonDecode(sessionString) as Map<String, dynamic>;
      print('Parsed session map: $sessionMap');

      if (sessionMap['access_token'] == null || sessionMap['user'] == null) {
        print('Missing required session data');
        return null;
      }

      final user = User.fromJson(sessionMap['user']);
      if (user == null) {
        print('Failed to parse user data');
        return null;
      }

      if (refreshToken == null) {
        print('No refresh token found');
        return null;
      }

      return Session(
        accessToken: sessionMap['access_token'],
        refreshToken: refreshToken,
        user: user,
        tokenType: 'bearer',
      );
    } catch (e) {
      print('Error parsing session: $e');
      return null;
    }
  }

  static Future<void> clearSession() async {
    print('Clearing saved session...');
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _refreshTokenKey);
    print('Session cleared successfully');
  }
}
