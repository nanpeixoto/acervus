import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_app_bar.dart';
import 'package:sistema_estagio/widgets/admin_drawer.dart';
import 'package:sistema_estagio/services/_pessoas/candidato/candidato_service.dart';
import 'package:sistema_estagio/models/_pessoas/candidato/candidato.dart';

class CandidatosScreen extends StatefulWidget {
  final String? regimeId;
  const CandidatosScreen({super.key, this.regimeId});

  @override
  State<CandidatosScreen> createState() => _CandidatosScreenState();
}

class _CandidatosScreenState extends State<CandidatosScreen>
    with SingleTickerProviderStateMixin {
  String? _regimeIdAnterior;
  String? _comprovanteMatriculaUrl;
  final _searchController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _cursoController = TextEditingController();
  String? _tipoSelecionado;
  late TabController _tabController;
  List<Candidato> _candidatos = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final int _totalPages = 1;
  final int _totalItems = 0;
  String? _error;

  bool _isLoadingPage = false;
  int _pageSize = 10; // NOVO: tamanho da página configurável
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  // NOVO: Opções de página
  final List<int> _pageSizeOptions = [5, 10, 20, 50];

  late final double _idPillWidth; // largura fixa do "ID"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _regimeIdAnterior = widget.regimeId;

    // calcula uma largura padrão para "ID 0000000000" + paddings
    _idPillWidth = _calcIdPillWidth();

    _loadCandidatos();
  }

  double _calcIdPillWidth() {
    const idTextStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: Color(0xFF2E7D32),
      letterSpacing: 0.2,
    );
    final tp = TextPainter(
      text: const TextSpan(text: 'ID 0000000000', style: idTextStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return tp.width + 20; // padding horizontal 10 + 10
  }

  @override
  void didUpdateWidget(covariant CandidatosScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.regimeId != oldWidget.regimeId) {
      _regimeIdAnterior = widget.regimeId;
      _currentPage = 1;
      _loadCandidatos();
    }
  }

  Future<void> _loadCandidatos({bool showLoading = true}) async {
    //imprimir(widget.regimeId );
    print('Carregando candidatos para o regime: ${widget.regimeId}');

    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingPage = true);
    }

    try {
      final result = await CandidatoService.listarCandidatos(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        tipoRegime: int.tryParse(widget.regimeId ?? '') ?? 0,
      );

      if (mounted) {
        setState(() {
          _candidatos = result['candidatos'];
          _pagination = result['pagination'];

          if (_pagination == null || _pagination!.isEmpty) {
            final totalItems = _candidatos.length;
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
            content: Text('Erro ao carregar candidatos: $e'),
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

  void _performSearch({bool resetPage = true}) async {
    // ⬅️ ADICIONAR PARÂMETRO
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      if (resetPage) {
        // ⬅️ SÓ RESETA SE SOLICITADO
        _currentPage = 1;
      }
      _currentSearch = _searchController.text.trim();
    });

    try {
      // Se todos os campos estão vazios, carrega lista normal
      if (_currentSearch.isEmpty &&
          _cidadeController.text.trim().isEmpty &&
          _cursoController.text.trim().isEmpty &&
          _tipoSelecionado == null) {
        await _loadCandidatos();
        return;
      }

      print(
          'Tipo regime: ${_tipoSelecionado ?? int.tryParse(widget.regimeId ?? '')}');

      // Chama serviço de busca com os novos parâmetros
      final result = await CandidatoService.buscarCandidato(
        _currentSearch,
        tipoRegime: _tipoSelecionado != null
            ? int.tryParse(_tipoSelecionado!)
            : int.tryParse(widget.regimeId ?? ''),
        cidade: _cidadeController.text.trim().isEmpty
            ? null
            : _cidadeController.text.trim(),
        curso: _cursoController.text.trim().isEmpty
            ? null
            : _cursoController.text.trim(),
        page: _currentPage, // ⬅️ USA A PÁGINA ATUAL
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _candidatos = result['candidatos'] ?? <Candidato>[];
          _pagination = result['pagination'] ??
              {
                'currentPage': 1,
                'totalPages': 1,
                'total': 0,
                'hasNextPage': false,
                'hasPrevPage': false,
              };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar candidatos: $e'),
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
    _cidadeController.clear();
    _cursoController.clear();
    setState(() {
      _currentSearch = '';
      _tipoSelecionado = null;
      _currentPage = 1;
    });
    _loadCandidatos();
  }

  Future<void> _refreshCandidatos() async {
    setState(() => _currentPage = 1);
    await _loadCandidatos();
  }

  @override
  Widget build(BuildContext context) {
    String titulo = 'Candidato';
    if (widget.regimeId == '1') titulo = 'Aprendiz';
    if (widget.regimeId == '2') titulo = 'Estudante';
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerenciar $titulo'),
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
          if (widget.regimeId != null && widget.regimeId!.isNotEmpty)
            IconButton(
              onPressed: () {
                context.go('/admin/candidatos/${widget.regimeId}/novo');
              },
              icon: const Icon(Icons.add),
              tooltip: 'Adicionar $titulo',
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
        Expanded(child: _buildCandidatosList()),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildEstatisticasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          //_buildEstatisticasGerais(),
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
                flex: 3,
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Buscar por nome ou CPF ou Email',
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
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cidadeController,
                  label: 'Buscar por Cidade',
                  prefixIcon: const Icon(Icons.location_city),
                  suffixIcon: _cidadeController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() => _cidadeController.clear());
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
            ],
          ),

// Espaçamento entre as linhas
          const SizedBox(height: 12),

// Campos de busca - SEGUNDA LINHA
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cursoController,
                  label: 'Buscar por Curso',
                  prefixIcon: const Icon(Icons.school),
                  suffixIcon: _cursoController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            setState(() => _cursoController.clear());
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              // Campo TIPO - Só aparece quando regimeId é null (rota /admin/candidatos)
              if (widget.regimeId == null || widget.regimeId!.isEmpty)
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _tipoSelecionado,
                    decoration: InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Todos')),
                      DropdownMenuItem(value: '1', child: Text('JOVEM')),
                      DropdownMenuItem(value: '2', child: Text('ESTUDANTE')),
                    ],
                    onChanged: (value) {
                      setState(() => _tipoSelecionado = value);
                    },
                  ),
                ),
              // Se não exibir o campo Tipo, adiciona espaço vazio para manter alinhamento
              if (widget.regimeId != null && widget.regimeId!.isNotEmpty)
                const Expanded(flex: 2, child: SizedBox.shrink()),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                    _loadCandidatos();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadCandidatos();
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

  bool _temFiltrosAtivos() {
    return _currentSearch.isNotEmpty ||
        _cidadeController.text.isNotEmpty ||
        _cursoController.text.isNotEmpty ||
        _tipoSelecionado != null;
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

  Widget _buildCandidatosList() {
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

    if (_candidatos.isEmpty) {
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
                  ? 'Nenhum ítem encontrado para a busca "$_currentSearch"'
                  : 'Nenhum ítem cadastrado',
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
                onPressed: () =>
                    context.go('/admin/candidatos/${widget.regimeId}/novo'),
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
      itemCount: _candidatos.length,
      itemBuilder: (context, index) {
        final candidato = _candidatos[index];
        return _buildCandidatoCard(candidato, index);
      },
    );
  }

  Widget _buildCandidatoCard(Candidato candidato, int index) {
    final nascimento = candidato.dataNascimento != null
        ? AppUtils.formatDate(candidato.dataNascimento!)
        : '';
    final idStr = (candidato.id ?? '').toString();

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
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ID com largura fixa
            SizedBox(
              width: _idPillWidth,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2E7D32)),
                ),
                alignment: Alignment.center,
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
            ),

            _vDivider(),

            // Nome (reduzido flex)
            _infoItem(
              icon: Icons.person,
              text: candidato.nomeCompleto,
              flex: 3,
              bold: true,
            ),

            _vDivider(),

            // CPF (sem prefixo)
            _infoItem(
              icon: Icons.badge,
              text: CandidatoService.formatarCPF(candidato.cpf),
              flex: 2,
            ),

            _vDivider(),

            // Nascimento (sem prefixo)
            _infoItem(
              icon: Icons.cake,
              text: nascimento,
              flex: 2,
            ),

            _vDivider(),

            // Celular
            _infoItem(
              icon: Icons.phone,
              text: candidato.celular ?? '',
              flex: 2,
            ),

            _vDivider(),

            // E-mail (reduzido flex)
            _infoItem(
              icon: Icons.email_outlined,
              text: candidato.email,
              flex: 2,
            ),

            const SizedBox(width: 8),

            // Status + badges (usando Wrap para quebra automática)
            Wrap(
              spacing: 4,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _statusChip(ativo: candidato.ativo ?? false),
                if (candidato.isMenorIdade == true)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB3E5FC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF01579B)),
                    ),
                    child: const Text(
                      'Menor',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF01579B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (candidato.idRegimeContratacao != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: candidato.idRegimeContratacao == 1
                          ? const Color(
                              0xFFFFF3E0) // Laranja claro para APRENDIZ
                          : const Color(
                              0xFFF3E5F5), // Roxo claro para ESTUDANTE
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: candidato.idRegimeContratacao == 1
                            ? const Color(
                                0xFFF57C00) // Laranja médio para APRENDIZ
                            : const Color(
                                0xFF7B1FA2), // Roxo médio para ESTUDANTE
                      ),
                    ),
                    child: Text(
                      candidato.idRegimeContratacao == 1
                          ? 'JOVEM'
                          : 'ESTUDANTE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: candidato.idRegimeContratacao == 1
                            ? const Color(
                                0xFFE65100) // Laranja escuro para APRENDIZ
                            : const Color(
                                0xFF4A148C), // Roxo escuro para ESTUDANTE
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 8),

            // Ações
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, candidato),
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
                  value: (candidato.ativo ?? false) ? 'inativar' : 'ativar',
                  child: Row(
                    children: [
                      Icon(
                        (candidato.ativo ?? false)
                            ? Icons.block
                            : Icons.check_circle,
                        size: 18,
                        color: (candidato.ativo ?? false)
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        (candidato.ativo ?? false) ? 'Inativar' : 'Ativar',
                        style: TextStyle(
                          color: (candidato.ativo ?? false)
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'visualizar_comprovante_matricula',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Comprovante de Matrícula',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'visualizar_curriculo',
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Currículo do Candidato',
                        style: TextStyle(color: Colors.green),
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

  // ---------- Helpers visuais (linha única) ----------

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE3E7E1),
    );
  }

  Widget _infoItem({
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

  Widget _statusChip({required bool ativo}) {
    final bg = ativo ? Colors.green[100] : Colors.grey[200];
    final fg = ativo ? Colors.green[800] : Colors.grey[700];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (ativo ? Colors.green : Colors.grey)),
      ),
      child: Text(
        ativo ? 'ATIVO' : 'INATIVO',
        style: TextStyle(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    if (_candidatos.isEmpty && !_isLoading && !_isLoadingPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['totalPages'] ??
        ((_candidatos.isNotEmpty)
            ? ((_candidatos.length / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt())
            : 1);
    final currentPage = _pagination?['currentPage'] ?? _currentPage;
    final total = _pagination?['total'] ?? _candidatos.length;
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
        ((_candidatos.isNotEmpty)
            ? ((_candidatos.length / _pageSize).ceil())
            : 1);

    if (page != _currentPage && page >= 1 && page <= totalPages) {
      setState(() => _currentPage = page);

      // ✅ SE ESTÁ EM MODO BUSCA, USA performSearch SEM RESETAR PÁGINA
      if (_temFiltrosAtivos()) {
        _performSearch(resetPage: false); // ⬅️ PASSAR resetPage: false
      } else {
        // ✅ SENÃO, USA loadCandidatos
        _loadCandidatos(showLoading: false);
      }
    }
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

  void _handleMenuAction(String action, Candidato candidato) {
    switch (action) {
      case 'detalhes':
        _showDetalhesDialog(candidato);
        break;
      case 'editar':
        _editarCandidato(candidato);
        break;
      case 'ativar':
        _ativarCandidato(candidato);
        break;
      case 'inativar':
        _bloquearCandidato(candidato);
        break;
      // case 'convenio':
      //   _gerenciarConvenio(candidato);
      //   break;
      case 'excluir':
        _confirmarExclusao(candidato);
        break;
      case 'visualizar_comprovante_matricula':
        _visualizarComprovanteExistente(candidato);
        break;
      case 'visualizar_curriculo':
        _visualizarCurriculoExistente(candidato);
        break;
    }
  }

  void _visualizarCurriculoExistente(Candidato candidato) async {
    await CandidatoService.visualizarResumoEstudante(candidato.id!);
  }

  void _visualizarComprovanteExistente(Candidato candidato) {
    _comprovanteMatriculaUrl = candidato.comprovanteUrl;
    if (_comprovanteMatriculaUrl != null &&
        _comprovanteMatriculaUrl!.isNotEmpty) {
      final url = _comprovanteMatriculaUrl!.startsWith('http')
          ? _comprovanteMatriculaUrl!
          : 'https://cideestagio.com.br/${_comprovanteMatriculaUrl!}'; // 👈 força caminho absoluto

      if (kIsWeb) {
        html.window
            .open(url, '_blank'); // 🔹 abre em nova aba real, fora da SPA
      } else {
        // Aqui segue sua lógica mobile (ex: abrir com url_launcher)
        // launchUrl(Uri.parse(url));
      }
    }
  }

  // MÉTODO MODIFICADO - Navega para tela completa de edição
  void _editarCandidato(Candidato candidato) {
    context.go(
        '/admin/candidatos/editar/${candidato.id}/${candidato.idRegimeContratacao}',
        extra: {
          'candidato': candidato,
          'modo': 'edicao',
          'candidatoId': candidato.id,
          'regimeId':
              candidato.idRegimeContratacao // Adicionar ID explicitamente
        });
  }

  Future<void> _ativarCandidato(Candidato candidato) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Ativar Candidato',
      content: 'Tem certeza que deseja ativar "${candidato.nomeCompleto}"?',
      confirmText: 'Ativar',
    );

    if (confirm) {
      try {
        final success = await CandidatoService.ativarCandidato(candidato.id!);

        if (success) {
          AppUtils.showSuccessSnackBar(
              context, 'Candidato ativada com sucesso!');
          _loadCandidatos(showLoading: false);
        } else {
          AppUtils.showErrorSnackBar(context, 'Erro ao bloquear candidato');
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  Future<void> _bloquearCandidato(Candidato candidato) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Inativar Candidato',
      content: 'Tem certeza que deseja inativar "${candidato.nomeCompleto}"?',
      confirmText: 'Inativar',
    );

    if (confirm) {
      try {
        final success = await CandidatoService.bloquearCandidato(candidato.id!);

        if (success) {
          AppUtils.showSuccessSnackBar(
              context, 'Candidato bloqueada com sucesso!');
          _loadCandidatos(showLoading: false);
        } else {
          AppUtils.showErrorSnackBar(context, 'Erro ao bloquear instituição');
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  Future<void> _confirmarExclusao(Candidato candidato) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Excluir Candidato',
      content:
          'Tem certeza que deseja excluir "${candidato.nomeCompleto}"?\n\nEsta ação não pode ser desfeita e removerá todos os dados relacionados.',
      confirmText: 'Excluir',
    );

    if (confirm) {
      _excluirCandidato(candidato);
    }
  }

  Future<void> _excluirCandidato(Candidato candidato) async {
    setState(() => _isLoading = true);

    try {
      final success = await CandidatoService.deletarCandidato(candidato.id!);

      if (success) {
        AppUtils.showSuccessSnackBar(
            context, 'Candidato excluído com sucesso!');

        if (_candidatos.length == 1 && _currentPage > 1) {
          _currentPage--;
        }

        _loadCandidatos();
        //_loadEstatisticas();
      } else {
        AppUtils.showErrorSnackBar(context, 'Erro ao excluir instituição');
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDetalhesDialog(Candidato candidato) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(candidato.nomeCompleto),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetalheItem('Nome', candidato.nomeCompleto),
                _buildDetalheItem(
                    'Data Nascimento', candidato.dataNascimento as String),
                _buildDetalheItem(
                    'CPF', CandidatoService.formatarCPF(candidato.cpf)),
                _buildDetalheItem('E-mail Principal', candidato.email ?? ''),
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

  Widget _buildFiltroAtivo() {
    return Row(
      children: [
        Chip(
          label: Text('Busca: "$_currentSearch"',
              style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: _clearSearch,
          backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
          deleteIconColor: const Color(0xFF2E7D32),
          labelStyle: const TextStyle(color: Color(0xFF2E7D32)),
        ),
      ],
    );
  }

  void _showFiltrosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: const SingleChildScrollView(
            // child: Column(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     DropdownButtonFormField<String>(
            //       value: _filtroTipo,
            //       decoration: const InputDecoration(labelText: 'Tipo'),
            //       items: const [
            //         DropdownMenuItem(value: null, child: Text('Todos')),
            //         DropdownMenuItem(
            //             value: 'UNIVERSIDADE', child: Text('Universidade')),
            //         DropdownMenuItem(
            //             value: 'FACULDADE', child: Text('Faculdade')),
            //         DropdownMenuItem(
            //             value: 'INSTITUTO', child: Text('Instituto')),
            //         DropdownMenuItem(value: 'CENTRO', child: Text('Centro')),
            //       ],
            //       onChanged: (value) => setState(() => _filtroTipo = value),
            //     ),
            //     const SizedBox(height: 16),
            //     DropdownButtonFormField<bool>(
            //       value: _filtroAtivo,
            //       decoration: const InputDecoration(labelText: 'Status'),
            //       items: const [
            //         DropdownMenuItem(value: null, child: Text('Todos')),
            //         DropdownMenuItem(value: true, child: Text('Ativas')),
            //         DropdownMenuItem(value: false, child: Text('Inativas')),
            //       ],
            //       onChanged: (value) => setState(() => _filtroAtivo = value),
            //     ),
            //     const SizedBox(height: 16),
            //     TextFormField(
            //       initialValue: _filtroCidade,
            //       decoration: const InputDecoration(labelText: 'Cidade'),
            //       onChanged: (value) =>
            //           _filtroCidade = value.isEmpty ? null : value,
            //     ),
            //     const SizedBox(height: 16),
            //     TextFormField(
            //       initialValue: _filtroEstado,
            //       decoration: const InputDecoration(labelText: 'Estado (UF)'),
            //       onChanged: (value) =>
            //           _filtroEstado = value.isEmpty ? null : value,
            //     ),
            //   ],
            // ),
            ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentPage = 1;
              });
              Navigator.of(context).pop();
              _loadCandidatos();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _currentPage = 1);
              _loadCandidatos();
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

  Widget _buildFiltrosAtivos() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (_currentSearch.isNotEmpty)
          _buildFiltroChip('Busca: "$_currentSearch"', _clearSearch),
        if (_cidadeController.text.isNotEmpty)
          _buildFiltroChip('Cidade: "${_cidadeController.text}"', () {
            setState(() => _cidadeController.clear());
            _performSearch();
          }),
        if (_cursoController.text.isNotEmpty)
          _buildFiltroChip('Curso: "${_cursoController.text}"', () {
            setState(() => _cursoController.clear());
            _performSearch();
          }),
        if (_tipoSelecionado != null)
          _buildFiltroChip(
              'Tipo: ${_tipoSelecionado == "1" ? "JOVEM" : "ESTUDANTE"}', () {
            setState(() => _tipoSelecionado = null);
            _performSearch();
          }),
      ],
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
    try {
      await CandidatoService.exportarCSV(
        tipo: _tipoSelecionado,
        cidade:
            _cidadeController.text.isNotEmpty ? _cidadeController.text : null,
        curso: _cursoController.text.isNotEmpty ? _cursoController.text : null,
        _currentSearch,
        tipoRegime: _tipoSelecionado != null
            ? int.tryParse(_tipoSelecionado!)
            : int.tryParse(widget.regimeId ?? ''),
      );
      AppUtils.showSuccessSnackBar(context, 'Dados exportados com sucesso!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao exportar: $e');
    }
  }

  Future<void> _exportarCSV() async {
    try {
      //   final csv = await InstituicaoService.exportarInstituicoesCSV(
      //     tipo: _filtroTipo,
      //     cidade: _filtroCidade,
      //     estado: _filtroEstado,
      //     ativo: _filtroAtivo,
      //);

      AppUtils.showSuccessSnackBar(context, 'CSV exportado com sucesso!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao exportar CSV: $e');
    }
  }

  Future<void> _exportarPDF() async {
    try {
      // final bytes = await InstituicaoService.exportarInstituicoesPDF(
      //   tipo: _filtroTipo,
      //   cidade: _filtroCidade,
      //   estado: _filtroEstado,
      // );

      // AppUtils.showSuccessSnackBar(context, 'PDF exportado com sucesso!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao exportar PDF: $e');
    }
  }

  Widget _buildPaginationControls2() {
    if (_candidatos.isEmpty && !_isLoading && !_isLoadingPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['totalPages'] ?? _totalPages;
    final currentPage = _pagination?['currentPage'] ?? _currentPage;
    final total = _pagination?['total'] ?? _totalItems;
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

  List<Widget> _buildPageNumbers2(int currentPage, int totalPages) {
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

  void _goToPage2(int page) {
    final totalPages = _pagination?['totalPages'] ?? _totalPages;

    if (page != _currentPage && page >= 1 && page <= totalPages) {
      setState(() => _currentPage = page);
      _loadCandidatos(showLoading: false);
    }
  }

  void _editCandidato(Candidato candidato) {
    context.go('/admin/candidatos/editar/${candidato.id}');
  }

  void _viewCandidato(Candidato candidato) {
    context.go('/admin/candidatos/detalhes/${candidato.id}');
  }

  Future<void> _deleteCandidato(Candidato candidato) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
            'Deseja realmente excluir o ítem "${candidato.nomeExibicao}"?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await CandidatoService.deletarCandidato(candidato.id!);
        if (success) {
          await _loadCandidatos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Ítem "${candidato.nomeExibicao}" excluído com sucesso'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception('Falha ao excluir ítem');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao excluir ítem: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _nextPage() {
    setState(() => _currentPage++);
    _loadCandidatos();
  }

  void _previousPage() {
    setState(() => _currentPage--);
    _loadCandidatos();
  }

  // CORREÇÃO: dispose correto (não aninhado dentro de outro método)
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _cidadeController.dispose();
    _cursoController.dispose();
    super.dispose();
  }
}

// Card simples que evita o erro do isThreeLine
class _CandidatoCardSimple extends StatelessWidget {
  final Candidato candidato;
  final VoidCallback onEdit;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _CandidatoCardSimple({
    required this.candidato,
    required this.onEdit,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Nome
            Expanded(
              flex: 3,
              child: Text(
                candidato.nomeExibicao,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 12),

            // CPF
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(Icons.credit_card, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'CPF: ${CandidatoService.formatarCPF(candidato.cpf)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Data de Nascimento
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(Icons.cake, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Nascimento: ${candidato.dataNascimento ?? "N/A"}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Email
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Icon(Icons.email, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      candidato.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badges
            Row(
              children: [
                if (candidato.isMenorIdade)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Menor',
                      style: TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                  ),
                if (candidato.pcd == true)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PCD',
                      style: TextStyle(fontSize: 10, color: Colors.purple),
                    ),
                  ),
                // Indicador de status de dados
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: candidato.isDadosCompletos
                        ? Colors.green[100]
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    candidato.isDadosCompletos ? 'ATIVO' : 'PENDENTE',
                    style: TextStyle(
                      fontSize: 10,
                      color: candidato.isDadosCompletos
                          ? Colors.green[800]
                          : Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 8),

            // Menu de ações
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'view':
                    onView();
                    break;
                  case 'edit':
                    onEdit();
                    break;
                  case 'delete':
                    onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('Visualizar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Excluir', style: TextStyle(color: Colors.red)),
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
}
