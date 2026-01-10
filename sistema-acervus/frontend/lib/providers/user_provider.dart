import 'package:flutter/material.dart';

import '../models/usuario.dart';

import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  // Estado geral
  bool _isLoading = false;
  String? _errorMessage;

  // Dados do usuário atual
  Usuario? _currentUser;
  dynamic _userProfile;

  // Dados específicos por tipo de usuário

  // Paginação
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  // Filtros
  Map<String, dynamic> _filtros = {};

  // Dashboard data
  Map<String, dynamic> _dashboardData = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Usuario? get currentUser => _currentUser;
  dynamic get userProfile => _userProfile;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  Map<String, dynamic> get filtros => _filtros;
  Map<String, dynamic> get dashboardData => _dashboardData;

  // Métodos de inicialização
  void setCurrentUser(Usuario user, dynamic profile) {
    _currentUser = user;
    _userProfile = profile;
    notifyListeners();
  }

  void clearUserData() {
    _currentUser = null;
    _userProfile = null;

    _dashboardData.clear();
    _filtros.clear();
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _errorMessage = null;
    notifyListeners();
  }

  // Métodos utilitários
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _setPagination(Map<String, dynamic> pagination) {
    _currentPage = pagination['page'] ?? 1;
    _totalPages = pagination['pages'] ?? 1;
    _totalItems = pagination['total'] ?? 0;
  }

  // CRUD Candidatos

  // Dashboard
  Future<void> loadDashboardData() async {
    try {
      _setLoading(true);
      _setError(null);

      final data = await UserService.getDashboardData();
      _dashboardData = data;

      _setLoading(false);
    } catch (e) {
      _setError('Erro ao carregar dados do dashboard: $e');
      _setLoading(false);
    }
  }

  // Perfil do usuário
  Future<bool> updateUserProfile(Map<String, dynamic> dados) async {
    try {
      _setLoading(true);
      _setError(null);

      final success =
          await UserService.updateProfile(_currentUser!.id.toString(), dados);

      if (success) {
        // Atualizar perfil baseado no tipo de usuário
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Erro ao atualizar perfil: $e');
      _setLoading(false);
      return false;
    }
  }

  // Métodos específicos por tipo de usuário

  // Filtros
  void updateFiltros(Map<String, dynamic> novosFiltros) {
    _filtros = novosFiltros;
    notifyListeners();
  }

  void clearFiltros() {
    _filtros.clear();
    notifyListeners();
  }

  // Paginação
  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      notifyListeners();
    }
  }

  // Método para refresh geral
  Future<void> refreshAll() async {
    if (_currentUser == null) return;

    final futures = <Future>[];

    try {
      await Future.wait(futures);
    } catch (e) {
      _setError('Erro ao atualizar dados: $e');
    }
  }

  // Método para limpar mensagens de erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Validações
  bool isOwner(String? resourceUserId) {
    if (_currentUser == null || resourceUserId == null) return false;

    // Admin pode acessar tudo
    if (_currentUser!.tipo == TipoUsuario.ADMIN) return true;

    // Verificar se é o próprio usuário
    return _currentUser!.id == resourceUserId;
  }

  bool canEdit(String? resourceUserId) {
    if (_currentUser == null) return false;

    // Admin e colaborador podem editar
    if (_currentUser!.tipo == TipoUsuario.ADMIN ||
        _currentUser!.tipo == TipoUsuario.COLABORADOR) {
      return true;
    }

    // Usuário pode editar próprios dados
    return isOwner(resourceUserId);
  }

  bool canDelete(String? resourceUserId) {
    if (_currentUser == null) return false;

    // Apenas admin pode deletar
    return _currentUser!.tipo == TipoUsuario.ADMIN;
  }
}
