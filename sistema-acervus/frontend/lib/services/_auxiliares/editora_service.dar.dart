import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:sistema_estagio/models/_auxiliares/editora.dart';
import '../../utils/app_config.dart';
import '../_core/storage_service.dart';

class EditoraService {
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
    int? paisId,
    int? estadoId,
    int? cidadeId,
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
      if (paisId != null) {
        queryParams['pais_id'] = paisId.toString();
      }
      if (estadoId != null) {
        queryParams['estado_id'] = estadoId.toString();
      }
      if (cidadeId != null) {
        queryParams['cidade_id'] = cidadeId.toString();
      }

      final uri = Uri.parse('$baseUrl/editora/listar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'Editoras': (data['dados'] as List)
              .map((json) => Editora.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar Editoras');
      }
    } catch (e) {
      throw Exception('Erro ao carregar Editoras: $e');
    }
  }

  // =============================
  // BUSCAR
  // =============================
  static Future<List<Editora>> buscar(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/editora/listar')
          .replace(queryParameters: {'q': query});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => Editora.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar Editora');
      }
    } catch (e) {
      throw Exception('Erro ao buscar Editora: $e');
    }
  }

  // =============================
  // BUSCAR POR ID
  // =============================
  static Future<Editora> buscarPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/editora/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Editora.fromJson(data['dados']);
      } else {
        throw Exception('Editora não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao buscar Editora: $e');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/editora/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar Editora');
      }

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar Editora: $e');
    }
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/editora/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao atualizar Editora');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao atualizar Editora: $e');
    }
  }

  // =============================
  // ATIVAR / DESATIVAR
  // =============================
  static Future<bool> ativar(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/editora/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao alterar status da Editora: $e');
    }
  }

  static Future<bool> desativar(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/editora/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao alterar status da Editora: $e');
    }
  }

  // =============================
  // EXCLUIR (SE EXISTIR)
  // =============================
  static Future<bool> deletar(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/editora/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir Editora: $e');
    }
  }

  // =============================
  // EXPORTAR CSV
  // =============================
  static Future<String?> exportarCSV({
    bool? ativo,
    int? paisId,
    int? estadoId,
    int? cidadeId,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (ativo != null) queryParams['ativo'] = ativo.toString();
      if (paisId != null) queryParams['pais_id'] = paisId.toString();
      if (estadoId != null) queryParams['estado_id'] = estadoId.toString();
      if (cidadeId != null) queryParams['cidade_id'] = cidadeId.toString();

      final uri = Uri.parse('$baseUrl/editora/exportar/csv')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final filename =
            'Editoras_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(
          bytes,
          filename: filename,
        );

        return savedPath;
      } else {
        throw Exception('Erro ao exportar CSV');
      }
    } catch (e) {
      throw Exception('Erro ao exportar Editoras: $e');
    }
  }
}
