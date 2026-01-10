import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_estagio/models/_auxiliares/assunto.dart';
import 'package:sistema_estagio/models/_auxiliares/autor.dart';
import 'package:sistema_estagio/models/_auxiliares/editora.dart';
import 'package:sistema_estagio/models/_auxiliares/estado_conservacao.dart';
import 'package:sistema_estagio/models/_auxiliares/material.dart';
import 'package:sistema_estagio/models/_auxiliares/subtipo_obra.dart';
import 'package:sistema_estagio/models/_pessoas/formacao/idioma.dart';
import 'package:sistema_estagio/services/_auxiliares/assunto_service.dart';
import 'package:sistema_estagio/services/_auxiliares/autor_service.dart';
import 'package:sistema_estagio/services/_auxiliares/editora_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/estado_conservacao_service.dart';
import 'package:sistema_estagio/services/_auxiliares/material_service.dart';
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

  DateTime? _dataCompra;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);

    _carregarTiposObra();

    _loadAssuntos();

    _loadIdiomas();

    _loadMateriais();

    _loadEstadosConservacao();

    _loadEditoras();

    _loadAutores();

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
        _estadosConservacao = List<EstadoConservacao>.from(result['estados'] ?? []);

        // segurança: evita value fora da lista
        if (cdEstadoConservacao != null && !_estadosConservacao.any((e) => e.id == cdEstadoConservacao)) {
          cdEstadoConservacao = null;
        }
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar estados de conservação');
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
      'data_compra': _dataCompra?.toIso8601String().substring(0, 10),
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
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvar,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cadastro'),
          ],
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAbaCadastro(),
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
      validator: (v) => v == null ? 'Estado de Conservação é obrigatório' : null,
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

  @override
  void dispose() {
    _tabController.dispose();
    _tituloController.dispose();
    _subtituloController.dispose();
    _origemController.dispose();
    _medidaController.dispose();
    _conjuntoController.dispose();
    _numeroEdicaoController.dispose();
    _qtdPaginasController.dispose();
    _volumeController.dispose();
    super.dispose();
  }
}
