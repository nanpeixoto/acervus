// lib/services/plano_pagamento_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/_financeiro/plano_pagamento.dart';
import '../../utils/app_config.dart';
import '../_core/storage_service.dart';

class PlanoPagamentoService {
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
  static Future<Map<String, dynamic>> listarPlanos({
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

      final uri = Uri.parse('$baseUrl/plano_pagamento/buscar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'planos': (data['dados'] as List)
              .map((json) => PlanoPagamento.fromJson(json))
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
  static Future<List<PlanoPagamento>?> buscarPlano(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/plano_pagamento/listar')
          .replace(queryParameters: {'ativo': 'true', 'q': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => PlanoPagamento.fromJson(json))
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

  static Future<List<PlanoPagamento>> buscarPlano2(String string) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plano_pagamento/buscar').replace(queryParameters: {
          'nome': string,
          'id': int,
        }),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // data['dados'] é uma lista!
        return (data['dados'] as List)
            .map((json) => PlanoPagamento.fromJson(json))
            .toList();
      } else {
        throw Exception('Plano não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar plano: $e');
    }
  }

  /// Busca um Ítem por ID
  static Future<PlanoPagamento> buscarPlanoPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/plano_pagamento/buscar/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlanoPagamento.fromJson(data['dados']);
      } else {
        throw Exception('Ítem não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar ítem $e');
    }
  }

  /// Cria um novo ítem
  static Future<bool> criarPlano(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/plano_pagamento/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );
      print(response.statusCode);
      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        String bRetorno = '';
        final data = jsonDecode(response.body);
        bRetorno = data['erro'] ?? '';
        print('data: $data');
        throw Exception(bRetorno);
      }
      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar ítem $e');
    }
  }

  /// Atualiza um ítem existente
  static Future<bool> atualizarPlano(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/plano_pagamento/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar ítem $e');
    }
  }

  /// Ativa um ítem
  static Future<bool> ativarPlano(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/plano_pagamento/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );
      print('Erro ao ativar ítem ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao ativar ítem $e');
      throw Exception('Erro ao ativar ítem $e');
    }
  }

  /// Desativa um ítem
  static Future<bool> desativarPlano(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/plano_pagamento/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar ítem $e');
    }
  }

  /// Exclui um ítem
  static Future<bool> deletarPlano(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/plano_pagamento/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir ítem $e');
    }
  }

  /// Reordena os ítems
  static Future<bool> reordenarPlanos(List<Map<String, dynamic>> ordem) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/plano_pagamento/reordenar'),
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
        Uri.parse('$baseUrl/plano_pagamento/cores'),
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
        Uri.parse('$baseUrl/plano_pagamento/estatisticas'),
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
  static Future<PlanoPagamento> duplicarPlano(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/plano_pagamento/$id/duplicar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PlanoPagamento.fromJson(data['data']);
      } else {
        throw Exception('Erro ao duplicar ítem');
      }
    } catch (e) {
      throw Exception('Erro ao duplicar ítem $e');
    }
  }

  /// Obtém itens que utilizam um determinado status
  static Future<Map<String, dynamic>> getPlanosComStatus(
    int statusId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/plano_pagamento/$statusId/items')
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

  static Future<String?> exportarCSV({
    bool? ativo,
    bool? isDefault,
  }) async {
    try {
      final queryParams = <String, String>{};
      // if (ativo != null) queryParams['ativo'] = ativo.toString();
      // if (isDefault != null) queryParams['is_default'] = isDefault.toString();

      final uri = Uri.parse('$baseUrl/plano_pagamento/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename = _extrairFilename(
                response.headers['content-disposition']) ??
            'plano_pagamento_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        // Usa o helper condicional (Web = download, Mobile/Desktop = salva no disco)
        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(bytes, filename: filename);

        return savedPath; // Na Web será null, no mobile/desktop será o path
      } else {
        throw Exception('Erro ao exportar CSV (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao exportar status de planos de pagamento: $e');
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

  /// Exporta ítens para PDF
  static Future<List<int>> exportarPlanosPDF({
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

      final uri = Uri.parse('$baseUrl/plano_pagamento/exportar/pdf')
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
    const cacheKey = 'cores_disponiveis_niveis_formacao';
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
    const cacheKey = 'estatisticas_gerais_niveis_formacao';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final stats = await getEstatisticasGerais();
    _setCache(cacheKey, stats);
    return stats;
  }

  /// Obtém ítens ativos com cache
  static Future<List<PlanoPagamento>> getCachedStatusAtivos() async {
    const cacheKey = 'status_Planos_ativos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached
          .map<PlanoPagamento>((json) => PlanoPagamento.fromJson(json))
          .toList();
    }

    final result = await listarPlanos(ativo: true, limit: 100);
    final statusList = result['Planos'] as List<PlanoPagamento>;
    _setCache(cacheKey, statusList.map((e) => e.toJson()).toList());
    return statusList;
  }
}
