import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:3000';

  static Future<List<dynamic>> getMarkers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/markers'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al cargar markers');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}