// lib/services/tipo_modelo_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/models/_contratos/modelo/tipo_modelo.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/services/_core/storage_service.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../utils/app_config.dart';
// Imports condicionais (NÃO mude a ordem dos ifs)
import 'package:sistema_estagio/utils/csv_downloader_stub.dart'
    if (dart.library.html) 'package:sistema_estagio/utils/csv_downloader_web.dart'
    if (dart.library.io) 'package:sistema_estagio/utils/csv_downloader_io.dart';

class TipoModeloService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers padrão para requisições
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Lista todos os tipos de modelos com paginação e filtros
  static Future<Map<String, dynamic>> listarTiposModelos({
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

      final uri = Uri.parse('$baseUrl/tipoModelo/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'tiposModelos': (data['dados'] as List)
              .map((json) => TipoModelo.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar tipos de modelos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar tipos de modelos: $e');
    }
  }

  /// Busca um tipo de modelo específico por ID, nome ou descrição
  static Future<List<TipoModelo>?> buscarTipoModelo(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/tipoModelo/buscar')
          .replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => TipoModelo.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar tipo de modelo');
      }
    } catch (e) {
      throw Exception('Erro ao buscar tipo de modelo: $e');
    }
  }

  /// Busca um tipo de modelo por ID
  static Future<TipoModelo> buscarTipoModeloPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tipoModelo/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return TipoModelo.fromJson(data['dados']);
      } else {
        throw Exception('Tipo de modelo não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar tipo de modelo: $e');
    }
  }

  /// Cria um novo tipo de modelo
  static Future<bool> criarTipoModelo(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tipoModelo/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados), // <-- incluirá 'complementar' se vier do form
      );

      // se não estiver em 200/201/204, levanta exceção com a mensagem do backend
      if (response.statusCode != 201 &&
          response.statusCode != 200 &&
          response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Falha ao criar tipo de modelo');
      }

      // ✅ considerar 200/201/204 como sucesso
      return response.statusCode == 201 ||
          response.statusCode == 200 ||
          response.statusCode == 204;
    } catch (e) {
      throw Exception('Erro ao criar tipo de modelo: $e');
    }
  }

  /// Atualiza um tipo de modelo existente
  static Future<bool> atualizarTipoModelo(
      int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tipoModelo/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados), // <-- incluirá 'complementar'
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final data = jsonDecode(response.body);
        throw Exception(data is Map && data['erro'] != null
            ? data['erro']
            : 'Falha ao atualizar tipo de modelo');
      }

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Erro ao atualizar tipo de modelo: $e');
    }
  }

  /// Ativa um tipo de modelo
  static Future<bool> ativarTipoModelo(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tipoModelo/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao ativar tipo de modelo: $e');
    }
  }

  /// Desativa um tipo de modelo
  static Future<bool> desativarTipoModelo(int id, {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tipoModelo/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar tipo de modelo: $e');
    }
  }

  /// Exclui um tipo de modelo
  static Future<bool> deletarTipoModelo(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tipoModelo/excluir/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir tipo de modelo: $e');
    }
  }

  /// Lista todas as categorias disponíveis
  static Future<List<String>> listarCategorias() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tipos-modelos/categorias'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data']);
      } else {
        return [
          'Contrato',
          'Termo Aditivo',
          'Declaração',
          'Convênio',
          'Relatório',
          'Comunicação',
          'Outros',
        ];
      }
    } catch (e) {
      return [
        'Contrato',
        'Termo Aditivo',
        'Declaração',
        'Convênio',
        'Relatório',
        'Comunicação',
        'Outros',
      ];
    }
  }

  /// Lista todos os tipos disponíveis
  static Future<List<String>> listarTipos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tipos-modelos/tipos'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data']);
      } else {
        return ['Estágio', 'Jovem Aprendiz', 'Geral'];
      }
    } catch (e) {
      return ['Estágio', 'Jovem Aprendiz', 'Geral'];
    }
  }

  /// Lista todos os formatos disponíveis
  static Future<List<String>> listarFormatos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tipos-modelos/formatos'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['data']);
      } else {
        return ['PDF', 'DOCX', 'HTML', 'TXT'];
      }
    } catch (e) {
      return ['PDF', 'DOCX', 'HTML', 'TXT'];
    }
  }

  /// Obtém estatísticas gerais dos tipos de modelos
  static Future<Map<String, dynamic>> getEstatisticasGerais() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tipos-modelos/estatisticas'),
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

  /// Duplica um tipo de modelo existente
  static Future<TipoModelo?> duplicarTipoModelo(int id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tipos-modelos/$id/duplicar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return TipoModelo.fromJson(data['data']);
      } else {
        throw Exception('Erro ao duplicar tipo de modelo');
      }
    } catch (e) {
      throw Exception('Erro ao duplicar tipo de modelo: $e');
    }
  }

  /// Valida o template de um tipo de modelo
  static Future<Map<String, dynamic>> validarTemplate(
      String conteudo, List<String> tags) async {
    try {
      final dados = {
        'conteudo': conteudo,
        'tags': tags,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/tipos-modelos/validar-template'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Erro ao validar template');
      }
    } catch (e) {
      throw Exception('Erro ao validar template: $e');
    }
  }

  /// Gera prévia de um documento usando um tipo de modelo
  static Future<String> gerarPrevia(
      int tipoModeloId, Map<String, dynamic> dados) async {
    try {
      final requestData = {
        'tipoModeloId': tipoModeloId,
        'dados': dados,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/tipos-modelos/previa'),
        headers: await _getHeaders(),
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['conteudo'] ?? '';
      } else {
        throw Exception('Erro ao gerar prévia do documento');
      }
    } catch (e) {
      throw Exception('Erro ao gerar prévia do documento: $e');
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

      final uri = Uri.parse('$baseUrl/tipoModelo/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename = _extrairFilename(
                response.headers['content-disposition']) ??
            'tipo_modelo_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

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

  /// Exporta tipos de modelos para PDF
  static Future<List<int>> exportarTiposModelosPDF({
    String? categoria,
    String? tipo,
    bool? ativo,
    String? formato,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (categoria != null) {
        queryParams['categoria'] = categoria;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (formato != null) {
        queryParams['formato'] = formato;
      }

      final uri = Uri.parse('$baseUrl/tipos-modelos/exportar/pdf')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erro ao exportar PDF');
      }
    } catch (e) {
      throw Exception('Erro ao exportar tipos de modelos em PDF: $e');
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

  /// Obtém categorias com cache
  static Future<List<String>> getCachedCategorias() async {
    const cacheKey = 'categorias_tipos_modelos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return List<String>.from(cached);
    }

    final categorias = await listarCategorias();
    _setCache(cacheKey, categorias);
    return categorias;
  }

  /// Obtém tipos com cache
  static Future<List<String>> getCachedTipos() async {
    const cacheKey = 'tipos_tipos_modelos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return List<String>.from(cached);
    }

    final tipos = await listarTipos();
    _setCache(cacheKey, tipos);
    return tipos;
  }

  /// Obtém formatos com cache
  static Future<List<String>> getCachedFormatos() async {
    const cacheKey = 'formatos_tipos_modelos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return List<String>.from(cached);
    }

    final formatos = await listarFormatos();
    _setCache(cacheKey, formatos);
    return formatos;
  }

  /// Obtém estatísticas gerais com cache
  static Future<Map<String, dynamic>> getCachedEstatisticasGerais() async {
    const cacheKey = 'estatisticas_gerais_tipos_modelos';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final stats = await getEstatisticasGerais();
    _setCache(cacheKey, stats);
    return stats;
  }
}
