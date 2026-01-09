import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/_auxiliares/autor.dart';
import 'package:sistema_estagio/services/_auxiliares/autor_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

class AutoresScreen extends StatefulWidget {
  const AutoresScreen({super.key});

  @override
  State<AutoresScreen> createState() => _AutoresScreenState();
}

class _AutoresScreenState extends State<AutoresScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<Autor> _autores = [];
  bool _isLoading = false;
  bool _isLoadingPage = false;

  // Filtros
  bool? _filtroAtivo;

  // Paginação
  late TabController _tabController;
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  // Formulário
  bool _showForm = false;
  Autor? _autorEditando;
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _observacaoController = TextEditingController();
  DateTime? _dataNascimento;
  DateTime? _dataFalecimento;
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadAutores();
  }

  // ===============================
  // LOAD
  // ===============================
  Future<void> _loadAutores({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingPage = true);
    }

    try {
      final result = await AutorService.listarAutores(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
      );

      setState(() {
        _autores = result['autores'];
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar autores: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
    }
  }

  // ===============================
  // BUILD
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Autores'),
        actions: [
          IconButton(
            onPressed: _showFiltrosDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros',
          ),
          IconButton(
            onPressed: _showNovoAutorForm,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Autor',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildListaTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildListaTab() {
    return Column(
      children: [
        _buildHeader(),
        if (_showForm) _buildFormulario(),
        Expanded(child: _buildAutoresList()),
        _buildPaginationControls(),
      ],
    );
  }

  // ===============================
  // HEADER (IGUAL AO DE IDIOMAS)
  // ===============================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Cards de estatística
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Autores',
                  (_pagination?['totalItems'] ?? _autores.length).toString(),
                  Icons.person,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total de Paginas',
                  (_pagination?['totalPages'] ?? _autores.length).toString(),
                  Icons.check_circle,
                  const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Busca
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Buscar por nome do autor',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          // Paginação
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Itens por página:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                items: _pageSizeOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _pageSize = v;
                      _currentPage = 1;
                    });
                    _loadAutores();
                  }
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadAutores();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          if (_filtroAtivo != null || _currentSearch.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildFiltrosAtivos(),
          ],
        ],
      ),
    );
  }

  // ===============================
  // FORMULÁRIO (MESMO PADRÃO)
  // ===============================
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
                  _autorEditando == null ? 'Novo Autor' : 'Editar Autor',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _cancelarForm,
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nomeController,
              label: 'Nome do Autor *',
              validator: (v) => Validators.validateRequired(v, 'Nome do Autor'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _dateField('Nascimento', _dataNascimento,
                        (d) => setState(() => _dataNascimento = d))),
                const SizedBox(width: 16),
                Expanded(
                    child: _dateField('Falecimento', _dataFalecimento,
                        (d) => setState(() => _dataFalecimento = d))),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _observacaoController,
              label: 'Observação',
              maxLines: 3,
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
                  onPressed: _cancelarForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _salvarAutor,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_autorEditando == null ? 'Criar' : 'Atualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // LISTA (CARD CLONE DO IDIOMA)
  // ===============================
  Widget _buildAutoresList() {
    if (_isLoadingPage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_autores.isEmpty) {
      return Center(
        child: Text(
          _currentSearch.isNotEmpty
              ? 'Nenhum autor encontrado'
              : 'Nenhum autor cadastrado',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _autores.length,
      itemBuilder: (_, i) => _buildAutorCard(_autores[i]),
    );
  }

  Widget _buildAutorCard(Autor autor) {
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
                    autor.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _menuAction(v, autor),
                  itemBuilder: (_) => [
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
                      value: autor.ativo ? 'desativar' : 'ativar',
                      child: Row(
                        children: [
                          Icon(
                            autor.ativo
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(autor.ativo ? 'Desativar' : 'Ativar'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statusChip(autor.ativo),
                const Spacer(),
                Text(
                  'ID: ${autor.id}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
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
        border: Border.all(
          color: ativo ? Colors.green : Colors.grey,
        ),
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

  // ===============================
  // PAGINAÇÃO (IDÊNTICA)
  // ===============================
  Widget _buildPaginationControls() {
    if (_pagination == null) return const SizedBox.shrink();

    final totalPages = _pagination!['totalPages'];
    final currentPage = _pagination!['currentPage'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 1 ? () => _goToPage(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('Página $currentPage de $totalPages'),
        IconButton(
          onPressed: currentPage < totalPages
              ? () => _goToPage(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _goToPage(int page) {
    if (page != _currentPage) {
      setState(() => _currentPage = page);
      _loadAutores(showLoading: false);
    }
  }

  // ===============================
  // ACTIONS
  // ===============================
  void _showNovoAutorForm() {
    _limparForm();
    setState(() => _showForm = true);
  }

  void _menuAction(String action, Autor autor) {
    if (action == 'editar') _editarAutor(autor);
    if (action == 'ativar' || action == 'desativar') {
      AutorService.atualizarAutor(autor.id!, {'ativo': !autor.ativo})
          .then((_) => _loadAutores(showLoading: false));
    }
  }

  void _editarAutor(Autor autor) {
    setState(() {
      _autorEditando = autor;
      _nomeController.text = autor.nome;
      _observacaoController.text = autor.observacao ?? '';
      _dataNascimento = autor.dataNascimento;
      _dataFalecimento = autor.dataFalecimento;
      _ativo = autor.ativo;
      _showForm = true;
    });
  }

  Future<void> _salvarAutor() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'nome': _nomeController.text.trim(),
      'observacao': _observacaoController.text.trim(),
      'data_nascimento': _dataNascimento?.toIso8601String(),
      'data_falecimento': _dataFalecimento?.toIso8601String(),
      'ativo': _ativo,
    };

    try {
      setState(() => _isLoading = true);

      if (_autorEditando == null) {
        await AutorService.criarAutor(dados);
      } else {
        await AutorService.atualizarAutor(_autorEditando!.id!, dados);
      }

      AppUtils.showSuccessSnackBar(context, 'Autor salvo com sucesso!');
      _cancelarForm();
      _loadAutores();
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelarForm() {
    _limparForm();
    setState(() => _showForm = false);
  }

  void _limparForm() {
    _autorEditando = null;
    _nomeController.clear();
    _observacaoController.clear();
    _dataNascimento = null;
    _dataFalecimento = null;
    _ativo = true;
  }

  void _performSearch() {
    setState(() {
      _currentSearch = _searchController.text.trim();
      _currentPage = 1;
    });
    _loadAutores();
  }

  void _clearSearch() {
    _searchController.clear();
    _currentSearch = '';
    _currentPage = 1;
    _loadAutores();
  }

  void _showFiltrosDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Filtros'),
        content: DropdownButtonFormField<bool>(
          value: _filtroAtivo,
          decoration: const InputDecoration(labelText: 'Status'),
          items: const [
            DropdownMenuItem(value: null, child: Text('Todos')),
            DropdownMenuItem(value: true, child: Text('Ativos')),
            DropdownMenuItem(value: false, child: Text('Inativos')),
          ],
          onChanged: (v) => setState(() => _filtroAtivo = v),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _filtroAtivo = null);
              Navigator.pop(context);
              _loadAutores();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAutores();
            },
            child: const Text('Aplicar'),
          ),
        ],
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
              Text(title,
                  style:
                      TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFiltrosAtivos() {
    return Wrap(
      spacing: 8,
      children: [
        if (_currentSearch.isNotEmpty)
          _buildFiltroChip('Busca: "$_currentSearch"', _clearSearch),
        if (_filtroAtivo != null)
          _buildFiltroChip(
            'Status: ${_filtroAtivo! ? "Ativos" : "Inativos"}',
            () {
              setState(() => _filtroAtivo = null);
              _loadAutores();
            },
          ),
      ],
    );
  }

  Widget _buildFiltroChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    Function(DateTime?) onChange,
  ) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(1500),
          lastDate: DateTime.now(),
          initialDate: value ?? DateTime.now(),
        );
        onChange(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value != null ? AppUtils.formatDate(value) : 'Selecionar data',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nomeController.dispose();
    _observacaoController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
