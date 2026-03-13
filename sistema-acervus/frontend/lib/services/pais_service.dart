import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/pais.dart';
import '../utils/app_config.dart';
import 'storage_service.dart';

class PaisService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // =============================
  // HEADERS
  // =============================
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
    bool? ativo,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }

    if (ativo != null) {
      queryParams['ativo'] = ativo.toString();
    }

    final uri =
        Uri.parse('$baseUrl/pais/listar').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'paises':
            (data['dados'] as List).map((json) => Pais.fromJson(json)).toList(),
        'pagination': data['pagination'],
      };
    } else {
      throw Exception('Erro ao listar países');
    }
  }

  // =============================
  // LISTAR SIMPLES (COMBO)
  // =============================
  static Future<List<Pais>> listarSimples() async {
    final response = await http.get(
      Uri.parse('$baseUrl/pais/listar-simples'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((e) => Pais.fromJson(e))
          .toList();
    } else {
      throw Exception('Erro ao listar países');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Pais pais) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pais/cadastrar'),
      headers: await _getHeaders(),
      body: jsonEncode(pais.toJson()),
    );

    return response.statusCode == 201;
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Pais pais) async {
    final response = await http.put(
      Uri.parse('$baseUrl/pais/alterar/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(pais.toJson()),
    );

    return response.statusCode == 200;
  }
}
