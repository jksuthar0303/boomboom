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

  // Email OTP Storage (5 Minutes Expiry)
  static const String _keyOtpCode = 'email_otp_code';
  static const String _keyOtpTime = 'email_otp_timestamp';
  static const String _keyOtpEmail = 'email_otp_email';

  Future<void> saveEmailOtp({required String email, required String otp}) async {
    await _storage.write(key: _keyOtpEmail, value: email.trim().toLowerCase());
    await _storage.write(key: _keyOtpCode, value: otp.trim());
    await _storage.write(
      key: _keyOtpTime,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<Map<String, dynamic>> verifyEmailOtp({
    required String email,
    required String enteredOtp,
  }) async {
    final storedEmail = await _storage.read(key: _keyOtpEmail);
    final storedOtp = await _storage.read(key: _keyOtpCode);
    final storedTimeStr = await _storage.read(key: _keyOtpTime);

    if (storedEmail == null || storedOtp == null || storedTimeStr == null) {
      return {
        "success": false,
        "message": "No OTP found. Please request a new code.",
      };
    }

    if (storedEmail.trim().toLowerCase() != email.trim().toLowerCase()) {
      return {
        "success": false,
        "message": "Email mismatch. Please request a new OTP.",
      };
    }

    final int? storedTime = int.tryParse(storedTimeStr);
    if (storedTime == null) {
      return {
        "success": false,
        "message": "Invalid OTP session. Please request a new code.",
      };
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final int diffMs = now - storedTime;
    const int fiveMinutesMs = 5 * 60 * 1000; // 5 minutes

    if (diffMs > fiveMinutesMs) {
      return {
        "success": false,
        "message": "OTP has expired (valid for 5 minutes). Please resend OTP.",
      };
    }

    if (storedOtp.trim() != enteredOtp.trim()) {
      return {
        "success": false,
        "message": "Invalid OTP. Please enter the correct 6-digit code.",
      };
    }

    // OTP matched & valid
    return {
      "success": true,
      "message": "OTP verified successfully!",
    };
  }

  // Clear email OTP keys
  Future<void> clearEmailOtp([String? email]) async {
    await _storage.delete(key: _keyOtpEmail);
    await _storage.delete(key: _keyOtpCode);
    await _storage.delete(key: _keyOtpTime);
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
