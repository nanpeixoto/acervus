import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/estante.dart';
import 'package:sistema_estagio/models/prateleira.dart';
import 'package:sistema_estagio/models/prateleiraForm.dart';
import 'package:sistema_estagio/models/pais.dart';
import 'package:sistema_estagio/models/estado.dart';
import 'package:sistema_estagio/models/cidade.dart';
import 'package:sistema_estagio/models/sala_obra.dart';

import 'package:sistema_estagio/services/estante_service.dart';
import 'package:sistema_estagio/services/pais_service.dart';
import 'package:sistema_estagio/services/estado_service.dart';
import 'package:sistema_estagio/services/cidade_service.dart';
import 'package:sistema_estagio/services/sala_service.dar.dart';
import 'package:sistema_estagio/utils/app_config.dart';

import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';

import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/widgets/crud_page.dart';
import 'package:sistema_estagio/widgets/crud_header.dart';
import 'package:sistema_estagio/widgets/crud_form_container.dart';
import 'package:sistema_estagio/widgets/crud_pagination.dart';

class EstanteScreen extends StatefulWidget {
  const EstanteScreen({super.key});

  @override
  State<EstanteScreen> createState() => _EstanteScreenState();
}

class _EstanteScreenState extends State<EstanteScreen> {
  final _searchController = TextEditingController();

  List<Estante> _estantes = [];

  bool _isLoading = false;
  bool _showForm = false;

  List<Pais> _paises = [];
  List<Estado> _estados = [];
  List<Cidade> _cidades = [];
  List<Sala> _salas = [];

  List<Sala> _salasFiltro = [];
  List<Sala> _salasFormulario = [];

  Sala? _salaFiltro;
  Pais? _pais;
  Estado? _estado;
  Cidade? _cidade;
  Sala? _sala;

  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';

  final _formKey = GlobalKey<FormState>();

  Estante? _editando;

  final _descricaoController = TextEditingController();
  final List<PrateleiraForm> _prateleiras = [];

  @override
  void initState() {
    super.initState();
    _loadPaises();
    _loadLista();
    _loadTodasSalas();
  }

  // ========================
  // LOADERS
  // ========================

  Future<void> _loadPaises() async {
    final r = await PaisService.listar(page: 1, limit: 999, ativo: true);
    setState(() => _paises = List<Pais>.from(r['paises'] ?? []));
  }

  Future<void> _loadTodasSalas() async {
    final r = await SalaService.listar(page: 1, limit: 999);

    setState(() {
      _salasFiltro = List<Sala>.from(r['Salas'] ?? []);
    });
  }

  Future<void> _loadEstados(int paisId) async {
    final r = await EstadoService.listarPorPais(paisId);
    setState(() {
      _estados = List<Estado>.from(r);
      _estado = null;
      _cidade = null;
      _salas = [];
    });
  }

  Future<void> _loadCidades(int estadoId) async {
    final r = await CidadeService.listarPorEstado(estadoId);
    setState(() {
      _cidades = List<Cidade>.from(r);
      _cidade = null;
      _salas = [];
    });
  }

  Future<void> _loadSalas(int cidadeId) async {
    final r = await SalaService.listarPorCidade(cidadeId);
    setState(() => _salasFormulario = r);
  }

  // ========================
  // LISTA
  // ========================

  Future<void> _loadLista() async {
    setState(() => _isLoading = true);

    try {
      final result = await EstanteService.listar(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        salaId: _salaFiltro?.id,
      );

      setState(() {
        _estantes = result['Estantes'];
        _pagination = result['pagination'];
      });
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao carregar estantes');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ========================
  // BUILD
  // ========================

  @override
  Widget build(BuildContext context) {
    return CrudPage(
      title: "Estantes",
      isLoading: _isLoading,
      onAdd: _novo,
      header: _buildHeader(),
      form: _showForm
          ? SizedBox(
              height: MediaQuery.of(context).size.height * 0.70,
              child: CrudFormContainer(
                child: _buildFormulario(),
              ),
            )
          : null,
      list: _buildList(),
      pagination: CrudPagination(
        currentPage: _currentPage,
        totalPages: _pagination?['totalPages'] ?? 1,
        onPageChange: _go,
      ),
    );
  }

  // ========================
  // HEADER
  // ========================

  Widget _buildHeader() {
    return CrudHeader(
      stats: Row(
        children: [
          Expanded(
            child: _statCard(
              "Total",
              (_pagination?['totalItems'] ?? _estantes.length).toString(),
              Icons.storage,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _statCard(
              "Páginas",
              (_pagination?['totalPages'] ?? 0).toString(),
              Icons.layers,
              Colors.blue,
            ),
          ),
        ],
      ),
      search: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<Sala?>(
            value: _salaFiltro,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sala',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<Sala?>(
                value: null,
                child: Text('Todas as salas'),
              ),
              ..._salasFiltro.map((s) {
                return DropdownMenuItem<Sala?>(
                  value: s,
                  child: Text(
                    s.descricao,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (v) {
              setState(() {
                _salaFiltro = v;
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: "Buscar estante",
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _search,
                  child: const Text("Buscar"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================
  // FORM
  // ========================

  Widget _buildFormulario() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            CustomTextField(
              controller: _descricaoController,
              label: "Descrição",
              validator: (v) => Validators.validateRequired(v, "Descrição"),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Pais>(
              value: _pais,
              items: _paises
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(p.nome),
                      ))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _pais = v);
                await _loadEstados(v.id!);
              },
              decoration: const InputDecoration(
                labelText: "País",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Estado>(
              value: _estado,
              items: _estados
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.nome),
                      ))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _estado = v);
                await _loadCidades(v.id!);
              },
              decoration: const InputDecoration(
                labelText: "Estado",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Cidade>(
              value: _cidade,
              items: _cidades
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.nome),
                      ))
                  .toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _cidade = v);
                await _loadSalas(v.id!);
              },
              decoration: const InputDecoration(
                labelText: "Cidade",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Sala>(
              value: _sala,
              items: _salasFormulario
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.descricao),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _sala = v),
              decoration: const InputDecoration(
                labelText: "Sala",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            _listaPrateleiras(),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _cancelar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text("Cancelar"),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _salvar,
                  child: Text(_editando == null ? "Salvar" : "Atualizar"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _listaPrateleiras() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Prateleiras",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _prateleiras.length,
          itemBuilder: (_, i) {
            final p = _prateleiras[i];

            return Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: p.controller,
                    label: "Descrição da Prateleira",
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() => _prateleiras.removeAt(i));
                  },
                )
              ],
            );
          },
        ),
        TextButton.icon(
          onPressed: () {
            setState(() => _prateleiras.add(PrateleiraForm(descricao: "")));
          },
          icon: const Icon(Icons.add),
          label: const Text("Adicionar prateleira"),
        )
      ],
    );
  }

  // ========================
  // LISTA
  // ========================
  Widget _buildList() {
    if (_estantes.isEmpty) {
      return const Center(child: Text('Nenhuma estante cadastrada'));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _estantes.length,
      itemBuilder: (_, i) {
        final e = _estantes[i];

        // LOCALIZAÇÃO (usando seu model correto)
        final localizacao = [
          e.sala_descricao,
          e.estado_descricao,
          e.cidade_descricao,
        ].whereType<String>().where((v) => v.isNotEmpty).join(' • ');

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              // ÍCONE PADRÃO
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal.withOpacity(0.1),
                child: const Icon(
                  Icons.storage,
                  color: Colors.teal,
                  size: 18,
                ),
              ),

              const SizedBox(width: 12),

              // CONTEÚDO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TÍTULO
                    Text(
                      e.descricao,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // META INFO
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _statusMeta(true), // ajuste se tiver campo ativo
                        _metaText('ID ${e.id}'),

                        if (localizacao.isNotEmpty) _metaText(localizacao),

                        _metaText('${e.totalPrateleiras} prateleiras'),
                      ],
                    ),
                  ],
                ),
              ),

              // MENU
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'editar') {
                    _editar(e.id!);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'editar',
                    child: Text('Editar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusMeta(bool ativo) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: ativo ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          ativo ? 'Ativo' : 'Inativo',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _metaText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[500],
      ),
    );
  }
  // ========================
  // ACTIONS
  // ========================

  void _novo() {
    _descricaoController.clear();
    _prateleiras.clear();

    setState(() {
      _editando = null;
      _showForm = true;
    });
  }

  Future<void> _editar(int id) async {
    final estante = await EstanteService.buscarPorId(id);

    _descricaoController.text = estante.descricao;

    // ===== PRATELEIRAS =====
    _prateleiras.clear();

    for (final p in estante.prateleiras) {
      _prateleiras.add(PrateleiraForm(
        id: p.id,
        descricao: p.descricao,
      ));
    }

    // ===== PAÍS =====
    _pais = _paises.firstWhere(
      (p) => p.id == estante.paisId,
    );

    // ===== ESTADOS =====
    await _loadEstados(estante.paisId);

    _estado = _estados.firstWhere(
      (e) => e.id == estante.estadoId,
    );

    // ===== CIDADES =====
    await _loadCidades(estante.estadoId);

    _cidade = _cidades.firstWhere(
      (c) => c.id == estante.cidadeId,
    );

    // ===== SALAS =====
    await _loadSalas(estante.cidadeId);

    final salaEncontrada = _salasFormulario.where(
      (s) => s.id == estante.cdSala,
    );

    if (salaEncontrada.isNotEmpty) {
      _sala = salaEncontrada.first;
    }

    setState(() {
      _editando = estante;
      _showForm = true;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final estante = Estante(
        id: _editando?.id,
        descricao: _descricaoController.text,
        paisId: _pais!.id!,
        estadoId: _estado!.id!,
        cidadeId: _cidade!.id!,
        cdSala: _sala!.id!,
        prateleiras: _prateleiras
            .map((p) => Prateleira(
                  id: p.id,
                  descricao: p.controller.text,
                  estante: _descricaoController.text,
                ))
            .toList(),
      );

      if (_editando == null) {
        await EstanteService.criar(estante);
      } else {
        await EstanteService.atualizar(_editando!.id!, estante);
      }

      await _loadLista();

      if (mounted) {
        setState(() {
          _showForm = false;
          _editando = null;
        });
      }

      AppUtils.showSuccessSnackBar(
        context,
        'Estante salva com sucesso!',
      );
    } catch (e) {
      AppUtils.showErrorSnackBar(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void _cancelar() {
    setState(() {
      _showForm = false;
      _editando = null;
    });
  }

  void _search() {
    _currentSearch = _searchController.text;
    _currentPage = 1;
    _loadLista();
  }

  void _go(int page) {
    _currentPage = page;
    _loadLista();
  }

  Widget _statCard(String t, String v, IconData i, Color c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(i, color: c),
          const SizedBox(height: 4),
          Text(v, style: TextStyle(fontSize: 20, color: c)),
          Text(t),
        ],
      ),
    );
  }
}
