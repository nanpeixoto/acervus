import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/models/obra.dart';

import '../utils/app_config.dart';
import '_core/storage_service.dart';

class ObraService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // ======================================================
  // HEADERS
  // ======================================================
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ======================================================
  // LISTAR / BUSCAR (PAGINADO)
  // ======================================================
  static Future<Map<String, dynamic>> listarObras({
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

      if (search != null && search.trim().isNotEmpty) {
        queryParams['q'] = search.trim();
      }

      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri = Uri.parse('$baseUrl/obra/listar')
          .replace(queryParameters: queryParams);

      print('🔍 [OBRA] Listando obras: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao listar obras');
      }

      final data = jsonDecode(response.body);

      final obrasRaw = _extrairObras(data);
      final pagination = _extrairPaginacao(data);

      final obras = <Obra>[];
      for (final item in obrasRaw) {
        try {
          obras.add(Obra.fromJson(item));
        } catch (e) {
          print('⚠️ Erro ao converter obra: $e');
        }
      }

      return {
        'dados': obras,
        'pagination': pagination,
      };
    } catch (e) {
      print('💥 Erro ao listar obras: $e');
      throw Exception('Erro ao listar obras: $e');
    }
  }

  // ======================================================
  // BUSCAR POR ID
  // ======================================================
  static Future<Obra?> buscarObraPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/obra/listar/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        Map<String, dynamic>? obraData;
        if (data['dados'] != null) {
          obraData = data['dados'];
        } else if (data['data'] != null) {
          obraData = data['data'];
        } else if (data is Map<String, dynamic>) {
          obraData = data;
        }

        if (obraData != null) {
          return Obra.fromJson(obraData);
        }
      }

      return null;
    } catch (e) {
      print('Erro ao buscar obra $id: $e');
      return null;
    }
  }

  // ======================================================
  // CRIAR OBRA
  // ======================================================
  static Future<Obra?> criarObra(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/obra/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final obraData =
            data['dados'] ?? data['data'] ?? (data is Map ? data : null);

        if (obraData != null) {
          return Obra.fromJson(obraData);
        }
      } else {
        throw Exception(data['erro'] ?? response.body);
      }

      return null;
    } catch (e) {
      print('Erro ao criar obra: $e');
      rethrow;
    }
  }

  // ======================================================
  // EDITAR OBRA
  // ======================================================
  static Future<Obra?> editarObra(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/obra/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final obraData =
            data['dados'] ?? data['data'] ?? (data is Map ? data : null);

        if (obraData != null) {
          return Obra.fromJson(obraData);
        }
      }

      return null;
    } catch (e) {
      print('Erro ao editar obra: $e');
      rethrow;
    }
  }

  // ======================================================
  // ATIVAR / DESATIVAR
  // ======================================================
  static Future<bool> alterarStatus(int id, bool ativo) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/obra/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao alterar status da obra: $e');
    }
  }

  // ======================================================
  // EXPORTAR CSV
  // ======================================================
  static Future<List<int>> exportarCSV({
    String? search,
    bool? ativo,
  }) async {
    final queryParams = <String, String>{};

    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
    }
    if (ativo != null) {
      queryParams['ativo'] = ativo.toString();
    }

    final uri = Uri.parse('$baseUrl/obra/exportar/csv')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Erro ao exportar CSV');
    }
  }

  // ======================================================
  // HELPERS DE EXTRAÇÃO (IGUAL AO CANDIDATO)
  // ======================================================
  static List<dynamic> _extrairObras(dynamic data) {
    if (data == null) return [];

    final caminhos = [
      () => data['dados'],
      () => data['data'],
      () => data['result'],
      () => data,
    ];

    for (final fn in caminhos) {
      try {
        final r = fn();
        if (r is List) return r;
      } catch (_) {}
    }

    return [];
  }

  static Map<String, dynamic> _extrairPaginacao(dynamic data) {
    if (data == null || data is! Map) return {};

    final caminhos = [
      () => data['pagination'],
      () => data['dados']?['pagination'],
      () => data['meta'],
      () => data['page_info'],
    ];

    for (final fn in caminhos) {
      try {
        final r = fn();
        if (r is Map<String, dynamic>) return r;
      } catch (_) {}
    }

    return {
      'currentPage': 1,
      'totalPages': 1,
      'totalItems': 0,
      'hasNextPage': false,
      'hasPrevPage': false,
    };
  }
}
