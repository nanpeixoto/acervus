// lib/services/_auxiliares/TipoObra_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:sistema_estagio/models/_auxiliares/tipo_obra.dart';
import '../../utils/app_config.dart';
import '../_core/storage_service.dart';

class TipoObraService {
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

      final uri = Uri.parse('$baseUrl/tipo_obra/listar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'TipoObras': (data['dados'] as List)
              .map((json) => TipoObra.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar TipoObras');
      }
    } catch (e) {
      throw Exception('Erro ao carregar TipoObras: $e');
    }
  }

  // =============================
  // BUSCAR
  // =============================
  static Future<List<TipoObra>> buscarTipoObras(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/tipo_obra/listar')
          .replace(queryParameters: {'q': query});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => TipoObra.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar TipoObra');
      }
    } catch (e) {
      throw Exception('Erro ao buscar TipoObra: $e');
    }
  }

  // =============================
  // BUSCAR POR ID
  // =============================
  static Future<TipoObra> buscarTipoObraPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tipo_obra/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TipoObra.fromJson(data['dados']);
      } else {
        throw Exception('TipoObra não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar TipoObra: $e');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tipo_obra/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar TipoObra');
      }

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar TipoObra: $e');
    }
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tipo_obra/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao atualizar TipoObra');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao atualizar TipoObra: $e');
    }
  }

  // =============================
  // ATIVAR / DESATIVAR
  // =============================
  static Future<bool> ativarTipoObra(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tipo_obra/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao ativar TipoObra: $e');
    }
  }

  static Future<bool> desativarTipoObra(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tipo_obra/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar TipoObra: $e');
    }
  }

  // =============================
  // EXCLUIR
  // =============================
  static Future<bool> deletarTipoObra(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tipo_obra/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir TipoObra: $e');
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

      final uri = Uri.parse('$baseUrl/tipo_obra/exportar/csv')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final filename =
            'TipoObras_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(bytes, filename: filename);

        return savedPath;
      } else {
        throw Exception('Erro ao exportar CSV');
      }
    } catch (e) {
      throw Exception('Erro ao exportar TipoObras: $e');
    }
  }
}
