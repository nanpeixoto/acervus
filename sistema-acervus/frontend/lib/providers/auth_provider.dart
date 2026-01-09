import 'package:flutter/material.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import '../models/_core/usuario.dart';
import '../services/_core/auth_service.dart';
import '../services/_core/storage_service.dart';
import '../routes/app_router.dart';

const String baseUrl = AppConfig.devBaseUrl;
const bool _BYPASS_LOGIN_FOR_TESTING = false; // MUDE PARA false EM PRODUÇÃO

class AuthProvider extends ChangeNotifier {
  Usuario? _usuario;
  bool _isLoading = false;
  String? _token;
  bool _isLoginInProgress = false;
  String? _lastError;

  // NOVO: cache do userData bruto carregado/salvo
  Map<String, dynamic>? _userDataCache;

  // Getters existentes
  Usuario? get usuario => _usuario;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _usuario != null;
  String? get token => _token;
  bool get isLoginInProgress => _isLoginInProgress;
  String? get lastError => _lastError;

  // NOVO: Getter para compatibilidade
  Usuario? get user => _usuario;
  bool get isLoggedIn => isAuthenticated;

  // NOVOS: Getters adicionais úteis
  String? get userName => _usuario?.nome;
  String? get userEmail => _usuario?.email;
  int? get userId => _usuario?.id;
  bool get hasUser => _usuario != null;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  AuthProvider() {
    _initializeAuth();
  }

  // ATUALIZADO: Método de inicialização com verificação de token
  Future<void> _initializeAuth() async {
    try {
      await _loadUserFromStorage();

      // CORREÇÃO: Se tem usuário e token, verifica validade MAS sem chamar reloadUser
      if (_usuario != null && _token != null) {
        // Verifica token em background, sem bloquear a UI
        AuthService.verificarToken().then((tokenValido) {
          if (!tokenValido) {
            debugPrint('Token expirado durante inicialização, fazendo logout');
            _clearAuthData();
          }
        }).catchError((e) {
          debugPrint('Erro na verificação em background: $e');
        });
      }
    } catch (e) {
      debugPrint('Erro ao inicializar autenticação: $e');
      await _clearAuthData();
    }
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final token = await StorageService.loadToken();
      final userData = await StorageService.loadUserData();

      debugPrint('=== LOAD FROM STORAGE DEBUG ===');
      debugPrint('Token exists: ${token != null}');
      debugPrint('UserData exists: ${userData != null}');
      debugPrint('UserData content: $userData');

      // 🔥 CRÍTICO: Verificar se cd_instituicao_ensino está presente
      if (userData != null) {
        debugPrint(
            'cd_instituicao_ensino no storage: ${userData['cd_instituicao_ensino']}');
        debugPrint('cd_empresa no storage: ${userData['cd_empresa']}');
        debugPrint('cd_supervisor no storage: ${userData['cd_supervisor']}');

        // NOVO: garantir chaves estáveis para "Meu Perfil"
        userData['cd_usuario'] ??= userData['id'] ?? userData['cd_candidato'];
        userData['regime'] ??= userData['regime_id'] ??
            userData['regimeId'] ??
            userData['tipoRegime'];
        debugPrint('cd_usuario normalizado: ${userData['cd_usuario']}');
        debugPrint('regime normalizado: ${userData['regime']}');
      }
      debugPrint('==============================');

      // CORREÇÃO: Só carrega usuário se TEM dados E TEM token
      if (userData != null && token != null && token.isNotEmpty) {
        _token = token;

        try {
          // 🔥 ANTES de criar o usuário, garantir que os campos estão presentes
          // Se estiverem faltando, adicionar valores nulos explícitos
          if (!userData.containsKey('cd_instituicao_ensino')) {
            debugPrint('⚠️ cd_instituicao_ensino ausente no userData!');
            userData['cd_instituicao_ensino'] = null;
          }

          if (!userData.containsKey('cd_empresa')) {
            userData['cd_empresa'] = null;
          }

          if (!userData.containsKey('cd_supervisor')) {
            userData['cd_supervisor'] = null;
          }

          // GARANTE novamente as chaves do perfil
          userData['cd_usuario'] ??= userData['id'] ?? userData['cd_candidato'];
          userData['regime'] ??= userData['regime_id'] ??
              userData['regimeId'] ??
              userData['tipoRegime'];

          _usuario = Usuario.fromJson(userData);
          // NOVO: garante cache após criar o model
          _userDataCache ??= Map<String, dynamic>.from(userData);
        } catch (e) {
          debugPrint('❌ Erro ao criar Usuario do storage: $e');
          debugPrint('Tentando criar usuario com dados básicos...');

          // Fallback: criar usuário com dados mínimos se fromJson falhar
          _usuario = Usuario.fromJson({
            'id': userData['id']?.toString() ??
                userData['cd_usuario']?.toString() ??
                userData['cd_candidato']?.toString() ??
                '0',
            'nome': userData['nome'] ?? 'Usuário',
            'login': userData['login'] ?? '',
            'email': userData['email'] ?? '',
            'perfil': userData['perfil'] ?? 'USER',

            // 🔥 CRÍTICO: Preservar campos de relacionamento no fallback
            'cd_instituicao_ensino': userData['cd_instituicao_ensino'],
            'cd_empresa': userData['cd_empresa'],
            'cd_supervisor': userData['cd_supervisor'],

            // Chaves do perfil
            'cd_usuario': userData['cd_usuario'] ??
                userData['id'] ??
                userData['cd_candidato'],
            'regime': userData['regime'] ??
                userData['regime_id'] ??
                userData['regimeId'] ??
                userData['tipoRegime'],
            'regime_id': userData['regime_id'] ?? userData['regime'],
            'regimeId': userData['regimeId'] ?? userData['regime'],

            'tipo': _mapPerfilToTipo(userData['perfil']),
            'ativo': userData['ativo'] ?? true,
          });
          debugPrint('✅ Usuario fallback criado: ${_usuario?.nome}');
          debugPrint(
              '   - cdInstituicaoEnsino no fallback: ${_usuario?.cdInstituicaoEnsino}');
        }

        notifyListeners();
      } else if (userData != null && (token == null || token.isEmpty)) {
        // Se tem dados mas não tem token, limpa tudo
        debugPrint('⚠️ Dados de usuário sem token válido, limpando...');
        await _clearAuthData();
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar dados do usuário: $e');
      await _clearAuthData();
    }
  }

  // CORRIGIDO: Login com melhor sincronização
  Future<bool> login(String login, String senha) async {
    _lastError = null;

    try {
      _isLoading = true;
      _isLoginInProgress = true;

      debugPrint('=== TENTANDO LOGIN ===');
      debugPrint('Login: $login');

      final response = await AuthService.login(login, senha);

      debugPrint('=== RESPOSTA DO LOGIN ===');
      debugPrint('Response completo: $response');

      // Verifica se há dados de usuário
      Map<String, dynamic>? userData;
      String? accessToken;

      // IMPORTANTE: Verificar TODAS as possíveis estruturas de resposta
      if (response.containsKey('usuario')) {
        userData = response['usuario'];
        // Procurar o token em diferentes lugares
        accessToken = response['token'] ??
            response['access_token'] ??
            response['accessToken'];
      } else if (response.containsKey('data')) {
        userData = response['data']['usuario'] ?? response['data']['user'];
        accessToken = response['data']['token'] ??
            response['data']['access_token'] ??
            response['data']['accessToken'];
      } else if (response.containsKey('user')) {
        userData = response['user'];
        accessToken = response['token'] ?? response['access_token'];
      }

      // SE não encontrou token, procurar no nível raiz
      accessToken ??= response['token'] ??
          response['access_token'] ??
          response['accessToken'];

      debugPrint('Token extraído: $accessToken');
      debugPrint('UserData encontrado: ${userData != null}');

      if (userData != null) {
        debugPrint('=== PROCESSANDO DADOS DO USUÁRIO ===');

        // Mapeia dados do backend
        final mappedUserData = _mapBackendUserData(userData);

        try {
          _usuario = Usuario.fromJson(mappedUserData);
          debugPrint('Usuario criado: ${_usuario?.nome}');
        } catch (e) {
          debugPrint('Erro ao criar Usuario: $e');
          // Criação de fallback
          _usuario = Usuario.fromJson({
            'id': userData['cd_usuario']?.toString() ??
                userData['id']?.toString() ??
                '0',
            'nome': userData['nome'] ?? 'Usuário',
            'login': userData['login'] ?? '',
            'email': userData['email'] ?? '',
            'perfil': userData['perfil'] ?? 'USER',
            'cd_instituicao_ensino': userData['cd_instituicao_ensino'],
            'cd_empresa': userData['cd_empresa'],
            'cd_supervisor': userData['cd_supervisor'],
            'tipo': _mapPerfilToTipo(userData['perfil']),
            'ativo': userData['ativo'] ?? true,
          });
        }

        _token = accessToken ?? 'no-token';

        // IMPORTANTE: Se não tem token válido, falha o login
        if (_token == 'no-token' || _token == null || _token!.isEmpty) {
          debugPrint('⚠️ AVISO: Login sem token válido retornado!');
          // Você pode optar por continuar ou falhar aqui
          return false; // Descomente se quiser falhar sem token
        }

        debugPrint('Salvando token: $_token');

        // Salva os dados
        await StorageService.saveUserData(_usuario!.toJson());
        await StorageService.saveToken(_token!);

        // IMPORTANTE: Pequeno delay para garantir sincronização
        await Future.delayed(const Duration(milliseconds: 100));

        _isLoading = false;
        _isLoginInProgress = false;

        // NOTIFICA APENAS EM CASO DE SUCESSO
        notifyListeners();

        return true;
      }

      // LOGIN FALHOU - NÃO NOTIFICA LISTENERS
      _isLoading = false;
      _isLoginInProgress = false;
      _lastError = 'Login ou senha incorretos';
      // NÃO CHAME notifyListeners() aqui!
      return false;
    } catch (e) {
      debugPrint('Erro no login: $e');
      _isLoading = false;
      _isLoginInProgress = false;
      _lastError = e.toString();
      // NÃO CHAME notifyListeners() aqui!
      return false;
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool _isPerfilCandidato(String? perfil) {
    final normalized = perfil?.toUpperCase();
    return normalized == 'CANDIDATO' ||
        normalized == 'ESTAGIARIO' ||
        normalized == 'JOVEM_APRENDIZ';
  }

  Map<String, dynamic> _mapBackendUserData(Map<String, dynamic> backendData) {
    final cdUsuario = _parseInt(
          backendData['cd_usuario'] ??
              backendData['id'] ??
              backendData['cdUsuario'],
        ) ??
        _parseInt(backendData['cd_candidato']);
    final cdCandidato =
        _parseInt(backendData['cd_candidato'] ?? backendData['cdCandidato']);
    final regime = _parseInt(
      backendData['regime'] ??
          backendData['regime_id'] ??
          backendData['regimeId'],
    );
    final perfil = backendData['perfil']?.toString();

    return {
      'id': cdUsuario,
      'nome': backendData['nome'],
      'login': backendData['login'] ?? backendData['email'] ?? '',
      'email': backendData['email'] ?? backendData['login'] ?? '',
      'tipo': _mapPerfilToTipo(perfil),
      'perfil': perfil,
      'ativo': backendData['ativo'] ?? true,
      'isAdmin': perfil?.toUpperCase() == 'ADMIN',
      'isEmpresa': perfil?.toUpperCase() == 'EMPRESA',
      'isCandidato': _isPerfilCandidato(perfil),
      'cd_usuario': cdUsuario,
      'original_data': backendData,
      'cd_instituicao_ensino': _parseInt(backendData['cd_instituicao_ensino']),
      'cd_empresa': _parseInt(backendData['cd_empresa']),
      'cd_supervisor': _parseInt(backendData['cd_supervisor']),
      'cd_candidato': cdCandidato,
      'regime': regime,
      'regime_id': regime,
      'regimeId': regime,
    };
  }

  String _mapPerfilToTipo(String? perfil) {
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
      case 'CANDIDATO':
        return 'candidato';
      case 'SUPERVISOR':
        return 'supervisor';
      default:
        return perfil.toLowerCase();
    }
  }

  // ATUALIZADO: Logout com chamada para o servidor
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('=== INICIANDO LOGOUT ===');

      // 1. Tenta fazer logout no servidor (mas não bloqueia se falhar)
      try {
        await AuthService.logout();
        debugPrint('✅ Logout no servidor realizado');
      } catch (e) {
        debugPrint('⚠️ Erro ao fazer logout no servidor: $e');
        // Continua o logout local mesmo se falhar no servidor
      }

      // 2. Limpa dados locais
      await _clearAuthData();

      // 3. IMPORTANTE: Reseta a verificação de token no router
      AppRouter.resetTokenVerification();
      debugPrint('✅ Verificação de token resetada');

      _isLoading = false;
      notifyListeners();

      debugPrint('=== LOGOUT CONCLUÍDO ===');
    } catch (e) {
      debugPrint('Erro durante logout: $e');

      // Mesmo com erro, garante limpeza local
      await _clearAuthData();
      AppRouter.resetTokenVerification();

      _isLoading = false;
      notifyListeners();
    }
  }

  // CORRIGIDO: Método de limpeza de dados
  Future<void> _clearAuthData() async {
    debugPrint('Limpando dados de autenticação...');

    _usuario = null;
    _token = null;

    await StorageService.clear();

    debugPrint('Dados de autenticação limpos');
  }

  // NOVO: Método para aguardar autenticação ser processada
  Future<void> waitForAuthSync() async {
    int attempts = 0;
    const maxAttempts = 20; // 1 segundo máximo

    while (attempts < maxAttempts) {
      if (!_isLoading) break;
      await Future.delayed(const Duration(milliseconds: 50));
      attempts++;
    }
  }

  // NOVO: Método para verificar se a autenticação está sincronizada
  bool get isAuthSynced => !_isLoading && _usuario != null;

  Future<bool> checkAuthStatus() async {
    // Se não tem usuário OU não tem token válido, retorna false sem tentar validar
    if (!isAuthenticated ||
        _token == null ||
        _token!.isEmpty ||
        _token == 'no-token') {
      debugPrint('⚠️ Sem token válido para verificar (token: $_token)');
      // NÃO limpa os dados aqui se acabou de fazer login
      if (!_isLoginInProgress) {
        await _clearAuthData();
      }
      return false;
    }

    try {
      debugPrint('Verificando token: $_token');

      // Verifica se o token ainda é válido no servidor
      final tokenValido = await AuthService.verificarToken();

      if (!tokenValido) {
        debugPrint('Token inválido segundo o servidor');
        if (!_isLoginInProgress) {
          await _clearAuthData();
        }
        return false;
      }

      debugPrint('✅ Token válido');
      return true;
    } catch (e) {
      debugPrint('Erro ao verificar status de autenticação: $e');
      // Se deu erro 403, provavelmente o token está inválido--
      if (e.toString().contains('403') ||
          e.toString().contains('Token inválido')) {
        debugPrint('Token rejeitado pelo servidor');
        if (!_isLoginInProgress) {
          await _clearAuthData();
        }
        return false;
      }
      return false;
    }
  }

  Future<bool> requestReset(String email,
      {String? tipo, String? regimeId}) async {
    // Encaminhe esses dados ao AuthService, querystring ou body conforme a API
    return await AuthService.requestReset(email,
        tipo: tipo, regimeId: regimeId);
  }

  Future<bool> confirmReset(String email, String code, String newPass,
      {String? tipo, String? regimeId}) async {
    return await AuthService.confirmReset(
      email,
      code,
      newPass,
      tipo: tipo,
      regimeId: regimeId,
    );
  }

  // CORRIGIDO: Métodos de registro com tratamento adequado
  Future<bool> registrarEstagiario(Map<String, dynamic> dados) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await AuthService.registrarEstagiario(dados);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Erro no registro: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarJovemAprendiz(Map<String, dynamic> dados) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await AuthService.registrarJovemAprendiz(dados);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Erro no registro de jovem aprendiz: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarEmpresa(Map<String, dynamic> dados) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await AuthService.registrarEmpresa(dados);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Erro no registro de empresa: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registrarInstituicao(Map<String, dynamic> dados) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await AuthService.registrarInstituicao(dados);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Erro no registro de instituição: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // CORRIGIDO: Atualizar dados do usuário
  Future<bool> atualizarPerfil(Map<String, dynamic> dados) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await AuthService.atualizarPerfil(dados);

      // Verificar estrutura de resposta do seu backend
      Map<String, dynamic>? userData;

      if (response.containsKey('usuario')) {
        userData = response['usuario'];
      } else if (response['success'] == true && response['data'] != null) {
        userData = response['data']['usuario'] ?? response['data']['user'];
      } else if (response['usuario'] != null || response['user'] != null) {
        userData = response['usuario'] ?? response['user'];
      }

      if (userData != null) {
        final mappedUserData = _mapBackendUserData(userData);
        _usuario = Usuario.fromJson(mappedUserData);

        // NOVO: garantir persistência de cd_usuario e regime
        final toSave = _usuario!.toJson();
        toSave['cd_usuario'] ??= mappedUserData['cd_usuario'] ??
            toSave['id'] ??
            toSave['cd_candidato'];
        toSave['regime'] ??= mappedUserData['regime'] ??
            mappedUserData['regime_id'] ??
            mappedUserData['regimeId'];

        await StorageService.saveUserData(toSave);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Erro ao atualizar perfil: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // NOVO: Alterar senha
  Future<bool> alterarSenha(String senhaAtual, String novaSenha) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await AuthService.alterarSenha(senhaAtual, novaSenha);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Erro ao alterar senha: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Recuperar senha por email (mantido para compatibilidade)
  Future<bool> recuperarSenha(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await AuthService.recuperarSenha(email);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Erro ao recuperar senha: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // NOVO: Recuperar senha por login
  Future<bool> recuperarSenhaPorLogin(String login) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await AuthService.recuperarSenhaPorLogin(login);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Erro ao recuperar senha por login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> redefinirSenha(String token, String novaSenha) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await AuthService.redefinirSenha(token, novaSenha);

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('Erro ao redefinir senha: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ATUALIZADO: Verificar token (pode não ser aplicável no seu sistema)
  Future<bool> verificarToken() async {
    if (_token == null) {
      // Se não usa tokens, considera válido se há usuário logado
      return _usuario != null;
    }

    try {
      final isValid = await AuthService.verificarToken();

      if (!isValid) {
        await _clearAuthData();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao verificar token: $e');
      // Se não usa tokens, não é erro crítico
      return _usuario != null;
    }
  }

  // CORRIGIDO: Refresh do token
  Future<bool> refreshToken() async {
    try {
      final response = await AuthService.refreshToken();

      // Verificar diferentes estruturas de resposta
      String? newToken;

      if (response['success'] == true && response['data'] != null) {
        newToken = response['data']['token'];
      } else if (response['token'] != null) {
        newToken = response['token'];
      } else if (response['access_token'] != null) {
        newToken = response['access_token'];
      }

      if (newToken != null) {
        _token = newToken;
        await StorageService.saveToken(_token!);
        notifyListeners();
        return true;
      }

      // Se não usa tokens, considera sucesso se usuário ainda está logado
      return _usuario != null;
    } catch (e) {
      debugPrint('Erro ao refresh token: $e');
      // Se não usa tokens, não é erro crítico
      return _usuario != null;
    }
  }

  // CORRIGIDO: Recarregar dados do usuário
  Future<bool> reloadUser() async {
    if (!isAuthenticated) return false;

    try {
      _isLoading = true;
      notifyListeners();

      final response = await AuthService.buscarPerfilUsuario();

      // Verificar estrutura de resposta do seu backend
      Map<String, dynamic>? userData;

      if (response.containsKey('usuario')) {
        userData = response['usuario'];
      } else if (response['success'] == true && response['data'] != null) {
        userData = response['data']['usuario'] ?? response['data']['user'];
      } else if (response['usuario'] != null || response['user'] != null) {
        userData = response['usuario'] ?? response['user'];
      } else {
        userData = response; // Assume que a resposta inteira é o usuário
      }

      if (userData != null) {
        final mappedUserData = _mapBackendUserData(userData);
        _usuario = Usuario.fromJson(mappedUserData);

        // NOVO: garantir persistência de cd_usuario e regime
        final toSave = _usuario!.toJson();
        toSave['cd_usuario'] ??= mappedUserData['cd_usuario'] ??
            toSave['id'] ??
            toSave['cd_candidato'];
        toSave['regime'] ??= mappedUserData['regime'] ??
            mappedUserData['regime_id'] ??
            mappedUserData['regimeId'];

        await StorageService.saveUserData(toSave);

        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('Erro ao recarregar usuário: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Métodos de validação
  Future<bool> verificarLoginExistente(String login) async {
    try {
      return await AuthService.verificarLoginExistente(login);
    } catch (e) {
      debugPrint('Erro ao verificar login: $e');
      return false;
    }
  }

  Future<bool> verificarEmailExistente(String email) async {
    try {
      return await AuthService.verificarEmailExistente(email);
    } catch (e) {
      debugPrint('Erro ao verificar email: $e');
      return false;
    }
  }

  Future<bool> verificarCpfExistente(String cpf) async {
    try {
      return await AuthService.verificarCpfExistente(cpf);
    } catch (e) {
      debugPrint('Erro ao verificar CPF: $e');
      return false;
    }
  }

  Future<bool> verificarCnpjExistente(String cnpj) async {
    try {
      return await AuthService.verificarCnpjExistente(cnpj);
    } catch (e) {
      debugPrint('Erro ao verificar CNPJ: $e');
      return false;
    }
  }

  // ATUALIZADO: Métodos de verificação de tipo baseados no perfil do backend
  bool temPermissao(String permissao) {
    if (_usuario == null) return false;
    // Implementar lógica de permissões baseada no perfil
    return _usuario!.temPermissao(permissao);
  }

  bool get isAdmin => _usuario?.perfil?.toUpperCase() == 'ADMIN';
  bool get isEmpresa => _usuario?.perfil?.toUpperCase() == 'EMPRESA';
  bool get isCandidato => ['ESTAGIARIO', 'JOVEM_APRENDIZ']
      .contains(_usuario?.perfil?.toUpperCase());
  bool get isEstagiario => _usuario?.perfil?.toUpperCase() == 'ESTAGIARIO';
  bool get isJovemAprendiz =>
      _usuario?.perfil?.toUpperCase() == 'JOVEM_APRENDIZ';
  bool get isInstituicao => _usuario?.perfil?.toUpperCase() == 'INSTITUICAO';

  // Getters de tipo
  String? get tipoUsuario => _usuario?.perfil;
  String? get perfilUsuario => _usuario?.perfil;

  //Getters de IDs relacionados
  int? get instituicaoId => _usuario?.cdInstituicaoEnsino;

  // NOVO: garante fallback para cd_usuario armazenado
  int? get candidatoId {
    final idPrimario = _usuario?.id;
    if (idPrimario != null) return idPrimario;
    try {
      final json = _usuario?.toJson();
      return _parseInt(
          json?['cd_usuario'] ?? json?['cd_candidato'] ?? json?['id']);
    } catch (_) {
      return null;
    }
  }

  // NOVO: garante fallback para regime armazenado
  int? get regimeId {
    final regimePrimario = _usuario?.regimeId;
    if (regimePrimario != null) return regimePrimario;
    try {
      final json = _usuario?.toJson();
      return _parseInt(json?['regime'] ??
          json?['regime_id'] ??
          json?['regimeId'] ??
          json?['tipoRegime']);
    } catch (_) {
      return null;
    }
  }

  // Métodos utilitários
  void updateUserField(String field, dynamic value) {
    if (_usuario != null) {
      // Implementar conforme modelo Usuario
      notifyListeners();
    }
  }

  Future<void> clearCache() async {
    try {
      await StorageService.clearCache();
    } catch (e) {
      debugPrint('Erro ao limpar cache: $e');
    }
  }

  Future<bool> confirmarEmail(String token) async {
    try {
      return await AuthService.confirmarEmail(token);
    } catch (e) {
      debugPrint('Erro ao confirmar email: $e');
      return false;
    }
  }

  Future<bool> reenviarConfirmacaoEmail(String email) async {
    try {
      return await AuthService.reenviarConfirmacaoEmail(email);
    } catch (e) {
      debugPrint('Erro ao reenviar confirmação: $e');
      return false;
    }
  }

  Future<void> initialize() async {
    await _initializeAuth();
  }

  void _mockAdminLogin() {
    try {
      // Criar dados mock de um usuário admin
      final mockUserData = {
        'id': '1',
        'nome': 'Admin de Teste',
        'login': 'admin_test',
        'email': 'admin@teste.com',
        'perfil': 'ADMIN',
        'tipo': 'admin',
        'ativo': true,
        'isAdmin': true,
        'isEmpresa': false,
        'isCandidato': false,
        'cd_usuario': '1',
        'token': 'mock_token_123456',
      };

      _usuario = Usuario.fromJson(mockUserData);
      _token = 'mock_token_123456';

      debugPrint('=== MOCK LOGIN ATIVO ===');
      debugPrint('Usuário mockado: ${_usuario?.nome}');
      debugPrint('Perfil: ${_usuario?.perfil}');
      debugPrint('=====================');

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao criar mock user: $e');
    }
  }

  // ===== MÉTODO PARA DESABILITAR O MOCK (OPCIONAL) =====
  void disableMockLogin() {
    if (_BYPASS_LOGIN_FOR_TESTING) {
      _clearAuthData();
      debugPrint('Mock login desabilitado');
    }
  }
}
