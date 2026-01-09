// lib/services/modelo_contrato_service.dart
import 'dart:html' as html;
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/utils/app_config.dart';
import '../../../models/_contratos/modelo/modelo_contrato.dart';
import '../../../models/_contratos/modelo/tipo_modelo.dart';
import '../../_core/storage_service.dart';

class ModeloContratoService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers com autenticação
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // CRUD BÁSICO
  static Future<Map<String, dynamic>> listarModelosContrato({
    int page = 1,
    int limit = 20,
    String? search,
    String? tipoModelo,
    int? idTipoModelo,
    bool? ativo,
    bool? modelo,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['q'] = search;
      }
      if (idTipoModelo != null) {
        queryParams['id_tipo_modelo'] = idTipoModelo.toString();
      }
      if (modelo != null) {
        queryParams['modelo'] = modelo.toString();
      }
      if (tipoModelo != null && tipoModelo.isNotEmpty) {
        queryParams['tipo_modelo'] = tipoModelo;
      }

      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri = Uri.parse('$baseUrl/modelo/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      ////print('Response status: ${response.statusCode}');
      ////print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'modelos': (data['dados'] as List)
              .map((json) => ModeloContrato.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar modelos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar modelos: $e');
    }
  }

// Métodos auxiliares para conversão segura de tipos
  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    if (value is double) return value.toInt();
    return 0;
  }

  static bool _safeToBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }

  static Future<ModeloContrato?> buscarModeloContrato(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/modelo/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ModeloContrato.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro ao buscar modelo: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar modelo de contrato: $e');
    }
  }

  static Future<List<ModeloContrato>> buscarModeloPorNome(String nome) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/modelo/buscar?nome=$nome'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data']['modelos'] != null) {
          return (data['data']['modelos'] as List)
              .map((json) => ModeloContrato.fromJson(json))
              .toList();
        }
        return [];
      } else {
        throw Exception(
            'Erro ao buscar modelo por nome: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar modelo por nome: $e');
    }
  }

  static Future<bool> criarModeloContrato(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/modelo/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao criar modelo');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro ao criar modelo de contrato: $e');
    }
  }

  static Future<bool> atualizarModeloContrato(
      int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/modelo/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao atualizar modelo');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro ao atualizar modelo de contrato: $e');
    }
  }

  static Future<bool> deletarModeloContrato(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/modelo/excluir/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao excluir modelo');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro ao excluir modelo de contrato: $e');
    }
  }

  static Future<bool> ativarModeloContrato(int id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/modelo/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao ativar modelo de contrato: $e');
    }
  }

  static Future<bool> desativarModeloContrato(int id,
      {bool ativo = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/modelo/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar modelo de contrato: $e');
    }
  }

  // FUNCIONALIDADES DE TIPOS DE MODELO
  static Future<List<TipoModelo>> listarTiposModeloAtivos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tipoModelo/listar?ativo=true&limit=100'),
        headers: await _getHeaders(),
      );

      //print('Response status: ${response.statusCode}');
      //print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //print('Dados decodificados: $data'); // Debug completo

        // Tratamento mais robusto da estrutura de dados
        List<dynamic> tiposModelos = [];

        // Primeira tentativa: dados.tiposModelos
        if (data is Map &&
            data['dados'] is Map &&
            data['dados']['tiposModelos'] is List) {
          tiposModelos = data['dados']['tiposModelos'];
        }
        // Segunda tentativa: tiposModelos direto
        else if (data is Map && data['tiposModelos'] is List) {
          tiposModelos = data['tiposModelos'];
        }
        // Terceira tentativa: data é diretamente uma lista
        else if (data is List) {
          tiposModelos = data;
        }
        // Quarta tentativa: verificar se há uma chave 'data'
        else if (data is Map &&
            data['data'] is Map &&
            data['data']['tiposModelos'] is List) {
          tiposModelos = data['data']['tiposModelos'];
        }
        // Quinta tentativa: data.data como lista direta
        else if (data is Map && data['data'] is List) {
          tiposModelos = data['data'];
        }
        // Sexta tentativa: verificar estrutura aninhada em 'dados'
        else if (data is Map && data['dados'] is List) {
          tiposModelos = data['dados'];
        }
        // Sétima tentativa: buscar qualquer lista no primeiro nível
        else if (data is Map) {
          for (var value in data.values) {
            if (value is List) {
              tiposModelos = value;
              break;
            }
          }
        }

        final result = <TipoModelo>[];
        for (var item in tiposModelos) {
          try {
            if (item is Map<String, dynamic>) {
              result.add(TipoModelo.fromJson(item));
            }
          } catch (e) {
            //print('Erro ao processar item: $item - Erro: $e');
            // Continua processando os outros itens
          }
        }

        //print('Tipos de modelo processados: ${result.length}');
        return result;
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      //print('Erro detalhado: $e');
      throw Exception('Erro ao carregar tipos de modelo ativos: $e');
    }
  }

  // ESTATÍSTICAS
  static Future<Map<String, dynamic>> getEstatisticasModelos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/modelo/estatisticas'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        return {
          'total': 0,
          'ativos': 0,
          'inativos': 0,
          'porTipo': <Map<String, dynamic>>[],
        };
      }
    } catch (e) {
      // Retorna estatísticas vazias em caso de erro
      return {
        'total': 0,
        'ativos': 0,
        'inativos': 0,
        'porTipo': <Map<String, dynamic>>[],
      };
    }
  }

  // Cache para estatísticas
  static Map<String, dynamic>? _cachedStats;
  static DateTime? _lastStatsUpdate;

  static Future<Map<String, dynamic>> getCachedEstatisticasModelos() async {
    // Cache por 5 minutos
    if (_cachedStats != null &&
        _lastStatsUpdate != null &&
        DateTime.now().difference(_lastStatsUpdate!).inMinutes < 5) {
      return _cachedStats!;
    }

    try {
      _cachedStats = await getEstatisticasModelos();
      _lastStatsUpdate = DateTime.now();
      return _cachedStats!;
    } catch (e) {
      // Retorna cache antigo ou estatísticas vazias
      return _cachedStats ??
          {
            'total': 0,
            'ativos': 0,
            'inativos': 0,
            'porTipo': <Map<String, dynamic>>[],
          };
    }
  }

  // FUNCIONALIDADES DE EXPORTAÇÃO
  static Future<void> exportarModelosCSV({
    int? idTipoModelo,
    bool? ativo,
    bool? modelo,
  }) async {
    try {
      final queryParams = <String, String>{
        'formato': 'csv',
      };

      if (idTipoModelo != null) {
        queryParams['id_tipo_modelo'] = idTipoModelo.toString();
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (modelo != null) {
        queryParams['modelo'] = modelo.toString();
      }

      final uri = Uri.parse('$baseUrl/modelo/exportar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        // Criar blob e fazer download
        final bytes = response.bodyBytes;
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download =
              'modelos_contrato_${DateTime.now().millisecondsSinceEpoch}.csv';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        throw Exception('Erro ao exportar modelos');
      }
    } catch (e) {
      throw Exception('Erro ao exportar modelos de contrato: $e');
    }
  }

  // FUNCIONALIDADES DE DUPLICAÇÃO
  static Future<bool> duplicarModeloContrato(int id, String novoNome) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/modelo/$id/duplicar'),
        headers: await _getHeaders(),
        body: jsonEncode({'nome': novoNome}),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao duplicar modelo');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erro ao duplicar modelo de contrato: $e');
    }
  }

  // VALIDAÇÕES
  static Future<bool> validarNomeModeloUnico(String nome,
      {int? excludeId}) async {
    try {
      final queryParams = <String, String>{
        'nome': nome,
      };

      if (excludeId != null) {
        queryParams['exclude_id'] = excludeId.toString();
      }

      final uri = Uri.parse('$baseUrl/modelo/validar-nome')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['disponivel'] ?? false;
      }
      return false;
    } catch (e) {
      // Em caso de erro, assume que o nome não está disponível
      return false;
    }
  }
}
