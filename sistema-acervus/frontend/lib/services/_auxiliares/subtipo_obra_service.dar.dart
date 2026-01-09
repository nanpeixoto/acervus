import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:sistema_estagio/models/_auxiliares/subtipo_obra.dart';
import '../../utils/app_config.dart';
import '../_core/storage_service.dart';

class SubtipoObraService {
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
    int? cdTipoObra,
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
      if (cdTipoObra != null) {
        queryParams['cd_tipo_obra'] = cdTipoObra.toString();
        queryParams['cd_tipo_peca'] = cdTipoObra.toString();
      }

      final uri = Uri.parse('$baseUrl/subtipo_obra/listar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'Subtipos': (data['dados'] as List)
              .map((json) => SubtipoObra.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar Subtipos de Obra');
      }
    } catch (e) {
      throw Exception('Erro ao carregar Subtipos de Obra: $e');
    }
  }

  // =============================
  // BUSCAR
  // =============================
  static Future<List<SubtipoObra>> buscarSubtipos(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/subtipo_obra/listar')
          .replace(queryParameters: {'q': query});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => SubtipoObra.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar Subtipo de Obra');
      }
    } catch (e) {
      throw Exception('Erro ao buscar Subtipo de Obra: $e');
    }
  }

  // =============================
  // BUSCAR POR ID
  // =============================
  static Future<SubtipoObra> buscarSubtipoPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subtipo_obra/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SubtipoObra.fromJson(data['dados']);
      } else {
        throw Exception('Subtipo de Obra não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar Subtipo de Obra: $e');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/subtipo_obra/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar Subtipo de Obra');
      }

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar Subtipo de Obra: $e');
    }
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/subtipo_obra/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao atualizar Subtipo de Obra');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao atualizar Subtipo de Obra: $e');
    }
  }

  // =============================
  // ATIVAR / DESATIVAR
  // =============================
  static Future<bool> ativarSubtipo(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/subtipo_obra/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao ativar Subtipo de Obra: $e');
    }
  }

  static Future<bool> desativarSubtipo(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/subtipo_obra/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar Subtipo de Obra: $e');
    }
  }

  // =============================
  // EXCLUIR
  // =============================
  static Future<bool> deletarSubtipo(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/subtipo_obra/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir Subtipo de Obra: $e');
    }
  }

  // =============================
  // EXPORTAR CSV
  // =============================
  static Future<String?> exportarCSV({
    bool? ativo,
    int? cdTipoObra,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (cdTipoObra != null) {
        queryParams['cd_tipo_obra'] = cdTipoObra.toString();
      }

      final uri = Uri.parse('$baseUrl/subtipo_obra/exportar/csv')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final filename =
            'SubtiposObra_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

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
      throw Exception('Erro ao exportar Subtipos de Obra: $e');
    }
  }
}
