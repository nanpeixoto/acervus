// lib/services/curso_aprendizagem_service.dart
import 'package:http/http.dart' as http;
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';
import '../../../models/_academico/curso/curso_aprendizagem.dart';

class CursoAprendizagemService {
  static String baseUrl = AppConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Lista todos os cursos de aprendizagem com paginação e filtros
  static Future<Map<String, dynamic>> listarCursosAprendizagem({
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

      final uri = Uri.parse('$baseUrl/curso_aprendizagem/listar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Garantir que sempre retorna uma estrutura válida
        final cursos = data['dados'] != null
            ? (data['dados'] as List)
                .map((json) => CursoAprendizagem.fromJson(json))
                .toList()
            : <CursoAprendizagem>[];

        final pagination = data['pagination'] ??
            {
              'total': cursos.length,
              'page': page,
              'limit': limit,
              'totalPages': (cursos.length / limit).ceil(),
            };

        return {
          'cursos': cursos,
          'pagination': pagination,
        };
      } else {
        throw Exception('Erro ao carregar cursos de aprendizagem');
      }
    } catch (e) {
      print('Erro em listarCursosAprendizagem: $e');
      // Retornar estrutura padrão em caso de erro
      return {
        'cursos': <CursoAprendizagem>[],
        'pagination': {
          'total': 0,
          'page': page,
          'limit': limit,
          'totalPages': 0,
        },
      };
    }
  }

  /// Busca um curso específico por ID, nome do curso ou CBO
  static Future<List<CursoAprendizagem>?> buscarCursoAprendizagem(
      String query) async {
    try {
      final uri = Uri.parse('$baseUrl/curso_aprendizagem/listar')
          .replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => CursoAprendizagem.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar curso de aprendizagem');
      }
    } catch (e) {
      throw Exception('Erro ao buscar curso de aprendizagem: $e');
    }
  }

  /// Busca curso de aprendizagem por ID
  static Future<CursoAprendizagem?> buscarCursoAprendizagemPorId(
      String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/curso_aprendizagem/buscar/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CursoAprendizagem.fromJson(data['dados'] ?? data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Curso de aprendizagem não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar curso de aprendizagem: $e');
    }
  }

  /// Cria um novo curso de aprendizagem
  static Future<bool> criarCursoAprendizagem(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/curso_aprendizagem/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar curso de aprendizagem');
      }
    } catch (e) {
      throw Exception('Erro ao criar curso de aprendizagem: $e');
    }
  }

  /// Atualiza um curso de aprendizagem existente
  static Future<bool> atualizarCursoAprendizagem(
      int id, Map<String, dynamic> dados) async {
    print('iniciando atualização do curso: $id');
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/curso_aprendizagem/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(
            data['erro'] ?? 'Erro ao atualizar curso de aprendizagem');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar curso de aprendizagem: $e');
    }
  }

  /// Deleta um curso de aprendizagem
  static Future<bool> deletarCursoAprendizagem(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/curso_aprendizagem/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(
            data['erro'] ?? 'Erro ao deletar curso de aprendizagem');
      }
    } catch (e) {
      throw Exception('Erro ao deletar curso de aprendizagem: $e');
    }
  }

  /// Ativa/desativa um curso de aprendizagem
  static Future<bool> ativarCursoAprendizagem(String id,
      {required bool ativo}) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/curso_aprendizagem/$id/status'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao alterar status do curso');
      }
    } catch (e) {
      throw Exception('Erro ao alterar status do curso: $e');
    }
  }

  /// Obtém estatísticas gerais dos cursos de aprendizagem
  static Future<Map<String, dynamic>> getEstatisticasGerais() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/curso_aprendizagem/estatisticas'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['dados'] ?? {};
      } else {
        // Retornar estatísticas padrão em caso de erro
        return {
          'total': 0,
          'ativos': 0,
          'inativos': 0,
          'total_modulos': 0,
        };
      }
    } catch (e) {
      print('Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'ativos': 0,
        'inativos': 0,
        'total_modulos': 0,
      };
    }
  }

  static Future<String?> exportarCursosCSV({
    bool? ativo,
    bool? isDefault,
  }) async {
    try {
      final queryParams = <String, String>{};
      // if (ativo != null) queryParams['ativo'] = ativo.toString();
      // if (isDefault != null) queryParams['is_default'] = isDefault.toString();

      final uri = Uri.parse('$baseUrl/curso_aprendizagem/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename = _extrairFilename(
                response.headers['content-disposition']) ??
            'curso_aprendizagem_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        // Usa o helper condicional (Web = download, Mobile/Desktop = salva no disco)
        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(bytes, filename: filename);

        return savedPath; // Na Web será null, no mobile/desktop será o path
      } else {
        throw Exception('Erro ao exportar CSV (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao exportar status de cursos de aprendizagem: $e');
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
}
