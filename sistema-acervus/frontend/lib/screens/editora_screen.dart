import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/editora.dart';
import 'package:sistema_estagio/models/pais.dart';
import 'package:sistema_estagio/models/estado.dart';
import 'package:sistema_estagio/models/cidade.dart';
import 'package:sistema_estagio/services/pais_service.dar.dart';
import 'package:sistema_estagio/services/estado_service.dar.dart';
import 'package:sistema_estagio/services/cidade_service.dar.dart';
import 'package:sistema_estagio/services/editora_service.dar.dart';
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
  final _descricaoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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

  bool _showForm = false;
  Editora? _editando;
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
    if (!mounted) return;
    setState(() => _paises = List<Pais>.from(r['paises'] ?? []));
  }

  Future<void> _loadEstados(int paisId) async {
    final r = await EstadoService.listarPorPais(paisId);
    if (!mounted) return;
    setState(() {
      _estados = List<Estado>.from(r);
      _estado = null;
      _cidade = null;
      _cidades = [];
    });
  }

  Future<void> _loadCidades(int estadoId) async {
    final r = await CidadeService.listarPorEstado(estadoId);
    if (!mounted) return;
    setState(() {
      _cidades = List<Cidade>.from(r);
      _cidade = null;
    });
  }

  Future<void> _loadEditoras({bool showLoading = true}) async {
    if (!mounted) return;

    setState(() {
      showLoading ? _isLoading = true : _isLoadingPage = true;
    });

    try {
      final result = await EditoraService.listar(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      if (!mounted) return;

      setState(() {
        _editoras = List<Editora>.from(result['Editoras'] ?? []);
        _pagination = result['pagination'];
      });
    } catch (_) {
      if (mounted) {
        AppUtils.showErrorSnackBar(context, 'Erro ao carregar editoras');
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editoras'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _novo),
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

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(children: [
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
          ]),
          const SizedBox(height: 16),
          Row(children: [
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
          ]),
          const SizedBox(height: 16),
          Row(children: [
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
          ]),
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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              _editando == null ? 'Nova Editora' : 'Editar Editora',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2)),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: _cancelar),
          ]),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _descricaoController,
            label: 'Descrição *',
            validator: (v) => Validators.validateRequired(v, 'Descrição'),
          ),
          const SizedBox(height: 16),

          // 🔑 KEYS FIXAS — PROBLEMA RESOLVIDO
          DropdownButtonFormField<Pais>(
            value: _pais,
            items: _paises
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(p.nome),
                    ))
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
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Estado>(
            value: _estado,
            items: _estados
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.nome),
                    ))
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
          ),

          const SizedBox(height: 16),
          DropdownButtonFormField<Cidade>(
            key: const ValueKey('cidade'),
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
          ]),
        ]),
      ),
    );
  }

  // ================= LIST / ACTIONS =================
  Widget _buildList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _editoras.length,
        itemBuilder: (_, i) {
          final e = _editoras[i];
          return Card(
            key: ValueKey(e.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(e.descricao),
              subtitle:
                  Text('${e.cidadeNome ?? '-'} / ${e.estadoSigla ?? '-'}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => _menu(v, e),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(e.ativo ? 'Desativar' : 'Ativar'),
                  ),
                ],
              ),
            ),
          );
        },
      );

  void _novo() {
    _limpar();
    setState(() => _showForm = true);
  }

  Future<void> _menu(String action, Editora e) async {
    if (action != 'editar') {
      await EditoraService.atualizar(e.id!, {'ativo': !e.ativo});
      if (mounted) _loadEditoras(showLoading: false);
      return;
    }

    setState(() {
      _editando = e;
      _descricaoController.text = e.descricao;
      _ativo = e.ativo;
      _showForm = true;
    });

    // ========= 1️⃣ PAÍS =========
    final paisSelecionado = _paises.firstWhere(
      (p) => p.id == e.paisId,
      orElse: () => _paises.first,
    );

    setState(() {
      _pais = paisSelecionado;
      _estado = null;
      _cidade = null;
      _estados = [];
      _cidades = [];
    });

    // ========= 2️⃣ ESTADOS =========
    await _loadEstados(paisSelecionado.id!);

    final estadoSelecionado = _estados.firstWhere(
      (s) => s.id == e.estadoId,
      orElse: () => _estados.first,
    );

    setState(() {
      _estado = estadoSelecionado;
      _cidade = null;
      _cidades = [];
    });

    // ========= 3️⃣ CIDADES =========
    await _loadCidades(estadoSelecionado.id!);

    final cidadeSelecionada = _cidades.firstWhere(
      (c) => c.id == e.cidadeId,
      orElse: () => _cidades.first,
    );

    setState(() {
      _cidade = cidadeSelecionada;
    });
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

    _editando == null
        ? await EditoraService.criar(dados)
        : await EditoraService.atualizar(_editando!.id!, dados);

    if (!mounted) return;
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

  void _clearSearch() {
    _searchController.clear();
    _currentSearch = '';
    _loadEditoras();
  }

  void _go(int p) {
    _currentPage = p;
    _loadEditoras(showLoading: false);
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
