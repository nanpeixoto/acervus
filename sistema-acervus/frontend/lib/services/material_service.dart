import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:sistema_estagio/models/material.dart';

import '../utils/app_config.dart';
import 'storage_service.dart';

class MateriaisService {
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
  static Future<Map<String, dynamic>> listarMateriais({
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

      final uri = Uri.parse('$baseUrl/Materiais/listar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'materiais': (data['dados'] as List)
              .map((json) => Materiais.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar materiais');
      }
    } catch (e) {
      throw Exception('Erro ao carregar materiais: $e');
    }
  }

  // =============================
  // BUSCAR
  // =============================
  static Future<List<Materiais>> buscarMateriais(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/Materiais/listar')
          .replace(queryParameters: {'q': query});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => Materiais.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar Materiais');
      }
    } catch (e) {
      throw Exception('Erro ao buscar Materiais: $e');
    }
  }

  // =============================
  // BUSCAR POR ID
  // =============================
  static Future<Materiais> buscarMateriaisPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Materiais/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Materiais.fromJson(data['dados']);
      } else {
        throw Exception('Materiais não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar Materiais: $e');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Materiais/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar Materiais');
      }

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar Materiais: $e');
    }
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Materiais/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao atualizar Materiais');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao atualizar Materiais: $e');
    }
  }

  // =============================
  // ATIVAR / DESATIVAR
  // =============================
  static Future<bool> ativarMateriais(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Materiais/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao ativar Materiais: $e');
    }
  }

  static Future<bool> desativarMateriais(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Materiais/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar Materiais: $e');
    }
  }

  // =============================
  // EXCLUIR
  // =============================
  static Future<bool> deletarMateriais(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/Materiais/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir Materiais: $e');
    }
  }

  // =============================
  // EXPORTAR CSV
  // =============================
  static Future<String?> exportarCSV({bool? ativo}) async {
    try {
      final queryParams = <String, String>{};
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri = Uri.parse('$baseUrl/Materiais/exportar/csv')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final filename =
            'materiais_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(bytes, filename: filename);

        return savedPath;
      } else {
        throw Exception('Erro ao exportar CSV');
      }
    } catch (e) {
      throw Exception('Erro ao exportar materiais: $e');
    }
  }
}
