import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../app/constants.dart';
import '../storage/secure_storage_service.dart';
import 'api_exception.dart';

class ApiClient {
  final SecureStorageService _storageService;
  final http.Client _client;

  ApiClient(this._storageService, {http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storageService.getToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return json.decode(response.body);
      }
      return null;
    } else {
      String errorMessage = 'Something went wrong';
      try {
        final decodedBody = json.decode(response.body);
        if (decodedBody is Map && decodedBody.containsKey('detail')) {
          errorMessage = decodedBody['detail'].toString();
        } else if (decodedBody is Map && decodedBody.containsKey('message')) {
          errorMessage = decodedBody['message'].toString();
        }
      } catch (_) {
        errorMessage = response.body.isNotEmpty ? response.body : response.reasonPhrase ?? errorMessage;
      }
      throw ApiException(errorMessage, response.statusCode);
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, bool isUrlEncoded = false}) async {
    try {
      final headers = await _getHeaders();
      if (isUrlEncoded) {
        headers['Content-Type'] = 'application/x-www-form-urlencoded';
      }
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      
      String? encodedBody;
      if (body != null) {
        if (isUrlEncoded && body is Map<String, dynamic>) {
           encodedBody = body.keys.map((key) => '$key=${Uri.encodeComponent(body[key].toString())}').join('&');
        } else {
           encodedBody = json.encode(body);
        }
      }

      final response = await _client
          .post(url, headers: headers, body: encodedBody)
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .put(url, headers: headers, body: body != null ? json.encode(body) : null)
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
  
  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .patch(url, headers: headers, body: body != null ? json.encode(body) : null)
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
      final response = await _client
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: AppConstants.apiTimeoutSeconds));
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('No Internet connection');
    } on TimeoutException {
      throw ApiException('Request timed out');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}
