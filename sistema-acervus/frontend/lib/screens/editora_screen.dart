import 'package:flutter/material.dart';

import 'package:sistema_estagio/models/editora.dart';
import 'package:sistema_estagio/models/pais.dart';
import 'package:sistema_estagio/models/estado.dart';
import 'package:sistema_estagio/models/cidade.dart';

import 'package:sistema_estagio/services/pais_service.dart';
import 'package:sistema_estagio/services/estado_service.dart';
import 'package:sistema_estagio/services/cidade_service.dart';
import 'package:sistema_estagio/services/editora_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';

import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';

import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/crud_page.dart';
import 'package:sistema_estagio/widgets/crud_header.dart';
import 'package:sistema_estagio/widgets/crud_form_container.dart';
import 'package:sistema_estagio/widgets/crud_pagination.dart';

class EditoraScreen extends StatefulWidget {
  const EditoraScreen({super.key});

  @override
  State<EditoraScreen> createState() => _EditoraScreenState();
}

class _EditoraScreenState extends State<EditoraScreen> {
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
  bool _showForm = false;

  int _currentPage = 1;
  int _pageSize = 10;

  Map<String, dynamic>? _pagination;

  String _currentSearch = '';

  Editora? _editando;

  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _loadPaises();
    _loadEditoras();
  }

  // ================= LOAD =================

  Future<void> _loadPaises() async {
    final r = await PaisService.listar(page: 1, limit: 999, ativo: true);
    setState(() => _paises = List<Pais>.from(r['paises'] ?? []));
  }

  Future<void> _loadEstados(int paisId) async {
    final r = await EstadoService.listarPorPais(paisId);

    setState(() {
      _estados = List<Estado>.from(r);
      _estado = null;
      _cidade = null;
      _cidades = [];
    });
  }

  Future<void> _loadCidades(int estadoId) async {
    final r = await CidadeService.listarPorEstado(estadoId);

    setState(() {
      _cidades = List<Cidade>.from(r);
      _cidade = null;
    });
  }

  Future<void> _loadEditoras() async {
    setState(() => _isLoading = true);

    try {
      final result = await EditoraService.listar(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      setState(() {
        _editoras = List<Editora>.from(result['Editoras'] ?? []);
        _pagination = result['pagination'];
      });
    } catch (_) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar editoras');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: "Editoras",
      isLoading: _isLoading,
      onAdd: _novo,
      header: _buildHeader(),
      form: _showForm ? CrudFormContainer(child: _buildFormulario()) : null,
      list: _buildList(),
      pagination: CrudPagination(
        currentPage: _currentPage,
        totalPages: _pagination?['totalPages'] ?? 1,
        onPageChange: _go,
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader() {
    return CrudHeader(
      stats: Row(
        children: [
          Expanded(
            child: _statCard(
              "Total",
              (_pagination?['totalItems'] ?? _editoras.length).toString(),
              Icons.book,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _statCard(
              "Páginas",
              (_pagination?['totalPages'] ?? 0).toString(),
              Icons.layers,
              Colors.blue,
            ),
          ),
        ],
      ),
      search: Row(
        children: [
          Expanded(
            child: CustomTextField(
              controller: _searchController,
              label: "Buscar editora",
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _search,
            child: const Text("Buscar"),
          ),
        ],
      ),
    );
  }

  // ================= FORM =================

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _descricaoController,
            label: "Descrição",
            validator: (v) => Validators.validateRequired(v, "Descrição"),
          ),
          const SizedBox(height: 16),
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

              setState(() => _pais = v);

              await _loadEstados(v.id!);
            },
            decoration: const InputDecoration(
              labelText: "País",
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
            onChanged: (v) async {
              if (v == null) return;

              setState(() => _estado = v);

              await _loadCidades(v.id!);
            },
            decoration: const InputDecoration(
              labelText: "Estado",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Cidade>(
            value: _cidade,
            items: _cidades
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.nome),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _cidade = v),
            decoration: const InputDecoration(
              labelText: "Cidade",
              border: OutlineInputBorder(),
            ),
          ),
          CheckboxListTile(
            title: const Text("Ativo"),
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v ?? true),
          ),
          Row(
            children: [
              ElevatedButton(
                onPressed: _cancelar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text("Cancelar"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _salvar,
                child: Text(_editando == null ? "Salvar" : "Atualizar"),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ================= LIST =================

  Widget _buildList() {
    if (_editoras.isEmpty) {
      return const Center(child: Text("Nenhuma editora cadastrada"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _editoras.length,
      itemBuilder: (_, i) {
        final e = _editoras[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.descricao,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: e.ativo
                                  ? Colors.green.withOpacity(0.12)
                                  : Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              e.ativo ? "ATIVO" : "INATIVO",
                              style: TextStyle(
                                color: e.ativo ? Colors.green : Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "ID: ${e.id}",
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) => _menu(v, e),
                  itemBuilder: (context) => [
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
          ),
        );
      },
    );
  }

  // ================= ACTIONS =================

  void _novo() {
    _limpar();

    setState(() => _showForm = true);
  }

  Future<void> _menu(String action, Editora e) async {
    if (action != "editar") {
      await EditoraService.atualizar(e.id!, {'ativo': !e.ativo});

      _loadEditoras();

      return;
    }

    setState(() {
      _editando = e;

      _descricaoController.text = e.descricao;

      _ativo = e.ativo;

      _showForm = true;
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

    if (_editando == null) {
      await EditoraService.criar(dados);
    } else {
      await EditoraService.atualizar(_editando!.id!, dados);
    }

    AppUtils.showSuccessSnackBar(context, "Editora salva com sucesso!");

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
    _currentSearch = _searchController.text;

    _currentPage = 1;

    _loadEditoras();
  }

  void _go(int page) {
    _currentPage = page;

    _loadEditoras();
  }

  Widget _statCard(String t, String v, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(i, color: c),
          const SizedBox(height: 4),
          Text(v, style: TextStyle(fontSize: 20, color: c)),
          Text(t),
        ],
      ),
    );
  }
}
