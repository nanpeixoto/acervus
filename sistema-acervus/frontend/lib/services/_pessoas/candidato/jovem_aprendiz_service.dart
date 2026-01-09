import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/_pessoas/candidato/jovem_aprendiz.dart';
import '../../_core/storage_service.dart';

class JovemAprendizService {
  static const String baseUrl = 'http://localhost:3001/api';

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Listar jovens aprendizes (com paginação e filtros)
  static Future<Map<String, dynamic>> listarJovensAprendizes({
    int page = 1,
    int limit = 10,
    String? search,
    String? curso,
    String? status,
    String? instituicaoId,
    bool? ativo,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (curso != null) queryParams['curso'] = curso;
      if (status != null) queryParams['status'] = status;
      if (instituicaoId != null) queryParams['instituicao'] = instituicaoId;
      if (ativo != null) queryParams['ativo'] = ativo.toString();

      final uri = Uri.parse('$baseUrl/jovens-aprendizes').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'jovensAprendizes': (data['data']['jovensAprendizes'] as List)
              .map((json) => JovemAprendiz.fromJson(json))
              .toList(),
          'pagination': data['data']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar jovens aprendizes');
      }
    } catch (e) {
      throw Exception('Erro ao carregar jovens aprendizes: $e');
    }
  }

  // Buscar jovem aprendiz por ID
  static Future<JovemAprendiz> buscarJovemAprendiz(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/jovens-aprendizes/$id'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return JovemAprendiz.fromJson(data['data']);
      } else {
        throw Exception('Jovem Aprendiz não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar jovem aprendiz: $e');
    }
  }

  // Criar jovem aprendiz
  static Future<bool> criarJovemAprendiz(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/jovens-aprendizes'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );
      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar jovem aprendiz: $e');
    }
  }

  // Atualizar jovem aprendiz
  static Future<bool> atualizarJovemAprendiz(String id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/jovens-aprendizes/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar jovem aprendiz: $e');
    }
  }

  // Deletar jovem aprendiz
  static Future<bool> deletarJovemAprendiz(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/jovens-aprendizes/$id'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao deletar jovem aprendiz: $e');
    }
  }

  // Ativar jovem aprendiz
  static Future<bool> ativarJovemAprendiz(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/jovens-aprendizes/$id/ativar'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao ativar jovem aprendiz: $e');
    }
  }

  // Desativar jovem aprendiz
  static Future<bool> desativarJovemAprendiz(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/jovens-aprendizes/$id/desativar'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar jovem aprendiz: $e');
    }
  }
}