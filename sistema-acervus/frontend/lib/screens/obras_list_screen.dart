import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_estagio/models/obra.dart';
import 'package:sistema_estagio/services/obra_service.dart';

import 'package:sistema_estagio/theme/acervus_colors.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';

class ObrasListScreen extends StatefulWidget {
  const ObrasListScreen({super.key});

  @override
  State<ObrasListScreen> createState() => _ObrasListScreenState();
}

class _ObrasListScreenState extends State<ObrasListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  List<Obra> _obras = [];
  bool _isLoading = true;
  bool _isLoadingPage = false;
  final bool _gerandoFicha = false;

  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final List<int> _pageSizeOptions = [5, 10, 20, 50];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadObras();
  }

  Future<void> _loadObras({bool showLoading = true}) async {
    if (!mounted) return;

    setState(() {
      showLoading ? _isLoading = true : _isLoadingPage = true;
    });

    try {
      final result = await ObraService.listarObras(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );

      setState(() {
        _obras = List<Obra>.from(result['dados'] ?? []);
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar obras: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingPage = false;
      });
    }
  }

  void _performSearch({bool resetPage = true}) {
    setState(() {
      _currentSearch = _searchController.text.trim();
      if (resetPage) _currentPage = 1;
    });
    _loadObras();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentSearch = '';
      _currentPage = 1;
    });
    _loadObras();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcervusColors.background,
      body: LoadingOverlay(
        isLoading: _isLoading || _gerandoFicha,
        child: Column(
          children: [
            _buildPageHeader(),
            _buildHeader(),
            Expanded(child: _buildObrasList()),
            _buildPaginationControls(),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gerenciar Obras',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AcervusColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Livros e obras do seu acervo',
                  style: TextStyle(
                    fontSize: 14,
                    color: AcervusColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/admin/obras/nova'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nova obra'),
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
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Buscar por título ou subtítulo',
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
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Buscar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Itens por página:',
                style: TextStyle(
                  fontSize: 13,
                  color: AcervusColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _pageSize,
                items: _pageSizeOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _pageSize = v;
                      _currentPage = 1;
                    });
                    _loadObras();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadObras();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= LIST =================

  Widget _buildObrasList() {
    if (_isLoadingPage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_obras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_outlined,
                size: 64, color: AcervusColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma obra encontrada',
              style: TextStyle(
                color: AcervusColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _currentSearch.isNotEmpty
                  ? _clearSearch
                  : () => context.go('/admin/obras/nova'),
              child: Text(_currentSearch.isNotEmpty
                  ? 'Limpar Busca'
                  : 'Cadastrar Obra'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _obras.length,
      itemBuilder: (context, index) {
        return _buildObraCard(_obras[index]);
      },
    );
  }

  Widget _buildObraCard(Obra obra) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 500;
        return isMobile
            ? _buildObraCardMobile(obra)
            : _buildObraCardDesktop(obra);
      },
    );
  }

  PopupMenuButton<String> _buildPopupMenu(Obra obra) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'editar') {
          context.push('/admin/obras/editar/${obra.id}');
        } else if (v == 'galeria') {
          context.push('/admin/obras/galeria/${obra.id}');
        } else if (v == 'movimentacoes') {
          context.push('/admin/obras/movimentacoes/${obra.id}');
        } else if (v == 'ficha-obra') {
          ObraService.baixarFichaPdf(obra.id!);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
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
          value: 'galeria',
          child: Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 18),
              SizedBox(width: 8),
              Text('Galeria'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'movimentacoes',
          child: Row(
            children: [
              Icon(Icons.swap_horiz, size: 18),
              SizedBox(width: 8),
              Text('Movimentação'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'ficha-obra',
          child: Row(
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 18),
              SizedBox(width: 8),
              Text('Ficha da Obra'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildObraCardMobile(Obra obra) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AcervusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcervusColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AcervusColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ID ${obra.id}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AcervusColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              _buildPopupMenu(obra),
            ],
          ),
          if ((obra.titulo ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              obra.titulo ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if ((obra.subtitulo ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              obra.subtitulo ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildObraCardDesktop(Obra obra) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AcervusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcervusColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ID (pill do design system)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AcervusColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ID ${obra.id}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AcervusColors.primary,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // CONTEÚDO PRINCIPAL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TÍTULO (protagonista)
                Text(
                  obra.titulo ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // SUBTÍTULO
                if ((obra.subtitulo ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    obra.subtitulo ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],

                const SizedBox(height: 6),

                // META INFO (linha leve)
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _meta(Icons.person_outline, obra.dsAutor),
                    _meta(Icons.menu_book_outlined, obra.dsTipoPeca),
                    _meta(Icons.label_outline, obra.dsAssunto),
                  ],
                ),
              ],
            ),
          ),

          // MENU
          _buildPopupMenu(obra),
        ],
      ),
    );
  }

  // ================= PAGINATION =================

  Widget _buildPaginationControls() {
    if (_pagination == null) return const SizedBox.shrink();

    final current = _pagination!['currentPage'] ?? 1;
    final totalPages = _pagination!['totalPages'] ?? 1;
    final total = _pagination!['total'] ?? _obras.length;

    final startItem = ((current - 1) * _pageSize) + 1;
    final endItem =
        (current * _pageSize) > total ? total : (current * _pageSize);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: AcervusColors.surface,
        border: Border(top: BorderSide(color: AcervusColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          final info = Text(
            'Mostrando $startItem-$endItem de $total registros',
            style: const TextStyle(
              fontSize: 13,
              color: AcervusColors.textSecondary,
            ),
          );

          final pager = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pagerArrow(
                Icons.chevron_left,
                current > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadObras(showLoading: false);
                      }
                    : null,
              ),
              ..._pageNumbers(current, totalPages).map(
                (p) => p == null
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '…',
                          style:
                              TextStyle(color: AcervusColors.textSecondary),
                        ),
                      )
                    : _pagePill(p, p == current),
              ),
              _pagerArrow(
                Icons.chevron_right,
                current < totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadObras(showLoading: false);
                      }
                    : null,
              ),
            ],
          );

          if (isMobile) {
            return Column(
              children: [info, const SizedBox(height: 8), pager],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [info, pager],
          );
        },
      ),
    );
  }

  /// Números de página com reticências: 1 … (c-1) c (c+1) … total
  List<int?> _pageNumbers(int current, int totalPages) {
    if (totalPages <= 7) {
      return List<int?>.generate(totalPages, (i) => i + 1);
    }
    final pages = <int?>[1];
    if (current > 3) pages.add(null);
    for (var p = current - 1; p <= current + 1; p++) {
      if (p > 1 && p < totalPages) pages.add(p);
    }
    if (current < totalPages - 2) pages.add(null);
    pages.add(totalPages);
    return pages;
  }

  Widget _pagePill(int page, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: isActive
            ? null
            : () {
                setState(() => _currentPage = page);
                _loadObras(showLoading: false);
              },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AcervusColors.primary : null,
            borderRadius: BorderRadius.circular(8),
            border: isActive ? null : Border.all(color: AcervusColors.border),
          ),
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? Colors.white : AcervusColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pagerArrow(IconData icon, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          foregroundColor: AcervusColors.textSecondary,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _meta(IconData icon, String? text) {
    if (text == null || text.isEmpty) return const SizedBox();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AcervusColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AcervusColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
