import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/_auxiliares/editora.dart';
import 'package:sistema_estagio/models/_auxiliares/pais.dart';
import 'package:sistema_estagio/models/_auxiliares/estado.dart';
import 'package:sistema_estagio/models/_auxiliares/cidade.dart';
import 'package:sistema_estagio/services/_auxiliares/cidade_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/editora_service.dar.dart';

import 'package:sistema_estagio/services/_auxiliares/estado_service.dar.dart';

import 'package:sistema_estagio/services/_auxiliares/pais_service.dar.dart';

import 'package:sistema_estagio/utils/app_config.dart';

import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

class EditoraScreen extends StatefulWidget {
  const EditoraScreen({super.key});

  @override
  State<EditoraScreen> createState() => _EditoraScreenState();
}

class _EditoraScreenState extends State<EditoraScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<Editora> _editoras = [];
  List<Pais> _paises = [];
  List<Estado> _estados = [];
  List<Cidade> _cidades = [];

  Pais? _pais;
  Estado? _estado;
  Cidade? _cidade;

  bool _isLoading = false;
  bool _isLoadingPage = false;

  late TabController _tabController;
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final _formKey = GlobalKey<FormState>();
  bool _showForm = false;
  Editora? _editando;

  final _descricaoController = TextEditingController();
  bool _ativo = true;

  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadPaises();
    _loadEditoras();
  }

  // ================= LOAD =================
  Future<void> _loadPaises() async {
    final r = await PaisService.listar(page: 1, limit: 999, ativo: true);
    setState(() => _paises = r['paises']);
  }

  Future<void> _loadEstados(int paisId) async {
    final r = await EstadoService.listarPorPais(paisId);
    setState(() {
      _estados = r;
      _estado = null;
      _cidade = null;
      _cidades = [];
    });
  }

  Future<void> _loadCidades(int estadoId) async {
    final r = await CidadeService.listarPorEstado(estadoId);
    setState(() {
      _cidades = r;
      _cidade = null;
    });
  }

  Future<void> _loadEditoras({bool showLoading = true}) async {
    setState(() {
      showLoading ? _isLoading = true : _isLoadingPage = true;
    });

    try {
      final result = await EditoraService.listar(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      setState(() {
        _editoras = result['Editoras'];
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar editoras');
    } finally {
      _isLoading = false;
      _isLoadingPage = false;
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editoras'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _novo,
          )
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [_buildLista()],
        ),
      ),
    );
  }

  Widget _buildLista() {
    return Column(
      children: [
        _buildHeader(),
        if (_showForm) _buildFormulario(),
        Expanded(child: _buildList()),
        _buildPaginationControls(),
      ],
    );
  }

  // ================= HEADER =================Widget _buildHeader() {
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
                  'Total de Editoras',
                  (_pagination?['totalItems'] ?? _editoras.length).toString(),
                  Icons.book,
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
                    .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _pageSize = v!;
                    _currentPage = 1;
                  });
                  _loadEditoras();
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadEditoras();
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

  void _clearSearch() {
    _searchController.clear();
    _currentSearch = '';
    _loadEditoras();
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
                _editando == null ? 'Nova Editora' : 'Editar Editora',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1976D2)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelar,
              )
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _descricaoController,
            label: 'Descrição *',
            validator: (v) => Validators.validateRequired(v, 'Descrição'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Pais>(
            key: ValueKey(_pais?.id),
            value: _pais,
            items: _paises
                .map((p) => DropdownMenuItem(value: p, child: Text(p.nome)))
                .toList(),
            onChanged: (v) async {
              if (v == null) return;

              setState(() {
                _pais = v;
                _estado = null;
                _cidade = null;
                _estados = [];
                _cidades = [];
              });

              await _loadEstados(v.id!);
            },
            decoration: const InputDecoration(
              labelText: 'País *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null ? 'País obrigatório' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Estado>(
            key: ValueKey(_estado?.id),
            value: _estado,
            items: _estados
                .map((e) => DropdownMenuItem(value: e, child: Text(e.nome)))
                .toList(),
            onChanged: _estados.isEmpty
                ? null
                : (v) async {
                    if (v == null) return;

                    setState(() {
                      _estado = v;
                      _cidade = null;
                      _cidades = [];
                    });

                    await _loadCidades(v.id!);
                  },
            decoration: const InputDecoration(
              labelText: 'Estado *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null ? 'Estado obrigatório' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Cidade>(
            key: ValueKey(_cidade?.id),
            value: _cidade,
            items: _cidades
                .map((c) => DropdownMenuItem(value: c, child: Text(c.nome)))
                .toList(),
            onChanged:
                _cidades.isEmpty ? null : (v) => setState(() => _cidade = v),
            decoration: const InputDecoration(
              labelText: 'Cidade *',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null ? 'Cidade obrigatória' : null,
          ),
          CheckboxListTile(
            title: const Text('Ativo'),
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v ?? true),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          Row(children: [
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
          ])
        ]),
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList() {
    if (_editoras.isEmpty) {
      return const Center(child: Text('Nenhuma editora cadastrada'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _editoras.length,
      itemBuilder: (_, i) {
        final e = _editoras[i];
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
                        e.descricao,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) => _menu(v, e),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar'),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(e.ativo ? 'Desativar' : 'Ativar'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${e.cidadeNome ?? '-'} / ${e.estadoSigla ?? '-'}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statusChip(e.ativo),
                    const Spacer(),
                    Text(
                      'ID: ${e.id}',
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

  void _menu(String a, Editora e) {
    if (a == 'editar') {
      setState(() {
        _editando = e;
        _descricaoController.text = e.descricao;
        _ativo = e.ativo;
        _showForm = true;
      });
    } else {
      EditoraService.atualizar(e.id!, {'ativo': !e.ativo})
          .then((_) => _loadEditoras(showLoading: false));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'descricao': _descricaoController.text.trim(),
      'pais_id': _pais!.id,
      'estado_id': _estado!.id,
      'cidade_id': _cidade!.id,
      'ativo': _ativo,
    };

    if (_editando == null) {
      await EditoraService.criar(dados);
    } else {
      await EditoraService.atualizar(_editando!.id!, dados);
    }

    AppUtils.showSuccessSnackBar(context, 'Editora salva com sucesso!');
    _cancelar();
    _loadEditoras();
  }

  void _cancelar() {
    _limpar();
    setState(() => _showForm = false);
  }

  void _limpar() {
    _editando = null;
    _descricaoController.clear();
    _pais = null;
    _estado = null;
    _cidade = null;
    _ativo = true;
  }

  void _search() {
    _currentSearch = _searchController.text.trim();
    _currentPage = 1;
    _loadEditoras();
  }

  void _go(int p) {
    _currentPage = p;
    _loadEditoras(showLoading: false);
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
          Icon(i, color: c),
          const SizedBox(width: 8),
          Text(t, style: TextStyle(color: c)),
        ]),
        const SizedBox(height: 4),
        Text(v,
            style:
                TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)),
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
