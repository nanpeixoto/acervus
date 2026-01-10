import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../models/_auxiliares/cidade.dart';
import '../../utils/app_config.dart';
import '../_core/storage_service.dart';

class CidadeService {
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
    int? estadoId,
    int? paisId,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }
    if (estadoId != null) {
      queryParams['estado_id'] = estadoId.toString();
    }
    if (paisId != null) {
      queryParams['pais_id'] = paisId.toString();
    }

    final uri = Uri.parse('$baseUrl/cidade/listar')
        .replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'cidades': (data['dados'] as List)
            .map((json) => Cidade.fromJson(json))
            .toList(),
        'pagination': data['pagination'],
      };
    } else {
      throw Exception('Erro ao listar cidades');
    }
  }

  // =============================
  // LISTAR SIMPLES (TELA)
  // =============================
  static Future<List<Cidade>> listarCidades() async {
    final uri = Uri.parse('$baseUrl/cidade/listar').replace(
        queryParameters: {'page': '1', 'limit': '500', 'confirms': 'true'});

    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['dados'] as List).map((e) => Cidade.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao listar cidades');
    }
  }

  // =============================
  // LISTAR POR ESTADO (COMBO)
  // =============================
  static Future<List<Cidade>> listarPorEstado(int estadoId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/cidade/listar-por-estado/$estadoId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((e) => Cidade.fromJson(e))
          .toList();
    } else {
      throw Exception('Erro ao listar cidades');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Cidade cidade) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cidade/cadastrar'),
      headers: await _getHeaders(),
      body: jsonEncode(cidade.toJson()),
    );

    return response.statusCode == 201;
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Cidade cidade) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cidade/alterar/$id'),
      headers: await _getHeaders(),
      body: jsonEncode(cidade.toJson()),
    );

    return response.statusCode == 200;
  }
}
