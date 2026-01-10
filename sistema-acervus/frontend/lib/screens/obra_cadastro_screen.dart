import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_estagio/models/_auxiliares/assunto.dart';
import 'package:sistema_estagio/models/_auxiliares/autor.dart';
import 'package:sistema_estagio/models/_auxiliares/editora.dart';
import 'package:sistema_estagio/models/_auxiliares/estado_conservacao.dart';
import 'package:sistema_estagio/models/_auxiliares/material.dart';
import 'package:sistema_estagio/models/_auxiliares/pais.dart';
import 'package:sistema_estagio/models/_auxiliares/estado.dart';
import 'package:sistema_estagio/models/_auxiliares/cidade.dart';
import 'package:sistema_estagio/models/_auxiliares/subtipo_obra.dart';
import 'package:sistema_estagio/models/_pessoas/formacao/idioma.dart';
import 'package:sistema_estagio/services/_auxiliares/assunto_service.dart';
import 'package:sistema_estagio/services/_auxiliares/autor_service.dart';
import 'package:sistema_estagio/services/_auxiliares/editora_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/estado_conservacao_service.dart';
import 'package:sistema_estagio/services/_auxiliares/material_service.dart';
import 'package:sistema_estagio/services/_auxiliares/pais_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/estado_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/cidade_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/subtipo_obra_service.dar.dart';
import 'package:sistema_estagio/services/_pessoas/formacao/idioma_service.dart';
import 'package:sistema_estagio/services/obra_service.dart';
import 'package:sistema_estagio/models/obra.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/models/_auxiliares/tipo_obra.dart';
import 'package:sistema_estagio/services/_auxiliares/tipo_obra_service.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class _ObraImagem {
  final int? id;
  final String? url;
  final Uint8List? bytes;
  final String? name;
  final String? descricao;
  final String? extensao;
  final bool isPrincipal;
  double rotationDeg;

  _ObraImagem({
    this.id,
    this.url,
    this.bytes,
    this.name,
    this.descricao,
    this.extensao,
    this.rotationDeg = 0,
    this.isPrincipal = false,
  });
}

class _Movimentacao {
  final int? id;
  final String tipoMovimento;
  final String? descricao;
  final int? paisId;
  final int? estadoId;
  final int? cidadeId;
  final DateTime? dataInicial;
  final DateTime? dataFinal;
  final double? valor;
  final String? laudoInicial;
  final String? laudoFinal;

  _Movimentacao({
    this.id,
    required this.tipoMovimento,
    this.descricao,
    this.paisId,
    this.estadoId,
    this.cidadeId,
    this.dataInicial,
    this.dataFinal,
    this.valor,
    this.laudoInicial,
    this.laudoFinal,
  });

  _Movimentacao copyWith({
    int? id,
    String? tipoMovimento,
    String? descricao,
    int? paisId,
    int? estadoId,
    int? cidadeId,
    DateTime? dataInicial,
    DateTime? dataFinal,
    double? valor,
    String? laudoInicial,
    String? laudoFinal,
  }) {
    return _Movimentacao(
      id: id ?? this.id,
      tipoMovimento: tipoMovimento ?? this.tipoMovimento,
      descricao: descricao ?? this.descricao,
      paisId: paisId ?? this.paisId,
      estadoId: estadoId ?? this.estadoId,
      cidadeId: cidadeId ?? this.cidadeId,
      dataInicial: dataInicial ?? this.dataInicial,
      dataFinal: dataFinal ?? this.dataFinal,
      valor: valor ?? this.valor,
      laudoInicial: laudoInicial ?? this.laudoInicial,
      laudoFinal: laudoFinal ?? this.laudoFinal,
    );
  }
}

class ObraCadastroScreen extends StatefulWidget {
  final int? obraId;

  const ObraCadastroScreen({super.key, this.obraId});

  @override
  State<ObraCadastroScreen> createState() => _ObraCadastroScreenState();
}

class _ObraCadastroScreenState extends State<ObraCadastroScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  bool get _isEdicao => widget.obraId != null;

  String? _carimbo;

  // =========================
  // Controllers
  // =========================
  final _tituloController = TextEditingController();
  final _subtituloController = TextEditingController();
  final _origemController = TextEditingController();
  final _medidaController = TextEditingController();
  final _conjuntoController = TextEditingController();
  final _numeroEdicaoController = TextEditingController();
  final _qtdPaginasController = TextEditingController();
  final _volumeController = TextEditingController();
  final _resumoController = TextEditingController();
  final _numeroApoliceController = TextEditingController();
  final _valorController = TextEditingController();
  late quill.QuillController _quillController;
  late quill.QuillController _quillInfoController;
  final List<_ObraImagem> _imagens = [];
  final List<_Movimentacao> _movimentacoes = [];
  bool _loadingMovimentacoes = false;
  bool _loadingGaleria = false;

  DateTime? _dataCompra;
  DateTime? _dataCompraInfCompl;

  // =========================
  // IDs (FKs)
  // =========================
  int? cdTipoPeca;
  int? cdSubtipoPeca;
  int? cdAssunto;
  int? cdMaterial;
  int? cdIdioma;
  int? cdEstadoConservacao;
  int? cdEstantePrateleira;
  int? cdAutor;
  int? cdEditora;

  List<TipoObra> _tiposObra = [];
  bool _loadingTipoObra = false;

  List<SubtipoObra> _subtiposObra = [];
  bool _loadingSubtipo = false;

  List<Assunto> _assuntos = [];
  bool _loadingAssuntos = false;

  List<Materiais> _materiais = [];
  bool _loadingMateriais = false;

  List<EstadoConservacao> _estadosConservacao = [];
  bool _loadingEstadosConservacao = false;

  List<Editora> _editoras = [];
  bool _loadingEditoras = false;

  List<Idioma> _idiomas = [];
  bool _loadingIdiomas = false;

  List<Autor> _autores = [];
  bool _loadingAutores = false;

  // Combos localização
  List<Pais> _paises = [];
  List<Estado> _estados = [];
  List<Cidade> _cidades = [];
  bool _loadingPaises = false;
  bool _loadingEstados = false;
  bool _loadingCidades = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _quillController = quill.QuillController.basic();
    _quillInfoController = quill.QuillController.basic();

    _carregarTiposObra();

    _loadAssuntos();

    _loadIdiomas();

    _loadMateriais();

    _loadEstadosConservacao();

    _loadEditoras();

    _loadAutores();

    _loadPaises();

    if (_isEdicao) {
      _carregarObra();
    }
  }

  Future<void> _loadIdiomas() async {
    setState(() => _loadingIdiomas = true);

    try {
      final result = await IdiomaService.listarIdiomas(
        page: 1,
        limit: 999,
        ativo: true,
      );

      setState(() {
        _idiomas = result['idiomas'];
      });

      setState(() {
        _idiomas = result['idiomas'];
      });

      print('Idiomas carregados: ${_idiomas.map((e) => e.descricao).toList()}');
      print('cdIdioma atual: $cdIdioma');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar idiomas');
    } finally {
      setState(() => _loadingIdiomas = false);
    }
  }

  Future<void> _loadAssuntos() async {
    setState(() => _loadingAssuntos = true);

    try {
      final result = await AssuntoService.listarAssuntos(
        page: 1,
        limit: 999, // para dropdown
        ativo: true,
      );

      setState(() {
        _assuntos = result['Assuntos'] as List<Assunto>;
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar Assuntos');
    } finally {
      setState(() => _loadingAssuntos = false);
    }
  }

  Future<void> _loadMateriais() async {
    setState(() => _loadingMateriais = true);

    try {
      final result = await MateriaisService.listarMateriais(
        page: 1,
        limit: 999,
        ativo: true,
      );

      setState(() {
        _materiais = List<Materiais>.from(result['materiais'] ?? []);

        // segurança: evita value fora da lista
        if (cdMaterial != null && !_materiais.any((m) => m.id == cdMaterial)) {
          cdMaterial = null;
        }
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar materiais');
    } finally {
      setState(() => _loadingMateriais = false);
    }
  }

  Future<void> _loadEstadosConservacao() async {
    setState(() => _loadingEstadosConservacao = true);

    try {
      final result = await EstadoConservacaoService.listar(
        page: 1,
        limit: 999,
        ativo: true,
      );

      setState(() {
        _estadosConservacao =
            List<EstadoConservacao>.from(result['estados'] ?? []);

        // segurança: evita value fora da lista
        if (cdEstadoConservacao != null &&
            !_estadosConservacao.any((e) => e.id == cdEstadoConservacao)) {
          cdEstadoConservacao = null;
        }
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(
          context, 'Erro ao carregar estados de conservação');
    } finally {
      setState(() => _loadingEstadosConservacao = false);
    }
  }

  Future<void> _loadEditoras() async {
    setState(() => _loadingEditoras = true);

    try {
      final result = await EditoraService.listar(
        page: 1,
        limit: 999,
        ativo: true,
      );

      setState(() {
        _editoras = List<Editora>.from(result['Editoras'] ?? []);

        // segurança: evita value fora da lista
        if (cdEditora != null && !_editoras.any((e) => e.id == cdEditora)) {
          cdEditora = null;
        }
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar editoras');
    } finally {
      setState(() => _loadingEditoras = false);
    }
  }

  Future<void> _loadAutores() async {
    setState(() => _loadingAutores = true);

    try {
      final result = await AutorService.listarAutores(
        page: 1,
        limit: 999,
        ativo: true,
      );

      setState(() {
        _autores = List<Autor>.from(result['autores'] ?? []);

        // segurança: evita value fora da lista
        if (cdAutor != null && !_autores.any((a) => a.id == cdAutor)) {
          cdAutor = null;
        }
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar autores');
    } finally {
      setState(() => _loadingAutores = false);
    }
  }

  Future<void> _loadPaises() async {
    setState(() => _loadingPaises = true);
    try {
      _paises = await PaisService.listarSimples();
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar países');
    } finally {
      if (mounted) setState(() => _loadingPaises = false);
    }
  }

  Future<void> _loadEstados(int? paisId) async {
    if (paisId == null) {
      setState(() => _estados = []);
      return;
    }
    setState(() => _loadingEstados = true);
    try {
      _estados = await EstadoService.listarPorPais(paisId);
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar estados');
    } finally {
      if (mounted) setState(() => _loadingEstados = false);
    }
  }

  Future<void> _loadCidades(int? estadoId) async {
    if (estadoId == null) {
      setState(() => _cidades = []);
      return;
    }
    setState(() => _loadingCidades = true);
    try {
      _cidades = await CidadeService.listarPorEstado(estadoId);
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar cidades');
    } finally {
      if (mounted) setState(() => _loadingCidades = false);
    }
  }

  Future<void> _carregarSubtiposPorTipo(int cdTipoPeca) async {
    setState(() {
      _loadingSubtipo = true;
      _subtiposObra = [];
      cdSubtipoPeca = null;
    });

    try {
      final result = await SubtipoObraService.listar(
        page: 1,
        limit: 999,
        ativo: true,
        cdTipoObra: cdTipoPeca, // 🔴 filtro pelo tipo
      );

      setState(() {
        _subtiposObra = List<SubtipoObra>.from(result['Subtipos']);
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(
        context,
        'Erro ao carregar Subtipos de Obra',
      );
    } finally {
      setState(() => _loadingSubtipo = false);
    }
  }

  Future<void> _carregarTiposObra() async {
    setState(() => _loadingTipoObra = true);

    try {
      final result = await TipoObraService.listar(
        page: 1,
        limit: 100,
        ativo: true,
      );

      setState(() {
        _tiposObra = List<TipoObra>.from(result['TipoObras']);
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar Tipos de Obra');
    } finally {
      setState(() => _loadingTipoObra = false);
    }
  }

  // =========================
  // LOAD
  // =========================
  Future<void> _carregarGaleria() async {
    if (!_isEdicao) return;

    setState(() => _loadingGaleria = true);

    try {
      final lista = await ObraService.listarGaleria(widget.obraId!);
      final imagens = <_ObraImagem>[];

      for (final item in lista) {
        Uint8List? bytes;
        final base64Data = item['imagem_base64'] ?? item['imagem'];
        if (base64Data is String && base64Data.isNotEmpty) {
          try {
            bytes = base64Decode(base64Data);
          } catch (_) {
            bytes = null;
          }
        }

        final dynamic idDynamic = item['id'];
        final int? id = idDynamic is int
            ? idDynamic
            : int.tryParse(idDynamic?.toString() ?? '');

        imagens.add(
          _ObraImagem(
            id: id,
            bytes: bytes,
            url: bytes == null && id != null
                ? ObraService.galeriaArquivoUrl(id)
                : null,
            name: item['nome'] as String?,
            descricao: item['ds_imagem'] as String?,
            extensao: item['extensao'] as String?,
            isPrincipal: item['sts_principal'] == true,
            rotationDeg: item['rotacao'] is num
                ? (item['rotacao'] as num).toDouble()
                : 0,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _imagens
          ..clear()
          ..addAll(imagens);
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar galeria');
    } finally {
      if (mounted) {
        setState(() => _loadingGaleria = false);
      }
    }
  }

  Future<void> _loadMovimentacoes() async {
    if (!_isEdicao) return;

    setState(() => _loadingMovimentacoes = true);
    try {
      final lista = await ObraService.listarMovimentacoes(widget.obraId!);
      final items = lista.map((m) {
        DateTime? dtIni;
        DateTime? dtFim;
        if (m['data_inicial'] != null) {
          dtIni = DateTime.tryParse(m['data_inicial'].toString());
        }
        if (m['data_final'] != null) {
          dtFim = DateTime.tryParse(m['data_final'].toString());
        }
        return _Movimentacao(
          id: m['id'] as int?,
          tipoMovimento: (m['tipo_movimento'] ?? '').toString(),
          descricao: m['descricao'] as String?,
          paisId: m['pais_id'] as int?,
          estadoId: m['estado_id'] as int?,
          cidadeId: m['cidade_id'] as int?,
          dataInicial: dtIni,
          dataFinal: dtFim,
          valor: m['valor'] != null
              ? double.tryParse(m['valor'].toString())
              : null,
          laudoInicial: m['laudo_inicial'] as String?,
          laudoFinal: m['laudo_final'] as String?,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _movimentacoes
          ..clear()
          ..addAll(items);
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar movimentações');
    } finally {
      if (mounted) setState(() => _loadingMovimentacoes = false);
    }
  }

  Future<void> _carregarObra() async {
    setState(() => _isLoading = true);

    try {
      final Obra? obra = await ObraService.buscarObraPorId(widget.obraId!);
      if (obra == null) return;

      _tituloController.text = obra.titulo ?? '';
      _subtituloController.text = obra.subtitulo ?? '';
      _origemController.text = obra.origem ?? '';
      _medidaController.text = obra.medida ?? '';
      _conjuntoController.text = obra.conjunto ?? '';
      _numeroEdicaoController.text = obra.numeroEdicao ?? '';
      _qtdPaginasController.text =
          obra.qtdPaginas != null ? obra.qtdPaginas.toString() : '';
      _volumeController.text = obra.volume ?? '';
      _resumoController.text = obra.resumoObra ?? '';
      _carimbo = obra.carimbo;

      cdTipoPeca = obra.cdTipoPeca;
      cdSubtipoPeca = obra.cdSubtipoPeca;
      cdAssunto = obra.cdAssunto;
      cdMaterial = obra.cdMaterial;
      cdIdioma = obra.cdIdioma;
      cdEstadoConservacao = obra.cdEstadoConservacao;
      cdEstantePrateleira = obra.cdEstantePrateleira;
      cdAutor = obra.cdAutor;
      cdEditora = obra.cdEditora;

      if (cdTipoPeca != null) {
        await _carregarSubtiposPorTipo(cdTipoPeca!);
        cdSubtipoPeca = obra.cdSubtipoPeca;
      }

      if (obra.dataCompra != null) {
        _dataCompra = DateTime.tryParse(obra.dataCompra!);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar obra');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =========================
  // SAVE
  // =========================
  Future<void> _salvar() async {
    if (_tituloController.text.trim().isEmpty) {
      AppUtils.showErrorSnackBar(context, 'Título é obrigatório');
      return;
    }

    setState(() => _isLoading = true);

    final payload = {
      'titulo': _tituloController.text.trim(),
      'subtitulo': _subtituloController.text.trim(),
      'cd_tipo_peca': cdTipoPeca,
      'cd_subtipo_peca': cdSubtipoPeca,
      'cd_assunto': cdAssunto,
      'cd_material': cdMaterial,
      'cd_idioma': cdIdioma,
      'cd_estado_conservacao': cdEstadoConservacao,
      'cd_estante_prateleira': cdEstantePrateleira,
      'cd_autor': cdAutor,
      'cd_editora': cdEditora,
      'origem': _origemController.text.trim(),
      'medida': _medidaController.text.trim(),
      'conjunto': _conjuntoController.text.trim(),
      'numero_edicao': _numeroEdicaoController.text.trim(),
      'qtd_paginas': int.tryParse(_qtdPaginasController.text),
      'volume': _volumeController.text.trim(),
      'resumo_obra': _resumoController.text.trim(),
        'data_compra': _dataCompra?.toIso8601String().substring(0, 10),
        'data_compra_complementar':
          _dataCompraInfCompl?.toIso8601String().substring(0, 10),
        'numero_apolice': _numeroApoliceController.text.trim(),
        'valor': double.tryParse(_valorController.text.replaceAll(',', '.')),
        'observacao_complementar':
          _quillInfoController.document.toPlainText().trim(),
    };

    try {
      if (_isEdicao) {
        await ObraService.editarObra(widget.obraId!, payload);
        AppUtils.showSuccessSnackBar(context, 'Obra alterada com sucesso!');
      } else {
        await ObraService.criarObra(payload);
        AppUtils.showSuccessSnackBar(context, 'Obra cadastrada com sucesso!');
      }
      context.pop();
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao salvar obra');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdicao ? 'Editar Obra' : 'Cadastrar Obra'),
        actions: [
          if (_isEdicao)
            IconButton(
              tooltip: 'Galeria',
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: () {
                final titulo = _tituloController.text.trim();
                final path = titulo.isNotEmpty
                    ? '/admin/obras/${widget.obraId}/galeria?titulo=${Uri.encodeComponent(titulo)}'
                    : '/admin/obras/${widget.obraId}/galeria';
                context.push(path);
              },
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvar,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cadastro'),
            Tab(text: 'Resumo'),
            Tab(text: 'Inf Complementares'),            
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAbaCadastro(),
            _buildAbaResumo(),
            _buildAbaInfComplementares(),
          ],
        ),
      ),
    );
  }

  // =========================
  // ABA CADASTRO
  // =========================
  Widget _buildAbaCadastro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if ((_carimbo ?? '').isNotEmpty) ...[
            Center(
              child: Text(
                _carimbo!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          CustomTextField(controller: _tituloController, label: 'Título *'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: cdTipoPeca,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Obra *',
                    border: OutlineInputBorder(),
                  ),
                  items: _tiposObra
                      .map(
                        (tipo) => DropdownMenuItem<int>(
                          value: tipo.id,
                          child: Text(tipo.descricao),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() => cdTipoPeca = value);
                    _carregarSubtiposPorTipo(
                        value); // 🚀 aqui acontece a mágica
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: cdSubtipoPeca,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Subtipo de Obra *',
                    border: OutlineInputBorder(),
                  ),
                  items: _subtiposObra
                      .map(
                        (s) => DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(s.descricao),
                        ),
                      )
                      .toList(),
                  onChanged: (_loadingSubtipo || cdTipoPeca == null)
                      ? null
                      : (value) {
                          setState(() => cdSubtipoPeca = value);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: cdAssunto,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Assunto *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _assuntos
                      .map(
                        (a) => DropdownMenuItem<int>(
                          value: a.id,
                          child: Text(a.descricao),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => cdAssunto = v),
                  validator: (v) => v == null ? 'Assunto é obrigatório' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: cdIdioma,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Idioma *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _idiomas
                      .map(
                        (i) => DropdownMenuItem<int>(
                          value: i.id,
                          child: Text(i.descricao),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => cdIdioma = v),
                  validator: (v) => v == null ? 'Idioma é obrigatório' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dropdownMaterial()),
              const SizedBox(width: 12),
              Expanded(
                  child: _dropdown('Localização *', cdEstantePrateleira,
                      (v) => setState(() => cdEstantePrateleira = v))),
            ],
          ),
          const SizedBox(height: 12),
          _dropdownAutor(),
          const SizedBox(height: 12),
          CustomTextField(controller: _subtituloController, label: 'Subtítulo'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dropdownEstadoConservacao()),
              const SizedBox(width: 12),
              Expanded(child: _dropdownEditora()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: CustomTextField(
                      controller: _medidaController, label: 'Dimensões')),
              const SizedBox(width: 12),
              Expanded(
                  child: CustomTextField(
                      controller: _conjuntoController, label: 'Conjunto')),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(controller: _origemController, label: 'Origem'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _dateField()),
              const SizedBox(width: 12),
              Expanded(
                  child: CustomTextField(
                      controller: _numeroEdicaoController,
                      label: 'Número da Edição')),
              const SizedBox(width: 12),
              Expanded(
                  child: CustomTextField(
                      controller: _qtdPaginasController,
                      label: 'Qtd. Páginas')),
              const SizedBox(width: 12),
              Expanded(
                  child: CustomTextField(
                      controller: _volumeController, label: 'Volume')),
            ],
          ),
        ],
      ),
    );
  }

  // =========================
  // OUTRAS ABAS
  // =========================
  Widget _buildAbaResumo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Barra de ferramentas do editor
          quill.QuillToolbar.simple(
            configurations: quill.QuillSimpleToolbarConfigurations(
              controller: _quillController,
              showAlignmentButtons: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showListBullets: true,
              showListNumbers: true,
            ),
          ),

          const SizedBox(height: 8),

          // Área de edição
          Container(
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: quill.QuillEditor.basic(
              controller: _quillController,
              configurations: const quill.QuillEditorConfigurations(
                padding: EdgeInsets.all(12),
                placeholder: 'Digite o resumo da obra...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbaInfComplementares() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _dateFieldComplementar(
                  label: 'Data Compra',
                  value: _dataCompraInfCompl,
                  onPicked: (d) => setState(() => _dataCompraInfCompl = d),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _numeroApoliceController,
                  decoration: const InputDecoration(
                    labelText: 'Número Apólice',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _valorController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text(
            'Observação',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          quill.QuillToolbar.simple(
            configurations: quill.QuillSimpleToolbarConfigurations(
              controller: _quillInfoController,
              showAlignmentButtons: true,
              showBoldButton: true,
              showItalicButton: true,
              showUnderLineButton: true,
              showListBullets: true,
              showListNumbers: true,
            ),
          ),

          const SizedBox(height: 8),

          Container(
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: quill.QuillEditor.basic(
              controller: _quillInfoController,
              configurations: const quill.QuillEditorConfigurations(
                padding: EdgeInsets.all(12),
                placeholder: 'Digite observações complementares...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbaGaleria() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Imagens da Obra',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Adicionar arquivo'),
                    onPressed: _adicionarImagemArquivoWeb,
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Adicionar URL'),
                    onPressed: _adicionarImagemPorUrl,
                  ),
                ],
              ),
            ],
          ),
          if (_loadingGaleria) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: 12),

          if (_imagens.isEmpty)
            const Text(
              'Nenhuma imagem adicionada.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _imagens
                  .asMap()
                  .entries
                  .map((entry) => _buildImagemCard(entry.key, entry.value))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAbaMovimentacao() {
    if (!_isEdicao) {
      return const Center(
        child: Text('Salve a obra primeiro para gerenciar movimentações.'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Movimentações',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nova movimentação'),
                onPressed: () => _abrirMovimentacaoDialog(),
              ),
            ],
          ),
          if (_loadingMovimentacoes) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
          const SizedBox(height: 12),
          if (_movimentacoes.isEmpty)
            const Text(
              'Nenhuma movimentação cadastrada.',
              style: TextStyle(color: Colors.grey),
            )
          else
            Column(
              children: _movimentacoes
                  .asMap()
                  .entries
                  .map((entry) => _buildMovimentacaoCard(entry.value))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAbaLocalizar() {
    return Center(
      child: Text('Localizar - Em desenvolvimento'),
    );
  }

  // =========================
  // HELPERS
  // =========================
  Widget _dropdown(String label, int? value, Function(int?) onChanged) {
    return DropdownButtonFormField<int>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: const [],
      onChanged: onChanged,
    );
  }

  Widget _dropdownMaterial() {
    if (_loadingMateriais) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_materiais.isEmpty) {
      return const Text(
        'Nenhum material disponível',
        style: TextStyle(color: Colors.grey),
      );
    }

    return DropdownButtonFormField<int>(
      value: cdMaterial,
      isExpanded: true,
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      decoration: const InputDecoration(
        labelText: 'Material *',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _materiais
          .map(
            (m) => DropdownMenuItem<int>(
              value: m.id,
              child: Text(
                m.descricao,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => cdMaterial = v),
      validator: (v) => v == null ? 'Material é obrigatório' : null,
    );
  }

  Widget _dropdownEstadoConservacao() {
    if (_loadingEstadosConservacao) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_estadosConservacao.isEmpty) {
      return const Text(
        'Nenhum estado de conservação disponível',
        style: TextStyle(color: Colors.grey),
      );
    }

    return DropdownButtonFormField<int>(
      value: cdEstadoConservacao,
      isExpanded: true,
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      decoration: const InputDecoration(
        labelText: 'Estado de Conservação *',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _estadosConservacao
          .map(
            (e) => DropdownMenuItem<int>(
              value: e.id,
              child: Text(
                e.descricao,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => cdEstadoConservacao = v),
      validator: (v) =>
          v == null ? 'Estado de Conservação é obrigatório' : null,
    );
  }

  Widget _dropdownEditora() {
    if (_loadingEditoras) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_editoras.isEmpty) {
      return const Text(
        'Nenhuma editora disponível',
        style: TextStyle(color: Colors.grey),
      );
    }

    return DropdownButtonFormField<int>(
      value: cdEditora,
      isExpanded: true,
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      decoration: const InputDecoration(
        labelText: 'Editora *',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _editoras
          .map(
            (e) => DropdownMenuItem<int>(
              value: e.id,
              child: Text(
                e.descricao,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => cdEditora = v),
      validator: (v) => v == null ? 'Editora é obrigatória' : null,
    );
  }

  Widget _dropdownAutor() {
    if (_loadingAutores) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_autores.isEmpty) {
      return const Text(
        'Nenhum autor disponível',
        style: TextStyle(color: Colors.grey),
      );
    }

    return DropdownButtonFormField<int>(
      value: cdAutor,
      isExpanded: true,
      dropdownColor: Colors.white,
      style: const TextStyle(color: Colors.black),
      decoration: const InputDecoration(
        labelText: 'Autor *',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: _autores
          .map(
            (a) => DropdownMenuItem<int>(
              value: a.id,
              child: Text(
                a.nome,
                style: const TextStyle(color: Colors.black),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => cdAutor = v),
      validator: (v) => v == null ? 'Autor é obrigatório' : null,
    );
  }

  Widget _buildMovimentacaoCard(_Movimentacao mov) {
    String formatDate(DateTime? d) =>
        d == null ? '-' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mov.tipoMovimento,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _abrirMovimentacaoDialog(mov),
                ),
              ],
            ),
            if ((mov.descricao ?? '').isNotEmpty)
              Text(mov.descricao ?? ''),
            const SizedBox(height: 6),
            Text('Datas: ${formatDate(mov.dataInicial)} - ${formatDate(mov.dataFinal)}'),
            if (mov.valor != null)
              Text('Valor: R\$ ${mov.valor!.toStringAsFixed(2)}'),
            if (mov.cidadeId != null || mov.estadoId != null || mov.paisId != null)
              Text(
                'Local: ' +
                    [
                      mov.cidadeId != null ? 'Cidade ${mov.cidadeId}' : null,
                      mov.estadoId != null ? 'Estado ${mov.estadoId}' : null,
                      mov.paisId != null ? 'País ${mov.paisId}' : null,
                    ].whereType<String>().join(' / '),
                style: const TextStyle(color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirMovimentacaoDialog([_Movimentacao? mov]) async {
    await _loadPaises();
    int? selPais = mov?.paisId;
    int? selEstado = mov?.estadoId;
    int? selCidade = mov?.cidadeId;

    if (selPais != null) {
      await _loadEstados(selPais);
    }
    if (selEstado != null) {
      await _loadCidades(selEstado);
    }

    String selTipo = mov?.tipoMovimento ?? 'Entrada';
    final descCtrl = TextEditingController(text: mov?.descricao ?? '');
    final valorCtrl = TextEditingController(
      text: mov?.valor != null ? mov!.valor!.toStringAsFixed(2) : '',
    );
    final laudoIniCtrl = TextEditingController(text: mov?.laudoInicial ?? '');
    final laudoFimCtrl = TextEditingController(text: mov?.laudoFinal ?? '');
    DateTime? dataIni = mov?.dataInicial;
    DateTime? dataFim = mov?.dataFinal;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              title: Text(mov == null ? 'Nova movimentação' : 'Editar movimentação'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: selTipo,
                        items: const [
                          DropdownMenuItem(value: 'Entrada', child: Text('Entrada')),
                          DropdownMenuItem(value: 'Saída', child: Text('Saída')),
                          DropdownMenuItem(value: 'Empréstimo', child: Text('Empréstimo')),
                        ],
                        onChanged: (v) => setModal(() => selTipo = v ?? 'Entrada'),
                        decoration: const InputDecoration(labelText: 'Tipo Movimento *'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'Descrição'),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selPais,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'País'),
                              items: _paises
                                  .map((p) => DropdownMenuItem<int>(
                                        value: p.id,
                                        child: Text(p.nome),
                                      ))
                                  .toList(),
                              onChanged: (v) async {
                                setModal(() {
                                  selPais = v;
                                  selEstado = null;
                                  selCidade = null;
                                  _estados = [];
                                  _cidades = [];
                                });
                                await _loadEstados(v);
                                setModal(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              value: selEstado,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Estado'),
                              items: _estados
                                  .map((e) => DropdownMenuItem<int>(
                                        value: e.id,
                                        child: Text(e.nome),
                                      ))
                                  .toList(),
                              onChanged: (v) async {
                                setModal(() {
                                  selEstado = v;
                                  selCidade = null;
                                  _cidades = [];
                                });
                                await _loadCidades(v);
                                setModal(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: selCidade,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Cidade'),
                        items: _cidades
                            .map((c) => DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(c.nome),
                                ))
                            .toList(),
                        onChanged: (v) => setModal(() => selCidade = v),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dataIni ?? DateTime.now(),
                                  firstDate: DateTime(1500),
                                  lastDate: DateTime(2500),
                                );
                                if (picked != null) {
                                  setModal(() => dataIni = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Data Inicial'),
                                child: Text(
                                  dataIni != null
                                      ? '${dataIni!.day.toString().padLeft(2, '0')}/${dataIni!.month.toString().padLeft(2, '0')}/${dataIni!.year}'
                                      : 'Selecionar',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: dataFim ?? DateTime.now(),
                                  firstDate: DateTime(1500),
                                  lastDate: DateTime(2500),
                                );
                                if (picked != null) {
                                  setModal(() => dataFim = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(labelText: 'Data Final'),
                                child: Text(
                                  dataFim != null
                                      ? '${dataFim!.day.toString().padLeft(2, '0')}/${dataFim!.month.toString().padLeft(2, '0')}/${dataFim!.year}'
                                      : 'Selecionar',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: valorCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Valor'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: laudoIniCtrl,
                        decoration: const InputDecoration(labelText: 'Laudo Inicial'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: laudoFimCtrl,
                        decoration: const InputDecoration(labelText: 'Laudo Final'),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final payload = {
                      'tipo_movimento': selTipo,
                      'descricao': descCtrl.text.trim(),
                      'pais_id': selPais,
                      'estado_id': selEstado,
                      'cidade_id': selCidade,
                      'data_inicial': dataIni?.toIso8601String().substring(0, 10),
                      'data_final': dataFim?.toIso8601String().substring(0, 10),
                      'valor': double.tryParse(valorCtrl.text.replaceAll(',', '.')),
                      'laudo_inicial': laudoIniCtrl.text.trim(),
                      'laudo_final': laudoFimCtrl.text.trim(),
                    };

                    try {
                      Map<String, dynamic> saved;
                      if (mov == null) {
                        saved = await ObraService.criarMovimentacao(widget.obraId!, payload);
                      } else {
                        saved = await ObraService.atualizarMovimentacao(mov.id!, payload);
                      }

                      final updated = _Movimentacao(
                        id: saved['id'] as int?,
                        tipoMovimento: (saved['tipo_movimento'] ?? '').toString(),
                        descricao: saved['descricao'] as String?,
                        paisId: saved['pais_id'] as int?,
                        estadoId: saved['estado_id'] as int?,
                        cidadeId: saved['cidade_id'] as int?,
                        dataInicial: saved['data_inicial'] != null
                            ? DateTime.tryParse(saved['data_inicial'].toString())
                            : null,
                        dataFinal: saved['data_final'] != null
                            ? DateTime.tryParse(saved['data_final'].toString())
                            : null,
                        valor: saved['valor'] != null
                            ? double.tryParse(saved['valor'].toString())
                            : null,
                        laudoInicial: saved['laudo_inicial'] as String?,
                        laudoFinal: saved['laudo_final'] as String?,
                      );

                      setState(() {
                        if (mov == null) {
                          _movimentacoes.insert(0, updated);
                        } else {
                          final idx = _movimentacoes.indexWhere((m) => m.id == mov.id);
                          if (idx != -1) {
                            _movimentacoes[idx] = updated;
                          }
                        }
                      });

                      if (context.mounted) Navigator.pop(ctx);
                    } catch (e) {
                      AppUtils.showErrorSnackBar(context, 'Erro ao salvar movimentação');
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildImagemPreview(_ObraImagem item, BoxFit fit) {
    if (item.bytes != null) {
      return Image.memory(
        item.bytes!,
        fit: fit,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    if (item.url != null && item.url!.isNotEmpty) {
      return Image.network(
        item.url!,
        fit: fit,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  Widget _buildImagemCard(int index, _ObraImagem item) {
    final angleRad = item.rotationDeg * 3.1415926535 / 180;

    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: ColoredBox(
                color: Colors.grey.shade100,
                child: Transform.rotate(
                  angle: angleRad,
                  child: _buildImagemPreview(item, BoxFit.cover),
                ),
              ),
            ),
          ),
          if (item.name != null || item.descricao != null) ...[
            const SizedBox(height: 6),
            if (item.name != null)
              Text(
                item.name!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            if (item.descricao != null && item.descricao!.trim().isNotEmpty)
              Text(
                item.descricao!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item.isPrincipal)
                const Icon(Icons.star, color: Colors.amber, size: 18),
              IconButton(
                tooltip: 'Rotacionar -90º',
                icon: const Icon(Icons.rotate_left),
                onPressed: () => setState(() {
                  item.rotationDeg = (item.rotationDeg - 90) % 360;
                }),
              ),
              IconButton(
                tooltip: 'Rotacionar +90º',
                icon: const Icon(Icons.rotate_right),
                onPressed: () => setState(() {
                  item.rotationDeg = (item.rotationDeg + 90) % 360;
                }),
              ),
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.fullscreen),
                onPressed: () => _abrirEditorImagem(index, item),
              ),
              IconButton(
                tooltip: 'Remover',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => setState(() => _imagens.removeAt(index)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarImagemPorUrl() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar imagem por URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://.../minha-imagem.jpg',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _imagens.add(_ObraImagem(url: result)));
    }
  }

  Future<void> _adicionarImagemArquivoWeb() async {
    if (!kIsWeb) {
      AppUtils.showErrorSnackBar(context, 'Disponível apenas na versão Web');
      return;
    }

    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = true;

    input.click();

    await input.onChange.first;
    final files = input.files;
    if (files == null || files.isEmpty) return;

    for (final file in files) {
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoadEnd.first;

      final result = reader.result;
      if (result is ByteBuffer) {
        final bytes = result.asUint8List();
        setState(() {
          _imagens.add(_ObraImagem(bytes: bytes, name: file.name));
        });
      }
    }
  }

  Future<void> _abrirEditorImagem(int index, _ObraImagem item) async {
    double tempRotation = item.rotationDeg;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar imagem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 320,
              height: 220,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ColoredBox(
                  color: Colors.grey.shade100,
                  child: Transform.rotate(
                    angle: tempRotation * 3.1415926535 / 180,
                    child: _buildImagemPreview(item, BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Rotação'),
                Expanded(
                  child: Slider(
                    value: tempRotation,
                    min: 0,
                    max: 360,
                    divisions: 36,
                    label: '${tempRotation.round()}º',
                    onChanged: (v) => setState(() {
                      tempRotation = v;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => item.rotationDeg = tempRotation % 360);
              Navigator.pop(ctx);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dataCompra ?? DateTime.now(),
          firstDate: DateTime(1500),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _dataCompra = date);
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Data',
          border: OutlineInputBorder(),
        ),
        child: Text(
          _dataCompra != null
              ? '${_dataCompra!.day.toString().padLeft(2, '0')}/'
                  '${_dataCompra!.month.toString().padLeft(2, '0')}/'
                  '${_dataCompra!.year}'
              : 'Selecionar',
        ),
      ),
    );
  }

  Widget _dateFieldComplementar({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1500),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          onPicked(date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value != null
              ? '${value.day.toString().padLeft(2, '0')}/'
                  '${value.month.toString().padLeft(2, '0')}/'
                  '${value.year}'
              : 'Selecionar',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quillController.dispose();
    _quillInfoController.dispose();
    _tituloController.dispose();
    _subtituloController.dispose();
    _origemController.dispose();
    _medidaController.dispose();
    _conjuntoController.dispose();
    _numeroEdicaoController.dispose();
    _qtdPaginasController.dispose();
    _volumeController.dispose();
    _resumoController.dispose();
    _numeroApoliceController.dispose();
    _valorController.dispose();
    super.dispose();
  }
}
