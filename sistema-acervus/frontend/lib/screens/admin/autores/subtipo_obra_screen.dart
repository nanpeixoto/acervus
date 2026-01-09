import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/_auxiliares/subtipo_obra.dart';
import 'package:sistema_estagio/models/_auxiliares/tipo_obra.dart';
import 'package:sistema_estagio/services/_auxiliares/subtipo_obra_service.dar.dart';

import 'package:sistema_estagio/services/_auxiliares/tipo_obra_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

class SubtipoObraScreen extends StatefulWidget {
  const SubtipoObraScreen({super.key});

  @override
  State<SubtipoObraScreen> createState() => _SubtipoObraScreenState();
}

class _SubtipoObraScreenState extends State<SubtipoObraScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<SubtipoObra> _subtipos = [];
  List<TipoObra> _tiposObra = [];

  bool _isLoading = false;
  bool _isLoadingPage = false;

  late TabController _tabController;
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  bool _showForm = false;
  SubtipoObra? _editando;
  final _formKey = GlobalKey<FormState>();

  final _descricaoController = TextEditingController();
  TipoObra? _tipoSelecionado;
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadTiposObra();
    _loadSubtipos();
  }

  Future<void> _loadTiposObra() async {
    try {
      final result = await TipoObraService.listar(
        page: 1,
        limit: 999,
        ativo: true,
      );
      setState(() => _tiposObra = result['TipoObras']);
    } catch (_) {}
  }

  Future<void> _loadSubtipos({bool showLoading = true}) async {
    if (!mounted) return;

    setState(() {
      showLoading ? _isLoading = true : _isLoadingPage = true;
    });

    try {
      final result = await SubtipoObraService.listar(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      setState(() {
        _subtipos = result['Subtipos'];
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(
        context,
        'Erro ao carregar subtipos de obra: $e',
      );
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
        title: const Text('Subtipo de Obra'),
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

  // ================= HEADER (PADRÃO ASSUNTOS) =================
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
                  'Total de Subtipos',
                  (_pagination?['totalItems'] ?? _subtipos.length).toString(),
                  Icons.category,
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Itens por página:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                items: _pageSizeOptions
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text('$s'),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _pageSize = v!;
                    _currentPage = 1;
                  });
                  _loadSubtipos();
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadSubtipos();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
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
                _editando == null
                    ? 'Novo Subtipo de Obra'
                    : 'Editar Subtipo de Obra',
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
          DropdownButtonFormField<TipoObra>(
            value: _tipoSelecionado,
            items: _tiposObra
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.descricao),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _tipoSelecionado = v),
            validator: (v) => v == null ? 'Tipo de Obra é obrigatório' : null,
            decoration: const InputDecoration(
              labelText: 'Tipo de Obra *',
              border: OutlineInputBorder(),
            ),
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
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _salvar,
                child: Text(_editando == null ? 'Criar' : 'Atualizar'),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList() {
    if (_subtipos.isEmpty) {
      return const Center(child: Text('Nenhum subtipo cadastrado'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subtipos.length,
      itemBuilder: (_, i) {
        final s = _subtipos[i];
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
                      s.descricao,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) => _menu(v, s),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'editar',
                        child: Text('Editar'),
                      ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(s.ativo ? 'Desativar' : 'Ativar'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tipo de Obra: ${s.tipoObraDescricao ?? '-'}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statusChip(s.ativo),
                  const Spacer(),
                  Text(
                    'Código: ${s.id}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ]),
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

  void _menu(String a, SubtipoObra s) {
    if (a == 'editar') {
      setState(() {
        _editando = s;
        _descricaoController.text = s.descricao;
        _tipoSelecionado = _tiposObra.firstWhere((t) => t.id == s.cdTipoObra);
        _ativo = s.ativo;
        _showForm = true;
      });
    } else {
      SubtipoObraService.atualizar(
        s.id!,
        {'ativo': !s.ativo},
      ).then((_) => _loadSubtipos(showLoading: false));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'descricao': _descricaoController.text.trim(),
      'cd_tipo_peca': _tipoSelecionado!.id,
      'ativo': _ativo,
    };

    if (_editando == null) {
      await SubtipoObraService.criar(dados);
    } else {
      await SubtipoObraService.atualizar(_editando!.id!, dados);
    }

    AppUtils.showSuccessSnackBar(context, 'Subtipo de obra salvo com sucesso!');
    _cancelar();
    _loadSubtipos();
  }

  void _cancelar() {
    _limpar();
    setState(() => _showForm = false);
  }

  void _limpar() {
    _editando = null;
    _descricaoController.clear();
    _tipoSelecionado = null;
    _ativo = true;
  }

  void _search() {
    _currentSearch = _searchController.text.trim();
    _currentPage = 1;
    _loadSubtipos();
  }

  void _clearSearch() {
    _searchController.clear();
    _currentSearch = '';
    _loadSubtipos();
  }

  void _go(int p) {
    _currentPage = p;
    _loadSubtipos(showLoading: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descricaoController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
