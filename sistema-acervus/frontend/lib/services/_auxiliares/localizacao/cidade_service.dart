// lib/services/cidade_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/services/_core/storage_service.dart';
import '../../../models/_auxiliares/localizacao/cidade.dart';
import '../../../utils/app_config.dart';
import '../../_core/auth_service.dart';

class CidadeService {
  static const String _endpoint = '/cidades';

  static Future<List<Cidade>> listarCidades({
    String? uf,
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final Map<String, String> queryParams = {};

      if (uf != null) queryParams['uf'] = uf;
      if (search != null) queryParams['search'] = search;
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse('${AppConfig.baseUrl}$_endpoint').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(
        uri,
        headers: _getBasicHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> cidadesJson = data['data'] ?? data;

        return cidadesJson.map((json) => Cidade.fromJson(json)).toList();
      } else {
        throw Exception('Erro ao carregar cidades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Cidade?> buscarCidadePorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}$_endpoint/$id'),
        headers: _getBasicHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Cidade.fromJson(data['data'] ?? data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro ao buscar cidade: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<bool> criarCidade(Cidade cidade) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}$_endpoint'),
        headers: _getBasicHeaders(),
        body: json.encode(cidade.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao criar cidade');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Erro de conexão com o servidor');
      }
      rethrow;
    }
  }

  static Future<bool> atualizarCidade(Cidade cidade) async {
    try {
      if (cidade.id == null) {
        throw Exception('ID da cidade é obrigatório para atualização');
      }

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}$_endpoint/${cidade.id}'),
        headers: _getBasicHeaders(),
        body: json.encode(cidade.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao atualizar cidade');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Erro de conexão com o servidor');
      }
      rethrow;
    }
  }

  static Future<bool> excluirCidade(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}$_endpoint/$id'),
        headers: _getBasicHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao excluir cidade');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Erro de conexão com o servidor');
      }
      rethrow;
    }
  }

  static Future<List<String>> listarUFs() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}$_endpoint/ufs'),
        headers: _getBasicHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ufsJson = data['data'] ?? data;

        return ufsJson.map((uf) => uf.toString()).toList();
      } else {
        // Retorna lista padrão de UFs caso a API não tenha o endpoint
        return [
          'AC',
          'AL',
          'AP',
          'AM',
          'BA',
          'CE',
          'DF',
          'ES',
          'GO',
          'MA',
          'MT',
          'MS',
          'MG',
          'PA',
          'PB',
          'PR',
          'PE',
          'PI',
          'RJ',
          'RN',
          'RS',
          'RO',
          'RR',
          'SC',
          'SP',
          'SE',
          'TO'
        ];
      }
    } catch (e) {
      // Retorna lista padrão em caso de erro
      return [
        'AC',
        'AL',
        'AP',
        'AM',
        'BA',
        'CE',
        'DF',
        'ES',
        'GO',
        'MA',
        'MT',
        'MS',
        'MG',
        'PA',
        'PB',
        'PR',
        'PE',
        'PI',
        'RJ',
        'RN',
        'RS',
        'RO',
        'RR',
        'SC',
        'SP',
        'SE',
        'TO'
      ];
    }
  }

  static Future<Map<String, List<Cidade>>> agruparCidadesPorRegiao() async {
    try {
      final cidades = await listarCidades();
      final Map<String, List<Cidade>> cidadesPorRegiao = {};

      for (var cidade in cidades) {
        if (!cidadesPorRegiao.containsKey(cidade.regiao)) {
          cidadesPorRegiao[cidade.regiao] = [];
        }
        cidadesPorRegiao[cidade.regiao]!.add(cidade);
      }

      // Ordena cidades dentro de cada região
      cidadesPorRegiao.forEach((regiao, cidades) {
        cidades.sort((a, b) => a.nome.compareTo(b.nome));
      });

      return cidadesPorRegiao;
    } catch (e) {
      throw Exception('Erro ao agrupar cidades por região: $e');
    }
  }

  static Future<bool> importarCidades(
      List<Map<String, dynamic>> cidadesData) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}$_endpoint/import'),
        headers: _getBasicHeaders(),
        body: json.encode({'cidades': cidadesData}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao importar cidades');
      }
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Erro de conexão com o servidor');
      }
      rethrow;
    }
  }

  static Map<String, String> _getBasicHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await StorageService.getToken();
    final headers = _getBasicHeaders();

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
