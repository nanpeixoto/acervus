import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/material.dart';
import 'package:sistema_estagio/services/material_service.dart';
import 'package:sistema_estagio/theme/acervus_colors.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/crud_pagination.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';

class MateriaisScreen extends StatefulWidget {
  const MateriaisScreen({super.key});

  @override
  State<MateriaisScreen> createState() => _MateriaisScreenState();
}

class _MateriaisScreenState extends State<MateriaisScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<Materiais> _materiais = [];
  bool _isLoading = false;
  bool _isLoadingPage = false;

  bool? _filtroAtivo;

  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  bool _showForm = false;
  Materiais? _editando;
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (!mounted) return;

    setState(() {
      showLoading ? _isLoading = true : _isLoadingPage = true;
    });

    try {
      final result = await MateriaisService.listarMateriais(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
      );

      setState(() {
        _materiais = result['materiais'];
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar materiais: $e');
    } finally {
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
      backgroundColor: AcervusColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            _buildPageHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(),
                    if (_showForm) _buildFormulario(),
                    _buildLista(),
                  ],
                ),
              ),
            ),
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Materiais',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AcervusColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: _exportar,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Exportar'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _novo,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Novo material'),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================

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
                child: _buildStatCard(
                  'Total de Materiais',
                  (_pagination?['totalItems'] ?? _materiais.length).toString(),
                  Icons.inventory_2_outlined,
                  AcervusColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Ativos',
                  _materiais.where((m) => m.ativo).length.toString(),
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
                  label: 'Buscar por descrição',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _limparBusca,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _buscar,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text('Itens por página:'),
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
                  _load();
                },
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _load();
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
                  _editando == null ? 'Novo Material' : 'Editar Material',
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

  // ================= LISTA =================

  Widget _buildLista() {
    if (_isLoadingPage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_materiais.isEmpty) {
      return const Center(child: Text('Nenhum material cadastrado'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _materiais.length,
      itemBuilder: (_, i) => _buildMaterialCard(_materiais[i]),
    );
  }

  Widget _buildMaterialCard(Materiais material) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    material.descricao,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) => _menu(v, material),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(material.ativo ? 'Desativar' : 'Ativar'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: material.ativo
                        ? AcervusColors.success.withOpacity(0.1)
                        : AcervusColors.textMuted.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    material.ativo ? 'ATIVO' : 'INATIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: material.ativo
                          ? AcervusColors.success
                          : AcervusColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${material.id}',
                  style: const TextStyle(
                      fontSize: 12, color: AcervusColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= PAGINAÇÃO =================

  Widget _buildPaginationControls() {
    if (_pagination == null) return const SizedBox.shrink();

    return CrudPagination(
      currentPage: _pagination!['currentPage'] ?? 1,
      totalPages: _pagination!['totalPages'] ?? 1,
      onPageChange: _go,
    );
  }

  // ================= ACTIONS =================

  void _novo() {
    _descricaoController.clear();
    _ativo = true;
    _editando = null;
    setState(() => _showForm = true);
  }

  void _menu(String a, Materiais m) {
    if (a == 'editar') {
      setState(() {
        _editando = m;
        _descricaoController.text = m.descricao;
        _ativo = m.ativo;
        _showForm = true;
      });
    } else {
      MateriaisService.atualizar(m.id!, {'ativo': !m.ativo})
          .then((_) => _load(showLoading: false));
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'descricao': _descricaoController.text.trim(),
      'ativo': _ativo,
    };

    if (_editando == null) {
      await MateriaisService.criar(dados);
    } else {
      await MateriaisService.atualizar(_editando!.id!, dados);
    }

    AppUtils.showSuccessSnackBar(context, 'Registro salvo com sucesso!');
    _cancelar();
    _load();
  }

  void _cancelar() {
    setState(() => _showForm = false);
  }

  void _buscar() {
    _currentSearch = _searchController.text.trim();
    _currentPage = 1;
    _load();
  }

  void _limparBusca() {
    _searchController.clear();
    _currentSearch = '';
    _load();
  }

  void _go(int p) {
    _currentPage = p;
    _load(showLoading: false);
  }

  void _exportar() {
    MateriaisService.exportarCSV();
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 12, color: color)),
        ]),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }
}
