// lib/services/_auxiliares/Assunto_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:sistema_estagio/models/assunto.dart';
import '../utils/app_config.dart';
import 'storage_service.dart';

class AssuntoService {
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
  static Future<Map<String, dynamic>> listarAssuntos({
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

      final uri = Uri.parse('$baseUrl/assunto/listar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'Assuntos': (data['dados'] as List)
              .map((json) => Assunto.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar Assuntos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar Assuntos: $e');
    }
  }

  // =============================
  // BUSCAR
  // =============================
  static Future<List<Assunto>> buscarAssuntos(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/assunto/listar')
          .replace(queryParameters: {'q': query});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => Assunto.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar Assunto');
      }
    } catch (e) {
      throw Exception('Erro ao buscar Assunto: $e');
    }
  }

  // =============================
  // BUSCAR POR ID
  // =============================
  static Future<Assunto> buscarAssuntoPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assunto/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Assunto.fromJson(data['dados']);
      } else {
        throw Exception('Assunto não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar Assunto: $e');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criarAssunto(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assunto/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar Assunto');
      }

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar Assunto: $e');
    }
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizarAssunto(
      int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assunto/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao atualizar Assunto');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao atualizar Assunto: $e');
    }
  }

  // =============================
  // ATIVAR / DESATIVAR
  // =============================
  static Future<bool> ativarAssunto(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assunto/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao ativar Assunto: $e');
    }
  }

  static Future<bool> desativarAssunto(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assunto/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar Assunto: $e');
    }
  }

  // =============================
  // EXCLUIR
  // =============================
  static Future<bool> deletarAssunto(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/assunto/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir Assunto: $e');
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

      final uri = Uri.parse('$baseUrl/assunto/exportar/csv')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final filename =
            'Assuntos_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(bytes, filename: filename);

        return savedPath;
      } else {
        throw Exception('Erro ao exportar CSV');
      }
    } catch (e) {
      throw Exception('Erro ao exportar Assuntos: $e');
    }
  }
}
