import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<String> login(String username, String password) async {
    final response = await _apiClient.post(
      '/users/login',
      body: {'phone_number': username, 'password': password},
    );
    return response['access_token'];
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await _apiClient.post('/users/register', body: userData);
    return Map<String, dynamic>.from(response);
  }

  Future<UserModel> getCurrentUser() async {
    final response = await _apiClient.get('/users/me');
    return UserModel.fromJson(response);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _apiClient.put('/users/profile', body: profileData);
    return UserModel.fromJson(response);
  }
}
