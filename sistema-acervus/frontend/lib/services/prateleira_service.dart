import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prateleira.dart';
import '../utils/app_config.dart';
import 'storage_service.dart';

class PrateleiraService {
  static const String baseUrl = AppConfig.devBaseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  static Future<List<Prateleira>> listar() async {
    final response = await http.get(
      Uri.parse('$baseUrl/estante/prateleira/listar'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return (data['dados'] as List)
          .map((e) => Prateleira.fromJson(e))
          .toList();
    } else {
      throw Exception('Erro ao listar prateleiras');
    }
  }
}
