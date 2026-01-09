import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/_pessoas/candidato/jovem_aprendiz.dart'
    as jovem;
import '../models/_core/usuario.dart';
import '../models/_pessoas/candidato/candidato.dart' as candidato;
import '../models/_organizacoes/empresa/empresa.dart' as emp;
import '../models/_organizacoes/instituicao/instituicao.dart' as inst;
import '../models/_pessoas/candidato/jovem_aprendiz.dart' as jovem;
import '../models/_contratos/contrato/contrato.dart' as contrato;
import '../models/_academico/_vagas/vaga.dart';
import '../services/_core/user_service.dart';
import '../services/_pessoas/candidato/candidato_service.dart';
import '../services/_organizacoes/empresa/empresa_service.dart';
import '../services/_organizacoes/instituicao/instituicao_service.dart';
import '../services/_pessoas/candidato/jovem_aprendiz_service.dart';
import '../services/_contratos/contrato/contrato_service.dart';

class UserProvider extends ChangeNotifier {
  // Estado geral
  bool _isLoading = false;
  String? _errorMessage;

  // Dados do usuário atual
  Usuario? _currentUser;
  dynamic _userProfile;

  // Dados específicos por tipo de usuário
  List<candidato.Candidato> _candidatos = [];
  List<emp.Empresa> _empresas = [];
  final List<inst.InstituicaoEnsino> _instituicoes = [];
  final List<jovem.JovemAprendiz> _jovensAprendizes = [];
  List<contrato.Contrato> _contratos = [];
  List<Vaga> _vagas = [];

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
  List<candidato.Candidato> get estagiarios => _candidatos;
  List<emp.Empresa> get empresas => _empresas;
  List<inst.InstituicaoEnsino> get instituicoes => _instituicoes;
  List<jovem.JovemAprendiz> get jovensAprendizes => _jovensAprendizes;
  List<contrato.Contrato> get contratos => _contratos;
  List<Vaga> get vagas => _vagas;
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
    _candidatos.clear();
    _empresas.clear();
    _instituicoes.clear();
    _jovensAprendizes.clear();
    _contratos.clear();
    _vagas.clear();
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
  Future<void> loadCandidatos({
    int page = 1,
    String? search,
    String? instituicao,
    bool? ativo,
    bool refresh = false,
  }) async {
    if (refresh) _currentPage = 1;

    try {
      _setLoading(true);
      _setError(null);

      final result = await CandidatoService.listarCandidatos(
        page: page,
        search: search,
        //instituicao: instituicao,
        //ativo: ativo,
      );

      if (refresh || page == 1) {
        _candidatos = List<candidato.Candidato>.from(result['candidatos']);
      } else {
        _candidatos
            .addAll(List<candidato.Candidato>.from(result['candidatos']));
      }

      _setPagination(result['pagination']);
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao carregar candidatos: $e');
      _setLoading(false);
    }
  }

  Future<bool> deleteCandidato(String id) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await CandidatoService.deletarCandidato(id as int);

      if (success) {
        _candidatos.removeWhere((e) => e.id == id);
        _totalItems = _totalItems > 0 ? _totalItems - 1 : 0;
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Erro ao deletar estagiário: $e');
      _setLoading(false);
      return false;
    }
  }

  // CRUD Empresas
  Future<void> loadEmpresas({
    int page = 1,
    String? search,
    bool? ativo,
    bool refresh = false,
  }) async {
    if (refresh) _currentPage = 1;

    try {
      _setLoading(true);
      _setError(null);

      final result = await EmpresaService.listarEmpresas(
        page: page,
        search: search,
        ativo: ativo,
      );

      if (refresh || page == 1) {
        _empresas = List<emp.Empresa>.from(result['empresas']);
      } else {
        _empresas.addAll(List<emp.Empresa>.from(result['empresas']));
      }

      _setPagination(result['pagination']);
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao carregar empresas: $e');
      _setLoading(false);
    }
  }

  Future<bool> updateEmpresa(String id, Map<String, dynamic> dados) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await EmpresaService.atualizarEmpresa(id, dados);

      if (success) {
        final index = _empresas.indexWhere((e) => e.id == id);
        if (index != -1) {
          final updatedEmpresa = await EmpresaService.buscarEmpresa(id);
          _empresas[index] = updatedEmpresa as emp.Empresa;
        }

        if (_currentUser?.tipo == TipoUsuario.EMPRESA &&
            _userProfile?.id == id) {
          _userProfile = await EmpresaService.buscarEmpresa(id);
        }
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Erro ao atualizar empresa: $e');
      _setLoading(false);
      return false;
    }
  }

  // CRUD Contratos
  Future<void> loadContratos({
    int page = 1,
    String? status,
    String? tipo,
    String? vencimento,
    bool refresh = false,
  }) async {
    if (refresh) _currentPage = 1;

    try {
      _setLoading(true);
      _setError(null);

      final result = await ContratoService.listarContratos(
        page: page,
        status: status,
        tipo: tipo,
      );

      if (refresh || page == 1) {
        _contratos = List<contrato.Contrato>.from(result['contratos']);
      } else {
        _contratos.addAll(List<contrato.Contrato>.from(result['contratos']));
      }

      _setPagination(result['pagination']);
      _setLoading(false);
    } catch (e) {
      _setError('Erro ao carregar contratos: $e');
      _setLoading(false);
    }
  }

  Future<bool> createContrato(Map<String, dynamic> dados) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await ContratoService.criarContrato(dados);

      if (success) {
        // Recarregar a lista de contratos
        await loadContratos(refresh: true);
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Erro ao criar contrato: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateContrato(String id, Map<String, dynamic> dados) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await ContratoService.atualizarContrato(id, dados);

      if (success) {
        final index = _contratos.indexWhere((c) => c.id == id);
        if (index != -1) {
          final updatedContrato = await ContratoService.buscarContrato(id);
          _contratos[index] = updatedContrato;
        }
      }

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Erro ao atualizar contrato: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<Object> generateContratoPDF(String contratoId) async {
    try {
      _setLoading(true);
      _setError(null);

      final success = await ContratoService.gerarPDF(contratoId);

      _setLoading(false);
      return success;
    } catch (e) {
      _setError('Erro ao gerar PDF: $e');
      _setLoading(false);
      return false;
    }
  }

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
        switch (_currentUser!.tipo) {
          case TipoUsuario.ESTAGIARIO:
            _userProfile =
                await CandidatoService.buscarCandidato(_userProfile.id);
            break;
          case TipoUsuario.EMPRESA:
            _userProfile = await EmpresaService.buscarEmpresa(_userProfile.id);
            break;
          case TipoUsuario.INSTITUICAO:
            _userProfile =
                await InstituicaoService.buscarInstituicao(_userProfile.id);
            break;
          case TipoUsuario.JOVEM_APRENDIZ:
            _userProfile =
                await JovemAprendizService.buscarJovemAprendiz(_userProfile.id);
            break;
          default:
            break;
        }
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
  List<contrato.Contrato> getContratosDoUsuario() {
    if (_currentUser == null || _userProfile == null) return [];

    switch (_currentUser!.tipo) {
      case TipoUsuario.ESTAGIARIO:
        return _contratos
            .where((c) =>
                c.estudante?.id == _userProfile.id && c.tipo == 'ESTAGIO')
            .toList();

      case TipoUsuario.JOVEM_APRENDIZ:
        return _contratos
            .where((c) =>
                c.estudante?.id == _userProfile.id &&
                c.tipo == 'JOVEM_APRENDIZ')
            .toList();

      case TipoUsuario.EMPRESA:
        return _contratos
            .where((c) => c.empresa?.id == _userProfile.id)
            .toList();

      case TipoUsuario.INSTITUICAO:
        return _contratos
            .where((c) => c.instituicao?.id == _userProfile.id)
            .toList();

      default:
        return _contratos;
    }
  }

  List<Vaga> getVagasDoUsuario() {
    if (_currentUser?.tipo == TipoUsuario.EMPRESA && _userProfile != null) {
      return _vagas.where((v) => v.empresa?.id == _userProfile.id).toList();
    }
    return _vagas;
  }

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

  // Métodos de busca
  List<candidato.Candidato> searchCandidatos(String query) {
    if (query.isEmpty) return _candidatos;

    return _candidatos.where((candidato) {
      return candidato.nomeCompleto
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          candidato.cpf.contains(query.replaceAll(RegExp(r'\D'), '')) ||
          candidato.email.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<emp.Empresa> searchEmpresas(String query) {
    if (query.isEmpty) return _empresas;

    return _empresas.where((empresa) {
      return empresa.nomeFantasia!
              .toLowerCase()
              .contains(query.toLowerCase()) ||
          empresa.razaoSocial!.toLowerCase().contains(query.toLowerCase()) ||
          empresa.cnpj.contains(query.replaceAll(RegExp(r'\D'), ''));
    }).toList();
  }

  List<contrato.Contrato> searchContratos(String query) {
    if (query.isEmpty) return _contratos;

    return _contratos.where((contrato) {
      return contrato.numero.contains(query) ||
          (contrato.empresa?.nomeFantasia
                  ?.toLowerCase()
                  .contains(query.toLowerCase()) ??
              false) ||
          (contrato.estudante?.nome
                  ?.toLowerCase()
                  .contains(query.toLowerCase()) ??
              false);
    }).toList();
  }

  // Estatísticas rápidas
  int get totalCandidatosAtivos => _candidatos
      .where((e) => getContratosDoUsuario()
          .any((c) => c.status == 'ATIVO' && c.tipo == 'ESTAGIO'))
      .length;

  int get totalJovensAprendizesAtivos => _jovensAprendizes
      .where((j) => getContratosDoUsuario()
          .any((c) => c.status == 'ATIVO' && c.tipo == 'JOVEM_APRENDIZ'))
      .length;

  int get totalContratosAtivos =>
      _contratos.where((c) => c.status == 'ATIVO').length;

  int get totalVagasAbertas => _vagas.where((v) => v.statusVaga == true).length;

  // Contratos próximos do vencimento (30 dias)
  List<contrato.Contrato> get contratosProximosVencimento {
    final dataLimite = DateTime.now().add(const Duration(days: 30));
    return _contratos
        .where((c) =>
            c.status == 'ATIVO' &&
            c.dataFim.isBefore(dataLimite) &&
            c.dataFim.isAfter(DateTime.now()))
        .toList();
  }

  // Método para refresh geral
  Future<void> refreshAll() async {
    if (_currentUser == null) return;

    final futures = <Future>[];

    // Carregar dados baseado no tipo de usuário
    switch (_currentUser!.tipo) {
      case TipoUsuario.ADMIN:
      case TipoUsuario.COLABORADOR:
        futures.addAll([
          loadCandidatos(refresh: true),
          loadEmpresas(refresh: true),
          loadContratos(refresh: true),
          loadDashboardData(),
        ]);
        break;

      case TipoUsuario.EMPRESA:
        futures.addAll([
          loadContratos(refresh: true),
        ]);
        break;

      case TipoUsuario.SUPERVISOR:
        futures.addAll([
          loadContratos(refresh: true),
        ]);
        break;

      case TipoUsuario.ESTAGIARIO:
      case TipoUsuario.JOVEM_APRENDIZ:
        futures.add(loadContratos(refresh: true));
        break;

      case TipoUsuario.INSTITUICAO:
        futures.addAll([
          loadCandidatos(refresh: true),
          loadContratos(refresh: true),
        ]);
        break;
    }

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
