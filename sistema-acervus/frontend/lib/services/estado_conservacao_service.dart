import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/models/estado_conservacao.dart';
import '../utils/app_config.dart';
import 'storage_service.dart';

class EstadoConservacaoService {
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

      final uri = Uri.parse('$baseUrl/estado-conservacao/listar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'estados': (data['dados'] as List)
              .map((e) => EstadoConservacao.fromJson(e))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao listar estados de conservação');
      }
    } catch (e) {
      throw Exception('Erro ao listar estados de conservação: $e');
    }
  }

  // =============================
  // BUSCAR POR ID
  // =============================
  static Future<EstadoConservacao> buscarPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/estado-conservacao/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return EstadoConservacao.fromJson(data['dados']);
      } else {
        throw Exception('Estado de conservação não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar estado de conservação: $e');
    }
  }

  // =============================
  // CRIAR
  // =============================
  static Future<bool> criar(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estado-conservacao/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (![200, 201, 204].contains(response.statusCode)) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar estado de conservação');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao criar estado de conservação: $e');
    }
  }

  // =============================
  // ATUALIZAR
  // =============================
  static Future<bool> atualizar(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/estado-conservacao/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(
            data['erro'] ?? 'Erro ao atualizar estado de conservação');
      }

      return true;
    } catch (e) {
      throw Exception('Erro ao atualizar estado de conservação: $e');
    }
  }

  // =============================
  // ATIVAR / DESATIVAR
  // =============================
  static Future<bool> ativar(int id) async {
    return atualizar(id, {'ativo': true});
  }

  static Future<bool> desativar(int id) async {
    return atualizar(id, {'ativo': false});
  }

  // =============================
  // EXCLUIR
  // =============================
  static Future<bool> excluir(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/estado-conservacao/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir estado de conservação: $e');
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

      final uri = Uri.parse('$baseUrl/estado-conservacao/exportar/csv')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final filename =
            'estado_conservacao_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(bytes, filename: filename);

        return savedPath;
      } else {
        throw Exception('Erro ao exportar CSV');
      }
    } catch (e) {
      throw Exception('Erro ao exportar estado de conservação: $e');
    }
  }
}
