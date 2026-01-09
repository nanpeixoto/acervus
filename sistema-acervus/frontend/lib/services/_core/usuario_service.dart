// lib/services/usuario_service.dart
import 'package:http/http.dart' as http;
import '../../models/_core/usuario.dart';
import '../../utils/app_config.dart';
import 'storage_service.dart';

class UsuarioService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers padrão
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    };
  }

  /// Lista todos os usuários
  static Future<Map<String, dynamic>> listarUsuarios({
    int page = 1,
    int limit = 10,
    String? search,
    bool? ativo,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ativo != null) queryParams['ativo'] = ativo.toString();

      final uri = Uri.parse('$baseUrl/usuario/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'usuarios': (data['dados'] as List)
              .map((json) => Usuario.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar usuários');
      }
    } catch (e) {
      throw Exception('Erro ao carregar usuários: $e');
    }
  }

  /// Busca usuários por texto
  static Future<List<Usuario>> buscarUsuario(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/usuario/listar')
          .replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => Usuario.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  /// Busca por ID
  static Future<Usuario> buscarUsuarioPorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuario/$id'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Usuario.fromJson(data['dados']);
      } else {
        throw Exception('Usuário não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  /// Cria novo usuário
  static Future<bool> criarUsuario(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuario/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );
      if (![200, 201, 204].contains(response.statusCode)) {
        final data = jsonDecode(response.body);
        throw Exception(data['erro'] ?? 'Erro ao criar usuário');
      }
      return true;
    } catch (e) {
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  /// Atualiza usuário
  static Future<bool> atualizarUsuario(
      String id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/usuario/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  /// Ativa/Desativa
  static Future<bool> ativarUsuario(String id, {bool ativo = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/usuario/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({'ativo': ativo}),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao alterar status do usuário: $e');
    }
  }

  static Future<bool> desativarUsuario(String id) =>
      ativarUsuario(id, ativo: false);

  /// Exclui
  static Future<bool> deletarUsuario(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/usuario/excluir/$id'),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao excluir usuário: $e');
    }
  }

  /// Estatísticas
  static Future<Map<String, dynamic>> getEstatisticas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuario/estatisticas'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  // ======================
  // MÉTODOS DE CACHE
  // ======================

  static const _cacheTimeout = Duration(minutes: 10);
  static final _cache = <String, dynamic>{};
  static final _cacheTimestamps = <String, DateTime>{};

  static void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static dynamic _getCache(String key) {
    final ts = _cacheTimestamps[key];
    if (ts != null && DateTime.now().difference(ts) < _cacheTimeout) {
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

  /// Lista usuários ativos com cache
  static Future<List<Usuario>> getCachedUsuariosAtivos() async {
    const cacheKey = 'usuarios_ativos';
    final cached = _getCache(cacheKey);
    if (cached != null) {
      return cached.map<Usuario>((json) => Usuario.fromJson(json)).toList();
    }
    final result = await listarUsuarios(ativo: true, limit: 100);
    final list = result['usuarios'] as List<Usuario>;
    _setCache(cacheKey, list.map((e) => e.toJson()).toList());
    return list;
  }
}
