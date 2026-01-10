import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/_auxiliares/estante.dart';
import 'package:sistema_estagio/models/_auxiliares/prateleira.dart';
import 'package:sistema_estagio/models/_auxiliares/sala_obra.dart';
import 'package:sistema_estagio/models/prateleiraForm.dart';
import 'package:sistema_estagio/services/_auxiliares/estante_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

import 'package:sistema_estagio/models/_auxiliares/pais.dart';
import 'package:sistema_estagio/models/_auxiliares/estado.dart';
import 'package:sistema_estagio/models/_auxiliares/cidade.dart';

import 'package:sistema_estagio/services/_auxiliares/pais_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/estado_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/cidade_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/sala_service.dar.dart';

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

  List<Pais> _paises = [];
  List<Estado> _estados = [];
  List<Cidade> _cidades = [];
  List<Sala> _salas = [];

  Pais? _pais;
  Estado? _estado;
  Cidade? _cidade;
  Sala? _sala;

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
    _loadPaises();
    _loadLista();
  }

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
      _sala = null;
      _cidades = [];
      _salas = [];
    });
  }

  Future<void> _loadCidades(int estadoId) async {
    final r = await CidadeService.listarPorEstado(estadoId);
    if (!mounted) return;
    setState(() {
      _cidades = List<Cidade>.from(r);
      _cidade = null;
      _sala = null;
      _salas = [];
    });
  }

  Future<void> _loadSalas(int cidadeId) async {
    final r = await SalaService.listarPorCidade(cidadeId);
    if (!mounted) return;
    setState(() {
      _salas = r;
      _sala = null;
    });
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
        child: SingleChildScrollView(
          // 👈 AQUI
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _formHeader(),
              const SizedBox(height: 16),
              _campoDescricao(),
              const SizedBox(height: 16),
              DropdownButtonFormField<Pais>(
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
                    _sala = null;
                    _estados = [];
                    _cidades = [];
                    _salas = [];
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
                          _sala = null;
                          _cidades = [];
                          _salas = [];
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
                value: _cidade,
                items: _cidades
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.nome)))
                    .toList(),
                onChanged: _cidades.isEmpty
                    ? null
                    : (v) async {
                        if (v == null) return;
                        setState(() {
                          _cidade = v;
                          _sala = null;
                          _salas = [];
                        });
                        await _loadSalas(v.id!);
                      },
                decoration: const InputDecoration(
                  labelText: 'Cidade *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Cidade obrigatória' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Sala>(
                value: _sala,
                items: _salas
                    .map((s) =>
                        DropdownMenuItem(value: s, child: Text(s.descricao)))
                    .toList(),
                onChanged:
                    _salas.isEmpty ? null : (v) => setState(() => _sala = v),
                decoration: const InputDecoration(
                  labelText: 'Sala *',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null ? 'Sala obrigatória' : null,
              ),
              const SizedBox(height: 24),
              _listaPrateleiras(),
              const SizedBox(height: 16),
              _botoesFormulario(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botoesFormulario() {
    return Row(
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
          child: Text(
            _editando == null ? 'Salvar' : 'Atualizar',
          ),
        ),
      ],
    );
  }

  Widget _campoDescricao() {
    return CustomTextField(
      controller: _descricaoController,
      label: 'Descrição da Estante *',
      validator: (v) => Validators.validateRequired(v, 'Descrição da Estante'),
    );
  }

  Widget _formHeader() {
    return Row(
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
          tooltip: 'Fechar',
          onPressed: _cancelar,
        ),
      ],
    );
  }

  Widget _listaPrateleiras() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prateleiras',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _prateleiras.length,
            itemBuilder: (context, index) {
              final p = _prateleiras[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: p.controller,
                        label: 'Descrição da Prateleira',
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _prateleiras.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _prateleiras.add(PrateleiraForm(descricao: ''));
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Prateleira'),
        ),
      ],
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ====== TOPO ======
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        e.descricao,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'editar') _editar(e.id!);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'editar',
                          child: Text('Editar'),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ====== INFORMAÇÕES ======
                Text(
                  'Sala: ${e.sala_descricao ?? '-'}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Localização: ${e.pais_descricao ?? '-'} / ${e.estado_descricao ?? '-'} / ${e.cidade_descricao ?? '-'}',
                  style: TextStyle(color: Colors.grey[700]),
                ),

                const SizedBox(height: 12),

                // ====== RODAPÉ ======
                Row(
                  children: [
                    Chip(
                      label: const Text(
                        'ATIVO',
                        style: TextStyle(color: Colors.green),
                      ),
                      backgroundColor: Colors.green.withOpacity(0.15),
                    ),
                    const Spacer(),
                    Text(
                      'Código: ${e.id}',
                      style: TextStyle(color: Colors.grey[600]),
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

  Future<void> _editar(int id) async {
    try {
      setState(() => _isLoading = true);

      final estante = await EstanteService.buscarPorId(id);

      _descricaoController.text = estante.descricao;
      _prateleiras.clear();
      for (final p in estante.prateleiras) {
        _prateleiras.add(PrateleiraForm(descricao: p.descricao));
      }

      final pais = _paises.firstWhere((p) => p.id == estante.paisId);
      setState(() => _pais = pais);

      await _loadEstados(pais.id!);
      final estado = _estados.firstWhere((e) => e.id == estante.estadoId);
      setState(() => _estado = estado);

      await _loadCidades(estado.id!);
      final cidade = _cidades.firstWhere((c) => c.id == estante.cidadeId);
      setState(() => _cidade = cidade);

      await _loadSalas(cidade.id!);
      final sala = _salas.firstWhere((s) => s.id == estante.cdSala);
      setState(() => _sala = sala);

      setState(() {
        _editando = estante;
        _showForm = true;
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao editar estante');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      final estante = Estante(
        id: _editando?.id,
        paisId: _pais!.id!,
        estadoId: _estado!.id!,
        cidadeId: _cidade!.id!,
        cdSala: _sala!.id!,
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
