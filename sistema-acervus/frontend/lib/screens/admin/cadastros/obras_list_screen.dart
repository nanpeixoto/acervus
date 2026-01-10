import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_estagio/models/obra.dart';
import 'package:sistema_estagio/services/obra_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

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
  bool _gerandoFicha = false;

  Uint8List? _logoBytes;

  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final List<int> _pageSizeOptions = [5, 10, 20, 50];
  late final double _idPillWidth;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _idPillWidth = _calcIdPillWidth();
    _loadObras();
  }

  double _calcIdPillWidth() {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    final tp = TextPainter(
      text: const TextSpan(text: 'ID 0000000000', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    return tp.width + 20;
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
      appBar: AppBar(
        title: const Text('Gerenciar Obras'),
        actions: [
          IconButton(
            onPressed: () => context.go('/admin/obras/nova'),
            icon: const Icon(Icons.add),
            tooltip: 'Nova Obra',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildObrasList()),
            _buildPaginationControls(),
          ],
        ),
      ),
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
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadObras();
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
            Icon(Icons.apartment, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _currentSearch.isNotEmpty
                  ? 'Nenhuma obra encontrada'
                  : 'Nenhuma obra cadastrada',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _currentSearch.isNotEmpty
                  ? _clearSearch
                  : () => context.go('/admin/obras/nova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: Text(_currentSearch.isNotEmpty
                  ? 'Limpar Busca'
                  : 'Cadastrar Obra'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _obras.length,
      itemBuilder: (context, index) {
        return _buildObraCard(_obras[index]);
      },
    );
  }

  Widget _buildObraCard(Obra obra) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6DE)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _idPillWidth,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2E7D32)),
              ),
              child: Text(
                'ID ${obra.id}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ),
          _vDivider(),
          _infoItem(
            icon: Icons.title,
            text: obra.titulo ?? '',
            flex: 4,
            bold: true,
          ),
          _vDivider(),
          _infoItem(
            icon: Icons.subtitles,
            text: obra.subtitulo ?? '',
            flex: 4,
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'editar') {
                context.go('/admin/obras/editar/${obra.id}');
              } else if (v == 'galeria') {
                context.go('/admin/obras/galeria/${obra.id}');
              } else if (v == 'movimentacoes') {
                context.go('/admin/obras/movimentacoes/${obra.id}');
              } else if (v == 'ficha-obra') {
                _gerarFichaPdf(obra);
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
          ),
        ],
      ),
    );
  }

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
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<Uint8List?> _loadLogoBytes() async {
    if (_logoBytes != null) return _logoBytes;
    try {
      final data = await rootBundle.load('assets/images/logo_acervus.png');
      _logoBytes = data.buffer.asUint8List();
      return _logoBytes;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _buscarPrimeiraImagem(int obraId) async {
    try {
      final galeria = await ObraService.listarGaleria(obraId);
      if (galeria.isEmpty) return null;
      final first = galeria.first;
      final base = first['imagem_base64'] ?? first['imagem'];
      if (base is String && base.isNotEmpty) {
        try {
          return base64Decode(base);
        } catch (_) {
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _gerarFichaPdf(Obra obra) async {
    if (_gerandoFicha) return;
    setState(() => _gerandoFicha = true);

    try {
      final obraDetalhada = await ObraService.buscarObraPorId(obra.id) ?? obra;
      final logoBytes = await _loadLogoBytes();
      final capaBytes = await _buscarPrimeiraImagem(obra.id);

      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      final logo = logoBytes != null ? pw.MemoryImage(logoBytes) : null;
      final capa = capaBytes != null ? pw.MemoryImage(capaBytes) : null;

      // Helper para criar seção com fundo cinza
      pw.Widget sectionHeader(String title) {
        return pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: PdfColors.grey400,
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        );
      }

      // Helper para informação em linha
      pw.Widget infoItem(String label, String value) {
        return pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '$label: ',
                style:
                    pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.TextSpan(
                text: value,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        );
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (logo != null)
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                              height: 50, child: pw.Image(logo, height: 50)),
                        ],
                      )
                    else
                      pw.SizedBox(width: 100),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Página: 1 de 1',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text('Impressão: $dateStr',
                            style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Título Principal
                pw.Center(
                  child: pw.Text(
                    'FICHA DA OBRA',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold),
                  ),
                ),

                pw.SizedBox(height: 16),

                // ID da Obra (em destaque)
                pw.Center(
                  child: pw.Text(
                    obraDetalhada.id.toString(),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red700,
                    ),
                  ),
                ),

                pw.SizedBox(height: 12),

                // Título e Subtítulo da Obra
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        obraDetalhada.titulo?.toUpperCase() ?? '',
                        style: pw.TextStyle(
                            fontSize: 13, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      if ((obraDetalhada.subtitulo ?? '').isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          obraDetalhada.subtitulo?.toUpperCase() ?? '',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                pw.SizedBox(height: 16),

                // DADOS DA OBRA
                sectionHeader('DADOS DA OBRA'),
                pw.SizedBox(height: 8),

                // Conteúdo com imagem
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Coluna de dados
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          infoItem('Tipo de Obra',
                              obraDetalhada.cdTipoPeca?.toString() ?? '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Assunto',
                              obraDetalhada.cdAssunto?.toString() ?? '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Localização', '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Material',
                              obraDetalhada.cdMaterial?.toString() ?? '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Dimensões', obraDetalhada.medida ?? '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Origem', obraDetalhada.origem ?? '-'),
                          pw.SizedBox(height: 3),
                          infoItem(
                              'Nº Edição', obraDetalhada.numeroEdicao ?? '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Volume', obraDetalhada.volume ?? '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Conjunto', obraDetalhada.conjunto ?? '-'),
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 8),

                    // Coluna intermediária
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          infoItem('Subtipo de Obra',
                              obraDetalhada.cdSubtipoPeca?.toString() ?? '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Idioma',
                              obraDetalhada.cdIdioma?.toString() ?? '-'),
                          pw.SizedBox(height: 18),
                          infoItem(
                              'Conservação',
                              obraDetalhada.cdEstadoConservacao?.toString() ??
                                  '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Data', obraDetalhada.dataCompra ?? '-'),
                          pw.SizedBox(height: 3),
                          infoItem('Qtd. Páginas',
                              obraDetalhada.qtdPaginas?.toString() ?? '-'),
                        ],
                      ),
                    ),

                    pw.SizedBox(width: 8),

                    // Imagem
                    if (capa != null)
                      pw.Container(
                        width: 110,
                        height: 140,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey600, width: 0.5),
                        ),
                        child: pw.Image(capa, fit: pw.BoxFit.cover),
                      )
                    else
                      pw.Container(
                        width: 110,
                        height: 140,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey600, width: 0.5),
                        ),
                      ),
                  ],
                ),

                pw.SizedBox(height: 16),

                // AUTOR
                sectionHeader('AUTOR'),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: infoItem('Autor', '-'),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: infoItem('Data de Nascimento', '-'),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      flex: 2,
                      child: infoItem('Data de Falecimento', '-'),
                    ),
                  ],
                ),

                pw.SizedBox(height: 16),

                // RESUMO
                sectionHeader('RESUMO'),
                pw.SizedBox(height: 8),
                if ((obraDetalhada.resumoObra ?? '').isNotEmpty)
                  pw.Text(
                    obraDetalhada.resumoObra ?? '',
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                pw.SizedBox(height: 16),

                // INFORMAÇÕES COMPLEMENTARES
                sectionHeader('INFORMAÇÕES COMPLEMENTARES'),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: infoItem(
                          'Data da Compra', obraDetalhada.dataCompra ?? '-'),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      flex: 2,
                      child: infoItem('Nº Apólice', '-'),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      flex: 2,
                      child: infoItem(
                        'Valor',
                        obraDetalhada.valor != null
                            ? 'R\$ ${obraDetalhada.valor!.toStringAsFixed(2)}'
                            : '-',
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                infoItem('Observações', '-'),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(
          bytes: bytes, filename: 'ficha_obra_${obra.id}.pdf');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao gerar ficha: $e');
    } finally {
      if (mounted) setState(() => _gerandoFicha = false);
    }
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
              Text('Mostrando $startItem-$endItem de $total registros'),
              Text('Página $current de $totalPages'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: current > 1
                    ? () {
                        setState(() => _currentPage--);
                        _loadObras(showLoading: false);
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                onPressed: current < totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadObras(showLoading: false);
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
