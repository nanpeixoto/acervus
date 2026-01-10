// lib/services/user_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';

import 'storage_service.dart';

class UserService {
  static const String baseUrl = 'http://localhost:3001/api';

  // Headers com autenticação
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Headers para upload de arquivos
  static Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  // DASHBOARD DATA
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Erro ao carregar dados do dashboard');
      }
    } catch (e) {
      throw Exception('Erro ao carregar dados do dashboard: $e');
    }
  }

  // USER PROFILE MANAGEMENT
  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/profile'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Perfil não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar perfil: $e');
    }
  }

  static Future<bool> updateProfile(
      String userId, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/profile'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar perfil: $e');
    }
  }

  static Future<bool> updatePassword(
      String userId, String senhaAtual, String novaSenha) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/password'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'senhaAtual': senhaAtual,
          'novaSenha': novaSenha,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar senha: $e');
    }
  }

  static Future<bool> uploadProfilePhoto(
      String userId, String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/$userId/photo'),
      );

      request.headers.addAll(await _getMultipartHeaders());
      request.files.add(await http.MultipartFile.fromPath('photo', imagePath));

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao fazer upload da foto: $e');
    }
  }

  static Future<bool> deleteAccount(String userId, String senha) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: await _getHeaders(),
        body: jsonEncode({'senha': senha}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao deletar conta: $e');
    }
  }

  // USER MANAGEMENT (Admin only)
  static Future<Map<String, dynamic>> listarUsuarios({
    int page = 1,
    int limit = 10,
    String? search,
    String? tipo,
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
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri =
          Uri.parse('$baseUrl/users').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'usuarios': (data['data']['usuarios'] as List)
              .map((json) => Usuario.fromJson(json))
              .toList(),
          'pagination': data['data']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar usuários');
      }
    } catch (e) {
      throw Exception('Erro ao carregar usuários: $e');
    }
  }

  static Future<Usuario> buscarUsuario(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Usuario.fromJson(data['data']);
      } else {
        throw Exception('Usuário não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar usuário: $e');
    }
  }

  static Future<bool> ativarUsuario(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$id/activate'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao ativar usuário: $e');
    }
  }

  static Future<bool> desativarUsuario(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$id/deactivate'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar usuário: $e');
    }
  }

  static Future<bool> redefinirSenha(String id) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/$id/reset-password'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao redefinir senha: $e');
    }
  }

  // NOTIFICATIONS
  static Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 10,
    bool? lida,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (lida != null) {
        queryParams['lida'] = lida.toString();
      }

      final uri = Uri.parse('$baseUrl/users/notifications')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'notificacoes': data['data']['notificacoes'],
          'pagination': data['data']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar notificações');
      }
    } catch (e) {
      throw Exception('Erro ao carregar notificações: $e');
    }
  }

  static Future<bool> marcarNotificacaoComoLida(String notificacaoId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/notifications/$notificacaoId/read'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao marcar notificação como lida: $e');
    }
  }

  static Future<bool> marcarTodasNotificacoesComoLidas() async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/notifications/read-all'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao marcar todas notificações como lidas: $e');
    }
  }

  static Future<int> getNotificacoesNaoLidas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/notifications/unread-count'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  // ACTIVITY LOG
  static Future<Map<String, dynamic>> getActivityLog({
    int page = 1,
    int limit = 10,
    String? action,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (action != null) {
        queryParams['action'] = action;
      }
      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/users/activity')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'atividades': data['data']['atividades'],
          'pagination': data['data']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar log de atividades');
      }
    } catch (e) {
      throw Exception('Erro ao carregar log de atividades: $e');
    }
  }

  // PREFERENCES
  static Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/preferences'),
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

  static Future<bool> updatePreferences(
      Map<String, dynamic> preferences) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/preferences'),
        headers: await _getHeaders(),
        body: jsonEncode(preferences),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar preferências: $e');
    }
  }

  // SEARCH USERS
  static Future<List<Usuario>> searchUsers(String query, {String? tipo}) async {
    try {
      final queryParams = <String, String>{
        'q': query,
        'limit': '50',
      };

      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }

      final uri = Uri.parse('$baseUrl/users/search')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((json) => Usuario.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // REPORTS
  static Future<Map<String, dynamic>> getUsersReport({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? tipo,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String();
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }

      final uri = Uri.parse('$baseUrl/users/reports')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Erro ao gerar relatório');
      }
    } catch (e) {
      throw Exception('Erro ao gerar relatório: $e');
    }
  }

  static Future<String> exportUsersToCSV({
    String? tipo,
    bool? ativo,
  }) async {
    try {
      final queryParams = <String, String>{
        'format': 'csv',
      };

      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri = Uri.parse('$baseUrl/users/export')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Erro ao exportar dados');
      }
    } catch (e) {
      throw Exception('Erro ao exportar dados: $e');
    }
  }

  // STATISTICS
  static Future<Map<String, dynamic>> getUsersStatistics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/statistics'),
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

  static Future<Map<String, dynamic>> getRegistrationTrends({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? agrupamento = 'day', // day, week, month
  }) async {
    try {
      final queryParams = <String, String>{
        'agrupamento': agrupamento!,
      };

      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/users/trends')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

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

  // PROFILE TYPE SPECIFIC METHODS
  static Future<Map<String, dynamic>> getEstagiarioData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/estagiario'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Dados do estagiário não encontrados');
      }
    } catch (e) {
      throw Exception('Erro ao buscar dados do estagiário: $e');
    }
  }

  static Future<Map<String, dynamic>> getEmpresaData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/empresa'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Dados da empresa não encontrados');
      }
    } catch (e) {
      throw Exception('Erro ao buscar dados da empresa: $e');
    }
  }

  static Future<Map<String, dynamic>> getInstituicaoData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/instituicao'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Dados da instituição não encontrados');
      }
    } catch (e) {
      throw Exception('Erro ao buscar dados da instituição: $e');
    }
  }

  static Future<Map<String, dynamic>> getJovemAprendizData(
      String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/jovem-aprendiz'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception('Dados do jovem aprendiz não encontrados');
      }
    } catch (e) {
      throw Exception('Erro ao buscar dados do jovem aprendiz: $e');
    }
  }

  // AUDIT TRAIL
  static Future<Map<String, dynamic>> getAuditTrail(
    String userId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/users/$userId/audit')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'auditoria': data['data']['auditoria'],
          'pagination': data['data']['pagination'],
        };
      } else {
        return {'auditoria': [], 'pagination': {}};
      }
    } catch (e) {
      return {'auditoria': [], 'pagination': {}};
    }
  }

  // EMAIL VERIFICATION
  static Future<bool> resendEmailVerification() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/resend-verification'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao reenviar email de verificação: $e');
    }
  }

  static Future<bool> verifyEmail(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao verificar email: $e');
    }
  }

  // SUPPORT
  static Future<bool> contactSupport({
    required String assunto,
    required String mensagem,
    String? categoria,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/support'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'assunto': assunto,
          'mensagem': mensagem,
          'categoria': categoria,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao enviar mensagem para suporte: $e');
    }
  }

  // DATA EXPORT (LGPD Compliance)
  static Future<Map<String, dynamic>> requestDataExport() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/export-data'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Erro ao solicitar exportação de dados');
      }
    } catch (e) {
      throw Exception('Erro ao solicitar exportação de dados: $e');
    }
  }

  static Future<bool> requestDataDeletion(String motivo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/delete-data'),
        headers: await _getHeaders(),
        body: jsonEncode({'motivo': motivo}),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao solicitar exclusão de dados: $e');
    }
  }

  // SYSTEM HEALTH
  static Future<bool> ping() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getSystemStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/status'),
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

  // HELPER METHODS
  static String getProfileTypeDisplayName(TipoUsuario tipo) {
    switch (tipo) {
      case TipoUsuario.ADMIN:
        return 'Administrador';
      case TipoUsuario.COLABORADOR:
        return 'Colaborador';
      case TipoUsuario.ESTAGIARIO:
        return 'Estagiário';
      case TipoUsuario.EMPRESA:
        return 'Empresa';
      case TipoUsuario.SUPERVISOR:
        return 'Supervisor';
      case TipoUsuario.INSTITUICAO:
        return 'Instituição de Ensino';
      case TipoUsuario.JOVEM_APRENDIZ:
        return 'Jovem Aprendiz';
    }
  }

  static bool canPerformAction(TipoUsuario userType, String action) {
    const adminActions = [
      'delete_user',
      'deactivate_user',
      'view_all_users',
      'export_data',
      'view_reports',
      'manage_system',
    ];

    const colaboradorActions = [
      'view_users',
      'edit_users',
      'view_reports',
      'manage_contracts',
    ];

    switch (userType) {
      case TipoUsuario.ADMIN:
        return true; // Admin pode fazer tudo
      case TipoUsuario.COLABORADOR:
        return colaboradorActions.contains(action) ||
            adminActions.contains(action);
      default:
        return false; // Outros tipos só podem gerenciar próprio perfil
    }
  }

  // CACHE MANAGEMENT
  static const Duration _cacheTimeout = Duration(minutes: 5);
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

  // CACHED DASHBOARD DATA
  static Future<Map<String, dynamic>> getCachedDashboardData() async {
    const cacheKey = 'dashboard_data';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final data = await getDashboardData();
    _setCache(cacheKey, data);
    return data;
  }

  // ERROR HANDLING HELPER
  static Exception _handleError(dynamic error, String operation) {
    if (error is http.ClientException) {
      return Exception('Erro de conexão durante $operation');
    } else if (error.toString().contains('SocketException')) {
      return Exception('Sem conexão com internet durante $operation');
    } else if (error.toString().contains('TimeoutException')) {
      return Exception('Timeout durante $operation');
    } else {
      return Exception('Erro inesperado durante $operation: $error');
    }
  }
}
