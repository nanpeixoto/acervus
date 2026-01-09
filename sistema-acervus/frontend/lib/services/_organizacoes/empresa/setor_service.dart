// lib/services/setor_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/_organizacoes/empresa/setor.dart';
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';

class SetorService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers padrão para requisições
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Lista todos os setores com paginação e filtros
  static Future<Map<String, dynamic>> listarSetores({
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

      final uri = Uri.parse('$baseUrl/setor/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'setores': (data['dados'] as List)
              .map((json) => Setor.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar setores');
      }
    } catch (e) {
      throw Exception('Erro ao carregar setores: $e');
    }
  }

  /// Busca setores por query (nome, descrição, etc.)
  static Future<List<Setor>?> buscarSetor(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/setor/listar')
          .replace(queryParameters: {'search': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => Setor.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar setor');
      }
    } catch (e) {
      throw Exception('Erro ao buscar setor: $e');
    }
  }

  /// Busca um setor específico por ID (aceita String ou int)
  static Future<Setor> buscarSetorPorId(dynamic id) async {
    try {
      final setorId = id.toString(); // Converte para String sempre
      final response = await http.get(
        Uri.parse('$baseUrl/setor/$setorId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Setor.fromJson(data['dados']);
      } else {
        throw Exception('Setor não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar setor: $e');
    }
  }

  /// Cria um novo setor
  static Future<bool> criarSetor(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/setor/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        String mensagemErro = '';
        try {
          final data = jsonDecode(response.body);
          mensagemErro = data['erro'] ?? 'Erro desconhecido';
        } catch (_) {
          mensagemErro = 'Erro na comunicação com o servidor';
        }
        throw Exception(mensagemErro);
      }
      return true;
    } catch (e) {
      throw Exception('Erro ao criar setor: $e');
    }
  }

  /// Cria um setor para candidato e retorna o ID
  static Future<String?> criarSetorCandidato(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/candidato/setor/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

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
        String mensagemErro = '';
        if (data is Map && data.containsKey('erro')) {
          mensagemErro = data['erro'];
        } else {
          mensagemErro = responseBody;
        }
        throw Exception(mensagemErro);
      }

      // Retorna o ID como String
      if (data is Map && data.containsKey('cd_setor_candidato')) {
        return data['cd_setor_candidato'].toString();
      } else if (data is Map && data.containsKey('cd_setor')) {
        return data['cd_setor'].toString();
      } else {
        throw Exception('Resposta inesperada do servidor: $responseBody');
      }
    } catch (e) {
      throw Exception('Erro ao criar setor do candidato: $e');
    }
  }

  /// Atualiza um setor existente (aceita String ou int para ID)
  static Future<bool> atualizarSetor(
      dynamic id, Map<String, dynamic> dados) async {
    try {
      final setorId = id.toString(); // Converte para String
      final response = await http.put(
        Uri.parse('$baseUrl/setor/alterar/$setorId'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        String mensagemErro = '';
        try {
          final data = jsonDecode(response.body);
          mensagemErro = data['erro'] ?? 'Erro ao atualizar setor';
        } catch (_) {
          mensagemErro = 'Erro na comunicação com o servidor';
        }
        throw Exception(mensagemErro);
      }
    } catch (e) {
      throw Exception('Erro ao atualizar setor: $e');
    }
  }

  /// Atualiza setor de candidato
  static Future<bool> atualizarSetorCandidato(
    Map<String, dynamic> dados, {
    required dynamic idSetorCandidato,
  }) async {
    try {
      final setorId = idSetorCandidato.toString(); // Converte para String
      final response = await http.put(
        Uri.parse('$baseUrl/candidato/setor/alterar/$setorId'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

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
        String mensagemErro = '';
        if (data is Map && data.containsKey('erro')) {
          mensagemErro = data['erro'];
        } else {
          mensagemErro = responseBody;
        }
        throw Exception(mensagemErro);
      }

      return true;
    } catch (e) {
      if (e is Exception &&
          e.toString().startsWith('Exception: ') &&
          !e.toString().contains('Erro ao atualizar setor')) {
        rethrow;
      }
      throw Exception('Erro ao atualizar setor do candidato: $e');
    }
  }

  /// Ativa/desativa um setor (aceita String ou int para ID)
  static Future<bool> alterarStatusSetor(dynamic id,
      {required bool ativo}) async {
    try {
      final setorId = id.toString(); // Converte para String
      final response = await http.put(
        Uri.parse('$baseUrl/setor/alterar/$setorId'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Erro ao alterar status do setor: $e');
    }
  }

  /// Ativa um setor (método de conveniência)
  static Future<bool> ativarSetor(dynamic id) async {
    return alterarStatusSetor(id, ativo: true);
  }

  /// Desativa um setor (método de conveniência)
  static Future<bool> desativarSetor(dynamic id) async {
    return alterarStatusSetor(id, ativo: false);
  }

  /// Exclui um setor (aceita String ou int para ID)
  static Future<bool> deletarSetor(dynamic id) async {
    try {
      final setorId = id.toString(); // Converte para String
      final response = await http.delete(
        Uri.parse('$baseUrl/setor/excluir/$setorId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        String mensagemErro = '';
        try {
          final data = jsonDecode(response.body);
          mensagemErro = data['erro'] ?? 'Erro ao excluir setor';
        } catch (_) {
          mensagemErro = 'Erro na comunicação com o servidor';
        }
        throw Exception(mensagemErro);
      }
    } catch (e) {
      throw Exception('Erro ao excluir setor: $e');
    }
  }

  /// Reordena os setores
  static Future<bool> reordenarSetores(List<Map<String, dynamic>> ordem) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/setor/reordenar'),
        headers: await _getHeaders(),
        body: jsonEncode({'ordem': ordem}),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Erro ao reordenar setores: $e');
    }
  }

  /// Lista as cores disponíveis para setores
  static Future<List<String>> listarCoresDisponiveis() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/setor/cores'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data'] ?? data['dados'] ?? []);
      } else {
        // Cores padrão para setores
        return [
          '#4CAF50', // Verde
          '#2196F3', // Azul
          '#FF9800', // Laranja
          '#9C27B0', // Roxo
          '#F44336', // Vermelho
          '#795548', // Marrom
          '#607D8B', // Azul acinzentado
          '#E91E63', // Rosa
          '#FF5722', // Laranja escuro
          '#9E9E9E', // Cinza
        ];
      }
    } catch (e) {
      // Retorna cores padrão em caso de erro
      return [
        '#4CAF50',
        '#2196F3',
        '#FF9800',
        '#9C27B0',
        '#F44336',
        '#795548',
        '#607D8B',
        '#E91E63',
        '#FF5722',
        '#9E9E9E',
      ];
    }
  }

  /// Obtém estatísticas gerais dos setores
  static Future<Map<String, dynamic>> getEstatisticasGerais() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/setor/estatisticas'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data['dados'] ?? {};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  /// Duplica um setor existente
  static Future<Setor?> duplicarSetor(dynamic id) async {
    try {
      final setorId = id.toString(); // Converte para String
      final response = await http.post(
        Uri.parse('$baseUrl/setor/$setorId/duplicar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Setor.fromJson(data['data'] ?? data['dados']);
      } else {
        throw Exception('Erro ao duplicar setor');
      }
    } catch (e) {
      throw Exception('Erro ao duplicar setor: $e');
    }
  }

  /// Obtém setores que utilizam um determinado status
  static Future<Map<String, dynamic>> getSetoresComStatus(
    dynamic statusId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final statusIdStr = statusId.toString(); // Converte para String
      final uri = Uri.parse('$baseUrl/setor/$statusIdStr/items')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? data['dados'] ?? {};
      } else {
        throw Exception('Erro ao buscar setores com status');
      }
    } catch (e) {
      throw Exception('Erro ao buscar setores com status: $e');
    }
  }

  /// Exporta setores para CSV
  static Future<void> exportarSetoresCSV({
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

      final uri = Uri.parse('$baseUrl/setor/exportar/csv')
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
      throw Exception('Erro ao exportar setores: $e');
    }
  }

  /// Exporta setores para PDF
  static Future<List<int>> exportarSetoresPDF({
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

      final uri = Uri.parse('$baseUrl/setor/exportar/pdf')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erro ao exportar PDF');
      }
    } catch (e) {
      throw Exception('Erro ao exportar setores em PDF: $e');
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
    const cacheKey = 'cores_disponiveis_setores';
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
    const cacheKey = 'estatisticas_gerais_setores';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final stats = await getEstatisticasGerais();
    _setCache(cacheKey, stats);
    return stats;
  }

  /// Obtém setores ativos com cache
  static Future<List<Setor>> getCachedSetoresAtivos() async {
    const cacheKey = 'setores_ativos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached.map<Setor>((json) => Setor.fromJson(json)).toList();
    }

    final result = await listarSetores(ativo: true, limit: 100);
    final setoresList = result['setores'] as List<Setor>;
    _setCache(cacheKey, setoresList.map((e) => e.toJson()).toList());
    return setoresList;
  }

  /// Busca setores para dropdown/select
  static Future<List<Setor>> buscarSetoresParaSelect({
    String? filtro,
    bool apenasAtivos = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': '100', // Limite alto para selects
      };

      if (filtro != null && filtro.isNotEmpty) {
        queryParams['search'] = filtro;
      }
      if (apenasAtivos) {
        queryParams['ativo'] = 'true';
      }

      final uri = Uri.parse('$baseUrl/setor/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => Setor.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Erro ao buscar setores para seleção: $e');
    }
  }
}
