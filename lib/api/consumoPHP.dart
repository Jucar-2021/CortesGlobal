import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = /*'http://dev-soluciones.com/api'*/ 'http://192.168.1.40/api2';

  Uri _uri(String endpoint) => Uri.parse('$baseUrl/$endpoint');

  Future<Map<String, dynamic>> postJson(
    String endpoint,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final res = await http
        .post(
          _uri(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);

    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }

    final responseBody = res.body.trim();

    if (responseBody.isEmpty) {
      throw Exception('El servidor devolvió una respuesta vacía.');
    }

    if (responseBody.startsWith('<')) {
      throw Exception(
          'El servidor devolvió HTML en lugar de JSON: $responseBody');
    }

    final decoded = jsonDecode(responseBody);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta no válida (no es JSON objeto): $responseBody');
    }

    if (decoded['ok'] != true) {
      throw Exception(decoded['error'] ?? decoded['mensaje'] ?? 'Error API');
    }

    return decoded;
  }

  Future<String> getRaw(String endpoint) async {
    final res = await http.get(_uri(endpoint));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    return res.body;
  }
}
