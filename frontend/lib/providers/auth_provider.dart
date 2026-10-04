import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, authenticating, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  final StorageService storageService;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthProvider(this.apiClient, this.storageService);

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<void> checkAuthStatus() async {
    final token = storageService.getToken();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final res = await apiClient.get(ApiConstants.me);
      _currentUser = UserModel.fromJson(res.data);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await storageService.clearToken();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        ApiConstants.login,
        data: {
          'username_or_email': usernameOrEmail.trim(),
          'password': password,
        },
      );

      final token = res.data['access_token'];
      await storageService.saveToken(token);

      // Fetch profile
      final meRes = await apiClient.get(ApiConstants.me);
      _currentUser = UserModel.fromJson(meRes.data);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    String? username,
    required String password,
  }) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await apiClient.post(
        ApiConstants.register,
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'username': username?.trim(),
          'password': password,
        },
      );

      final token = res.data['access_token'];
      await storageService.saveToken(token);

      final meRes = await apiClient.get(ApiConstants.me);
      _currentUser = UserModel.fromJson(meRes.data);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.post(ApiConstants.logout);
    } catch (_) {}
    await storageService.clearToken();
    await storageService.clearUser();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    try {
      final res = await apiClient.get(ApiConstants.me);
      _currentUser = UserModel.fromJson(res.data);
      notifyListeners();
    } catch (_) {}
  }
}
