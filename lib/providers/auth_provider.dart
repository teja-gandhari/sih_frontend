import 'package:flutter/material.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final SecureStorageService _storageService;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthProvider(this._authService, this._storageService);

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;

  Future<void> initialize() async {
    _setStatus(AuthStatus.loading);
    try {
      final token = await _storageService.getToken();
      if (token != null) {
        _currentUser = await _authService.getCurrentUser();
        _setStatus(AuthStatus.authenticated);
      } else {
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      await _storageService.deleteToken();
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      final token = await _authService.login(username, password);
      await _storageService.saveToken(token);
      _currentUser = await _authService.getCurrentUser();
      _setStatus(AuthStatus.authenticated);
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(AuthStatus.error);
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _setStatus(AuthStatus.loading);
    _errorMessage = null;
    try {
      await _authService.register(userData);
      // Registration only creates the account. Require an explicit login before
      // entering any authenticated screens.
      _setStatus(AuthStatus.unauthenticated);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setStatus(AuthStatus.error);
      return false;
    }
  }

  Future<void> logout() async {
    _setStatus(AuthStatus.loading);
    await _storageService.deleteToken();
    _currentUser = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
