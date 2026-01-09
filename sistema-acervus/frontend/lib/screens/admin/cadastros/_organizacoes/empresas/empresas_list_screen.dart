import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_app_bar.dart';
import 'package:sistema_estagio/widgets/admin_drawer.dart';
import 'package:sistema_estagio/services/_organizacoes/empresa/empresa_service.dart';
import 'package:sistema_estagio/models/_organizacoes/empresa/empresa.dart';
import 'dart:html' as html;

class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

class _EmpresasScreenState extends State<EmpresasScreen>
    with TickerProviderStateMixin {
  final _cepMask = MaskTextInputFormatter(
      mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});
  final _cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final _cnpjMask = MaskTextInputFormatter(
      mask: '##.###.###/####-##', filter: {"#": RegExp(r'[0-9]')});
  final _searchController = TextEditingController();

  List<Empresa> _empresas = [];
  Map<String, dynamic> _estatisticas = {};
  bool _isLoading = false;

  // Filtros
  String? _filtroTipo;
  String? _filtroCidade;
  String? _filtroEstado;
  bool? _filtroAtivo;
  String? _filtroNivel;

  // Paginação
  late TabController _tabController;
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';
  bool _isLoadingPage = false;

  // Opções de página
  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEmpresas();
    //_loadEstatisticas();
  }

  Future<void> _loadEmpresas({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingPage = true);
    }

    try {
      final result = await EmpresaService.listarEmpresas(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        tipo: _filtroTipo,
        cidade: _filtroCidade,
        estado: _filtroEstado,
        ativo: _filtroAtivo,
        nivel: _filtroNivel,
      );

      if (mounted) {
        setState(() {
          _empresas = result['empresas'];
          _pagination = result['pagination'];

          if (_pagination == null || _pagination!.isEmpty) {
            final totalItems = _empresas.length;
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
            content: Text('Erro ao carregar empresas: $e'),
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
      final stats = await EmpresaService.getCachedEstatisticasGerais();
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
        await _loadEmpresas();
        return;
      }

      final result = await EmpresaService.buscarEmpresa(_currentSearch);

      if (mounted) {
        setState(() {
          _empresas = result ?? <Empresa>[];
          _pagination = {
            'currentPage': 1,
            'totalPages': 1,
            'total': _empresas.length,
            'hasNextPage': false,
            'hasPrevPage': false,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar empresas: $e'),
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
    _loadEmpresas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Empresas'),
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
            onPressed: () {
              context.go('/admin/empresas/novo');
            },
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Empresa',
          ),
        ],
        //Estatísticas rápidas
        // bottom: TabBar(
        //   indicatorColor: const Color(0xFF82265C),
        //   controller: _tabController,
        //   tabs: const [
        //     Tab(
        //       text: 'Lista',
        //       icon: Icon(Icons.list),
        //     ),
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
        Expanded(child: _buildEmpresasList()),
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
          // Campo de busca
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Buscar por nome ou CNPJ',
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
                    _loadEmpresas();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadEmpresas();
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

  Widget _buildEmpresasList() {
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

    if (_empresas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _currentSearch.isNotEmpty
                  ? 'Nenhuma empresa encontrada para a busca "$_currentSearch"'
                  : 'Nenhuma empresa cadastrada',
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
                onPressed: () => context.go('/admin/empresas/novo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar Primeira Empresa'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _empresas.length,
      itemBuilder: (context, index) {
        final empresa = _empresas[index];
        return _buildEmpresaCard(empresa, index);
      },
    );
  }

  Widget _buildEmpresaCard(Empresa empresa, int index) {
    final idStr = (empresa.id ?? '').toString();
    final cnpj = EmpresaService.formatarCNPJ(empresa.cnpj);
    final telefone = (empresa.telefone?.trim().isNotEmpty == true)
        ? empresa.telefone!
        : (empresa.celular ?? '');
    final endereco = _enderecoCompleto(empresa);

    return SelectionArea(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F7F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E6DE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ID como texto (pill)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2E7D32)),
              ),
              child: Text(
                'ID $idStr',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nome Fantasia
            _infoItemRow(
              icon: Icons.apartment,
              text: empresa.nomeFantasia ?? '',
              flex: 3,
              bold: true,
            ),

            _vDivider(),

            // Razão Social
            _infoItemRow(
              icon: Icons.business,
              text: empresa.razaoSocial ?? '',
              flex: 3,
            ),

            _vDivider(),

            // CNPJ
            _infoItemRow(
              icon: Icons.badge_outlined,
              text: 'CNPJ: $cnpj',
              flex: 2,
            ),

            _vDivider(),

            // Telefone
            _infoItemRow(
              icon: Icons.phone,
              text: telefone,
              flex: 2,
            ),

            _vDivider(),

            // Endereço completo
            _infoItemRow(
              icon: Icons.location_on_outlined,
              text: endereco,
              flex: 4,
            ),

            const SizedBox(width: 8),

            // Ações
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, empresa),
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
                const PopupMenuItem(
                  value: 'imprimir',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 18),
                      SizedBox(width: 8),
                      Text('Imprimir'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'listar_vagas',
                  child: Row(
                    children: [
                      Icon(Icons.list, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Vagas', style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'cadastrar_vaga',
                  child: Row(
                    children: [
                      Icon(Icons.add_box, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Cadastrar Vaga',
                          style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: empresa.ativo ? 'bloquear' : 'ativar',
                  child: Row(
                    children: [
                      Icon(
                        empresa.ativo ? Icons.block : Icons.check_circle,
                        size: 18,
                        color: empresa.ativo ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        empresa.ativo ? 'Bloquear' : 'Ativar',
                        style: TextStyle(
                          color: empresa.ativo ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Monta endereço completo em uma string única
  String _enderecoCompleto(Empresa e) {
    final end = e.enderecoCompleto;
    if (end == null) return '';
    return end;
  }

  // Divisor vertical compacto
  Widget _vDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE3E7E1),
    );
  }

  // Item compacto com ícone + texto, truncado em uma linha
  Widget _infoItemRow({
    required IconData icon,
    required String text,
    required int flex,
    bool bold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message: text,
              waitDuration: const Duration(milliseconds: 400),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color: Colors.grey[900],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_empresas.isEmpty && !_isLoading && !_isLoadingPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['totalPages'] ??
        ((_empresas.isNotEmpty)
            ? ((_empresas.length / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt())
            : 1);
    final currentPage = _pagination?['currentPage'] ?? _currentPage;
    final total = _pagination?['total'] ?? _empresas.length;
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
    final totalPages = _pagination?['totalPages'] ??
        ((_empresas.isNotEmpty) ? ((_empresas.length / _pageSize).ceil()) : 1);

    if (page != _currentPage && page >= 1 && page <= totalPages) {
      setState(() => _currentPage = page);
      _loadEmpresas(showLoading: false);
    }
  }

  Widget _buildEstatisticasGerais() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas Gerais',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
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
              'Total de Empresas',
              (_estatisticas['total'] ?? 0).toString(),
              Icons.school,
              const Color(0xFF2E7D32),
            ),
            _buildStatCard(
              'Ativas',
              (_estatisticas['ativas'] ?? 0).toString(),
              Icons.check_circle,
              const Color(0xFF1976D2),
            ),
            _buildStatCard(
              'Convênios Assinados',
              (_estatisticas['convenios'] ?? 0).toString(),
              Icons.handshake,
              const Color(0xFFED6C02),
            ),
            _buildStatCard(
              'Total de Estudantes',
              (_estatisticas['totalEstudantes'] ?? 0).toString(),
              Icons.people,
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
          'Distribuição por Tipo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
              'Gráfico de distribuição por tipo\n(Implementar com charts)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, Empresa empresa) {
    switch (action) {
      case 'detalhes':
        _showDetalhesDialog(empresa);
        break;
      case 'editar':
        _editarEmpresa(empresa);
        break;
      case 'listar_vagas':
        _listarVagas(empresa);
        break;
      case 'cadastrar_vaga':
        _cadastrarVaga(empresa);
        break;
      case 'ativar':
        _ativarEmpresa(empresa);
        break;
      case 'bloquear':
        _bloquearEmpresa(empresa);
        break;
      case 'convenio':
        _gerenciarConvenio(empresa);
        break;
      case 'imprimir':
        _imprimirConvenioEmpresa(empresa);
        break;
      case 'excluir':
        _confirmarExclusao(empresa);
        break;
    }
  }

  Future<void> _imprimirConvenioEmpresa(Empresa empresa) async {
    try {
      setState(() => _isLoading = true);
      print('EmpresaID: ${empresa.id}');
      print('ModeloID: ${empresa.idModelo}');

      // Gerar o PDF do contrato
      final pdfBytes = await EmpresaService.gerarPdfContratoEmpresa(
        id: int.parse(empresa.id!),
        idModelo: empresa.idModelo
            as int, // Defina o ID do modelo conforme necessário
        download: true,
      );

      // Criar nome do arquivo com CODIGO CONTRATO - NOME INSTITUIÇÃO
      final nomeInstituicao = (empresa.nomeFantasia ?? '')
          .toString()
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = '${empresa.id ?? 'empresa'} - $nomeInstituicao.pdf';

      // Fazer o download
      await _downloadPdf(pdfBytes, fileName);

      _showSuccessSnackBar('PDF baixado com sucesso!');
    } catch (e) {
      print('❌ Erro completo: $e');
      _showErrorSnackBar('Erro ao gerar PDF: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPdf(Uint8List pdfBytes, String fileName) async {
    try {
      if (kIsWeb) {
        // Para Flutter Web
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();

        html.Url.revokeObjectUrl(url);

        print('✅ Download iniciado: $fileName');
      } else {
        // Para mobile (Android/iOS) - implementar conforme necessário
        throw UnimplementedError('Download em mobile não implementado ainda');
      }
    } catch (e) {
      print('❌ Erro no download: $e');
      throw Exception('Erro ao fazer download do PDF: $e');
    }
  }

  Future<void> _previewPdf(Uint8List pdfBytes) async {
    try {
      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Abrir em nova aba para preview
        html.window.open(url, '_blank');

        // Limpar URL após um tempo
        Timer(const Duration(minutes: 5), () {
          html.Url.revokeObjectUrl(url);
        });
      } else {
        throw UnimplementedError('Preview em mobile não implementado');
      }
    } catch (e) {
      throw Exception('Erro ao abrir preview do PDF: $e');
    }
  }

  void _listarVagas(Empresa empresa) {
    // Navegar para a tela de listagem de vagas passando o ID da empresa
    context.go('/admin/vagas', extra: {
      'empresaId': empresa.id,
      'nomeEmpresa': empresa.nomeFantasia ?? empresa.razaoSocial
    });
  }

  void _cadastrarVaga(Empresa empresa) {
    // Navegar para a tela de cadastro de vaga passando o ID da empresa
    context.go('/admin/vagas/novo', extra: {'empresaId': empresa.id});
  }

  // MÉTODO MODIFICADO - Navega para tela completa de edição
  void _editarEmpresa(Empresa empresa) {
    // Navegar para a tela de cadastro passando os dados da empresa para edição
    context.go('/admin/empresas/editar/${empresa.id}',
        extra: {'empresa': empresa, 'modo': 'edicao'});
  }

  Future<void> _ativarEmpresa(Empresa empresa) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Ativar Empresa',
      content: 'Tem certeza que deseja ativar "${empresa.nomeFantasia}"?',
      confirmText: 'Ativar',
    );

    if (confirm) {
      try {
        final success = await EmpresaService.ativarEmpresa(empresa.id!);

        if (success) {
          AppUtils.showSuccessSnackBar(context, 'Empresa ativada com sucesso!');
          _loadEmpresas(showLoading: false);
        } else {
          AppUtils.showErrorSnackBar(context, 'Erro ao ativar empresa');
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  Future<void> _bloquearEmpresa(Empresa empresa) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Bloquear Empresa',
      content: 'Tem certeza que deseja bloquear "${empresa.nomeFantasia}"?',
      confirmText: 'Bloquear',
    );

    if (confirm) {
      try {
        final success = await EmpresaService.bloquearEmpresa(empresa.id!);

        if (success) {
          AppUtils.showSuccessSnackBar(
              context, 'Empresa bloqueada com sucesso!');
          _loadEmpresas(showLoading: false);
        } else {
          AppUtils.showErrorSnackBar(context, 'Erro ao bloquear empresa');
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  Future<void> _confirmarExclusao(Empresa empresa) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Excluir Empresa',
      content:
          'Tem certeza que deseja excluir "${empresa.nomeFantasia}"?\n\nEsta ação não pode ser desfeita e removerá todos os dados relacionados.',
      confirmText: 'Excluir',
    );

    if (confirm) {
      _excluirEmpresa(empresa);
    }
  }

  Future<void> _excluirEmpresa(Empresa empresa) async {
    setState(() => _isLoading = true);

    try {
      final success = await EmpresaService.deletarEmpresa(empresa.id!);

      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Empresa excluída com sucesso!');

        if (_empresas.length == 1 && _currentPage > 1) {
          _currentPage--;
        }

        _loadEmpresas();
        _loadEstatisticas();
      } else {
        AppUtils.showErrorSnackBar(context, 'Erro ao excluir empresa');
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDetalhesDialog(Empresa empresa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(empresa.nomeFantasia ?? ''),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetalheItem('Razão Social', empresa.razaoSocial ?? ''),
                _buildDetalheItem('Nome Fantasia', empresa.nomeFantasia ?? ''),
                _buildDetalheItem(
                    'CNPJ', EmpresaService.formatarCNPJ(empresa.cnpj)),
                _buildDetalheItem('E-mail Principal', empresa.email ?? ''),
                _buildDetalheItem('Telefone', empresa.telefone ?? ''),
                _buildDetalheItem('Celular', empresa.celular ?? ''),
                const Divider(),
                _buildDetalheItem(
                  'Endereço',
                  '${empresa.endereco?.logradouro}, ${empresa.endereco?.numero}, '
                      '${empresa.endereco?.bairro}, ${empresa.endereco?.cidade} - '
                      '${empresa.endereco?.estado}, CEP: ${empresa.endereco?.cep}',
                ),
                _buildDetalheItem('CEP', empresa.endereco?.cep ?? ''),
                _buildDetalheItem(
                    'Logradouro', empresa.endereco?.logradouro ?? ''),
                _buildDetalheItem('Número', empresa.endereco?.numero ?? ''),
                _buildDetalheItem('Bairro', empresa.endereco?.bairro ?? ''),
                _buildDetalheItem('Cidade', empresa.endereco?.cidade ?? ''),
                _buildDetalheItem('UF', empresa.endereco?.estado ?? ''),
                const Divider(),
                _buildDetalheItem(
                    'Data de Criação',
                    empresa.createdAt != null
                        ? AppUtils.formatDate(empresa.createdAt!)
                        : ''),
                const Divider(),
                _buildDetalheItem(
                    'Status', empresa.ativo ? 'ATIVA' : 'INATIVA'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _gerenciarConvenio(Empresa empresa) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Convênio - ${empresa.nomeFantasia}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => _gerarConvenio(empresa),
              icon: const Icon(Icons.description),
              label: const Text('Gerar Convênio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _downloadConvenio(empresa),
              icon: const Icon(Icons.download),
              label: const Text('Download Convênio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _gerarConvenio(Empresa empresa) async {
    try {
      final success = await EmpresaService.gerarConvenio(empresa.id!);

      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Convênio gerado com sucesso!');
      } else {
        AppUtils.showErrorSnackBar(context, 'Erro ao gerar convênio');
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _downloadConvenio(Empresa empresa) async {
    try {
      final bytes = await EmpresaService.downloadConvenio(empresa.id!);
      AppUtils.showSuccessSnackBar(context, 'Convênio baixado com sucesso!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao baixar convênio: $e');
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
              DropdownButtonFormField<String>(
                value: _filtroTipo,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(
                      value: 'UNIVERSIDADE', child: Text('Universidade')),
                  DropdownMenuItem(
                      value: 'FACULDADE', child: Text('Faculdade')),
                  DropdownMenuItem(
                      value: 'INSTITUTO', child: Text('Instituto')),
                  DropdownMenuItem(value: 'CENTRO', child: Text('Centro')),
                ],
                onChanged: (value) => setState(() => _filtroTipo = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<bool>(
                value: _filtroAtivo,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: true, child: Text('Ativas')),
                  DropdownMenuItem(value: false, child: Text('Inativas')),
                ],
                onChanged: (value) => setState(() => _filtroAtivo = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _filtroCidade,
                decoration: const InputDecoration(labelText: 'Cidade'),
                onChanged: (value) =>
                    _filtroCidade = value.isEmpty ? null : value,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _filtroEstado,
                decoration: const InputDecoration(labelText: 'Estado (UF)'),
                onChanged: (value) =>
                    _filtroEstado = value.isEmpty ? null : value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtroTipo = null;
                _filtroAtivo = null;
                _filtroCidade = null;
                _filtroEstado = null;
                _filtroNivel = null;
                _currentPage = 1;
              });
              Navigator.of(context).pop();
              _loadEmpresas();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _currentPage = 1);
              _loadEmpresas();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  bool _temFiltrosAtivos() {
    return _filtroTipo != null ||
        _filtroAtivo != null ||
        _filtroCidade != null ||
        _filtroEstado != null ||
        _filtroNivel != null ||
        _currentSearch.isNotEmpty;
  }

  Widget _buildFiltrosAtivos() {
    final filtros = <Widget>[];

    if (_currentSearch.isNotEmpty) {
      filtros.add(_buildFiltroChip('Busca: "$_currentSearch"', () {
        _clearSearch();
      }));
    }

    if (_filtroTipo != null) {
      filtros.add(_buildFiltroChip('Tipo: $_filtroTipo', () {
        setState(() {
          _filtroTipo = null;
          _currentPage = 1;
        });
        _loadEmpresas();
      }));
    }

    if (_filtroAtivo != null) {
      filtros.add(_buildFiltroChip(
          'Status: ${_filtroAtivo! ? "Ativas" : "Inativas"}', () {
        setState(() {
          _filtroAtivo = null;
          _currentPage = 1;
        });
        _loadEmpresas();
      }));
    }

    if (_filtroCidade != null) {
      filtros.add(_buildFiltroChip('Cidade: $_filtroCidade', () {
        setState(() {
          _filtroCidade = null;
          _currentPage = 1;
        });
        _loadEmpresas();
      }));
    }

    if (_filtroEstado != null) {
      filtros.add(_buildFiltroChip('Estado: $_filtroEstado', () {
        setState(() {
          _filtroEstado = null;
          _currentPage = 1;
        });
        _loadEmpresas();
      }));
    }

    return Wrap(
      spacing: 8,
      children: filtros,
    );
  }

  Widget _buildFiltroChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
      deleteIconColor: const Color(0xFF2E7D32),
      labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
    );
  }

  Future<void> _exportarDados() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Dados'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => _exportarPDF(),
              icon: const Icon(Icons.table_chart),
              label: const Text('Exportar CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _exportarPDF(),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Exportar PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  // Future<void> _exportarCSV() async {
  //   try {
  //     final csv = await EmpresaService.exportarEmpresasCSV(
  //       tipo: _filtroTipo,
  //       cidade: _filtroCidade,
  //       estado: _filtroEstado,
  //       ativo: _filtroAtivo,
  //     );

  //     AppUtils.showSuccessSnackBar(context, 'CSV exportado com sucesso!');
  //   } catch (e) {
  //     AppUtils.showErrorSnackBar(context, 'Erro ao exportar CSV: $e');
  //   }
  // }

  Future<void> _exportarPDF() async {
    try {
      final bytes = await EmpresaService.exportarEmpresasPDF(
        tipo: _filtroTipo,
        cidade: _filtroCidade,
        estado: _filtroEstado,
      );

      AppUtils.showSuccessSnackBar(context, 'PDF exportado com sucesso!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao exportar PDF: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
}
