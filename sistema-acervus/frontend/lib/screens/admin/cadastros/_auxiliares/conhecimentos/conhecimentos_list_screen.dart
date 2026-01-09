// lib/screens/admin/status_curso_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_app_bar.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/models/_pessoas/formacao/conhecimento.dart'
    as conhecimento;
import 'package:sistema_estagio/services/_pessoas/formacao/conhecimento_service.dart'
    as conhecimentoService;
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ConhecimentosScreen extends StatefulWidget {
  const ConhecimentosScreen({super.key});

  @override
  State<ConhecimentosScreen> createState() => _ConhecimentosScreenState();
}

class _ConhecimentosScreenState extends State<ConhecimentosScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<conhecimento.Conhecimento> _conhecimentos = [];
  Map<String, dynamic> _estatisticas = {};
  bool _isLoading = false;

  // Filtros
  bool? _filtroAtivo;
  bool? _filtroDefault;

  // Paginação
  late TabController _tabController;
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';
  bool _isLoadingPage = false;

  // Opções de página
  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  // Formulário
  bool _showForm = false;
  conhecimento.Conhecimento? _statusEditando;
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _ordemController = TextEditingController();
  String? _corSelecionada;
  bool _ativo = true;
  bool _isDefault = false;

  // Cores disponíveis
  final List<String> _coresDisponiveis = [
    '#4CAF50', // Verde
    '#FF9800', // Laranja
    '#F44336', // Vermelho
    '#2196F3', // Azul
    '#9C27B0', // Roxo
    '#FF5722', // Laranja escuro
    '#795548', // Marrom
    '#607D8B', // Azul acinzentado
    '#9E9E9E', // Cinza
    '#E91E63', // Rosa
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConhecimentos();
    //_loadEstatisticas();
  }

  Future<void> _loadConhecimentos({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingPage = true);
    }

    try {
      final result =
          await conhecimentoService.ConhecimentoService.listarConhecimentos(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
        isDefault: _filtroDefault,
      );

      if (mounted) {
        setState(() {
          _conhecimentos = result['conhecimentos'];
          _pagination = result['pagination'];

          if (_pagination == null || _pagination!.isEmpty) {
            final totalItems = _conhecimentos.length;
            final totalPages = (totalItems / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt();

            _pagination = {
              'currentPage': _currentPage,
              'totalPages': totalPages,
              'total': totalItems,
              'hasNextPage': _currentPage < totalPages,
              'hasPrevPage': _currentPage > 1,
            };
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar Items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingPage = false;
        });
      }
    }
  }

  Future<void> _loadEstatisticas() async {
    try {
      final stats = await conhecimentoService.ConhecimentoService
          .getCachedEstatisticasGerais();
      setState(() {
        _estatisticas = stats;
      });
    } catch (e) {
      // Ignorar erro de estatísticas
    }
  }

  void _performSearch() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _currentSearch = _searchController.text.trim();
    });

    try {
      if (_currentSearch.isEmpty) {
        await _loadConhecimentos();
        return;
      }

      final result =
          await conhecimentoService.ConhecimentoService.buscarConhecimento(
              _currentSearch);

      if (mounted) {
        setState(() {
          _conhecimentos = result ?? <conhecimento.Conhecimento>[];
          _pagination = {
            'currentPage': 1,
            'totalPages': 1,
            'total': _conhecimentos.length,
            'hasNextPage': false,
            'hasPrevPage': false,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar Items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentSearch = '';
      _currentPage = 1;
    });
    _loadConhecimentos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cursos e Conhecimentos'),
        actions: [
          IconButton(
            onPressed: _showFiltrosDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros',
          ),
          IconButton(
            onPressed: _exportarDados,
            icon: const Icon(Icons.download),
            tooltip: 'Exportar',
          ),
          IconButton(
            onPressed: _showNovoStatusForm,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Conhecimento',
          ),
        ],
        // bottom: TabBar(
        //   controller: _tabController,
        //   tabs: const [
        //     Tab(text: 'Lista', icon: Icon(Icons.list)),
        //     Tab(text: 'Estatísticas', icon: Icon(Icons.analytics)),
        //   ],
        // ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildListaTab(),
            _buildEstatisticasTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildListaTab() {
    return Column(
      children: [
        _buildHeader(),
        if (_showForm) _buildFormulario(),
        Expanded(child: buscarConhecimentosList()),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildEstatisticasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEstatisticasGerais(),
          const SizedBox(height: 16),
          _buildGraficos(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Estatísticas rápidas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Status',
                  (_pagination?['total'] ?? _conhecimentos.length).toString(),
                  Icons.description,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Ativos',
                  (_conhecimentos.where((s) => s.ativo).length).toString(),
                  Icons.check_circle,
                  const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Padrão',
                  (_conhecimentos.where((s) => s.isDefault).length).toString(),
                  Icons.star,
                  const Color(0xFFED6C02),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de busca
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Buscar por nome ou descrição',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          // Configurações de paginação
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Itens por página: ', style: TextStyle(fontSize: 14)),
              DropdownButton<int>(
                value: _pageSize,
                items: _pageSizeOptions.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(size.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _pageSize = value;
                      _currentPage = 1;
                    });
                    _loadConhecimentos();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadConhecimentos();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // Filtros ativos
          if (_temFiltrosAtivos()) ...[
            const SizedBox(height: 8),
            _buildFiltrosAtivos(),
          ],
        ],
      ),
    );
  }

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _statusEditando == null ? 'Novo Item' : 'Editar Item',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                IconButton(
                  onPressed: _cancelarForm,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nomeController,
              label: 'Nome do Item *',
              maxLines: 1,
              validator: (value) =>
                  Validators.validateRequired(value, 'Nome do Item'),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Ativo'),
              value: _ativo,
              onChanged: (value) => setState(() => _ativo = value ?? true),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _cancelarForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _salvarStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_statusEditando == null ? 'Criar' : 'Atualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buscarConhecimentosList() {
    if (_isLoadingPage) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando página...'),
          ],
        ),
      );
    }

    if (_conhecimentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _currentSearch.isNotEmpty
                  ? 'Nenhum Item encontrado para a busca "$_currentSearch"'
                  : 'Nenhum Item cadastrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_currentSearch.isNotEmpty)
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Limpar Busca'),
              )
            else
              ElevatedButton(
                onPressed: _showNovoStatusForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar Primeiro Ítem'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conhecimentos.length,
      itemBuilder: (context, index) {
        final conhecimentoConhecimento = _conhecimentos[index];
        return _buildConhecimentoCard(conhecimentoConhecimento, index);
      },
    );
  }

  Widget _buildConhecimentoCard(
      conhecimento.Conhecimento conhecimentoConhecimento, int index) {
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
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: Center(
                    child: Text(
                      conhecimentoConhecimento.ordem?.toString() ??
                          '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            conhecimentoConhecimento.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (conhecimentoConhecimento.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: const Text(
                                'PADRÃO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (conhecimentoConhecimento.descricao.isNotEmpty)
                        Text(
                          conhecimentoConhecimento.descricao,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handleMenuAction(value, conhecimentoConhecimento),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: conhecimentoConhecimento.ativo
                          ? 'desativar'
                          : 'ativar',
                      child: Row(
                        children: [
                          Icon(
                            conhecimentoConhecimento.ativo
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                            color: conhecimentoConhecimento.ativo
                                ? Colors.orange
                                : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            conhecimentoConhecimento.ativo
                                ? 'Desativar'
                                : 'Ativar',
                            style: TextStyle(
                              color: conhecimentoConhecimento.ativo
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // if (!conhecimentoConhecimento.isDefault)
                    //   const PopupMenuItem(
                    //     value: 'excluir',
                    //     child: Row(
                    //       children: [
                    //         Icon(Icons.delete, size: 18, color: Colors.red),
                    //         SizedBox(width: 8),
                    //         Text('Excluir', style: TextStyle(color: Colors.red)),
                    //       ],
                    //     ),
                    //   ),
                  ],
                ),
              ],
            ),
            // const SizedBox(height: 12),

            // // Informações principais
            // Row(
            //   children: [
            //     Expanded(
            //       child: _buildInfoChip(
            //         'Criado em',
            //         conhecimentoConhecimento.createdAt != null
            //             ? AppUtils.formatDate(conhecimentoConhecimento.createdAt!)
            //             : 'N/A',
            //         Icons.calendar_today,
            //       ),
            //     ),
            //     const SizedBox(width: 8),
            //     Expanded(
            //       child: _buildInfoChip(
            //         'Usos',
            //         conhecimentoConhecimento.totalUsos.toString(),
            //         Icons.assignment,
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 12),

            // Status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: conhecimentoConhecimento.ativo
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: conhecimentoConhecimento.ativo
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  child: Text(
                    conhecimentoConhecimento.ativo ? 'ATIVO' : 'INATIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: conhecimentoConhecimento.ativo
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${conhecimentoConhecimento.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    if (_conhecimentos.isEmpty && !_isLoading && !_isLoadingPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['totalPages'] ??
        ((_conhecimentos.isNotEmpty)
            ? ((_conhecimentos.length / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt())
            : 1);
    final currentPage = _pagination?['currentPage'] ?? _currentPage;
    final total = _pagination?['total'] ?? _conhecimentos.length;
    final hasNextPage =
        _pagination?['hasNextPage'] ?? (_currentPage < totalPages);
    final hasPrevPage = _pagination?['hasPrevPage'] ?? (_currentPage > 1);

    final startItem = ((currentPage - 1) * _pageSize) + 1;
    final endItem =
        (currentPage * _pageSize) > total ? total : (currentPage * _pageSize);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando $startItem-$endItem de $total registros',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Página $currentPage de $totalPages',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: currentPage > 1 ? () => _goToPage(1) : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'Primeira página',
                style: IconButton.styleFrom(
                  backgroundColor: currentPage > 1
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              IconButton(
                onPressed:
                    hasPrevPage ? () => _goToPage(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Página anterior',
                style: IconButton.styleFrom(
                  backgroundColor: hasPrevPage
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              const SizedBox(width: 16),
              ..._buildPageNumbers(currentPage, totalPages),
              const SizedBox(width: 16),
              IconButton(
                onPressed:
                    hasNextPage ? () => _goToPage(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Próxima página',
                style: IconButton.styleFrom(
                  backgroundColor: hasNextPage
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              IconButton(
                onPressed: currentPage < totalPages
                    ? () => _goToPage(totalPages)
                    : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Última página',
                style: IconButton.styleFrom(
                  backgroundColor: currentPage < totalPages
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
            ],
          ),
          if (totalPages > 5) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ir para página: '),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page >= 1 && page <= totalPages) {
                        _goToPage(page);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int currentPage, int totalPages) {
    List<Widget> pages = [];

    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (currentPage + 2).clamp(1, totalPages);

    if (end - start < 4) {
      if (start == 1) {
        end = (start + 4).clamp(1, totalPages);
      } else if (end == totalPages) {
        start = (end - 4).clamp(1, totalPages);
      }
    }

    for (int i = start; i <= end; i++) {
      pages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ElevatedButton(
            onPressed: i == currentPage ? null : () => _goToPage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  i == currentPage ? const Color(0xFF2E7D32) : Colors.white,
              foregroundColor:
                  i == currentPage ? Colors.white : const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              i.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return pages;
  }

  void _goToPage(int page) {
    if (page != _currentPage && page >= 1) {
      setState(() => _currentPage = page);
      _loadConhecimentos(showLoading: false);
    }
  }

  Widget _buildEstatisticasGerais() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas Gerais',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total de Status',
              (_estatisticas['total'] ?? 0).toString(),
              Icons.flag,
              const Color(0xFF2E7D32),
            ),
            _buildStatCard(
              'Status Ativos',
              (_estatisticas['ativos'] ?? 0).toString(),
              Icons.check_circle,
              const Color(0xFF1976D2),
            ),
            _buildStatCard(
              'Status Padrão',
              (_estatisticas['padrao'] ?? 0).toString(),
              Icons.star,
              const Color(0xFFED6C02),
            ),
            _buildStatCard(
              'Criados Este Mês',
              (_estatisticas['criadosEsteMes'] ?? 0).toString(),
              Icons.trending_up,
              const Color(0xFF9C27B0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGraficos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribuição por Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Gráfico de distribuição de status\n(Implementar com charts)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(
      String action, conhecimento.Conhecimento conhecimentoConhecimento) {
    switch (action) {
      case 'editar':
        _editarConhecimento(conhecimentoConhecimento);
        break;
      case 'ativar':
        _ativarConhecimento(conhecimentoConhecimento);
        break;
      case 'desativar':
        _desativarConhecimento(conhecimentoConhecimento);
        break;
      case 'excluir':
        _confirmarExclusao(conhecimentoConhecimento);
        break;
    }
  }

  void _editarConhecimento(conhecimento.Conhecimento conhecimentoConhecimento) {
    setState(() {
      _statusEditando = conhecimentoConhecimento;
      _nomeController.text = conhecimentoConhecimento.nome;
      //_descricaoController.text = conhecimentoConhecimento.descricao;
      _ordemController.text = conhecimentoConhecimento.ordem?.toString() ?? '';
      _corSelecionada = conhecimentoConhecimento.cor;
      _ativo = conhecimentoConhecimento.ativo;
      _isDefault = conhecimentoConhecimento.isDefault;
      _showForm = true;
    });
  }

  Future<void> _ativarConhecimento(
      conhecimento.Conhecimento conhecimentoConhecimento) async {
    try {
      final success =
          await conhecimentoService.ConhecimentoService.ativarConhecimento(
              conhecimentoConhecimento.id!);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Item ativado com sucesso!');
        _loadConhecimentos(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _desativarConhecimento(
      conhecimento.Conhecimento conhecimentoConhecimento) async {
    try {
      final success =
          await conhecimentoService.ConhecimentoService.desativarConhecimento(
              conhecimentoConhecimento.id!);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Item desativado com sucesso!');
        _loadConhecimentos(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _confirmarExclusao(
      conhecimento.Conhecimento conhecimentoConhecimento) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Excluir Item',
      content:
          'Tem certeza que deseja excluir "${conhecimentoConhecimento.nome}"?\n\nEsta ação não pode ser desfeita e pode afetar cursos que utilizam este status.',
      confirmText: 'Excluir',
    );

    if (confirm) {
      try {
        final success =
            await conhecimentoService.ConhecimentoService.deletarConhecimento(
                conhecimentoConhecimento.id!);
        if (success) {
          AppUtils.showSuccessSnackBar(context, 'Item excluído com sucesso!');
          _loadConhecimentos();
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  void _showNovoStatusForm() {
    _limparFormulario();
    setState(() => _showForm = true);
  }

  void _cancelarForm() {
    _limparFormulario();
    setState(() => _showForm = false);
  }

  void _limparFormulario() {
    _nomeController.clear();
    _descricaoController.clear();
    _ordemController.clear();
    _corSelecionada = null;
    _ativo = true;
    _isDefault = false;
    _statusEditando = null;
  }

  Future<void> _salvarStatus() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'descricao': _nomeController.text.trim(),
      //'descricao': _descricaoController.text.trim(),
      //'cor': _corSelecionada,
      //'ordem': _ordemController.text.isNotEmpty ? int.parse(_ordemController.text) : null,
      //'is_default': _isDefault,
      'ativo': _ativo,
    };

    try {
      setState(() => _isLoading = true);

      bool success;
      if (_statusEditando == null) {
        success =
            await conhecimentoService.ConhecimentoService.criarConhecimento(
                dados);
      } else {
        success =
            await conhecimentoService.ConhecimentoService.atualizarConhecimento(
                _statusEditando!.id!, dados);
      }

      if (success) {
        AppUtils.showSuccessSnackBar(
          context,
          _statusEditando == null
              ? 'Item criado com sucesso!'
              : 'Item atualizado com sucesso!',
        );
        _cancelarForm();
        _loadConhecimentos();
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFiltrosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<bool>(
                value: _filtroAtivo,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: true, child: Text('Ativos')),
                  DropdownMenuItem(value: false, child: Text('Inativos')),
                ],
                onChanged: (value) => setState(() => _filtroAtivo = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<bool>(
                value: _filtroDefault,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: true, child: Text('Status Padrão')),
                  DropdownMenuItem(value: false, child: Text('Personalizados')),
                ],
                onChanged: (value) => setState(() => _filtroDefault = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtroAtivo = null;
                _filtroDefault = null;
                _currentPage = 1;
              });
              Navigator.of(context).pop();
              _loadConhecimentos();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _currentPage = 1);
              _loadConhecimentos();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  bool _temFiltrosAtivos() {
    return _filtroAtivo != null ||
        _filtroDefault != null ||
        _currentSearch.isNotEmpty;
  }

  Widget _buildFiltrosAtivos() {
    final filtros = <Widget>[];

    if (_currentSearch.isNotEmpty) {
      filtros.add(_buildFiltroChip('Busca: "$_currentSearch"', _clearSearch));
    }

    if (_filtroAtivo != null) {
      filtros.add(_buildFiltroChip(
          'Status: ${_filtroAtivo! ? "Ativos" : "Inativos"}', () {
        setState(() => _filtroAtivo = null);
        _loadConhecimentos();
      }));
    }

    if (_filtroDefault != null) {
      filtros.add(_buildFiltroChip(
          'Tipo: ${_filtroDefault! ? "Padrão" : "Personalizados"}', () {
        setState(() => _filtroDefault = null);
        _loadConhecimentos();
      }));
    }

    return Wrap(spacing: 8, children: filtros);
  }

  Widget _buildFiltroChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
    );
  }

  Future<void> _exportarDados() async {
    try {
      await conhecimentoService.ConhecimentoService.exportarConhecimentosCSV(
        ativo: _filtroAtivo,
        isDefault: _filtroDefault,
      );
      AppUtils.showSuccessSnackBar(context, 'Dados exportados com sucesso!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao exportar: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _nomeController.dispose();
    _descricaoController.dispose();
    _ordemController.dispose();
    super.dispose();
  }
}
