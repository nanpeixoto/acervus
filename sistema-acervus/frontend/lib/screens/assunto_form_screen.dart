import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/assunto.dart';
import 'package:sistema_estagio/services/assunto_service.dart';
import 'package:sistema_estagio/theme/acervus_colors.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:sistema_estagio/widgets/crud_pagination.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

class AssuntosScreen extends StatefulWidget {
  const AssuntosScreen({super.key});

  @override
  State<AssuntosScreen> createState() => _AssuntosScreenState();
}

class _AssuntosScreenState extends State<AssuntosScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<Assunto> _assuntos = [];
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
  Assunto? _editando;
  final _formKey = GlobalKey<FormState>();

  final _siglaController = TextEditingController();
  final _descricaoController = TextEditingController();
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadAssuntos();
  }

  Future<void> _loadAssuntos({bool showLoading = true}) async {
    if (!mounted) return;

    setState(() {
      showLoading ? _isLoading = true : _isLoadingPage = true;
    });

    try {
      final result = await AssuntoService.listarAssuntos(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
      );

      setState(() {
        _assuntos = result['Assuntos'];
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar assuntos: $e');
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
              'Assuntos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AcervusColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _showFiltrosDialog,
            tooltip: 'Filtros',
            icon: const Icon(Icons.filter_list,
                color: AcervusColors.textSecondary),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _novo,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo assunto'),
          ),
        ],
      ),
    );
  }

  // ================= HEADER CLONE =================
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
                  'Total de Assuntos',
                  (_pagination?['totalItems'] ?? _assuntos.length).toString(),
                  Icons.label_outline,
                  AcervusColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Total de Páginas',
                  (_pagination?['totalPages'] ?? 0).toString(),
                  Icons.check_circle_outline,
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
                  label: 'Buscar por sigla ou descrição',
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
                  _loadAssuntos();
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadAssuntos();
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

  // ================= FORM CLONE =================
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editando == null ? 'Novo Assunto' : 'Editar Assunto',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AcervusColors.textPrimary,
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
              controller: _siglaController,
              label: 'Sigla *',
              validator: (v) => Validators.validateRequired(v, 'Sigla'),
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
                OutlinedButton(
                  onPressed: _cancelar,
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

  // ================= LIST CLONE =================
  Widget _buildList() {
    if (_assuntos.isEmpty) {
      return const Center(child: Text('Nenhum assunto cadastrado'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _assuntos.length,
      itemBuilder: (_, i) {
        final a = _assuntos[i];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AcervusColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AcervusColors.border),
          ),
          child: Row(
            children: [
              // SIGLA (tipo badge leve)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AcervusColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  a.sigla,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AcervusColors.primary,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // CONTEÚDO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.descricao,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _statusDot(a.ativo),
                        const SizedBox(width: 6),
                        Text(
                          a.ativo ? 'Ativo' : 'Inativo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ID ${a.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // MENU
              PopupMenuButton<String>(
                onSelected: (v) => _menu(v, a),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(a.ativo ? 'Desativar' : 'Ativar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusDot(bool ativo) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: ativo ? AcervusColors.success : AcervusColors.textMuted,
        shape: BoxShape.circle,
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
    return CrudPagination(
      currentPage: _currentPage,
      totalPages: _pagination!['totalPages'] ?? 1,
      onPageChange: _go,
    );
  }

  // ================= ACTIONS =================
  void _novo() {
    _limpar();
    setState(() => _showForm = true);
  }

  void _menu(String a, Assunto s) {
    if (a == 'editar') {
      setState(() {
        _editando = s;
        _siglaController.text = s.sigla;
        _descricaoController.text = s.descricao;
        _ativo = s.ativo;
        _showForm = true;
      });
    } else {
      AssuntoService.atualizarAssunto(s.id!, {'ativo': !s.ativo})
          .then((_) => _loadAssuntos(showLoading: false));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'sigla': _siglaController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'ativo': _ativo,
    };

    if (_editando == null) {
      await AssuntoService.criarAssunto(dados);
    } else {
      await AssuntoService.atualizarAssunto(_editando!.id!, dados);
    }

    AppUtils.showSuccessSnackBar(context, 'Assunto salvo com sucesso!');
    _cancelar();
    _loadAssuntos();
  }

  void _cancelar() {
    _limpar();
    setState(() => _showForm = false);
  }

  void _limpar() {
    _editando = null;
    _siglaController.clear();
    _descricaoController.clear();
    _ativo = true;
  }

  void _search() {
    _currentSearch = _searchController.text.trim();
    _currentPage = 1;
    _loadAssuntos();
  }

  void _clearSearch() {
    _searchController.clear();
    _currentSearch = '';
    _loadAssuntos();
  }

  void _go(int p) {
    _currentPage = p;
    _loadAssuntos(showLoading: false);
  }

  void _showFiltrosDialog() {}

  @override
  void dispose() {
    _searchController.dispose();
    _siglaController.dispose();
    _descricaoController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
