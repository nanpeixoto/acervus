import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/_auxiliares/estante.dart';
import 'package:sistema_estagio/models/_auxiliares/prateleira.dart';
import 'package:sistema_estagio/models/prateleiraForm.dart';
import 'package:sistema_estagio/services/_auxiliares/estante_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

class EstanteScreen extends StatefulWidget {
  const EstanteScreen({super.key});

  @override
  State<EstanteScreen> createState() => _EstanteScreenState();
}

class _EstanteScreenState extends State<EstanteScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  // ================= LISTA =================
  List<Estante> _estantes = [];

  bool _isLoading = false;
  bool _isLoadingPage = false;

  late TabController _tabController;
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  // ================= FORM =================
  bool _showForm = false;
  final _formKey = GlobalKey<FormState>();

  Estante? _editando; // <<< CONTROLE DE EDIÇÃO

  final _descricaoController = TextEditingController();
  final List<PrateleiraForm> _prateleiras = [];

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadLista();
  }

  // ================= LOAD LISTA =================
  Future<void> _loadLista({bool showLoading = true}) async {
    if (!mounted) return;

    setState(() {
      showLoading ? _isLoading = true : _isLoadingPage = true;
    });

    try {
      final result = await EstanteService.listar(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      setState(() {
        _estantes = result['Estantes'];
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(
        context,
        'Erro ao carregar estantes: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estantes'),
        actions: [
          IconButton(
            onPressed: _novo,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [_buildListaTab()],
        ),
      ),
    );
  }

  // ================= LISTA TAB =================
  Widget _buildListaTab() {
    return Column(
      children: [
        _buildHeader(),
        if (_showForm) _buildFormulario(),
        Expanded(child: _buildList()),
        _buildPaginationControls(),
      ],
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total de Estantes',
                  (_pagination?['totalItems'] ?? _estantes.length).toString(),
                  Icons.storage,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Total de Páginas',
                  (_pagination?['totalPages'] ?? 0).toString(),
                  Icons.layers,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Buscar por descrição',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= FORM =================
  Widget _buildFormulario() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Form(
        key: _formKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _editando == null ? 'Cadastro de Estante' : 'Editar Estante',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelar,
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _descricaoController,
            label: 'Descrição da Estante *',
            validator: (v) =>
                Validators.validateRequired(v, 'Descrição da Estante'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Prateleiras',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._prateleiras.asMap().entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: e.value.controller,
                      label: 'Descrição da Prateleira',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        setState(() => _prateleiras.removeAt(e.key)),
                  )
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () =>
                setState(() => _prateleiras.add(PrateleiraForm(descricao: ''))),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Prateleira'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _cancelar,
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _salvar,
                child: Text(_editando == null ? 'Salvar' : 'Atualizar'),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList() {
    if (_estantes.isEmpty) {
      return const Center(child: Text('Nenhuma estante cadastrada'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _estantes.length,
      itemBuilder: (_, i) {
        final e = _estantes[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      e.descricao,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editar(e),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Prateleiras: ${e.prateleiras.length}',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ]),
          ),
        );
      },
    );
  }

  // ================= PAGINAÇÃO =================
  Widget _buildPaginationControls() {
    if (_pagination == null) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: _currentPage > 1 ? () => _go(_currentPage - 1) : null,
        ),
        Text('Página $_currentPage de ${_pagination!['totalPages']}'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < _pagination!['totalPages']
              ? () => _go(_currentPage + 1)
              : null,
        ),
      ],
    );
  }

  // ================= ACTIONS =================
  void _novo() {
    _limpar();
    setState(() {
      _editando = null;
      _showForm = true;
    });
  }

  void _editar(Estante e) {
    setState(() {
      _editando = e;
      _showForm = true;

      _descricaoController.text = e.descricao;
      _prateleiras.clear();

      for (final p in e.prateleiras) {
        _prateleiras.add(
          PrateleiraForm(descricao: p.descricao),
        );
      }
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final estante = Estante(
        id: _editando?.id,
        paisId: 1,
        estadoId: 1,
        cidadeId: 1,
        cdSala: 1,
        descricao: _descricaoController.text.trim(),
        prateleiras: _prateleiras
            .map((p) => Prateleira(descricao: p.controller.text.trim()))
            .toList(),
      );

      if (_editando == null) {
        await EstanteService.criar(estante);
      } else {
        await EstanteService.atualizar(_editando!.id!, estante);
      }

      AppUtils.showSuccessSnackBar(
        context,
        _editando == null
            ? 'Estante criada com sucesso!'
            : 'Estante atualizada com sucesso!',
      );

      _cancelar();
      _loadLista();
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao salvar estante: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelar() {
    _limpar();
    setState(() {
      _editando = null;
      _showForm = false;
    });
  }

  void _limpar() {
    _descricaoController.clear();
    _prateleiras.clear();
  }

  void _search() {
    _currentSearch = _searchController.text.trim();
    _currentPage = 1;
    _loadLista();
  }

  void _clearSearch() {
    _searchController.clear();
    _currentSearch = '';
    _loadLista();
  }

  void _go(int p) {
    _currentPage = p;
    _loadLista(showLoading: false);
  }

  Widget _statCard(String t, String v, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(i, color: c, size: 20),
          const SizedBox(width: 8),
          Text(t, style: TextStyle(fontSize: 12, color: c)),
        ]),
        const SizedBox(height: 4),
        Text(
          v,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: c,
          ),
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descricaoController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
