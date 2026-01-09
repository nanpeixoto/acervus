// lib/services/turma_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/_academico/turma/turma.dart';
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';

class TurmaService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers padrão para requisições
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Lista todas as turmas com paginação e filtros
  static Future<Map<String, dynamic>> listarTurmas({
    int page = 1,
    int limit = 10,
    String? search,
    bool? ativo,
    int? cursoAprendizagemId,
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
      if (cursoAprendizagemId != null) {
        queryParams['cd_curso'] = cursoAprendizagemId.toString();
      }
      if (isDefault != null) {
        queryParams['is_default'] = isDefault.toString();
      }

      final uri = Uri.parse('$baseUrl/turma/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'turmas': (data['dados'] as List)
              .map((json) => Turma.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar turmas');
      }
    } catch (e) {
      throw Exception('Erro ao carregar turmas: $e');
    }
  }

  /// Busca uma turma específica por ID, número ou curso
  static Future<List<Turma>?> buscarTurma(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/turma/listar')
          .replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => Turma.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar turma');
      }
    } catch (e) {
      throw Exception('Erro ao buscar turma: $e');
    }
  }

  /// Busca uma turma por ID
  static Future<Map<String, dynamic>> buscarTurmaPorId(int id) async {
    print('🔍 [TURMA_SERVICE] Iniciando busca por ID: "$id"');

    try {
      // ✅ VALIDAÇÕES PRÉVIAS
      if (id <= 0) {
        throw Exception('ID deve ser um número válido maior que zero');
      }

      print('✅ [TURMA_SERVICE] ID validado: $id');

      // ✅ CONSTRUÇÃO DA URL
      final url = '$baseUrl/turma/buscar/$id';
      print('🌐 [TURMA_SERVICE] URL: $url');

      // ✅ HEADERS
      final headers = await _getHeaders();
      print('📋 [TURMA_SERVICE] Headers preparados');

      print('⏳ [TURMA_SERVICE] Fazendo requisição HTTP GET...');

      // ✅ REQUISIÇÃO COM TIMEOUT
      final response = await http
          .get(
        Uri.parse(url),
        headers: headers,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏰ [TURMA_SERVICE] Timeout da requisição');
          throw Exception('Timeout: A requisição demorou muito para responder');
        },
      );

      print('📡 [TURMA_SERVICE] Resposta recebida');
      print('📊 [TURMA_SERVICE] Status Code: ${response.statusCode}');
      print('📏 [TURMA_SERVICE] Body Length: ${response.body.length}');
      print('📋 [TURMA_SERVICE] Response Body: ${response.body}');

      // ✅ VERIFICAÇÃO DO STATUS CODE
      if (response.statusCode == 200) {
        print('✅ [TURMA_SERVICE] Status 200 - Sucesso');

        // ✅ VALIDAÇÃO DO BODY
        if (response.body.isEmpty) {
          throw Exception('Resposta do servidor está vazia');
        }

        try {
          print('🔄 [TURMA_SERVICE] Decodificando JSON...');
          final responseData = jsonDecode(response.body);
          print('✅ [TURMA_SERVICE] JSON decoded com sucesso');
          print(
              '🔍 [TURMA_SERVICE] Response type: ${responseData.runtimeType}');

          // ✅ VERIFICAR ESTRUTURA DA RESPOSTA
          if (responseData == null) {
            throw Exception('Resposta do servidor é null');
          }

          // Verificar se tem estrutura com 'dados' ou se é direto
          Map<String, dynamic> turmaData;

          if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('dados') &&
                responseData['dados'] != null) {
              turmaData = responseData['dados'] as Map<String, dynamic>;
              print(
                  '📋 [TURMA_SERVICE] Dados extraídos de responseData["dados"]');
            } else {
              turmaData = responseData;
              print('📋 [TURMA_SERVICE] Dados são a resposta completa');
            }
          } else {
            throw Exception(
                'Formato de resposta inválido: esperado Map, recebido ${responseData.runtimeType}');
          }

          print('📋 [TURMA_SERVICE] Dados da turma: $turmaData');

          // Verificar se tem os campos esperados
          if (!turmaData.containsKey('cd_turma') &&
              !turmaData.containsKey('numero')) {
            throw Exception(
                'Dados da turma incompletos: campos obrigatórios ausentes');
          }

          return turmaData;
        } catch (e) {
          print('❌ [TURMA_SERVICE] Erro ao processar resposta JSON: $e');
          throw Exception('Erro ao processar resposta do servidor: $e');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Turma não encontrada');
      } else {
        print('❌ [TURMA_SERVICE] Status não é 200: ${response.statusCode}');
        print('📋 [TURMA_SERVICE] Response body: ${response.body}');
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 [TURMA_SERVICE] Erro geral: $e');
      throw Exception('Erro ao buscar turma: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> buscarTurmaPorIdCurso(
      int id) async {
    print('🔍 [TURMA_SERVICE] Iniciando busca por ID: "$id"');

    try {
      // ✅ VALIDAÇÕES PRÉVIAS
      if (id <= 0) {
        throw Exception('ID deve ser um número válido maior que zero');
      }

      print('✅ [TURMA_SERVICE] ID validado: $id');

      // ✅ CONSTRUÇÃO DA URL
      final url = '$baseUrl/turma/listar/curso/$id';
      print('🌐 [TURMA_SERVICE] URL: $url');

      // ✅ HEADERS
      final headers = await _getHeaders();
      print('📋 [TURMA_SERVICE] Headers preparados');

      print('⏳ [TURMA_SERVICE] Fazendo requisição HTTP GET...');

      // ✅ REQUISIÇÃO COM TIMEOUT
      final response = await http
          .get(
        Uri.parse(url),
        headers: headers,
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏰ [TURMA_SERVICE] Timeout da requisição');
          throw Exception('Timeout: A requisição demorou muito para responder');
        },
      );

      print('📡 [TURMA_SERVICE] Resposta recebida');
      print('📊 [TURMA_SERVICE] Status Code: ${response.statusCode}');
      print('📏 [TURMA_SERVICE] Body Length: ${response.body.length}');
      print('📋 [TURMA_SERVICE] Response Body: ${response.body}');

      // ✅ VERIFICAÇÃO DO STATUS CODE
      if (response.statusCode == 200) {
        print('✅ [TURMA_SERVICE] Status 200 - Sucesso');

        // ✅ VALIDAÇÃO DO BODY
        if (response.body.isEmpty) {
          throw Exception('Resposta do servidor está vazia');
        }

        try {
          print('🔄 [TURMA_SERVICE] Decodificando JSON...');
          final responseData = jsonDecode(response.body);
          print('✅ [TURMA_SERVICE] JSON decoded com sucesso');
          print(
              '🔍 [TURMA_SERVICE] Response type: ${responseData.runtimeType}');

          // ✅ TRATAMENTO ESPECÍFICO PARA SUA ESTRUTURA DE RESPOSTA
          List<dynamic> turmasData = [];

          if (responseData is Map<String, dynamic>) {
            // Verificar se tem o campo 'dados' com uma lista
            if (responseData.containsKey('dados') &&
                responseData['dados'] is List) {
              turmasData = responseData['dados'] as List<dynamic>;
              print(
                  '📋 [TURMA_SERVICE] Lista extraída de responseData["dados"] com ${turmasData.length} itens');
            } else {
              print(
                  '⚠️ [TURMA_SERVICE] Estrutura não contém campo "dados" como lista');
              throw Exception(
                  'Estrutura de resposta inválida: campo "dados" não encontrado ou não é uma lista');
            }
          } else {
            throw Exception(
                'Formato de resposta inválido: esperado Map com campo "dados", recebido ${responseData.runtimeType}');
          }

          // ✅ CONVERTER CADA ITEM DA LISTA PARA O FORMATO ESPERADO
          final List<Map<String, dynamic>> turmasProcessadas = [];

          for (var item in turmasData) {
            if (item is Map<String, dynamic>) {
              // Normalizar campos baseado na sua estrutura JSON
              final turmaFormatada = {
                'id': item['cd_turma']?.toString() ?? '',
                'cd_turma': item['cd_turma'] ?? 0,
                'nome':
                    'Turma ${item['numero'] ?? item['cd_turma']}', // Gerar nome baseado no número
                'descricao': 'Turma ${item['numero']} - ${item['curso'] ?? ''}',
                'display_name':
                    'Turma ${item['numero']} - ${item['curso'] ?? ''}',
                'numero': item['numero']?.toString() ?? '',
                'cd_curso': item['cd_curso'] ?? 0,
                'curso': item['curso'] ?? '',
                'ativo': item['ativo'] ?? true,
                'criado_por': item['criado_por'],
                'data_criacao': item['data_criacao'],
                'alterado_por': item['alterado_por'],
                'data_alteracao': item['data_alteracao'],
                'curso_aprendizagem_id': item['cd_curso'] ?? id,
              };

              turmasProcessadas.add(turmaFormatada);
              print(
                  '✅ [TURMA_SERVICE] Turma processada: ${turmaFormatada['display_name']}');
            } else {
              print(
                  '⚠️ [TURMA_SERVICE] Item da lista não é um Map: ${item.runtimeType}');
            }
          }

          print(
              '📊 [TURMA_SERVICE] Total de turmas processadas: ${turmasProcessadas.length}');
          return turmasProcessadas;
        } catch (e) {
          print('❌ [TURMA_SERVICE] Erro ao processar resposta JSON: $e');
          throw Exception('Erro ao processar resposta do servidor: $e');
        }
      } else if (response.statusCode == 404) {
        print('📝 [TURMA_SERVICE] Nenhuma turma encontrada (404)');
        return [];
      } else {
        print('❌ [TURMA_SERVICE] Status não é 200: ${response.statusCode}');
        print('📋 [TURMA_SERVICE] Response body: ${response.body}');
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('💥 [TURMA_SERVICE] Erro geral: $e');
      throw Exception('Erro ao buscar turmas: $e');
    }
  }

  /// Cria uma nova turma
  static Future<bool> criarTurma(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/turma/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        String bRetorno = '';
        final data = jsonDecode(response.body);
        bRetorno = data['erro'] ?? data['message'] ?? 'Erro desconhecido';
        throw Exception(bRetorno);
      }
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      if (e.toString().contains('turma')) {
        rethrow;
      }
      throw Exception('Erro ao criar turma: $e');
    }
  }

  /// Atualiza uma turma existente
  static Future<bool> atualizarTurma(int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/turma/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        final erro =
            data['erro'] ?? data['message'] ?? 'Erro ao atualizar turma';
        throw Exception(erro);
      }
      return response.statusCode == 200;
    } catch (e) {
      if (e.toString().contains('turma')) {
        rethrow;
      }
      throw Exception('Erro ao atualizar turma: $e');
    }
  }

  /// Ativa uma turma
  static Future<bool> ativarTurma(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/turma/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao ativar turma: $e');
      throw Exception('Erro ao ativar turma: $e');
    }
  }

  /// Desativa uma turma
  static Future<bool> desativarTurma(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/turma/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar turma: $e');
    }
  }

  /// Exclui uma turma
  static Future<bool> deletarTurma(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/turma/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir turma: $e');
    }
  }

  /// Lista os cursos de aprendizagem disponíveis para dropdown
  static Future<List<CursoAprendizagemOption>> listarCursosAprendizagem({
    bool apenasAtivos = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': '100',
      };

      if (apenasAtivos) {
        queryParams['ativo'] = 'true';
      }

      final uri = Uri.parse('$baseUrl/curso_aprendizagem/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => CursoAprendizagemOption.fromJson(json))
            .toList();
      } else {
        throw Exception('Erro ao carregar cursos de aprendizagem');
      }
    } catch (e) {
      throw Exception('Erro ao carregar cursos de aprendizagem: $e');
    }
  }

  /// Reordena as turmas
  static Future<bool> reordenarTurmas(List<Map<String, dynamic>> ordem) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/turma/reordenar'),
        headers: await _getHeaders(),
        body: jsonEncode({'ordem': ordem}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao reordenar turmas: $e');
    }
  }

  /// Lista as cores disponíveis para turmas
  static Future<List<String>> listarCoresDisponiveis() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/turma/cores'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['cores']);
      } else {
        // Cores padrão se a API não retornar
        return [
          '#4CAF50', // Verde
          '#2196F3', // Azul
          '#FF9800', // Laranja
          '#9C27B0', // Roxo
          '#F44336', // Vermelho
          '#607D8B', // Azul acinzentado
          '#795548', // Marrom
          '#E91E63', // Rosa
        ];
      }
    } catch (e) {
      // Cores padrão em caso de erro
      return [
        '#4CAF50',
        '#2196F3',
        '#FF9800',
        '#9C27B0',
        '#F44336',
        '#607D8B',
        '#795548',
        '#E91E63',
      ];
    }
  }

  /// Lista estatísticas gerais das turmas
  static Future<Map<String, dynamic>> getEstatisticasGerais() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/turma/estatisticas'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao carregar estatísticas');
      }
    } catch (e) {
      throw Exception('Erro ao carregar estatísticas: $e');
    }
  }

  /// Exporta turmas para CSV
  static Future<void> exportarTurmasCSV({
    bool? ativo,
    int? cursoAprendizagemId,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (cursoAprendizagemId != null) {
        queryParams['cd_curso'] = cursoAprendizagemId.toString();
      }

      final uri = Uri.parse('$baseUrl/turma/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        // TODO: Implementar download do CSV
        print('CSV exportado com sucesso');
      } else {
        throw Exception('Erro ao exportar CSV');
      }
    } catch (e) {
      throw Exception('Erro ao exportar turmas em CSV: $e');
    }
  }

  /// Exporta turmas para PDF
  static Future<List<int>> exportarTurmasPDF({
    bool? ativo,
    int? cursoAprendizagemId,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (cursoAprendizagemId != null) {
        queryParams['cd_curso'] = cursoAprendizagemId.toString();
      }

      final uri = Uri.parse('$baseUrl/turma/exportar/pdf')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erro ao exportar PDF');
      }
    } catch (e) {
      throw Exception('Erro ao exportar turmas em PDF: $e');
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

  /// Obtém turmas ativas com cache
  static Future<List<Turma>> getCachedTurmasAtivas() async {
    const cacheKey = 'turmas_ativas';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached.map<Turma>((json) => Turma.fromJson(json)).toList();
    }

    final result = await listarTurmas(ativo: true, limit: 100);
    final turmasList = result['turmas'] as List<Turma>;
    _setCache(cacheKey, turmasList.map((e) => e.toJson()).toList());
    return turmasList;
  }

  /// Obtém cursos de aprendizagem com cache
  static Future<List<CursoAprendizagemOption>>
      getCachedCursosAprendizagem() async {
    const cacheKey = 'cursos_aprendizagem_opcoes';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached
          .map<CursoAprendizagemOption>(
              (json) => CursoAprendizagemOption.fromJson(json))
          .toList();
    }

    final cursos = await listarCursosAprendizagem();
    _setCache(
        cacheKey,
        cursos
            .map((e) =>
                {'id': e.id, 'nome': e.nome, 'cbo': e.cbo, 'ativo': e.ativo})
            .toList());
    return cursos;
  }

  /// Obtém cores disponíveis com cache
  static Future<List<String>> getCachedCoresDisponiveis() async {
    const cacheKey = 'cores_disponiveis_turmas';
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
    const cacheKey = 'estatisticas_gerais_turmas';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final stats = await getEstatisticasGerais();
    _setCache(cacheKey, stats);
    return stats;
  }
}
