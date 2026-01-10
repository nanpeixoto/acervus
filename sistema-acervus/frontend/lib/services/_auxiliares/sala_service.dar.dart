import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:sistema_estagio/models/_auxiliares/sala_obra.dart';
import '../../utils/app_config.dart';
import '../_core/storage_service.dart';

class SalaService {
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
    bool? ativo,
  }) async {
    try {
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

      final uri = Uri.parse('$baseUrl/sala/listar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'Salas': (data['dados'] as List)
              .map((json) => Sala.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar Salas');
      }
    } catch (e) {
      throw Exception('Erro ao carregar Salas: $e');
    }
  }

  // =============================
  // BUSCAR POR ID
  // =============================
  static Future<Sala> buscarPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sala/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Sala.fromJson(data['dados']);
      } else {
        throw Exception('Sala não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao buscar Sala: $e');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sala/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar Sala');
      }

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar Sala: $e');
    }
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sala/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao atualizar Sala');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao atualizar Sala: $e');
    }
  }

  // =============================
  // ATIVAR / DESATIVAR
  // =============================
  static Future<bool> ativarSala(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sala/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao alterar status da Sala: $e');
    }
  }

  // =============================
  // EXCLUIR (se existir)
  // =============================
  static Future<bool> deletarSala(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/sala/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir Sala: $e');
    }
  }
}
