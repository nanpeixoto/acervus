// lib/screens/admin/experiencia_profissional_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_app_bar.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/models/_pessoas/formacao/experiencia_profissional.dart'
    as experiencia;
import 'package:sistema_estagio/services/_pessoas/formacao/experiencia_profissional_service.dart'
    as experienciaService;
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class ExperienciaProfissionalScreen extends StatefulWidget {
  const ExperienciaProfissionalScreen({super.key});

  @override
  State<ExperienciaProfissionalScreen> createState() =>
      _ExperienciaProfissionalScreenState();
}

class _ExperienciaProfissionalScreenState
    extends State<ExperienciaProfissionalScreen> with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  List<experiencia.ExperienciaProfissional> _experiencias = [];
  Map<String, dynamic> _estatisticas = {};
  bool _isLoading = false;

  // Filtros
  String? _filtroEmpresa;
  DateTime? _filtroDataInicio;
  DateTime? _filtroDataFim;

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
  experiencia.ExperienciaProfissional? _experienciaEditando;
  final _formKey = GlobalKey<FormState>();
  final _empresaController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _candidatoIdController = TextEditingController();
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExperienciasProfissionais();
    _loadEstatisticas();
  }

  Future<void> _loadExperienciasProfissionais({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingPage = true);
    }

    try {
      final result = await experienciaService.ExperienciaProfissionalService
          .listarExperienciasProfissionais(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        empresa: _filtroEmpresa,
        dataInicio: _filtroDataInicio,
        dataFim: _filtroDataFim,
      );

      if (mounted) {
        setState(() {
          _experiencias = result['experiencias'];
          _pagination = result['pagination'];

          if (_pagination == null || _pagination!.isEmpty) {
            final totalItems = _experiencias.length;
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
            content: Text('Erro ao carregar experiências: $e'),
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
      final stats = await experienciaService.ExperienciaProfissionalService
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
        await _loadExperienciasProfissionais();
        return;
      }

      final result = await experienciaService.ExperienciaProfissionalService
          .buscarExperienciaProfissional(_currentSearch);

      if (mounted) {
        setState(() {
          _experiencias = result ?? <experiencia.ExperienciaProfissional>[];
          _pagination = {
            'currentPage': 1,
            'totalPages': 1,
            'total': _experiencias.length,
            'hasNextPage': false,
            'hasPrevPage': false,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar experiências: $e'),
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
    _loadExperienciasProfissionais();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiências Profissionais'),
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
            onPressed: _showNovaExperienciaForm,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Experiência Profissional',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Lista', icon: Icon(Icons.list)),
            Tab(text: 'Estatísticas', icon: Icon(Icons.analytics)),
          ],
        ),
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
        Expanded(child: _buildExperienciasList()),
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
                  'Total de Experiências',
                  (_pagination?['total'] ?? _experiencias.length).toString(),
                  Icons.work,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Em Andamento',
                  (_experiencias.where((e) => e.dataFim == null).length)
                      .toString(),
                  Icons.timeline,
                  const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Finalizadas',
                  (_experiencias.where((e) => e.dataFim != null).length)
                      .toString(),
                  Icons.check_circle,
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
                  label: 'Buscar por empresa ou atividades',
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
                    _loadExperienciasProfissionais();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadExperienciasProfissionais();
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
                  _experienciaEditando == null
                      ? 'Nova Experiência'
                      : 'Editar Experiência',
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

            // ID do Candidato
            CustomTextField(
              controller: _candidatoIdController,
              label: 'ID do Candidato *',
              keyboardType: TextInputType.number,
              validator: (value) =>
                  Validators.validateRequired(value, 'ID do Candidato'),
            ),
            const SizedBox(height: 16),

            // Empresa
            CustomTextField(
              controller: _empresaController,
              label: 'Empresa *',
              maxLines: 1,
              validator: (value) =>
                  Validators.validateRequired(value, 'Empresa'),
            ),
            const SizedBox(height: 16),

            // Atividades desenvolvidas
            CustomTextField(
              controller: _descricaoController,
              label: 'Atividades Desenvolvidas *',
              maxLines: 3,
              validator: (value) => Validators.validateRequired(
                  value, 'Atividades Desenvolvidas'),
            ),
            const SizedBox(height: 16),

            // Data de Início
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selecionarDataInicio(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dataInicio != null
                                ? 'Data Início: ${_formatarData(_dataInicio!)}'
                                : 'Selecionar Data de Início *',
                            style: TextStyle(
                              color: _dataInicio != null
                                  ? Colors.black
                                  : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Data de Fim
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selecionarDataFim(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _dataFim != null
                                ? 'Data Fim: ${_formatarData(_dataFim!)}'
                                : 'Selecionar Data de Fim (opcional)',
                            style: TextStyle(
                              color: _dataFim != null
                                  ? Colors.black
                                  : Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => setState(() => _dataFim = null),
                  child: const Text('Limpar'),
                ),
              ],
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
                  onPressed: _salvarExperiencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                      _experienciaEditando == null ? 'Criar' : 'Atualizar'),
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

  Widget _buildExperienciasList() {
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

    if (_experiencias.isEmpty) {
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
                  ? 'Nenhuma experiência encontrada para a busca "$_currentSearch"'
                  : 'Nenhuma experiência cadastrada',
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
                onPressed: _showNovaExperienciaForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar Primeira Experiência'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _experiencias.length,
      itemBuilder: (context, index) {
        final experiencia = _experiencias[index];
        return _buildExperienciaCard(experiencia, index);
      },
    );
  }

  Widget _buildExperienciaCard(
      experiencia.ExperienciaProfissional experiencia, int index) {
    final isAtiva = experiencia.dataFim == null;
    final duracao =
        _calcularDuracao(experiencia.dataInicio, experiencia.dataFim);

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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isAtiva
                        ? const Color(0xFF2E7D32).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAtiva ? const Color(0xFF2E7D32) : Colors.grey,
                    ),
                  ),
                  child: Icon(
                    Icons.work,
                    size: 20,
                    color: isAtiva ? const Color(0xFF2E7D32) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              experiencia.empresa,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isAtiva) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Text(
                                'EM ANDAMENTO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        experiencia.descricaoAtividades,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, experiencia),
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

            // Informações da experiência
            _buildInfoChip(
                'Período',
                '${_formatarData(experiencia.dataInicio)} - ${experiencia.dataFim != null ? _formatarData(experiencia.dataFim!) : 'Atual'}',
                Icons.calendar_today),
            const SizedBox(height: 4),
            _buildInfoChip('Duração', duracao, Icons.schedule),
            const SizedBox(height: 12),

            // Status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAtiva
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAtiva ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Text(
                    isAtiva ? 'EM ANDAMENTO' : 'FINALIZADA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isAtiva ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${experiencia.id} | Candidato: ${experiencia.candidatoId}',
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
    if (_experiencias.isEmpty && !_isLoading && !_isLoadingPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['totalPages'] ??
        ((_experiencias.isNotEmpty)
            ? ((_experiencias.length / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt())
            : 1);
    final currentPage = _pagination?['currentPage'] ?? _currentPage;
    final total = _pagination?['total'] ?? _experiencias.length;
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
      _loadExperienciasProfissionais(showLoading: false);
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
              'Total de Experiências',
              (_estatisticas['total'] ?? 0).toString(),
              Icons.work,
              const Color(0xFF2E7D32),
            ),
            _buildStatCard(
              'Em Andamento',
              (_estatisticas['emAndamento'] ?? 0).toString(),
              Icons.timeline,
              const Color(0xFF1976D2),
            ),
            _buildStatCard(
              'Finalizadas',
              (_estatisticas['finalizadas'] ?? 0).toString(),
              Icons.check_circle,
              const Color(0xFFED6C02),
            ),
            _buildStatCard(
              'Este Mês',
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
              'Gráfico de distribuição de experiências\n(Implementar com charts)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(
      String action, experiencia.ExperienciaProfissional experiencia) {
    switch (action) {
      case 'editar':
        _editarExperiencia(experiencia);
        break;
      case 'excluir':
        _confirmarExclusao(experiencia);
        break;
    }
  }

  void _editarExperiencia(experiencia.ExperienciaProfissional experiencia) {
    setState(() {
      _experienciaEditando = experiencia;
      _candidatoIdController.text = experiencia.candidatoId.toString();
      _empresaController.text = experiencia.empresa;
      _descricaoController.text = experiencia.descricaoAtividades;
      _dataInicio = experiencia.dataInicio;
      _dataFim = experiencia.dataFim;
      _showForm = true;
    });
  }

  Future<void> _confirmarExclusao(
      experiencia.ExperienciaProfissional experiencia) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Excluir Experiência',
      content:
          'Tem certeza que deseja excluir a experiência em "${experiencia.empresa}"?\n\nEsta ação não pode ser desfeita.',
      confirmText: 'Excluir',
    );

    if (confirm) {
      try {
        final success = await experienciaService.ExperienciaProfissionalService
            .deletarExperienciaProfissional(experiencia.id!);
        if (success) {
          AppUtils.showSuccessSnackBar(
              context, 'Experiência excluída com sucesso!');
          _loadExperienciasProfissionais();
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  void _showNovaExperienciaForm() {
    _limparFormulario();
    setState(() => _showForm = true);
  }

  void _cancelarForm() {
    _limparFormulario();
    setState(() => _showForm = false);
  }

  void _limparFormulario() {
    _candidatoIdController.clear();
    _empresaController.clear();
    _descricaoController.clear();
    _dataInicio = null;
    _dataFim = null;
    _experienciaEditando = null;
  }

  Future<void> _salvarExperiencia() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dataInicio == null) {
      AppUtils.showErrorSnackBar(context, 'Data de início é obrigatória');
      return;
    }

    if (_dataFim != null && _dataFim!.isBefore(_dataInicio!)) {
      AppUtils.showErrorSnackBar(
          context, 'Data de fim deve ser posterior à data de início');
      return;
    }

    final dados = {
      'candidatoId': int.parse(_candidatoIdController.text.trim()),
      'empresa': _empresaController.text.trim(),
      'descricao': _descricaoController.text.trim(),
      'dataInicio': _dataInicio!.toIso8601String(),
      if (_dataFim != null) 'dataFim': _dataFim!.toIso8601String(),
    };

    try {
      setState(() => _isLoading = true);

      bool success;
      if (_experienciaEditando == null) {
        success = await experienciaService.ExperienciaProfissionalService
            .criarExperienciaProfissional(dados);
      } else {
        success = await experienciaService.ExperienciaProfissionalService
            .atualizarExperienciaProfissional(_experienciaEditando!.id!, dados);
      }

      if (success) {
        AppUtils.showSuccessSnackBar(
          context,
          _experienciaEditando == null
              ? 'Experiência criada com sucesso!'
              : 'Experiência atualizada com sucesso!',
        );
        _cancelarForm();
        _loadExperienciasProfissionais();
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selecionarDataInicio(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataInicio ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _dataInicio = date);
    }
  }

  Future<void> _selecionarDataFim(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataFim ?? _dataInicio ?? DateTime.now(),
      firstDate: _dataInicio ?? DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dataFim = date);
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _calcularDuracao(DateTime inicio, DateTime? fim) {
    final dataFim = fim ?? DateTime.now();
    final diferenca = dataFim.difference(inicio);
    final anos = (diferenca.inDays / 365).floor();
    final meses = ((diferenca.inDays % 365) / 30).floor();

    if (anos > 0) {
      if (meses > 0) {
        return '$anos ano${anos > 1 ? 's' : ''} e $meses mes${meses > 1 ? 'es' : ''}';
      } else {
        return '$anos ano${anos > 1 ? 's' : ''}';
      }
    } else if (meses > 0) {
      return '$meses mes${meses > 1 ? 'es' : ''}';
    } else {
      return '${diferenca.inDays} dia${diferenca.inDays > 1 ? 's' : ''}';
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
              TextFormField(
                initialValue: _filtroEmpresa,
                decoration: const InputDecoration(labelText: 'Empresa'),
                onChanged: (value) =>
                    _filtroEmpresa = value.isEmpty ? null : value,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Data Início'),
                subtitle: Text(_filtroDataInicio != null
                    ? _formatarData(_filtroDataInicio!)
                    : 'Não selecionada'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filtroDataInicio ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() => _filtroDataInicio = date);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Data Fim'),
                subtitle: Text(_filtroDataFim != null
                    ? _formatarData(_filtroDataFim!)
                    : 'Não selecionada'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _filtroDataFim ?? DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _filtroDataFim = date);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtroEmpresa = null;
                _filtroDataInicio = null;
                _filtroDataFim = null;
                _currentPage = 1;
              });
              Navigator.of(context).pop();
              _loadExperienciasProfissionais();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _currentPage = 1);
              _loadExperienciasProfissionais();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  bool _temFiltrosAtivos() {
    return _filtroEmpresa != null ||
        _filtroDataInicio != null ||
        _filtroDataFim != null ||
        _currentSearch.isNotEmpty;
  }

  Widget _buildFiltrosAtivos() {
    final filtros = <Widget>[];

    if (_currentSearch.isNotEmpty) {
      filtros.add(_buildFiltroChip('Busca: "$_currentSearch"', _clearSearch));
    }

    if (_filtroEmpresa != null) {
      filtros.add(_buildFiltroChip('Empresa: "$_filtroEmpresa"', () {
        setState(() => _filtroEmpresa = null);
        _loadExperienciasProfissionais();
      }));
    }

    if (_filtroDataInicio != null) {
      filtros.add(_buildFiltroChip(
          'Data Início: ${_formatarData(_filtroDataInicio!)}', () {
        setState(() => _filtroDataInicio = null);
        _loadExperienciasProfissionais();
      }));
    }

    if (_filtroDataFim != null) {
      filtros.add(
          _buildFiltroChip('Data Fim: ${_formatarData(_filtroDataFim!)}', () {
        setState(() => _filtroDataFim = null);
        _loadExperienciasProfissionais();
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
      await experienciaService.ExperienciaProfissionalService
          .exportarExperienciasProfissionaisCSV(
        empresa: _filtroEmpresa,
        dataInicio: _filtroDataInicio,
        dataFim: _filtroDataFim,
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
    _candidatoIdController.dispose();
    _empresaController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }
}
