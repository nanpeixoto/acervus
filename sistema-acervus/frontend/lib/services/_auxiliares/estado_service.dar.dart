import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/_auxiliares/estado.dart';
import '../../utils/app_config.dart';
import '../_core/storage_service.dart';

class EstadoService {
  static const String baseUrl = AppConfig.devBaseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  // =============================
  // LISTAR (PAGINADO)
  // =============================
  static Future<Map<String, dynamic>> listar({
    int page = 1,
    int limit = 50,
    String? search,
    int? paisId,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }
    if (paisId != null) {
      queryParams['pais_id'] = paisId.toString();
    }

    final uri = Uri.parse('$baseUrl/estado/listar')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'estados': (data['dados'] as List)
            .map((json) => Estado.fromJson(json))
            .toList(),
        'pagination': data['pagination'],
      };
    } else {
      throw Exception('Erro ao listar estados');
    }
  }

  // =============================
  // LISTAR POR PAÍS (COMBO)
  // =============================
  static Future<List<Estado>> listarPorPais(int paisId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/estado/listar-por-pais/$paisId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((e) => Estado.fromJson(e))
          .toList();
    } else {
      throw Exception('Erro ao listar estados');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Estado estado) async {
    final response = await http.post(
      Uri.parse('$baseUrl/estado/cadastrar'),
      headers: await _getHeaders(),
      body: jsonEncode(estado.toJson()),
    );

    return response.statusCode == 201;
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Estado estado) async {
    final response = await http.put(
      Uri.parse('$baseUrl/estado/alterar/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(estado.toJson()),
    );

    return response.statusCode == 200;
  }
}
