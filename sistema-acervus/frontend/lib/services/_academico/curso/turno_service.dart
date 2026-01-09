// lib/services/status_curso_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/models/_pessoas/formacao/turno.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/services/_core/storage_service.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/utils/app_config.dart';
// Imports condicionais (NÃO mude a ordem dos ifs)
import 'package:sistema_estagio/utils/csv_downloader_stub.dart'
    if (dart.library.html) 'package:sistema_estagio/utils/csv_downloader_web.dart'
    if (dart.library.io) 'package:sistema_estagio/utils/csv_downloader_io.dart';

class TurnoService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers padrão para requisições
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Lista todos os status de curso com paginação e filtros
  static Future<Map<String, dynamic>> listarTurnos({
    int page = 1,
    int limit = 10,
    String? search,
    bool? ativo,
    bool? isDefault,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (isDefault != null) {
        queryParams['is_default'] = isDefault.toString();
      }

      final uri = Uri.parse('$baseUrl/turno/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'turnos': (data['dados'] as List)
              .map((json) => Turno.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar turnos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar turnos: $e');
    }
  }

  /// Busca um turno de curso específico por ID, nome ou descrição
  static Future<List<Turno>?> buscarTurno(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/turno/buscar')
          .replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => Turno.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar status de curso');
      }
    } catch (e) {
      throw Exception('Erro ao buscar status de curso: $e');
    }
  }

  /// Busca um turno de curso por ID
  static Future<Turno> buscarTurnoPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/turno/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Turno.fromJson(data['dados']);
      } else {
        throw Exception('Status de curso não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar status de curso: $e');
    }
  }

  /// Cria um novo status de curso
  static Future<bool> criarTurno(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/turno/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );
      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        String bRetorno = '';
        final data = jsonDecode(response.body);
        bRetorno = data['erro'] ?? '';
        throw Exception(bRetorno);
      }
      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar status de curso: $e');
    }
  }

  /// Atualiza um turno de curso existente
  static Future<bool> atualizarTurno(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/turno/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar status de curso: $e');
    }
  }

  /// Ativa um turno de curso
  static Future<bool> ativarTurno(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/turno/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );
      print('Erro ao ativar status de curso: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao ativar status de curso: $e');
      throw Exception('Erro ao ativar status de curso: $e');
    }
  }

  /// Desativa um turno de curso
  static Future<bool> desativarTurno(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/turno/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar status de curso: $e');
    }
  }

  /// Exclui um turno de curso
  static Future<bool> deletarTurno(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/turno/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir status de curso: $e');
    }
  }

  /// Reordena os status de turnos
  static Future<bool> reordenarTurno(List<Map<String, dynamic>> ordem) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/turno/reordenar'),
        headers: await _getHeaders(),
        body: jsonEncode({'ordem': ordem}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao reordenar status de turnos: $e');
    }
  }

  /// Lista as cores disponíveis para status
  static Future<List<String>> listarCoresDisponiveis() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/turno/cores'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data']);
      } else {
        return [
          '#4CAF50', // Verde
          '#FF9800', // Laranja
          '#F44336', // Vermelho
          '#2196F3', // Azul
          '#9C27B0', // Roxo
          '#FF5722', // Laranja escuro
          '#795548', // Marrom
          '#607D8B', // Azul acinzentado
          '#9E9E9E', // Cinza
          '#E91E63', // Rosa
        ];
      }
    } catch (e) {
      return [
        '#4CAF50',
        '#FF9800',
        '#F44336',
        '#2196F3',
        '#9C27B0',
        '#FF5722',
        '#795548',
        '#607D8B',
        '#9E9E9E',
        '#E91E63',
      ];
    }
  }

  /// Obtém estatísticas gerais dos status de turnos
  static Future<Map<String, dynamic>> getEstatisticasGerais() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/turno/estatisticas'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  /// Duplica um turno de curso existente
  static Future<Turno?> duplicarTurno(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/turno/$id/duplicar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Turno.fromJson(data['data']);
      } else {
        throw Exception('Erro ao duplicar status de curso');
      }
    } catch (e) {
      throw Exception('Erro ao duplicar status de curso: $e');
    }
  }

  /// Obtém cursos que utilizam um determinado status
  static Future<Map<String, dynamic>> getCursosComStatus(
    int statusId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/turno/$statusId/cursos')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Erro ao buscar cursos com status');
      }
    } catch (e) {
      throw Exception('Erro ao buscar cursos com status: $e');
    }
  }

  /// Exporta status de turnos para CSV
  /// Exporta status de turnos para CSV
  static Future<String?> exportarTurnoCSV({
    bool? ativo,
    bool? isDefault,
  }) async {
    try {
      final queryParams = <String, String>{};
      // if (ativo != null) queryParams['ativo'] = ativo.toString();
      // if (isDefault != null) queryParams['is_default'] = isDefault.toString();

      final uri = Uri.parse('$baseUrl/turno/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename = _extrairFilename(
                response.headers['content-disposition']) ??
            'turnos_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        // Usa o helper condicional (Web = download, Mobile/Desktop = salva no disco)
        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(bytes, filename: filename);

        return savedPath; // Na Web será null, no mobile/desktop será o path
      } else {
        throw Exception('Erro ao exportar CSV (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao exportar status de turnos: $e');
    }
  }

  /// Extrai o filename do header Content-Disposition, se presente
  static String? _extrairFilename(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.isEmpty) return null;

    // filename="turnos.csv"  |  filename=turnos.csv  |  filename*=UTF-8''turnos.csv
    final regex = RegExp('filename\\*?=(?:UTF-8\'\')?(")?([^";]+)\\1');

    final match = regex.firstMatch(contentDisposition);
    if (match != null) {
      final raw = match.group(2);
      if (raw == null) return null;
      try {
        return Uri.decodeFull(raw); // lida com %C3%B3 etc.
      } catch (_) {
        return raw;
      }
    }
    return null;
  }

  /// Exporta status de turnos para PDF
  static Future<List<int>> exportarTurnoPDF({
    bool? ativo,
    bool? isDefault,
  }) async {
    try {
      final queryParams = <String, String>{};

      final uri = Uri.parse('$baseUrl/turno/exportar/pdf')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erro ao exportar PDF');
      }
    } catch (e) {
      throw Exception('Erro ao exportar status de turnos em PDF: $e');
    }
  }

  // ==========================================
  // MÉTODOS DE CACHE
  // ==========================================

  static const Duration _cacheTimeout = Duration(minutes: 10);
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  static void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static dynamic _getCache(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheTimeout) {
      return _cache[key];
    }
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }

  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Obtém cores disponíveis com cache
  static Future<List<String>> getCachedCoresDisponiveis() async {
    const cacheKey = 'cores_disponiveis_status_cursos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return List<String>.from(cached);
    }

    final cores = await listarCoresDisponiveis();
    _setCache(cacheKey, cores);
    return cores;
  }

  /// Obtém estatísticas gerais com cache
  static Future<Map<String, dynamic>> getCachedEstatisticasGerais() async {
    const cacheKey = 'estatisticas_gerais_status_cursos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final stats = await getEstatisticasGerais();
    _setCache(cacheKey, stats);
    return stats;
  }

  /// Obtém status de turnos ativos com cache
  static Future<List<Turno>> getCachedStatusAtivos() async {
    const cacheKey = 'status_cursos_ativos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached.map<Turno>((json) => Turno.fromJson(json)).toList();
    }

    final result = await listarTurnos(ativo: true, limit: 100);
    final statusList = result['turnos'] as List<Turno>;
    _setCache(cacheKey, statusList.map((e) => e.toJson()).toList());
    return statusList;
  }
}
