import 'package:flutter/material.dart';

import 'package:sistema_estagio/models/estado_conservacao.dart';
import 'package:sistema_estagio/services/estado_conservacao_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';

import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';

import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/crud_page.dart';
import 'package:sistema_estagio/widgets/crud_header.dart';
import 'package:sistema_estagio/widgets/crud_form_container.dart';
import 'package:sistema_estagio/widgets/crud_pagination.dart';

class EstadoConservacaoScreen extends StatefulWidget {
  const EstadoConservacaoScreen({super.key});

  @override
  State<EstadoConservacaoScreen> createState() =>
      _EstadoConservacaoScreenState();
}

class _EstadoConservacaoScreenState extends State<EstadoConservacaoScreen> {
  final _searchController = TextEditingController();
  final _descricaoController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  List<EstadoConservacao> _itens = [];

  bool _isLoading = false;
  bool _showForm = false;

  bool? _filtroAtivo;

  int _currentPage = 1;
  int _pageSize = 10;

  Map<String, dynamic>? _pagination;

  String _currentSearch = '';

  EstadoConservacao? _editando;

  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ================= LOAD =================

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      final result = await EstadoConservacaoService.listar(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
      );

      setState(() {
        _itens = List<EstadoConservacao>.from(result['estados']);
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar dados');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: "Estado de Conservação",
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
              (_pagination?['totalItems'] ?? _itens.length).toString(),
              Icons.inventory_2,
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
              label: "Buscar",
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _buscar,
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
  Widget _statusMeta(bool ativo) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: ativo ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          ativo ? 'Ativo' : 'Inativo',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _metaText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
      ),
    );
  }

  Widget _buildList() {
    if (_itens.isEmpty) {
      return const Center(child: Text("Nenhum registro encontrado"));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _itens.length,
      itemBuilder: (_, i) {
        final e = _itens[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              // Ícone padrão
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.orange.withOpacity(0.1),
                child: const Icon(
                  Icons.inventory_2,
                  color: Colors.orange,
                  size: 18,
                ),
              ),

              const SizedBox(width: 12),

              // CONTEÚDO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO
                    Text(
                      e.descricao,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // META
                    Row(
                      children: [
                        _statusMeta(e.ativo),
                        const SizedBox(width: 12),
                        _metaText('ID ${e.id}'),
                      ],
                    ),
                  ],
                ),
              ),

              // MENU
              PopupMenuButton<String>(
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
        );
      },
    );
  }
  // ================= ACTIONS =================

  void _novo() {
    _descricaoController.clear();
    _ativo = true;
    _editando = null;

    setState(() => _showForm = true);
  }

  void _menu(String action, EstadoConservacao e) {
    if (action == 'editar') {
      setState(() {
        _editando = e;
        _descricaoController.text = e.descricao;
        _ativo = e.ativo;
        _showForm = true;
      });
    } else {
      EstadoConservacaoService.atualizar(
        e.id!,
        {'ativo': !e.ativo},
      ).then((_) => _load());
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'descricao': _descricaoController.text.trim(),
      'ativo': _ativo,
    };

    if (_editando == null) {
      await EstadoConservacaoService.criar(dados);
    } else {
      await EstadoConservacaoService.atualizar(_editando!.id!, dados);
    }

    AppUtils.showSuccessSnackBar(context, "Registro salvo com sucesso");

    _cancelar();

    _load();
  }

  void _cancelar() {
    setState(() => _showForm = false);
  }

  void _buscar() {
    _currentSearch = _searchController.text;

    _currentPage = 1;

    _load();
  }

  void _go(int page) {
    _currentPage = page;

    _load();
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
