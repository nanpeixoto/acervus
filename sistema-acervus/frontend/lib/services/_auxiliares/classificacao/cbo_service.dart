// lib/services/cbo_service.dart
import 'package:http/http.dart' as http;
import '../../../models/_auxiliares/classificacao/cbo.dart';
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';

class CBOService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers padrão para requisições
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Lista todos os CBOs com paginação e filtros
  static Future<Map<String, dynamic>> listarCBOs({
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
        queryParams['search'] = search;
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri = Uri.parse('$baseUrl/cbo/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Adaptar estrutura de resposta baseada no padrão dos outros serviços
        List<dynamic> cboData = [];
        Map<String, dynamic>? pagination;

        if (data['dados'] != null) {
          cboData = data['dados'] is List ? data['dados'] : [];
          pagination = data['pagination'];
        } else if (data['data'] != null) {
          cboData = data['data'] is List ? data['data'] : [];
          pagination = data['pagination'];
        } else if (data is List) {
          cboData = data;
        }

        return {
          'cbos': cboData.map((json) => CBO.fromJson(json)).toList(),
          'pagination': pagination,
        };
      } else {
        throw Exception('Erro ao carregar CBOs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar CBOs: $e');
    }
  }

  /// Busca CBOs por código ou descrição
  static Future<List<CBO>?> buscarCBO(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/cbo/buscar')
          .replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> cboData = [];

        if (data['dados'] != null) {
          cboData = data['dados'] is List ? data['dados'] : [];
        } else if (data['data'] != null) {
          cboData = data['data'] is List ? data['data'] : [];
        } else if (data is List) {
          cboData = data;
        }

        return cboData.map((json) => CBO.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar CBO: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar CBO: $e');
    }
  }

  /// Busca um CBO específico por ID
  static Future<CBO?> buscarCBOPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cbo/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cboData = data['dados'] ?? data['data'] ?? data;
        return CBO.fromJson(cboData);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro ao buscar CBO: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar CBO: $e');
    }
  }

  /// Cria um novo CBO
  static Future<bool> criarCBO(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cbo/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? errorData['erro'] ?? 'Erro ao criar CBO');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro ao criar CBO: $e');
    }
  }

  /// Atualiza um CBO existente
  static Future<bool> atualizarCBO(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cbo/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ??
            errorData['erro'] ??
            'Erro ao atualizar CBO');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro ao atualizar CBO: $e');
    }
  }

  /// Ativa um CBO
  static Future<bool> ativarCBO(int id) async {
    try {
      return await atualizarCBO(id, {'ativo': true});
    } catch (e) {
      throw Exception('Erro ao ativar CBO: $e');
    }
  }

  /// Desativa um CBO
  static Future<bool> desativarCBO(int id) async {
    try {
      return await atualizarCBO(id, {'ativo': false});
    } catch (e) {
      throw Exception('Erro ao desativar CBO: $e');
    }
  }

  /// Deleta um CBO
  static Future<bool> deletarCBO(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cbo/excluir/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['message'] ?? errorData['erro'] ?? 'Erro ao excluir CBO');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro ao excluir CBO: $e');
    }
  }

  /// Obtém estatísticas dos CBOs
  static Future<Map<String, dynamic>> getEstatisticas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cbo/estatisticas'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['dados'] ?? data['data'] ?? data;
      } else {
        return {
          'total': 0,
          'ativos': 0,
          'inativos': 0,
          'criadosEsteMes': 0,
        };
      }
    } catch (e) {
      return {
        'total': 0,
        'ativos': 0,
        'inativos': 0,
        'criadosEsteMes': 0,
      };
    }
  }

  /// Cache para estatísticas
  static Map<String, dynamic>? _cachedStats;
  static DateTime? _lastStatsUpdate;

  /// Obtém estatísticas com cache
  static Future<Map<String, dynamic>> getCachedEstatisticasGerais() async {
    // Cache de 5 minutos
    if (_cachedStats != null &&
        _lastStatsUpdate != null &&
        DateTime.now().difference(_lastStatsUpdate!).inMinutes < 5) {
      return _cachedStats!;
    }

    try {
      _cachedStats = await getEstatisticas();
      _lastStatsUpdate = DateTime.now();
      return _cachedStats!;
    } catch (e) {
      // Retorna cache antigo ou estatísticas vazias
      return _cachedStats ??
          {
            'total': 0,
            'ativos': 0,
            'inativos': 0,
            'criadosEsteMes': 0,
          };
    }
  }

  /// Exporta CBOs para CSV
  static Future<String?> exportarCSV({
    bool? ativo,
    bool? isDefault,
  }) async {
    try {
      final queryParams = <String, String>{};
      // if (ativo != null) queryParams['ativo'] = ativo.toString();
      // if (isDefault != null) queryParams['is_default'] = isDefault.toString();

      final uri = Uri.parse('$baseUrl/cbo/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename =
            _extrairFilename(response.headers['content-disposition']) ??
                'cbo_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

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

  /// Lista CBOs ativos para dropdown
  static Future<List<CBO>> listarCBOsAtivos() async {
    try {
      final result = await listarCBOs(ativo: true, limit: 1000);
      return result['cbos'] as List<CBO>;
    } catch (e) {
      throw Exception('Erro ao carregar CBOs ativos: $e');
    }
  }

  /// Limpa cache
  static void clearCache() {
    _cachedStats = null;
    _lastStatsUpdate = null;
  }
}
