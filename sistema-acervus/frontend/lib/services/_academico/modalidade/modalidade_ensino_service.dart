// lib/services/modalidade_ensino_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/_academico/modalidade/modalidade_ensino.dart'
    as modalidade_model;
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';

class ModalidadeService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers padrão para requisições
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Lista todos os modalidade com paginação e filtros
  static Future<Map<String, dynamic>> listarModalidades({
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

      final uri = Uri.parse('$baseUrl/modalidade_ensino/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'modalidades': (data['dados'] as List)
              .map((json) => modalidade_model.Modalidade.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar modalidades');
      }
    } catch (e) {
      throw Exception('Erro ao carregar modalidades: $e');
    }
  }

  /// Busca um modalidade específico por ID, nome ou descrição
  static Future<List<modalidade_model.Modalidade>?> buscarModalidade(
      String query) async {
    try {
      final uri = Uri.parse('$baseUrl/modalidade_ensino/listar')
          .replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => modalidade_model.Modalidade.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar modalidade');
      }
    } catch (e) {
      throw Exception('Erro ao buscar modalidade: $e');
    }
  }

  /// Busca um modalidade por ID
  static Future<modalidade_model.Modalidade> buscarModalidadePorId(
      int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/modalidade_ensino/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return modalidade_model.Modalidade.fromJson(data['dados']);
      } else {
        throw Exception('Status de curso não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar modalidade: $e');
    }
  }

  /// Cria um novo modalidade
  static Future<bool> criarModalidade(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/modalidade_ensino/cadastrar'),
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
      throw Exception('Erro ao criar modalidade: $e');
    }
  }

  /// Atualiza um modalidade existente
  static Future<bool> atualizarModalidade(
      int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/modalidade_ensino/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar modalidade: $e');
    }
  }

  /// Ativa um modalidade
  static Future<bool> ativarModalidade(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/modalidade_ensino/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );
      print('Erro ao ativar modalidade: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao ativar modalidade: $e');
      throw Exception('Erro ao ativar modalidade: $e');
    }
  }

  /// Desativa um modalidade
  static Future<bool> desativarModalidade(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/modalidade_ensino/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar modalidade: $e');
    }
  }

  /// Exclui um modalidade
  static Future<bool> deletarModalidade(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/modalidade_ensino/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir modalidade: $e');
    }
  }

  /// Reordena os modalidades
  static Future<bool> reordenarModalidades(
      List<Map<String, dynamic>> ordem) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/modalidade_ensino/reordenar'),
        headers: await _getHeaders(),
        body: jsonEncode({'ordem': ordem}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao reordenar modalidades: $e');
    }
  }

  /// Lista as cores disponíveis para status
  static Future<List<String>> listarCoresDisponiveis() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/modalidade_ensino/cores'),
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

  /// Obtém estatísticas gerais dos modalidades
  static Future<Map<String, dynamic>> getEstatisticasGerais() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/modalidade_ensino/estatisticas'),
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

  /// Duplica um modalidade existente
  static Future<modalidade_model.Modalidade?> duplicarModalidade(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/modalidade_ensino/$id/duplicar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return modalidade_model.Modalidade.fromJson(data['data']);
      } else {
        throw Exception('Erro ao duplicar modalidade');
      }
    } catch (e) {
      throw Exception('Erro ao duplicar modalidade: $e');
    }
  }

  /// Obtém modalidades que utilizam um determinado status
  static Future<Map<String, dynamic>> getModalidadesComStatus(
    int statusId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/modalidade_ensino/$statusId/modalidades')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Erro ao buscar modalidades com status');
      }
    } catch (e) {
      throw Exception('Erro ao buscar modalidades com status: $e');
    }
  }

  /// Exporta modalidades para CSV
  static Future<void> exportarModalidadesCSV({
    bool? ativo,
    bool? isDefault,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (isDefault != null) {
        queryParams['is_default'] = isDefault.toString();
      }

      final uri = Uri.parse('$baseUrl/modalidade_ensino/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        // Implementar download do arquivo CSV
        // A implementação específica depende da plataforma (web/mobile)
        print('CSV exportado com sucesso');
      } else {
        throw Exception('Erro ao exportar CSV');
      }
    } catch (e) {
      throw Exception('Erro ao exportar modalidades: $e');
    }
  }

  /// Exporta modalidades para PDF
  static Future<List<int>> exportarModalidadesPDF({
    bool? ativo,
    bool? isDefault,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (isDefault != null) {
        queryParams['is_default'] = isDefault.toString();
      }

      final uri = Uri.parse('$baseUrl/modalidade_ensino/exportar/pdf')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erro ao exportar PDF');
      }
    } catch (e) {
      throw Exception('Erro ao exportar modalidades em PDF: $e');
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
    const cacheKey = 'cores_disponiveis_status_modalidades';
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
    const cacheKey = 'estatisticas_gerais_status_modalidades';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final stats = await getEstatisticasGerais();
    _setCache(cacheKey, stats);
    return stats;
  }

  /// Obtém modalidades ativos com cache
  static Future<List<modalidade_model.Modalidade>>
      getCachedStatusAtivos() async {
    const cacheKey = 'status_modalidades_ativos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached
          .map<modalidade_model.Modalidade>(
              (json) => modalidade_model.Modalidade.fromJson(json))
          .toList();
    }

    final result = await listarModalidades(ativo: true, limit: 100);
    final statusList =
        result['modalidades'] as List<modalidade_model.Modalidade>;
    _setCache(cacheKey, statusList.map((e) => e.toJson()).toList());
    return statusList;
  }
}
