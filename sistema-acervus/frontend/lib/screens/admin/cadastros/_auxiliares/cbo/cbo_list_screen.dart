import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sistema_estagio/models/_auxiliares/classificacao/cbo.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sistema_estagio/widgets/custom_app_bar.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/models/_auxiliares/classificacao/cbo.dart';
import 'package:sistema_estagio/services/_auxiliares/classificacao/cbo_service.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';

class CBOScreen extends StatefulWidget {
  const CBOScreen({super.key});

  @override
  State<CBOScreen> createState() => _CBOScreenState();
}

class _CBOScreenState extends State<CBOScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<CBO> _cbos = [];
  Map<String, dynamic> _estatisticas = {};
  bool _isLoading = false;

  // Filtros
  bool? _filtroAtivo;
  bool? _filtroDefault;
  final bool _isDefault = false;

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
  CBO? _cboEditando;
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _descricaoController = TextEditingController();
  bool _ativo = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCBOs();
    //_loadEstatisticas();
  }

  Future<void> _loadCBOs({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingPage = true);
    }

    try {
      final result = await CBOService.listarCBOs(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
      );

      if (mounted) {
        setState(() {
          _cbos = result['cbos'];
          _pagination = result['pagination'];

          if (_pagination == null || _pagination!.isEmpty) {
            final totalItems = _cbos.length;
            final totalPages = (totalItems / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt();

            _pagination = {
              'currentPage': _currentPage,
              'totalPages': totalPages,
              'totalItems': totalItems,
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
            content: Text('Erro ao carregar CBOs: $e'),
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
      final stats = await CBOService.getCachedEstatisticasGerais();
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
        await _loadCBOs();
        return;
      }

      final result = await CBOService.buscarCBO(_currentSearch);

      if (mounted) {
        setState(() {
          _cbos = result ?? <CBO>[];
          _pagination = {
            'currentPage': 1,
            'totalPages': 1,
            'total': _cbos.length,
            'hasNextPage': false,
            'hasPrevPage': false,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar CBOs: $e'),
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
    _loadCBOs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CBOs - Classificação Brasileira de Ocupações'),
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
            onPressed: _showNovoCBOForm,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar CBO',
          ),
        ],
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
        Expanded(child: _buildCBOsList()),
        _buildPaginationControls(),
      ],
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
                  _cboEditando == null ? 'Novo CBO' : 'Editar CBO',
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
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: CustomTextField(
                    controller: _codigoController,
                    label: 'Código CBO *',
                    maxLines: 1,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Código é obrigatório';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    controller: _descricaoController,
                    label: 'Descrição *',
                    maxLines: 1,
                    validator: (value) =>
                        Validators.validateRequired(value, 'Descrição'),
                  ),
                ),
              ],
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
                  onPressed: _salvarCBO,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_cboEditando == null ? 'Criar' : 'Atualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCBOsList() {
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

    if (_cbos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _currentSearch.isNotEmpty
                  ? 'Nenhum CBO encontrado para a busca "$_currentSearch"'
                  : 'Nenhum CBO cadastrado',
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
                onPressed: _showNovoCBOForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar Primeiro CBO'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cbos.length,
      itemBuilder: (context, index) {
        final cbo = _cbos[index];
        return _buildCBOCard(cbo, index);
      },
    );
  }

  Widget _buildPaginationControls() {
    if (_cbos.isEmpty && !_isLoading && !_isLoadingPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['totalPages'] ??
        ((_cbos.isNotEmpty)
            ? ((_cbos.length / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt())
            : 1);
    final currentPage = _pagination?['currentPage'] ?? _currentPage;
    final total = _pagination?['total'] ?? _cbos.length;
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
        ],
      ),
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
                  'Total de CBOs',
                  (_pagination?['total'] ?? _cbos.length).toString(),
                  Icons.work,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Ativos',
                  (_cbos.where((c) => c.ativo).length).toString(),
                  Icons.check_circle,
                  const Color(0xFF1976D2),
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
                  label: 'Buscar por código ou descrição',
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
                    _loadCBOs();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadCBOs();
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

  Widget _buildCBOCard(CBO cbo, int index) {
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
                  width: 50,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: Center(
                    child: Text(
                      cbo.codigo,
                      style: const TextStyle(
                        fontSize: 10,
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
                      Text(
                        cbo.descricao,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${cbo.codigo}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, cbo),
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
                      value: cbo.ativo ? 'desativar' : 'ativar',
                      child: Row(
                        children: [
                          Icon(
                            cbo.ativo ? Icons.visibility_off : Icons.visibility,
                            size: 18,
                            color: cbo.ativo ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cbo.ativo ? 'Desativar' : 'Ativar',
                            style: TextStyle(
                              color: cbo.ativo ? Colors.orange : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'excluir',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Excluir', style: TextStyle(color: Colors.red)),
                        ],
                      ),
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
                    color: cbo.ativo
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cbo.ativo ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Text(
                    cbo.ativo ? 'ATIVO' : 'INATIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cbo.ativo ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                if (cbo.dataCriacao != null)
                  Text(
                    'Criado: ${_formatDate(cbo.dataCriacao!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  'ID: ${cbo.id}',
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

  _showFiltrosDialog() {
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
              _loadCBOs();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _currentPage = 1);
              _loadCBOs();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportarDados() async {
    try {
      await CBOService.exportarCSV(
        ativo: _filtroAtivo,
      );
      AppUtils.showSuccessSnackBar(context, 'Dados exportados com sucesso!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao exportar: $e');
    }
  }

  void _showNovoCBOForm() {
    _limparFormulario();
    setState(() => _showForm = true);
  }

  void _limparFormulario() {
    _codigoController.clear();
    _descricaoController.clear();
    _ativo = true;
    _cboEditando = null;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
      _loadCBOs(showLoading: false);
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
              'Total de CBOs',
              (_estatisticas['total'] ?? 0).toString(),
              Icons.work,
              const Color(0xFF2E7D32),
            ),
            _buildStatCard(
              'CBOs Ativos',
              (_estatisticas['ativos'] ?? 0).toString(),
              Icons.check_circle,
              const Color(0xFF1976D2),
            ),
            _buildStatCard(
              'CBOs Inativos',
              (_estatisticas['inativos'] ?? 0).toString(),
              Icons.cancel,
              const Color(0xFFD32F2F),
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
          'Distribuição de CBOs',
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
              'Gráfico de distribuição de CBOs\n(Implementar com charts)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, CBO cbo) {
    switch (action) {
      case 'editar':
        _editarCBO(cbo);
        break;
      case 'ativar':
        _ativarCBO(cbo);
        break;
      case 'desativar':
        _desativarCBO(cbo);
        break;
      case 'excluir':
        _confirmarExclusao(cbo);
        break;
    }
  }

  void _editarCBO(CBO cbo) {
    setState(() {
      _cboEditando = cbo;
      _codigoController.text = cbo.codigo;
      _descricaoController.text = cbo.descricao;
      _ativo = cbo.ativo;
      _showForm = true;
    });
  }

  Future<void> _ativarCBO(CBO cbo) async {
    try {
      final success = await CBOService.ativarCBO(cbo.id!);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'CBO ativado com sucesso!');
        _loadCBOs(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _desativarCBO(CBO cbo) async {
    try {
      final success = await CBOService.desativarCBO(cbo.id!);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'CBO desativado com sucesso!');
        _loadCBOs(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _confirmarExclusao(CBO cbo) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Excluir CBO',
      content:
          'Tem certeza que deseja excluir o CBO "${cbo.codigo} - ${cbo.descricao}"?\n\nEsta ação não pode ser desfeita.',
      confirmText: 'Excluir',
    );

    if (confirm) {
      try {
        final success = await CBOService.deletarCBO(cbo.id!);
        if (success) {
          AppUtils.showSuccessSnackBar(context, 'CBO excluído com sucesso!');
          _loadCBOs();
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  void _cancelarForm() {
    _limparFormulario();
    setState(() => _showForm = false);
  }

  Future<void> _salvarCBO() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'codigo': _codigoController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'ativo': _ativo,
    };

    try {
      setState(() => _isLoading = true);

      bool success;
      if (_cboEditando == null) {
        success = await CBOService.criarCBO(dados);
      } else {
        success = await CBOService.atualizarCBO(_cboEditando!.id!, dados);
      }

      if (success) {
        AppUtils.showSuccessSnackBar(
          context,
          _cboEditando == null
              ? 'CBO criado com sucesso!'
              : 'CBO atualizado com sucesso!',
        );
        _cancelarForm();
        _loadCBOs();
        _loadEstatisticas();
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _temFiltrosAtivos() {
    return _filtroAtivo != null || _currentSearch.isNotEmpty;
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
        _loadCBOs();
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

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _codigoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }
}
