// lib/services/conhecimento_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/_pessoas/formacao/conhecimento.dart';
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';

class ConhecimentoService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers padrão para requisições
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Lista todos os itens com paginação e filtros
  static Future<Map<String, dynamic>> listarConhecimentos({
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

      final uri = Uri.parse('$baseUrl/conhecimento/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'conhecimentos': (data['dados'] as List)
              .map((json) => Conhecimento.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar ítens');
      }
    } catch (e) {
      throw Exception('Erro ao carregar itens: $e');
    }
  }

  /// Busca um ítem específico por ID, nome ou descrição
  static Future<List<Conhecimento>?> buscarConhecimento(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/conhecimento/listar')
          .replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => Conhecimento.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar ítem');
      }
    } catch (e) {
      throw Exception('Erro ao buscar ítem $e');
    }
  }

  /// Busca um Ítem por ID
  static Future<Conhecimento> buscarConhecimentoPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conhecimento/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Conhecimento.fromJson(data['dados']);
      } else {
        throw Exception('Ítem não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar ítem $e');
    }
  }

  /// Cria um novo ítem
  static Future<bool> criarConhecimento(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conhecimento/cadastrar'),
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
      throw Exception('Erro ao criar ítem $e');
    }
  }

  static Future<int?> criarConhecimentoCandidato(
      Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/candidato/conhecimento/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      // Sempre tenta exibir o conteúdo do response, independente do status
      String responseBody = response.body;
      dynamic data;
      try {
        data = jsonDecode(responseBody);
      } catch (_) {
        data = responseBody;
      }

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        // Se possível, mostra o erro detalhado
        String bRetorno = '';
        if (data is Map && data.containsKey('erro')) {
          bRetorno = data['erro'];
        } else {
          bRetorno = responseBody;
        }
        throw Exception(bRetorno);
      }

      // Para sucesso, retorna o id se existir, ou o body inteiro
      if (data is Map && data.containsKey('cd_conhecimento_candidato')) {
        return data['cd_conhecimento_candidato'];
      } else {
        // Se não houver o campo esperado, lança o body para o usuário
        throw Exception(responseBody);
      }
    } catch (e) {
      throw Exception('Erro ao criar ítem: $e');
    }
  }

  /// Atualiza um ítem existente
  static Future<bool> atualizarConhecimento(
      int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/candidato/conhecimento/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar ítem $e');
    }
  }

  static Future<bool> atualizarConhecimentoCandidato(Map<String, dynamic> dados,
      {required int idConhecimentoCandidato}) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/candidato/conhecimento/alterar/$idConhecimentoCandidato'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      // Sempre tenta exibir o conteúdo do response, independente do status
      String responseBody = response.body;
      dynamic data;
      try {
        data = jsonDecode(responseBody);
      } catch (_) {
        data = responseBody;
      }

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        // Se possível, mostra o erro detalhado
        String bRetorno = '';
        if (data is Map && data.containsKey('erro')) {
          bRetorno = data['erro'];
        } else {
          bRetorno = responseBody;
        }
        throw Exception(bRetorno);
      }

      return response.statusCode == 200;
    } catch (e) {
      // Se é uma Exception já tratada acima, propaga ela
      if (e is Exception &&
          e.toString().startsWith('Exception: ') &&
          !e.toString().contains('Erro ao atualizar ítem')) {
        rethrow;
      }
      throw Exception('Erro ao atualizar ítem: $e');
    }
  }

  /// Ativa um ítem
  static Future<bool> ativarConhecimento(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/conhecimento/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao ativar ítem $e');
      throw Exception('Erro ao ativar ítem $e');
    }
  }

  /// Desativa um ítem
  static Future<bool> desativarConhecimento(int id,
      {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/conhecimento/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar ítem $e');
    }
  }

  /// Exclui um ítem
  static Future<bool> deletarConhecimento(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/conhecimento/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir ítem $e');
    }
  }

  /// Reordena os ítems
  static Future<bool> reordenarConhecimentos(
      List<Map<String, dynamic>> ordem) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/conhecimento/reordenar'),
        headers: await _getHeaders(),
        body: jsonEncode({'ordem': ordem}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao reordenar itens: $e');
    }
  }

  /// Lista as cores disponíveis para status
  static Future<List<String>> listarCoresDisponiveis() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conhecimento/cores'),
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

  /// Obtém estatísticas gerais dos itens
  static Future<Map<String, dynamic>> getEstatisticasGerais() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/conhecimento/estatisticas'),
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

  /// Duplica um ítem existente
  static Future<Conhecimento?> duplicarConhecimento(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/conhecimento/$id/duplicar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Conhecimento.fromJson(data['data']);
      } else {
        throw Exception('Erro ao duplicar ítem');
      }
    } catch (e) {
      throw Exception('Erro ao duplicar ítem $e');
    }
  }

  /// Obtém itens que utilizam um determinado status
  static Future<Map<String, dynamic>> getNiveisConhecimentoComStatus(
    int statusId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/conhecimento/$statusId/items')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Erro ao buscar itens com status');
      }
    } catch (e) {
      throw Exception('Erro ao buscar itens com status: $e');
    }
  }

  /// Exporta itens para CSV
  static Future<void> exportarConhecimentosCSV({
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

      final uri = Uri.parse('$baseUrl/conhecimento/exportar/csv')
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
      throw Exception('Erro ao exportar itens: $e');
    }
  }

  /// Exporta ítens para PDF
  static Future<List<int>> exportarNiveisConhecimentoPDF({
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

      final uri = Uri.parse('$baseUrl/conhecimento/exportar/pdf')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erro ao exportar PDF');
      }
    } catch (e) {
      throw Exception('Erro ao exportar ítens em PDF: $e');
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
    const cacheKey = 'cores_disponiveis_niveis_conhecimento';
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
    const cacheKey = 'estatisticas_gerais_niveis_conhecimento';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final stats = await getEstatisticasGerais();
    _setCache(cacheKey, stats);
    return stats;
  }

  /// Obtém ítens ativos com cache
  static Future<List<Conhecimento>> getCachedStatusAtivos() async {
    const cacheKey = 'status_niveis_conhecimento_ativos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached
          .map<Conhecimento>((json) => Conhecimento.fromJson(json))
          .toList();
    }

    final result = await listarConhecimentos(ativo: true, limit: 100);
    final statusList = result['conhecimentos'] as List<Conhecimento>;
    _setCache(cacheKey, statusList.map((e) => e.toJson()).toList());
    return statusList;
  }
}
