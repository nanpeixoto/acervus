// lib/screens/admin/curso_aprendizagem_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_app_bar.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/models/_academico/curso/curso_aprendizagem.dart';
import 'package:sistema_estagio/services/_academico/curso/curso_aprendizagem_service.dart';
import 'package:sistema_estagio/services/_auxiliares/classificacao/cbo_service.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CursoAprendizagemScreen extends StatefulWidget {
  const CursoAprendizagemScreen({super.key});

  @override
  State<CursoAprendizagemScreen> createState() =>
      _CursoAprendizagemScreenState();
}

class _CursoAprendizagemScreenState extends State<CursoAprendizagemScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  static const Color _primaryColor = Color(0xFF82265C);

  List<CursoAprendizagem> _cursos = [];
  Map<String, dynamic> _estatisticas = {};
  bool _isLoading = false;

  // Filtros
  bool? _filtroAtivo;
  bool? _filtroDefault;

  // Paginação
  late TabController _tabController;
  int _currentPage = 1;
  final int _totalPages = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';
  bool _isLoadingPage = false;

  // Opções de página
  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  // Formulário Principal
  bool _showForm = false;
  CursoAprendizagem? _cursoEditando;
  final _formKey = GlobalKey<FormState>();
  final _nomeCursoController = TextEditingController();
  final _cboController = TextEditingController();
  final _validadeController = TextEditingController();

  DateTime? _validadeSelecionada;
  bool _ativo = true;

  // Variáveis para CBO
  String? _cboSelecionado;
  String? _cboCodigoSelecionado;
  int? _cdCBO;
  final _cboBuscaController = TextEditingController();

  // Formulário de Módulos
  final _disciplinaController = TextEditingController();
  List<ModuloCurso> _modulosList = [];
  bool _showModuloForm = false;
  int? _moduloEditandoIndex;

  // Formatadores
  final _cboFormatter = MaskTextInputFormatter(
    mask: '####-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCursos();
    //_loadEstatisticas();
  }

  Future<void> _loadCursos({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingPage = true);
    }

    try {
      final result = await CursoAprendizagemService.listarCursosAprendizagem(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
      );

      if (mounted) {
        setState(() {
          _cursos = result['cursos'];
          _pagination = result['pagination'];

          if (_pagination == null || _pagination!.isEmpty) {
            final totalItems = _cursos.length;
            final totalPages = (totalItems / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt();

            _pagination = {
              'currentPage': _currentPage,
              'totalPages': totalPages,
              'totalItems': totalItems,
              'hasNextPage': _currentPage < totalPages,
              'hasPrevPage': _currentPage > 1,
            };
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar Items 1: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingPage = false;
        });
      }
    }
  }

  Future<void> _loadEstatisticas() async {
    try {
      final stats = await CursoAprendizagemService.getEstatisticasGerais();
      if (mounted) {
        setState(() => _estatisticas = stats);
      }
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }

  void _pesquisar() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _currentSearch = _searchController.text.trim();
    });

    try {
      if (_currentSearch.isEmpty) {
        await _loadCursos();
        return;
      }

      final result = await CursoAprendizagemService.buscarCursoAprendizagem(
          _currentSearch);

      if (mounted) {
        setState(() {
          _cursos = result ?? <CursoAprendizagem>[];
          _pagination = {
            'currentPage': 1,
            'totalPages': 1,
            'total': _cursos.length,
            'hasNextPage': false,
            'hasPrevPage': false,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar Items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _limparPesquisa() {
    _searchController.clear();
    setState(() {
      _currentSearch = '';
      _currentPage = 1;
    });
    _loadCursos();
  }

  void _showFormulario([CursoAprendizagem? curso]) async {
    if (curso != null) {
      setState(() => _isLoading = true);

      try {
        // Buscar dados completos via endpoint
        final cursoCompleto =
            await CursoAprendizagemService.buscarCursoAprendizagemPorId(
                curso.id.toString());

        setState(() {
          _showForm = true;
          _cursoEditando = cursoCompleto;
          _nomeCursoController.text = cursoCompleto!.nomeCurso;
          // Buscar e preencher dados do CBO
          _preencherDadosCbo(cursoCompleto.cbo.toString());
          _validadeController.text =
              AppUtils.formatDate(cursoCompleto.validade);

          _validadeSelecionada = cursoCompleto.validade;
          _ativo = cursoCompleto.ativo;
          _modulosList = List.from(cursoCompleto.modulos);
        });
      } catch (e) {
        AppUtils.showErrorSnackBar(
            context, 'Erro ao carregar dados do curso: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() {
        _showForm = true;
        _cursoEditando = null;
      });
      _limparFormulario();
    }
  }

  Future<void> _preencherDadosCbo(String cbo) async {
    try {
      // Extrair código do formato "####-##"
      final codigoLimpo = cbo.replaceAll(RegExp(r'[^0-9]'), '');

      if (codigoLimpo.length == 6) {
        // Buscar dados completos do CBO
        final dadosCbo = await CBOService.buscarCBOPorId(codigoLimpo as int);

        if (dadosCbo != null) {
          setState(() {
            _cboCodigoSelecionado = dadosCbo.codigo;
            _cboSelecionado = '${dadosCbo.codigo} - ${dadosCbo.descricao}';
            _cboController.text = cbo; // Manter formato original
            _cboBuscaController.text = _cboSelecionado!;
          });
        } else {
          // Se não encontrar, usar apenas o código
          setState(() {
            _cboCodigoSelecionado = codigoLimpo;
            _cboSelecionado = cbo;
            _cboController.text = cbo;
            _cboBuscaController.text = cbo;
          });
        }
      }
    } catch (e) {
      print('Erro ao buscar dados do CBO: $e');
      // Em caso de erro, usar o valor original
      setState(() {
        _cboController.text = cbo;
        _cboBuscaController.text = cbo;
      });
    }
  }

  void _limparFormulario() {
    _nomeCursoController.clear();
    _cboController.clear();
    _cboBuscaController.clear();
    _validadeController.clear();

    _disciplinaController.clear();
    _validadeSelecionada = null;
    _cboSelecionado = null;
    _cboCodigoSelecionado = null;
    _cdCBO = null;
    _ativo = true;
    _modulosList.clear();
    _showModuloForm = false;
    _moduloEditandoIndex = null;
    _cursoEditando = null;
  }

  Future<void> _salvarCurso() async {
    if (!_formKey.currentState!.validate()) return;
    if (_validadeSelecionada == null) {
      AppUtils.showErrorSnackBar(
          context, 'Por favor, selecione uma data de validade');
      return;
    }
    if (_cboCodigoSelecionado == null) {
      AppUtils.showErrorSnackBar(context, 'Por favor, selecione um CBO válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dados = {
        'nome': _nomeCursoController.text.trim(),
        'cd_cbo': _cdCBO!, // Usar código selecionado
        'validade': _validadeSelecionada!.toIso8601String().split('T')[0],
        'modulos': _modulosList.map((m) => m.toCreateJson()).toList(),
        'ativo': _ativo,
      };

      bool sucesso;
      if (_cursoEditando != null) {
        print('Dados para atualização: $dados');
        sucesso = await CursoAprendizagemService.atualizarCursoAprendizagem(
          _cursoEditando!.id!,
          dados,
        );
      } else {
        print('Dados para criação: $dados');
        sucesso = await CursoAprendizagemService.criarCursoAprendizagem(dados);
      }

      if (sucesso) {
        AppUtils.showSuccessSnackBar(
          context,
          _cursoEditando != null
              ? 'Curso atualizado com sucesso!'
              : 'Curso criado com sucesso!',
        );
        setState(() {
          _showForm = false;
          _cursoEditando = null;
        });
        _loadCursos();
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao salvar curso: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _excluirCurso(CursoAprendizagem curso) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir o curso "${curso.nomeCurso}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmacao == true) {
      setState(() => _isLoading = true);
      try {
        await CursoAprendizagemService.deletarCursoAprendizagem(
            curso.id! as String);
        AppUtils.showSuccessSnackBar(context, 'Curso excluído com sucesso!');
        _loadCursos();
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro ao excluir curso: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _alterarStatusCurso(CursoAprendizagem curso) async {
    setState(() => _isLoading = true);
    try {
      final novoStatus = !curso.ativo;
      final sucesso = await CursoAprendizagemService.ativarCursoAprendizagem(
        curso.id! as String,
        ativo: novoStatus,
      );

      if (sucesso) {
        AppUtils.showSuccessSnackBar(
          context,
          novoStatus ? 'Curso ativado!' : 'Curso desativado!',
        );
        _loadCursos();
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao alterar status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _adicionarModulo() {
    if (_disciplinaController.text.trim().isEmpty) {
      AppUtils.showErrorSnackBar(context, 'Nome da disciplina é obrigatório');
      return;
    }

    setState(() {
      if (_moduloEditandoIndex != null) {
        // Editando módulo existente
        _modulosList[_moduloEditandoIndex!] = ModuloCurso(
          id: _modulosList[_moduloEditandoIndex!].id,
          nomeDisciplina: _disciplinaController.text.trim(),
        );
        _moduloEditandoIndex = null;
      } else {
        // Adicionando novo módulo
        _modulosList.add(ModuloCurso(
          nomeDisciplina: _disciplinaController.text.trim(),
        ));
      }
      _disciplinaController.clear();
      _showModuloForm = false;
    });
  }

  void _editarModulo(int index) {
    setState(() {
      _disciplinaController.text = _modulosList[index].nomeDisciplina;
      _moduloEditandoIndex = index;
      _showModuloForm = true;
    });
  }

  void _removerModulo(int index) {
    setState(() {
      _modulosList.removeAt(index);
    });
  }

  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate:
          _validadeSelecionada ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      locale: const Locale('pt', 'BR'),
    );

    if (data != null) {
      setState(() {
        _validadeSelecionada = data;
        _validadeController.text = AppUtils.formatDate(data);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos de Aprendizagem'),
        actions: [
          IconButton(
            onPressed: _showFiltrosDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros',
          ),
          IconButton(
            onPressed: _exportarDados,
            icon: const Icon(Icons.download),
            tooltip: 'Exportar',
          ),
          IconButton(
            onPressed: _showNovoStatusForm,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Curso',
          ),
        ],
        // bottom: TabBar(
        //   controller: _tabController,
        //   tabs: const [
        //     Tab(text: 'Lista', icon: Icon(Icons.list)),
        //     Tab(text: 'Estatísticas', icon: Icon(Icons.analytics)),
        //   ],
        // ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildListaTab(),
            _buildEstatisticasTab(),
          ],
        ),
      ),
    );
  }

  void _showFiltrosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<bool>(
                value: _filtroAtivo,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: true, child: Text('Ativos')),
                  DropdownMenuItem(value: false, child: Text('Inativos')),
                ],
                onChanged: (value) => setState(() => _filtroAtivo = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<bool>(
                value: _filtroDefault,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: true, child: Text('Status Padrão')),
                  DropdownMenuItem(value: false, child: Text('Personalizados')),
                ],
                onChanged: (value) => setState(() => _filtroDefault = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtroAtivo = null;
                _filtroDefault = null;
                _currentPage = 1;
              });
              Navigator.of(context).pop();
              _loadCursos();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _currentPage = 1);
              _loadCursos();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  bool _temFiltrosAtivos() {
    return _filtroAtivo != null ||
        _filtroDefault != null ||
        _currentSearch.isNotEmpty;
  }

  Widget _buildFiltrosAtivos() {
    final filtros = <Widget>[];

    if (_currentSearch.isNotEmpty) {
      filtros
          .add(_buildFiltroChip('Busca: "$_currentSearch"', _limparPesquisa));
    }

    if (_filtroAtivo != null) {
      filtros.add(_buildFiltroChip(
          'Status: ${_filtroAtivo! ? "Ativos" : "Inativos"}', () {
        setState(() => _filtroAtivo = null);
        _loadCursos();
      }));
    }

    if (_filtroDefault != null) {
      filtros.add(_buildFiltroChip(
          'Tipo: ${_filtroDefault! ? "Padrão" : "Personalizados"}', () {
        setState(() => _filtroDefault = null);
        _loadCursos();
      }));
    }

    return Wrap(spacing: 8, children: filtros);
  }

  Widget _buildFiltroChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
    );
  }

  void _showNovoStatusForm() {
    setState(() => _cursoEditando = null);
    _limparFormulario();
    setState(() => _showForm = true);
  }

  Widget _buildListaTab() {
    return Column(
      children: [
        _buildHeader(),
        if (_showForm) _buildFormulario(),
        Expanded(child: _buildCursosList()),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    if (_cursos.isEmpty && !_isLoading && !_isLoadingPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['totalPages'] ??
        ((_cursos.isNotEmpty)
            ? ((_cursos.length / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt())
            : 1);
    final currentPage = _pagination?['currentPage'] ?? _currentPage;
    final total = _pagination?['total'] ?? _cursos.length;
    final hasNextPage =
        _pagination?['hasNextPage'] ?? (_currentPage < totalPages);
    final hasPrevPage = _pagination?['hasPrevPage'] ?? (_currentPage > 1);

    final startItem = ((currentPage - 1) * _pageSize) + 1;
    final endItem =
        (currentPage * _pageSize) > total ? total : (currentPage * _pageSize);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando $startItem-$endItem de $total registros',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Página $currentPage de $totalPages',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: currentPage > 1 ? () => _goToPage(1) : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'Primeira página',
                style: IconButton.styleFrom(
                  backgroundColor: currentPage > 1
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              IconButton(
                onPressed:
                    hasPrevPage ? () => _goToPage(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Página anterior',
                style: IconButton.styleFrom(
                  backgroundColor: hasPrevPage
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              const SizedBox(width: 16),
              ..._buildPageNumbers(currentPage, totalPages),
              const SizedBox(width: 16),
              IconButton(
                onPressed:
                    hasNextPage ? () => _goToPage(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Próxima página',
                style: IconButton.styleFrom(
                  backgroundColor: hasNextPage
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              IconButton(
                onPressed: currentPage < totalPages
                    ? () => _goToPage(totalPages)
                    : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Última página',
                style: IconButton.styleFrom(
                  backgroundColor: currentPage < totalPages
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
            ],
          ),
          if (totalPages > 5) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ir para página: '),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page >= 1 && page <= totalPages) {
                        _goToPage(page);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int currentPage, int totalPages) {
    List<Widget> pages = [];

    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (currentPage + 2).clamp(1, totalPages);

    if (end - start < 4) {
      if (start == 1) {
        end = (start + 4).clamp(1, totalPages);
      } else if (end == totalPages) {
        start = (end - 4).clamp(1, totalPages);
      }
    }

    for (int i = start; i <= end; i++) {
      pages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ElevatedButton(
            onPressed: i == currentPage ? null : () => _goToPage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  i == currentPage ? const Color(0xFF2E7D32) : Colors.white,
              foregroundColor:
                  i == currentPage ? Colors.white : const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              i.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return pages;
  }

  void _goToPage(int page) {
    if (page != _currentPage && page >= 1) {
      setState(() => _currentPage = page);
      _loadCursos(showLoading: false);
    }
  }

  Widget _buildEstatisticasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEstatisticasGerais(),
          const SizedBox(height: 16),
          _buildGraficos(),
        ],
      ),
    );
  }

  Widget _buildEstatisticasGerais() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas Gerais',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total de Status',
              (_estatisticas['total'] ?? 0).toString(),
              Icons.flag,
              const Color(0xFF2E7D32),
            ),
            _buildStatCard(
              'Status Ativos',
              (_estatisticas['ativos'] ?? 0).toString(),
              Icons.check_circle,
              const Color(0xFF1976D2),
            ),
            _buildStatCard(
              'Status Padrão',
              (_estatisticas['padrao'] ?? 0).toString(),
              Icons.star,
              const Color(0xFFED6C02),
            ),
            _buildStatCard(
              'Criados Este Mês',
              (_estatisticas['criadosEsteMes'] ?? 0).toString(),
              Icons.trending_up,
              const Color(0xFF9C27B0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGraficos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribuição por Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Gráfico de distribuição de status\n(Implementar com charts)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Estatísticas rápidas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Cursos',
                  (_pagination?['total'] ?? _cursos.length).toString(),
                  Icons.description,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Ativos',
                  (_cursos.where((s) => s.ativo).length).toString(),
                  Icons.check_circle,
                  const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de busca
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Buscar por nome ou descrição',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _limparPesquisa,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _pesquisar,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          // Configurações de paginação
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Itens por página: ', style: TextStyle(fontSize: 14)),
              DropdownButton<int>(
                value: _pageSize,
                items: _pageSizeOptions.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(size.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _pageSize = value;
                      _currentPage = 1;
                    });
                    _loadCursos();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadCursos();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // Filtros ativos
          if (_temFiltrosAtivos()) ...[
            const SizedBox(height: 8),
            _buildFiltrosAtivos(),
          ],
        ],
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCursosList(),
        _buildRelatorios(),
      ],
    );
  }

  Widget _buildFormulario() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _cursoEditando != null ? Icons.edit : Icons.add,
                  color: const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                Text(
                  _cursoEditando != null ? 'Editar Curso' : 'Novo Curso',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() {
                    _showForm = false;
                    _cursoEditando = null;
                  }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Primeira linha de campos
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: _nomeCursoController,
                    label: 'Nome do Curso',
                    validator: (value) =>
                        Validators.validateRequired(value, 'Nome do Curso'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAutocompleteCbo(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    controller: _validadeController,
                    label: 'Validade',
                    readOnly: true,
                    suffixIcon: const Icon(Icons.calendar_today),
                    onTap: _selecionarData,
                    validator: (_) {
                      if (_validadeSelecionada == null) {
                        return 'Selecione uma data';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Seção de Módulos
            _buildSecaoModulos(),

            const SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                ElevatedButton(
                  onPressed: _salvarCurso,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: Text(_cursoEditando != null ? 'Atualizar' : 'Criar'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => setState(() {
                    _showForm = false;
                    _cursoEditando = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Cancelar'),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Text('Ativo: '),
                    Switch(
                      value: _ativo,
                      onChanged: (value) => setState(() => _ativo = value),
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutocompleteCbo() {
    return Autocomplete<Map<String, dynamic>>(
      displayStringForOption: (cbo) => '${cbo['codigo']} - ${cbo['descricao']}',
      optionsBuilder: (textEditingValue) async {
        final query = textEditingValue.text.trim();

        if (query.length < 3) {
          return const Iterable<Map<String, dynamic>>.empty();
        }

        try {
          final result = await CBOService.buscarCBO(query);
          // ✅ CORREÇÃO: Converter cada CBO para Map usando toJson()
          return (result ?? []).map((cbo) => cbo.toJson());
        } catch (e) {
          print('Erro ao buscar CBOs: $e');
          return const Iterable<Map<String, dynamic>>.empty();
        }
      },
      onSelected: (cbo) {
        setState(() {
          _cboSelecionado = '${cbo['codigo']} - ${cbo['descricao']}';
          _cboCodigoSelecionado = cbo['codigo'];
          _cdCBO = cbo['cd_cbo'];
          _cboBuscaController.text = _cboSelecionado!;
          // Atualizar o campo formatado para exibição
          _cboController.text = cbo['codigo'];
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        // Preencher o campo no modo edição
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              _cboSelecionado != null &&
              _cboSelecionado!.isNotEmpty &&
              controller.text.isEmpty) {
            controller.text = _cboSelecionado!;
          }
        });

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            labelText: 'CBO',
            hintText: 'Digite para buscar CBO (mín. 3 caracteres)',
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      controller.clear();
                      setState(() {
                        _cboSelecionado = null;
                        _cboCodigoSelecionado = null;
                        _cboController.clear();
                        _cdCBO = null;
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            // Se o usuário limpar o campo, limpar a seleção
            if (value.isEmpty) {
              setState(() {
                _cboSelecionado = null;
                _cboCodigoSelecionado = null;
                _cboController.clear();
                _cdCBO = null;
              });
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Campo obrigatório';
            }
            if (_cboCodigoSelecionado == null) {
              return 'Selecione um CBO válido da lista';
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return _buildCboOptionsView(options, onSelected);
      },
    );
  }

  Widget _buildCboOptionsView(
    Iterable<Map<String, dynamic>> options,
    AutocompleteOnSelected<Map<String, dynamic>> onSelected,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          width: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: options.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Nenhum CBO encontrado',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final cbo = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 60,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFF2E7D32).withOpacity(0.3),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cbo['codigo']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        cbo['descricao']?.toString() ?? '',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: cbo['descricao'] != null
                          ? Text(
                              cbo['descricao'].toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      onTap: () => onSelected(cbo),
                      hoverColor: const Color(0xFF2E7D32).withOpacity(0.1),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildSecaoModulos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.library_books, color: Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            const Text(
              'Módulos do Curso',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                _showModuloForm = true;
                _moduloEditandoIndex = null;
                _disciplinaController.clear();
              }),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Incluir Módulo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Formulário de módulo
        if (_showModuloForm) _buildFormularioModulo(),

        // Lista de módulos
        if (_modulosList.isNotEmpty) _buildListaModulos(),

        if (_modulosList.isEmpty && !_showModuloForm)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'Nenhum módulo adicionado ainda',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFormularioModulo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.green[50],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _disciplinaController,
              decoration: const InputDecoration(
                labelText: 'Nome da Disciplina',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _adicionarModulo(),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _adicionarModulo,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child:
                Text(_moduloEditandoIndex != null ? 'Atualizar' : 'Adicionar'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => setState(() {
              _showModuloForm = false;
              _moduloEditandoIndex = null;
              _disciplinaController.clear();
            }),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildListaModulos() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _modulosList.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final modulo = _modulosList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              radius: 16,
              child: Text('${index + 1}'),
            ),
            title: Text(modulo.nomeDisciplina),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editarModulo(index),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () => _removerModulo(index),
                  tooltip: 'Remover',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCursosList() {
    if (_isLoadingPage) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando página...'),
          ],
        ),
      );
    }

    if (_cursos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _currentSearch.isNotEmpty
                  ? 'Nenhum curso encontrado com "$_currentSearch"'
                  : 'Nenhum curso de aprendizagem cadastrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar primeiro curso'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cursos.length,
      itemBuilder: (context, index) {
        final curso = _cursos[index];
        return _buildCursoCard(curso, index);
      },
    );
  }

  Widget _buildCursoCard(CursoAprendizagem curso, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: Center(
                    child: Text(
                      curso.id?.toString() ?? '',
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            curso.nomeCurso,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (curso.nomeCursoAprendizagem.isNotEmpty)
                        Text(
                          curso.nomeCursoAprendizagem,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildInfoChip(
                              'CBO',
                              (curso.descricaoCBO ?? '').toString(),
                              Icons.work),
                          const SizedBox(width: 8),
                          _buildInfoChip(
                            'Validade',
                            AppUtils.formatDate(curso.validade),
                            Icons.calendar_today,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (curso.modulos.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: curso.modulos
                              .map((m) => Chip(
                                    label: Text(
                                      m.nomeDisciplina,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    backgroundColor:
                                        Colors.green.withOpacity(0.1),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, curso),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: curso.ativo ? 'desativar' : 'ativar',
                      child: Row(
                        children: [
                          Icon(
                            curso.ativo
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                            color: curso.ativo ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            curso.ativo ? 'Desativar' : 'Ativar',
                            style: TextStyle(
                              color: curso.ativo ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: curso.ativo
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: curso.ativo ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Text(
                    curso.ativo ? 'ATIVO' : 'INATIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: curso.ativo ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${curso.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return IntrinsicWidth(
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              '$label: ',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatorios() {
    return const Center(
      child: Text('Relatórios em desenvolvimento...'),
    );
  }

  void _handleMenuAction(String action, CursoAprendizagem curso) {
    switch (action) {
      case 'editar':
        _editarCurso(curso);
        break;
      case 'ativar':
        _ativarCurso(curso);
        break;
      case 'desativar':
        _desativarCurso(curso);
        break;
      case 'excluir':
        _confirmarExclusao(curso);
        break;
    }
  }

  Future<void> _editarCurso(CursoAprendizagem curso) async {
    setState(() => _isLoading = true);

    try {
      print('🔍 Buscando curso ID: ${curso.id}');

      // Buscar dados completos do curso via endpoint
      final cursoCompleto =
          await CursoAprendizagemService.buscarCursoAprendizagemPorId(
              curso.id.toString());

      print('✅ Dados recebidos: ${cursoCompleto!.toJson()}');

      setState(() {
        _cursoEditando = cursoCompleto;
        _nomeCursoController.text = cursoCompleto.nomeCurso;

        // Preencher CBO usando os dados corretos da resposta
        if (cursoCompleto.cbo != null) {
          _preencherDadosCboCompleto(cursoCompleto.cbo.toString(),
              cursoCompleto.descricaoCBO, cursoCompleto.cbo);
        }

        _validadeController.text = AppUtils.formatDate(cursoCompleto.validade);
        _validadeSelecionada = cursoCompleto.validade;
        _ativo = cursoCompleto.ativo;
        _modulosList = List.from(cursoCompleto.modulos);
        _showForm = true;
      });
    } catch (e) {
      print('❌ Erro ao buscar curso: $e');
      AppUtils.showErrorSnackBar(
          context, 'Erro ao carregar dados do curso: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _preencherDadosCboCompleto(
      String cboCode, String? cboDescricao, int? cdCbo) {
    setState(() {
      _cboController.text = cboCode;
      _cboCodigoSelecionado = cboCode;
      _cdCBO = cdCbo;

      if (cboDescricao != null) {
        _cboSelecionado = '$cboCode - $cboDescricao';
        _cboBuscaController.text = _cboSelecionado!;
      } else {
        _cboSelecionado = cboCode;
        _cboBuscaController.text = cboCode;
      }
    });
  }

  Future<void> _ativarCurso(CursoAprendizagem curso) async {
    try {
      final success = await CursoAprendizagemService.ativarCursoAprendizagem(
          curso.id!.toString(),
          ativo: true);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Item ativado com sucesso!');
        _loadCursos(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _desativarCurso(CursoAprendizagem curso) async {
    try {
      final success = await CursoAprendizagemService.ativarCursoAprendizagem(
          curso.id!.toString(),
          ativo: false);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Item desativado com sucesso!');
        _loadCursos(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _confirmarExclusao(CursoAprendizagem curso) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Excluir Item',
      content:
          'Tem certeza que deseja excluir "${curso.nomeCurso}"?\n\nEsta ação não pode ser desfeita e pode afetar Cursos que utilizam este status.',
      confirmText: 'Excluir',
    );

    if (confirm) {
      try {
        final success = await CursoAprendizagemService.deletarCursoAprendizagem(
            curso.id! as String);
        if (success) {
          AppUtils.showSuccessSnackBar(context, 'Item excluído com sucesso!');
          _loadCursos();
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  Widget _buildPaginacao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Página $_currentPage de $_totalPages'),
          Row(
            children: [
              ElevatedButton(
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadCursos();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Anterior'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _currentPage < _totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadCursos();
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Próxima'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportarDados() async {
    try {
      await CursoAprendizagemService.exportarCursosCSV(
        ativo: _filtroAtivo,
      );
      AppUtils.showSuccessSnackBar(context, 'Dados exportados com sucesso!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao exportar: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _nomeCursoController.dispose();
    _cboController.dispose();
    _cboBuscaController.dispose(); // Novo controller
    _validadeController.dispose();
    _disciplinaController.dispose();
    super.dispose();
  }
}
