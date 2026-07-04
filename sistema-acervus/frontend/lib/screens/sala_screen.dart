import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/sala_obra.dart';
import 'package:sistema_estagio/services/sala_service.dar.dart';

import 'package:sistema_estagio/theme/acervus_colors.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:sistema_estagio/widgets/crud_pagination.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

class SalaScreen extends StatefulWidget {
  const SalaScreen({super.key});

  @override
  State<SalaScreen> createState() => _SalaScreenState();
}

class _SalaScreenState extends State<SalaScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<Sala> _salas = [];

  bool _isLoading = false;
  bool _isLoadingPage = false;

  late TabController _tabController;

  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final List<int> _pageSizeOptions = [5, 10, 20, 50];

  bool _showForm = false;
  Sala? _editando;

  final _formKey = GlobalKey<FormState>();

  final _codigoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _observacaoController = TextEditingController();

  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadSalas();
  }

  Future<void> _loadSalas({bool showLoading = true}) async {
    if (!mounted) return;

    setState(() {
      showLoading ? _isLoading = true : _isLoadingPage = true;
    });

    try {
      final result = await SalaService.listar(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      setState(() {
        _salas = result['Salas'];
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar salas');
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
      backgroundColor: AcervusColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [_buildListaTab()],
        ),
      ),
    );
  }

  Widget _buildListaTab() {
    return Column(
      children: [
        _buildPageHeader(),
        _buildHeader(),
        if (_showForm) _buildFormulario(),
        Expanded(child: _buildList()),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Salas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AcervusColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _novo,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nova sala'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcervusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcervusColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total de Salas',
                  (_pagination?['totalItems'] ?? _salas.length).toString(),
                  Icons.meeting_room_outlined,
                  AcervusColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Total de Páginas',
                  (_pagination?['totalPages'] ?? 0).toString(),
                  Icons.layers_outlined,
                  AcervusColors.success,
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

  Widget _buildFormulario() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AcervusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcervusColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _editando == null ? 'Cadastro de Sala' : 'Editar Sala',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          CustomTextField(
            controller: _observacaoController,
            label: 'Observação',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text("Ativo"),
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v ?? true),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _cancelar,
                child: const Text("Cancelar"),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _salvar,
                child: Text(_editando == null ? "Salvar" : "Atualizar"),
              )
            ],
          )
        ]),
      ),
    );
  }

  Widget _buildList() {
    if (_salas.isEmpty) {
      return const Center(child: Text("Nenhuma sala cadastrada"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _salas.length,
      itemBuilder: (_, i) {
        final s = _salas[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AcervusColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AcervusColors.border),
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
                          s.descricao,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: s.ativo
                                    ? AcervusColors.success.withOpacity(0.12)
                                    : AcervusColors.textMuted
                                        .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                s.ativo ? "ATIVO" : "INATIVO",
                                style: TextStyle(
                                  color: s.ativo
                                      ? AcervusColors.success
                                      : AcervusColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "ID: ${s.id}",
                              style: const TextStyle(
                                color: AcervusColors.textSecondary,
                                fontSize: 12,
                              ),
                            )
                          ],
                        )
                      ]),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    if (v == "editar") _editar(s);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: "editar",
                      child: Text("Editar"),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
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
        Text(
          v,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c),
        ),
      ]),
    );
  }

  Widget _buildPaginationControls() {
    if (_pagination == null) return const SizedBox.shrink();
    return CrudPagination(
      currentPage: _currentPage,
      totalPages: _pagination!['totalPages'] ?? 1,
      onPageChange: (p) {
        _currentPage = p;
        _loadSalas(showLoading: false);
      },
    );
  }

  void _novo() {
    _limpar();
    setState(() => _showForm = true);
  }

  void _editar(Sala s) {
    setState(() {
      _editando = s;
      _descricaoController.text = s.descricao;
      _observacaoController.text = s.observacao ?? '';
      _ativo = s.ativo;
      _showForm = true;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'descricao': _descricaoController.text.trim(),
      'observacao': _observacaoController.text.trim(),
      'ativo': _ativo,
    };

    if (_editando == null) {
      await SalaService.criar(dados);
    } else {
      await SalaService.atualizar(_editando!.id!, dados);
    }

    AppUtils.showSuccessSnackBar(context, 'Sala salva com sucesso');
    _cancelar();
    _loadSalas();
  }

  void _cancelar() {
    _limpar();
    setState(() => _showForm = false);
  }

  void _limpar() {
    _editando = null;
    _codigoController.clear();
    _descricaoController.clear();
    _observacaoController.clear();
    _ativo = true;
  }

  void _search() {
    _currentSearch = _searchController.text.trim();
    _currentPage = 1;
    _loadSalas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _codigoController.dispose();
    _descricaoController.dispose();
    _observacaoController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
