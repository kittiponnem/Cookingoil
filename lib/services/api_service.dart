import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiConfig {
  // TODO: Replace with actual middleware API base URL
  static const String baseUrl = 'https://your-middleware-api.azurewebsites.net/api';
  
  // API endpoints
  static const String authLogin = '/auth/login';
  static const String catalogProducts = '/catalog/products';
  static const String orders = '/orders';
  static const String pickups = '/pickups';
  static const String dispatchJobs = '/dispatch/jobs';
  static const String documents = '/documents';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  final http.Client _client;
  String? _authToken;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  void setAuthToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else {
      throw ApiException(
        'API request failed: ${response.body}',
        response.statusCode,
      );
    }
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      final response = await _client.get(uri, headers: _headers);
      return await _handleResponse(response);
    } catch (e) {
      throw ApiException('GET request failed: $e');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client.post(
        uri,
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );
      return await _handleResponse(response);
    } catch (e) {
      throw ApiException('POST request failed: $e');
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client.put(
        uri,
        headers: _headers,
        body: body != null ? json.encode(body) : null,
      );
      return await _handleResponse(response);
    } catch (e) {
      throw ApiException('PUT request failed: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final response = await _client.delete(uri, headers: _headers);
      return await _handleResponse(response);
    } catch (e) {
      throw ApiException('DELETE request failed: $e');
    }
  }
}
