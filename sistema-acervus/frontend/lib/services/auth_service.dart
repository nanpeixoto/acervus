import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
import 'storage_service.dart';

class AuthService {
  static String get baseUrl => AppConfig.apiURLPRD;

  // ==========================================
  // MÉTODOS AUXILIARES
  // ==========================================

  /// Retorna headers básicos
  static Map<String, String> _getBasicHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Retorna headers com token de autenticação
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await StorageService.getToken();
    final headers = _getBasicHeaders();

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Processa resposta HTTP para seu backend específico
  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        // Tratar erros específicos do backend com mensagens mais descritivas
        final errorMessage = body['mensagem'] ??
            body['message'] ??
            body['erro'] ??
            'Erro no servidor';

        // NOVO: Adiciona contexto baseado no status code
        String contextualError = errorMessage;

        switch (response.statusCode) {
          case 400:
            contextualError = 'Dados inválidos: $errorMessage';
            break;
          case 401:
            contextualError = 'Não autorizado: $errorMessage';
            break;
          case 403:
            contextualError = 'Acesso negado: $errorMessage';
            break;
          case 404:
            contextualError = errorMessage; // Já vem descritivo do backend
            break;
          case 409:
            contextualError = 'Conflito: $errorMessage';
            break;
          case 422:
            contextualError = 'Dados inválidos: $errorMessage';
            break;
          case 500:
            contextualError = 'Erro interno do servidor';
            break;
          case 503:
            contextualError = 'Serviço temporariamente indisponível';
            break;
          default:
            contextualError = errorMessage;
        }

        throw Exception(contextualError);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Resposta inválida do servidor');
      }
      rethrow;
    }
  }

  // ==========================================
  // MÉTODOS DE AUTENTICAÇÃO
  // ==========================================

  /// Faz login do usuário usando login e senha
  /// Retorna: { "mensagem": "Login realizado com sucesso.", "usuario": {...} }
  static Future<Map<String, dynamic>> login(String login, String senha) async {
    try {
      final requestBody = {
        'login': login,
        'senha': senha,
      };

      debugPrint('=== LOGIN REQUEST ===');
      debugPrint('URL: $baseUrl/adm/login');
      debugPrint('Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/adm/login'),
        headers: _getBasicHeaders(),
        body: jsonEncode(requestBody),
      );

      debugPrint('=== LOGIN RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      // IMPORTANTE: Processar resposta (irá lançar exception se houver erro)
      final result = _processResponse(response);

      // Se chegou aqui, login foi bem-sucedido
      return result;
    } catch (e) {
      debugPrint('=== LOGIN ERROR ===');
      debugPrint('Error: $e');

      // NOVO: Re-lança a exception original para manter a mensagem
      rethrow;
    }
  }

  /// Faz logout do usuário
  static Future<bool> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/adm/logout'),
        headers: await _getAuthHeaders(),
      );

      final result = _processResponse(response);

      // Verificar se logout foi bem-sucedido baseado na mensagem
      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') || mensagem.contains('realizado');
    } catch (e) {
      // Mesmo se falhar no servidor, consideramos logout bem-sucedido localmente
      return true;
    }
  }

  /// Verifica se o token/sessão ainda é válida
  static Future<bool> verificarToken() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('Token não encontrado no storage');
        return false;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/autenticacao/token/validar'),
        headers: await _getAuthHeaders(),
      );

      // Verifica status codes de erro primeiro
      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('Token expirado/inválido - Status: ${response.statusCode}');
        return false;
      }

      // Se status é 200, processa resposta
      if (response.statusCode == 200) {
        try {
          final result = _processResponse(response);

          // 🔥 CORREÇÃO: Se retorna dados do usuário, MESCLA com dados existentes
          if (result.containsKey('usuario') && result['usuario'] != null) {
            final tokenUserData = result['usuario'];
            await _mergeUserDataFromToken(tokenUserData);
            return true;
          }

          // Verifica mensagem de sucesso
          final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
          return mensagem.contains('valida') ||
              mensagem.contains('ativa') ||
              mensagem.contains('sucesso');
        } catch (e) {
          debugPrint('Erro ao processar resposta mas status 200: $e');
          return true; // Token válido mesmo com erro de parse
        }
      }

      return false;
    } catch (e) {
      debugPrint('Erro ao verificar token: $e');
      return false;
    }
  }

  /// 🔥 NOVO: Mescla dados do token com dados existentes (não substitui)
  static Future<void> _mergeUserDataFromToken(
      Map<String, dynamic> tokenUserData) async {
    try {
      debugPrint('=== _mergeUserDataFromToken DEBUG ===');
      debugPrint('Dados do token: $tokenUserData');

      // 1. Carrega dados existentes do storage
      final existingData = await StorageService.loadUserData();
      debugPrint('Dados existentes no storage: $existingData');

      if (existingData == null) {
        // Se não tem dados existentes, salva os dados do token
        debugPrint('⚠️ Sem dados existentes, salvando dados do token');
        await _updateUserFromTokenValidation(tokenUserData);
        return;
      }

      // 2. Mescla: mantém dados existentes e atualiza apenas campos do token
      final mergedData = Map<String, dynamic>.from(existingData);

      // Atualiza campos que vêm do token (dados mais recentes)
      if (tokenUserData['cd_usuario'] != null) {
        mergedData['cd_usuario'] = tokenUserData['cd_usuario'];
        mergedData['id'] = tokenUserData['cd_usuario']?.toString();
      }

      if (tokenUserData['perfil'] != null) {
        mergedData['perfil'] = tokenUserData['perfil'];
        mergedData['tipo'] = _mapPerfilToTipo(tokenUserData['perfil']);
      }

      // 🔥 CRÍTICO: Atualiza campos de relacionamento apenas se existirem no token
      if (tokenUserData.containsKey('cd_empresa')) {
        mergedData['cd_empresa'] = tokenUserData['cd_empresa'];
      }

      if (tokenUserData.containsKey('cd_instituicao_ensino')) {
        mergedData['cd_instituicao_ensino'] =
            tokenUserData['cd_instituicao_ensino'];
      }

      if (tokenUserData.containsKey('cd_supervisor')) {
        mergedData['cd_supervisor'] = tokenUserData['cd_supervisor'];
      }

      debugPrint('Dados mesclados: $mergedData');
      debugPrint(
          'cd_instituicao_ensino após merge: ${mergedData['cd_instituicao_ensino']}');

      // 3. Salva dados mesclados
      await StorageService.saveUserData(mergedData);

      debugPrint('✅ Dados do usuário mesclados e salvos com sucesso');
    } catch (e) {
      debugPrint('❌ Erro ao mesclar dados: $e');
    }
  }

  /// Método auxiliar para criar dados do usuário pela primeira vez (mantido para compatibilidade)
  static Future<void> _updateUserFromTokenValidation(
      Map<String, dynamic> userData) async {
    try {
      debugPrint('=== _updateUserFromTokenValidation DEBUG ===');
      debugPrint('userData recebido: $userData');

      final mappedData = {
        'id': userData['cd_usuario']?.toString(),
        'cd_usuario': userData['cd_usuario'],
        'perfil': userData['perfil'],
        'nome': userData['nome'] ?? 'Usuário',
        'email': userData['email'] ?? '',
        'login': userData['login'] ?? '',
        'regime': userData['regime'] ?? '',
        'ativo': true,
        'tipo': _mapPerfilToTipo(userData['perfil']),
        'cd_empresa': userData['cd_empresa'],
        'cd_instituicao_ensino': userData['cd_instituicao_ensino'],
        'cd_supervisor': userData['cd_supervisor'],
      };

      debugPrint('Dados mapeados: $mappedData');

      await StorageService.saveUserData(mappedData);

      debugPrint('✅ Dados do usuário salvos');
    } catch (e) {
      debugPrint('❌ Erro ao salvar dados: $e');
    }
  }

  static String _mapPerfilToTipo(String? perfil) {
    if (perfil == null) return 'usuario';

    switch (perfil.toUpperCase()) {
      case 'ADMIN':
        return 'admin';
      case 'EMPRESA':
        return 'empresa';
      case 'ESTAGIARIO':
        return 'estagiario';
      case 'JOVEM_APRENDIZ':
        return 'jovem_aprendiz';
      case 'INSTITUICAO':
        return 'instituicao';
      default:
        return perfil.toLowerCase();
    }
  }

  /// Renova o token de acesso (pode não ser aplicável no seu sistema)
  static Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();

      final response = await http.post(
        Uri.parse('$baseUrl/adm/refresh'),
        headers: _getBasicHeaders(),
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Erro ao renovar token: $e');
    }
  }

  // ==========================================
  // MÉTODOS DE REGISTRO
  // ==========================================

  /// Registra um estagiário
  static Future<bool> registrarEstagiario(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro/estagiario'),
        headers: _getBasicHeaders(),
        body: jsonEncode(dados),
      );

      final result = _processResponse(response);

      // Verificar sucesso baseado na mensagem
      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') ||
          mensagem.contains('cadastrado') ||
          mensagem.contains('criado');
    } catch (e) {
      throw Exception('Erro ao registrar estagiário: $e');
    }
  }

  /// Registra um jovem aprendiz
  static Future<bool> registrarJovemAprendiz(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro/jovem-aprendiz'),
        headers: _getBasicHeaders(),
        body: jsonEncode(dados),
      );

      final result = _processResponse(response);

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') ||
          mensagem.contains('cadastrado') ||
          mensagem.contains('criado');
    } catch (e) {
      throw Exception('Erro ao registrar jovem aprendiz: $e');
    }
  }

  /// Registra uma empresa
  static Future<bool> registrarEmpresa(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro/empresa'),
        headers: _getBasicHeaders(),
        body: jsonEncode(dados),
      );

      final result = _processResponse(response);

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') ||
          mensagem.contains('cadastrado') ||
          mensagem.contains('criado');
    } catch (e) {
      throw Exception('Erro ao registrar empresa: $e');
    }
  }

  /// Registra uma instituição de ensino
  static Future<bool> registrarInstituicao(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registro/instituicao'),
        headers: _getBasicHeaders(),
        body: jsonEncode(dados),
      );

      final result = _processResponse(response);

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') ||
          mensagem.contains('cadastrado') ||
          mensagem.contains('criado');
    } catch (e) {
      throw Exception('Erro ao registrar instituição: $e');
    }
  }

  // ==========================================
  // MÉTODOS DE PERFIL
  // ==========================================

  /// Busca o perfil do usuário logado
  static Future<Map<String, dynamic>> buscarPerfilUsuario() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/adm/perfil'),
        headers: await _getAuthHeaders(),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Erro ao buscar perfil: $e');
    }
  }

  /// Atualiza o perfil do usuário
  static Future<Map<String, dynamic>> atualizarPerfil(
      Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/adm/perfil'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(dados),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Erro ao atualizar perfil: $e');
    }
  }

  /// Atualiza a foto de perfil
  static Future<Map<String, dynamic>> atualizarFotoPerfil(
      String imagePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/adm/perfil/foto'),
      );

      // Adiciona headers de autorização
      final headers = await _getAuthHeaders();
      request.headers.addAll(headers);

      // Adiciona o arquivo
      request.files.add(await http.MultipartFile.fromPath('foto', imagePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } catch (e) {
      throw Exception('Erro ao atualizar foto: $e');
    }
  }

  // ==========================================
  // MÉTODOS DE SENHA
  // ==========================================

  /// Solicita o envio do código de recuperação
  /// Parâmetros opcionais:
  /// - tipo: 'candidato' | 'empresa' | 'instituicao'
  /// - regimeId: '1' (aprendiz) | '2' (estagiário) quando tipo == 'candidato'
  static Future<bool> requestReset(String email,
      {String? tipo, String? regimeId}) async {
    try {
      final body = <String, dynamic>{
        'email': email,
      };

      if (tipo != null && tipo.isNotEmpty) {
        body['tipo'] = tipo; // backend identifica o contexto
      }
      if (regimeId != null && regimeId.isNotEmpty) {
        // envia como regime e regimeId para compatibilidade
        body['regime'] = int.tryParse(regimeId) ?? regimeId;
        body['regimeId'] = int.tryParse(regimeId) ?? regimeId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/request-reset'),
        headers: _getBasicHeaders(),
        body: jsonEncode(body),
      );

      final result = _processResponse(response);
      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') ||
          mensagem.contains('enviado') ||
          result['success'] == true;
    } catch (e) {
      throw Exception('Erro ao solicitar recuperação: $e');
    }
  }

  /// Confirma o código e redefine a senha
  /// Usa o mesmo "code" enviado por e-mail como token
  /// Parâmetros opcionais:
  /// - tipo/regimeId: mesmos do requestReset (para backends que exigem contexto)
  static Future<bool> confirmReset(
    String email,
    String code,
    String novaSenha, {
    String? tipo,
    String? regimeId,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'code': code,
        'nova_senha': novaSenha,
      };

      if (tipo != null && tipo.isNotEmpty) {
        body['tipo'] = tipo;
      }
      if (regimeId != null && regimeId.isNotEmpty) {
        body['regime'] = int.tryParse(regimeId) ?? regimeId;
        body['regimeId'] = int.tryParse(regimeId) ?? regimeId;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/auth/confirm-reset'),
        headers: _getBasicHeaders(),
        body: jsonEncode(body),
      );

      final result = _processResponse(response);
      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') ||
          mensagem.contains('redefinida') ||
          result['success'] == true;
    } catch (e) {
      throw Exception('Erro ao redefinir senha: $e');
    }
  }

  /// Solicita o envio do código de recuperação por e-mail (modo simples)
  static Future<bool> recuperarSenha(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar-senha'),
        headers: _getBasicHeaders(),
        body: jsonEncode({'email': email}),
      );

      final result = _processResponse(response);
      final msg = (result['mensagem'] ?? '').toString().toLowerCase();
      return result['success'] == true ||
          msg.contains('sucesso') ||
          msg.contains('enviado');
    } catch (e) {
      throw Exception('Erro ao solicitar recuperação por e-mail: $e');
    }
  }

  /// Solicita o envio do código de recuperação usando o login/usuário
  static Future<bool> recuperarSenhaPorLogin(String login) async {
    try {
      // Envia para o mesmo endpoint, informando o campo "login"
      final response = await http.post(
        Uri.parse('$baseUrl/recuperar-senha'),
        headers: _getBasicHeaders(),
        body: jsonEncode({'login': login}),
      );

      final result = _processResponse(response);
      final msg = (result['mensagem'] ?? '').toString().toLowerCase();
      return result['success'] == true ||
          msg.contains('sucesso') ||
          msg.contains('enviado');
    } catch (e) {
      throw Exception('Erro ao solicitar recuperação por login: $e');
    }
  }

  /// Redefine a senha usando um token/código recebido por e-mail
  static Future<bool> redefinirSenha(String token, String novaSenha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/redefinir-senha'),
        headers: _getBasicHeaders(),
        body: jsonEncode({
          'token': token,
          'novaSenha': novaSenha,
        }),
      );

      final result = _processResponse(response);
      final msg = (result['mensagem'] ?? '').toString().toLowerCase();
      return result['success'] == true ||
          msg.contains('sucesso') ||
          msg.contains('redefinida') ||
          msg.contains('alterada');
    } catch (e) {
      throw Exception('Erro ao redefinir senha: $e');
    }
  }

  /// Altera a senha do usuário autenticado
  static Future<bool> alterarSenha(String senhaAtual, String novaSenha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/adm/alterar-senha'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          'senhaAtual': senhaAtual,
          'novaSenha': novaSenha,
        }),
      );

      final result = _processResponse(response);
      final msg = (result['mensagem'] ?? '').toString().toLowerCase();
      return result['success'] == true ||
          msg.contains('sucesso') ||
          msg.contains('alterada') ||
          msg.contains('atualizada');
    } catch (e) {
      throw Exception('Erro ao alterar senha: $e');
    }
  }

  // ==========================================
  // MÉTODOS DE VALIDAÇÃO E VERIFICAÇÃO
  // ==========================================

  /// Verifica se o login já está em uso
  static Future<bool> verificarLoginExistente(String login) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verificar-login'),
        headers: _getBasicHeaders(),
        body: jsonEncode({
          'login': login,
        }),
      );

      final result = _processResponse(response);

      // Pode retornar { "existe": true/false } ou { "mensagem": "Login já existe" }
      if (result.containsKey('existe')) {
        return result['existe'] == true;
      }

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('existe') || mensagem.contains('já está em uso');
    } catch (e) {
      return false; // Em caso de erro, assume que não existe
    }
  }

  /// Verifica se o email já está em uso
  static Future<bool> verificarEmailExistente(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verificar-email'),
        headers: _getBasicHeaders(),
        body: jsonEncode({
          'email': email,
        }),
      );

      final result = _processResponse(response);

      if (result.containsKey('existe')) {
        return result['existe'] == true;
      }

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('existe') || mensagem.contains('já está em uso');
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o CPF já está em uso
  static Future<bool> verificarCpfExistente(String cpf) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verificar-cpf'),
        headers: _getBasicHeaders(),
        body: jsonEncode({
          'cpf': cpf,
        }),
      );

      final result = _processResponse(response);

      if (result.containsKey('existe')) {
        return result['existe'] == true;
      }

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('existe') || mensagem.contains('já está em uso');
    } catch (e) {
      return false;
    }
  }

  /// Verifica se o CNPJ já está em uso
  static Future<bool> verificarCnpjExistente(String cnpj) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verificar-cnpj'),
        headers: _getBasicHeaders(),
        body: jsonEncode({
          'cnpj': cnpj,
        }),
      );

      final result = _processResponse(response);

      if (result.containsKey('existe')) {
        return result['existe'] == true;
      }

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('existe') || mensagem.contains('já está em uso');
    } catch (e) {
      return false;
    }
  }

  /// Confirma email do usuário
  static Future<bool> confirmarEmail(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/confirmar-email'),
        headers: _getBasicHeaders(),
        body: jsonEncode({
          'token': token,
        }),
      );

      final result = _processResponse(response);

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') || mensagem.contains('confirmado');
    } catch (e) {
      throw Exception('Erro ao confirmar email: $e');
    }
  }

  /// Reenvia email de confirmação
  static Future<bool> reenviarConfirmacaoEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reenviar-confirmacao'),
        headers: _getBasicHeaders(),
        body: jsonEncode({
          'email': email,
        }),
      );

      final result = _processResponse(response);

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') || mensagem.contains('enviado');
    } catch (e) {
      throw Exception('Erro ao reenviar confirmação: $e');
    }
  }

  // ==========================================
  // MÉTODOS UTILITÁRIOS
  // ==========================================

  /// Testa conectividade com o servidor
  static Future<bool> testarConectividade() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: _getBasicHeaders(),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Busca informações sobre o sistema
  static Future<Map<String, dynamic>> buscarInfoSistema() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/info'),
        headers: _getBasicHeaders(),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Erro ao buscar informações do sistema: $e');
    }
  }

  // ==========================================
  // MÉTODOS PARA OBTER TOKEN
  // ==========================================

  /// Obtém o token atual armazenado
  static Future<String?> getToken() async {
    return await StorageService.getToken();
  }

  /// Obtém o refresh token atual armazenado
  static Future<String?> getRefreshToken() async {
    return await StorageService.getRefreshToken();
  }

  /// Remove tokens do armazenamento local
  static Future<void> clearTokens() async {
    await StorageService.removeToken();
    await StorageService.removeRefreshToken();
  }

  // ==========================================
  // MÉTODOS ESPECÍFICOS PARA SEU SISTEMA
  // ==========================================

  /// Busca usuários (para admins)
  static Future<Map<String, dynamic>> listarUsuarios({
    int page = 1,
    int limit = 20,
    String? search,
    String? perfil,
    bool? ativo,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null) queryParams['search'] = search;
      if (perfil != null) queryParams['perfil'] = perfil;
      if (ativo != null) queryParams['ativo'] = ativo.toString();

      final uri = Uri.parse('$baseUrl/adm/usuarios')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _getAuthHeaders(),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Erro ao listar usuários: $e');
    }
  }

  /// Atualiza usuário (somente admin)
  static Future<bool> atualizarUsuario(
      String userId, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/adm/usuarios/$userId'),
        headers: await _getAuthHeaders(),
        body: jsonEncode(dados),
      );

      final result = _processResponse(response);

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') || mensagem.contains('atualizado');
    } catch (e) {
      throw Exception('Erro ao atualizar usuário: $e');
    }
  }

  /// Ativa/desativa usuário (somente admin)
  static Future<bool> toggleUsuarioAtivo(String userId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/adm/usuarios/$userId/toggle-ativo'),
        headers: await _getAuthHeaders(),
      );

      final result = _processResponse(response);

      final mensagem = result['mensagem']?.toString().toLowerCase() ?? '';
      return mensagem.contains('sucesso') || mensagem.contains('alterado');
    } catch (e) {
      throw Exception('Erro ao alterar status do usuário: $e');
    }
  }
}
