import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _preferences;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _preferences ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _preferences?.setString(AppConstants.tokenKey, token);
  }

  String? getToken() {
    return _preferences?.getString(AppConstants.tokenKey);
  }

  Future<void> clearToken() async {
    await _preferences?.remove(AppConstants.tokenKey);
  }

  // User Profile Cache
  Future<void> saveUser(Map<String, dynamic> userMap) async {
    await _preferences?.setString(AppConstants.userKey, jsonEncode(userMap));
  }

  Map<String, dynamic>? getUser() {
    final raw = _preferences?.getString(AppConstants.userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUser() async {
    await _preferences?.remove(AppConstants.userKey);
  }

  // Theme Mode
  Future<void> saveThemeMode(String mode) async {
    await _preferences?.setString(AppConstants.themeModeKey, mode);
  }

  String getThemeMode() {
    return _preferences?.getString(AppConstants.themeModeKey) ?? 'system';
  }

  // Clear all
  Future<void> clearAll() async {
    await _preferences?.clear();
  }
}
