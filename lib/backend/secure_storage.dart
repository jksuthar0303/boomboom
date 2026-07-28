import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyFcmToken = 'fcm_token';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserToken = 'user_token';
  static const String _keyUserPassword = 'user_password';

  // FCM Token
  Future<void> saveFcmToken(String token) async {
    await _storage.write(key: _keyFcmToken, value: token);
  }

  Future<String?> getFcmToken() async {
    return await _storage.read(key: _keyFcmToken);
  }

  // User Email
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  // User Token
  Future<void> saveUserToken(String token) async {
    await _storage.write(key: _keyUserToken, value: token);
  }

  Future<String?> getUserToken() async {
    return await _storage.read(key: _keyUserToken);
  }

  // User Password
  Future<void> saveUserPassword(String password) async {
    await _storage.write(key: _keyUserPassword, value: password);
  }

  Future<String?> getUserPassword() async {
    return await _storage.read(key: _keyUserPassword);
  }

  // Profile JSON
  Future<void> saveProfileJson(String jsonStr) async {
    await _storage.write(key: 'profile_json', value: jsonStr);
  }

  Future<String?> getProfileJson() async {
    return await _storage.read(key: 'profile_json');
  }

  // Interest Map (maps interest name to server record ID)
  Future<void> saveInterestMap(String jsonStr) async {
    await _storage.write(key: 'interest_map', value: jsonStr);
  }

  Future<String?> getInterestMap() async {
    return await _storage.read(key: 'interest_map');
  }

  // Delete specific keys
  Future<void> deleteKey(String key) async {
    await _storage.delete(key: key);
  }

  // Clear all storage
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
