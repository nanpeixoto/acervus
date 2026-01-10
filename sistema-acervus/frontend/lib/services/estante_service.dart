import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:sistema_estagio/models/estante.dart';
import '../utils/app_config.dart';
import 'storage_service.dart';

class EstanteService {
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
    int limit = 10,
    String? search,
    int? salaId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['q'] = search;
      }
      if (salaId != null) {
        queryParams['cd_sala'] = salaId.toString();
      }

      final uri = Uri.parse('$baseUrl/estante/listar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'Estantes':
              (data['dados'] as List).map((e) => Estante.fromJson(e)).toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao listar estantes');
      }
    } catch (e) {
      throw Exception('Erro ao listar estantes: $e');
    }
  }

  // =============================
  // BUSCAR POR ID
  // =============================
  static Future<Estante> buscarPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estante/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Estante.fromJson(data['dados']);
      } else {
        throw Exception('Estante não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao buscar estante: $e');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Estante estante) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estante/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(estante.toJson()),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar estante');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao criar estante: $e');
    }
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Estante estante) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/estante/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(estante.toJson()),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao atualizar estante');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao atualizar estante: $e');
    }
  }

  // =============================
  // EXCLUIR
  // =============================
  static Future<bool> excluir(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/estante/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir estante: $e');
    }
  }
}
