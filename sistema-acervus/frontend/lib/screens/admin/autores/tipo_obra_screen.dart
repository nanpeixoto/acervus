import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/_auxiliares/tipo_obra.dart';
import 'package:sistema_estagio/services/_auxiliares/tipo_obra_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

class TipoObraScreen extends StatefulWidget {
  const TipoObraScreen({super.key});

  @override
  State<TipoObraScreen> createState() => _TipoObraScreenState();
}

class _TipoObraScreenState extends State<TipoObraScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<TipoObra> _tipos = [];
  bool _isLoading = false;
  bool _isLoadingPage = false;

  bool? _filtroAtivo;

  late TabController _tabController;
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  bool _showForm = false;
  TipoObra? _editando;
  final _formKey = GlobalKey<FormState>();

  final _descricaoController = TextEditingController();
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadTipos();
  }

  Future<void> _loadTipos({bool showLoading = true}) async {
    if (!mounted) return;

    setState(() {
      showLoading ? _isLoading = true : _isLoadingPage = true;
    });

    try {
      final result = await TipoObraService.listar(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
      );

      setState(() {
        _tipos = result['TipoObras'];
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar tipos de obra: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipo de Obra'),
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

  // ================= LISTA =================
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
                  'Total de Tipos',
                  (_pagination?['totalItems'] ?? _tipos.length).toString(),
                  Icons.apartment,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Total de Páginas',
                  (_pagination?['totalPages'] ?? 0).toString(),
                  Icons.layers,
                  const Color(0xFF1976D2),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editando == null
                      ? 'Novo Tipo de Obra'
                      : 'Editar Tipo de Obra',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
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
              label: 'Descrição *',
              validator: (v) => Validators.validateRequired(v, 'Descrição'),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Ativo'),
              value: _ativo,
              onChanged: (v) => setState(() => _ativo = v ?? true),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _cancelar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _salvar,
                  child: Text(_editando == null ? 'Criar' : 'Atualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList() {
    if (_tipos.isEmpty) {
      return const Center(child: Text('Nenhum tipo de obra cadastrado'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tipos.length,
      itemBuilder: (_, i) {
        final t = _tipos[i];
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
                    Expanded(
                      child: Text(
                        t.descricao,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) => _menu(v, t),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(t.ativo ? 'Desativar' : 'Ativar'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statusChip(t.ativo),
                    const Spacer(),
                    Text(
                      'Código: ${t.id}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusChip(bool ativo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ativo
            ? Colors.green.withOpacity(0.1)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ativo ? Colors.green : Colors.grey),
      ),
      child: Text(
        ativo ? 'ATIVO' : 'INATIVO',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: ativo ? Colors.green : Colors.grey,
        ),
      ),
    );
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
        Text(v,
            style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)),
      ]),
    );
  }

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
    setState(() => _showForm = true);
  }

  void _menu(String a, TipoObra t) {
    if (a == 'editar') {
      setState(() {
        _editando = t;
        _descricaoController.text = t.descricao;
        _ativo = t.ativo;
        _showForm = true;
      });
    } else {
      TipoObraService.atualizar(t.id!, {'ativo': !t.ativo})
          .then((_) => _loadTipos(showLoading: false));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'descricao': _descricaoController.text.trim(),
      'ativo': _ativo,
    };

    if (_editando == null) {
      await TipoObraService.criar(dados);
    } else {
      await TipoObraService.atualizar(_editando!.id!, dados);
    }

    AppUtils.showSuccessSnackBar(context, 'Tipo de obra salvo com sucesso!');
    _cancelar();
    _loadTipos();
  }

  void _cancelar() {
    _limpar();
    setState(() => _showForm = false);
  }

  void _limpar() {
    _editando = null;
    _descricaoController.clear();
    _ativo = true;
  }

  void _search() {
    _currentSearch = _searchController.text.trim();
    _currentPage = 1;
    _loadTipos();
  }

  void _clearSearch() {
    _searchController.clear();
    _currentSearch = '';
    _loadTipos();
  }

  void _go(int p) {
    _currentPage = p;
    _loadTipos(showLoading: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descricaoController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
