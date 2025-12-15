import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';
import 'api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Make a GET request with authorization
  static Future<dynamic> get(String endpoint) async {
    final token = await AuthService().getToken();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Make a POST request with authorization
  static Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final token = await AuthService().getToken();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Make a PUT request with authorization
  static Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final token = await AuthService().getToken();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Make a DELETE request with authorization
  static Future<dynamic> delete(String endpoint) async {
    final token = await AuthService().getToken();
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body);
      } catch (e) {
        return {'status': 'success'};
      }
    } else if (response.statusCode == 401) {
      AuthService().logout();
      throw Exception('Unauthorized');
    } else {
      try {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Unknown error');
      } catch (e) {
        throw Exception('Error: ${response.statusCode}');
      }
    }
  }
}
