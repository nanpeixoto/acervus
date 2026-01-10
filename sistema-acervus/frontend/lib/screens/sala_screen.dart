import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/_auxiliares/sala_obra.dart';
import 'package:sistema_estagio/services/_auxiliares/sala_service.dar.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

// ================= SCREEN =================
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
      appBar: AppBar(
        title: const Text('Sala'),
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
                  'Total de Salas',
                  (_pagination?['totalItems'] ?? _salas.length).toString(),
                  Icons.meeting_room,
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
                  _loadSalas();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= FORMULÁRIO =================
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
                _editando == null ? 'Cadastro de Sala' : 'Editar Sala',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelar,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Código + Situação
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: CustomTextField(
                  controller: _codigoController,
                  label: 'Código',
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Situação'),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _ativo,
                          onChanged: (v) => setState(() => _ativo = true),
                        ),
                        const Text('Ativo'),
                        Radio<bool>(
                          value: false,
                          groupValue: _ativo,
                          onChanged: (v) => setState(() => _ativo = false),
                        ),
                        const Text('Inativo'),
                      ],
                    ),
                  ],
                ),
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
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          Row(
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
                child: Text(_editando == null ? 'Salvar' : 'Atualizar'),
              ),
            ],
          ),
        ]),
      ),
    );
  }

  // ================= LIST =================
  Widget _buildList() {
    if (_salas.isEmpty) {
      return const Center(child: Text('Nenhuma sala cadastrada'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _salas.length,
      itemBuilder: (_, i) {
        final s = _salas[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(s.descricao),
            subtitle: Text(s.ativo ? 'Ativo' : 'Inativo'),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editar(s),
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
    return Text(
      'Página $_currentPage de ${_pagination!['totalPages']}',
    );
  }

  // ================= ACTIONS =================
  void _novo() {
    _limpar();
    setState(() => _showForm = true);
  }

  void _editar(Sala s) {
    setState(() {
      _editando = s;
      _codigoController.text = s.id?.toString() ?? '';
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
