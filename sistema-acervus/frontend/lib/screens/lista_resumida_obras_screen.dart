import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_estagio/models/autor.dart';
import 'package:sistema_estagio/services/autor_service.dart';
import '../services/obra_service.dart';
import 'dart:html' as html;

class ListaResumidaObrasScreen extends StatefulWidget {
  const ListaResumidaObrasScreen({super.key});

  @override
  State<ListaResumidaObrasScreen> createState() =>
      _ListaResumidaObrasScreenState();
}

class _ListaResumidaObrasScreenState extends State<ListaResumidaObrasScreen> {
  final _tituloController = TextEditingController();

  int? tipo;
  int? subtipo;
  int? assunto;
  int? idioma;
  int? material;
  int? localizacao;
  int? autor;
  int? estadoConservacao;
  int? editora;

  bool _loadingFiltros = false;
  bool _loadingLista = false;

  List _tipos = [];
  List _subtipos = [];
  List _assuntos = [];
  List _idiomas = [];
  List _materiais = [];
  List _localizacoes = [];
  List _estados = [];
  List _editoras = [];

  List obras = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadFiltros);
  }

  // 🔥 ADICIONE ISSO DENTRO DA CLASSE
  final Map<String, ScrollController> _controllers = {};

  void _scroll(String key, double offset) {
    final controller = _controllers[key];
    if (controller == null || !controller.hasClients) return;

    final destino = (controller.offset + offset).clamp(
      0.0,
      controller.position.maxScrollExtent,
    );

    controller.animateTo(
      destino,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Future<void> _loadFiltros() async {
    setState(() => _loadingFiltros = true);

    try {
      final data = await ObraService.carregarFiltros();

      if (!mounted) return;

      setState(() {
        _tipos = data['tipos'];
        _subtipos = data['subtipos'];
        _assuntos = data['assuntos'];
        _idiomas = data['idiomas'];
        _materiais = data['materiais'];
        _localizacoes = data['localizacoes'];
        _estados = data['estados'];
        _editoras = data['editoras'];
      });
    } finally {
      if (mounted) setState(() => _loadingFiltros = false);
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required List<T> items,
    required int? value,
    required ValueChanged<int?> onChanged,
    required int Function(T item) getId,
    required String Function(T item) getLabel,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      items: items.map((item) {
        return DropdownMenuItem<int>(
          value: getId(item),
          child: Text(getLabel(item), overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  int _contarFiltrosPreenchidos() {
    int count = 0;
    if (_tituloController.text.trim().isNotEmpty) count++;
    if (tipo != null) count++;
    if (subtipo != null) count++;
    if (assunto != null) count++;
    if (idioma != null) count++;
    if (material != null) count++;
    if (localizacao != null) count++;
    if (autor != null) count++;
    if (estadoConservacao != null) count++;
    if (editora != null) count++;
    return count;
  }

  void limpar() {
    setState(() {
      _tituloController.clear();
      tipo = null;
      subtipo = null;
      assunto = null;
      idioma = null;
      material = null;
      localizacao = null;
      autor = null;
      estadoConservacao = null;
      editora = null;
      obras = [];
    });
  }

  Future<void> buscar() async {
    /*if (_contarFiltrosPreenchidos() < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Informe pelo menos 2 filtros para gerar a lista.")),
      );
      return;
    }*/

    setState(() => _loadingLista = true);

    try {
      final pdf = await ObraService.listaResumida(
        titulo: _tituloController.text.trim(),
        autor: autor,
        material: material,
        tipo: tipo,
        subtipo: subtipo,
        editora: editora,
        conservacao: estadoConservacao,
        localizacao: localizacao,
        assunto: assunto,
        idioma: idioma,
      );

      final blob = html.Blob([pdf]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      html.AnchorElement(href: url)
        ..setAttribute("download", "lista_obras.pdf")
        ..click();
    } finally {
      if (mounted) setState(() => _loadingLista = false);
    }
  }

  Future<void> visualizar() async {
    setState(() => _loadingLista = true);

    try {
      final lista = await ObraService.buscarListaVisual(
        titulo: _tituloController.text.trim(),
        autor: autor,
        material: material,
        tipo: tipo,
        subtipo: subtipo,
        editora: editora,
        conservacao: estadoConservacao,
        localizacao: localizacao,
        assunto: assunto,
        idioma: idioma,
      );

      setState(() {
        obras = lista;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar obras: $e')),
      );
    } finally {
      setState(() => _loadingLista = false);
    }
  }

  Widget _buildAreaResultado() {
    return Container(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _loadingLista
            ? const Center(child: CircularProgressIndicator())
            : obras.isEmpty
                ? const Center(
                    child: Text(
                      "Nenhum resultado ainda",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _buildGridObras(),
      ),
    );
  }

  Widget _buildGridObras() {
    final Map<String, List<dynamic>> agrupado = {};

    for (var obra in obras) {
      final assunto = obra['assunto'] ?? 'Outros';
      agrupado.putIfAbsent(assunto, () => []);
      agrupado[assunto]!.add(obra);
    }

    final assuntos = agrupado.keys.toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: assuntos.length,
      itemBuilder: (context, index) {
        final assunto = assuntos[index];
        final lista = agrupado[assunto]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Text(
                assunto,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 220,
              child: Builder(
                builder: (context) {
                  final controller = _controllers.putIfAbsent(
                    assunto,
                    () => ScrollController(),
                  );

                  return Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: ListView.builder(
                          controller: controller,
                          scrollDirection: Axis.horizontal,
                          itemCount: lista.length,
                          itemBuilder: (_, i) {
                            final obra = lista[i];
                            final capa = obra['capa_url'];

                            return Container(
                              width: 140,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              child: InkWell(
                                onTap: () => _abrirObra(obra),
                                child: Card(
                                  elevation: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: capa != null
                                            ? Image.network(
                                                "${ObraService.baseUrl}$capa",
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (_, __, ___) =>
                                                    _semImagem(),
                                              )
                                            : _semImagem(),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              obra['titulo'] ?? '',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              obra['autor'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _arrowButton(
                            icon: Icons.chevron_left,
                            onTap: () => _scroll(assunto, -320),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _arrowButton(
                            icon: Icons.chevron_right,
                            onTap: () => _scroll(assunto, 320),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Widget _buildCardObra(dynamic obra) {
    final capa = obra['capa_url'];

    return Card(
      elevation: 2,
      child: Column(
        children: [
          Expanded(
            child: capa != null
                ? Image.network(
                    "${ObraService.baseUrl}$capa",
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _semImagem(),
                  )
                : _semImagem(),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Text(
                  obra['titulo'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  obra['autor'] ?? '',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _semImagem() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported),
    );
  }

  Widget _buildAutorAutocomplete() {
    return Autocomplete<Autor>(
      displayStringForOption: (Autor option) => option.nome,
      optionsBuilder: (text) async {
        if (text.text.length < 3) return [];
        return await AutorService.buscarAutores(text.text);
      },
      fieldViewBuilder: (context, controller, focusNode, _) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Autor',
            border: OutlineInputBorder(),
          ),
        );
      },
      onSelected: (Autor a) => autor = a.id,
    );
  }

  // 🔥 SOMENTE A PARTE DO BUILD FOI AJUSTADA

  void _abrirObra(dynamic obra) {
    final id = obra['cd_obra'];

    context.push('/admin/obras/editar/$id');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista Resumida de Obras'),
      ),
      body: _loadingFiltros
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 TÍTULO
                            const Row(
                              children: [
                                Icon(Icons.picture_as_pdf, size: 28),
                                SizedBox(width: 10),
                                Text(
                                  "Lista Resumida de Obras",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // 🔹 BUSCA
                            TextField(
                              controller: _tituloController,
                              decoration: const InputDecoration(
                                labelText:
                                    "Trecho do Título, Subtítulo, Autor, Editora ou Assunto",
                                border: OutlineInputBorder(),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 🔹 TODOS OS FILTROS (mantidos!)
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _box(
                                    _buildDropdown(
                                        label: 'Tipo',
                                        items: _tipos,
                                        value: tipo,
                                        onChanged: (v) =>
                                            setState(() => tipo = v),
                                        getId: (i) => i['id'],
                                        getLabel: (i) => i['descricao']),
                                    isMobile),
                                _box(
                                    _buildDropdown(
                                      label: 'Subtipo',
                                      items: _subtipos,
                                      value: subtipo,
                                      onChanged: (v) =>
                                          setState(() => subtipo = v),
                                      getId: (i) => i['id'],
                                      getLabel: (i) => i['descricao'],
                                    ),
                                    isMobile),
                                _box(
                                    _buildDropdown(
                                      label: 'Assunto',
                                      items: _assuntos,
                                      value: assunto,
                                      onChanged: (v) =>
                                          setState(() => assunto = v),
                                      getId: (i) => i['id'],
                                      getLabel: (i) => i['descricao'],
                                    ),
                                    isMobile),
                                _box(
                                    _buildDropdown(
                                      label: 'Idioma',
                                      items: _idiomas,
                                      value: idioma,
                                      onChanged: (v) =>
                                          setState(() => idioma = v),
                                      getId: (i) => i['id'],
                                      getLabel: (i) => i['descricao'],
                                    ),
                                    isMobile),
                                _box(
                                    _buildDropdown(
                                      label: 'Material',
                                      items: _materiais,
                                      value: material,
                                      onChanged: (v) =>
                                          setState(() => material = v),
                                      getId: (i) => i['id'],
                                      getLabel: (i) => i['descricao'],
                                    ),
                                    isMobile),
                                _box(
                                    _buildDropdown(
                                      label: 'Localização',
                                      items: _localizacoes,
                                      value: localizacao,
                                      onChanged: (v) =>
                                          setState(() => localizacao = v),
                                      getId: (i) => i['id'],
                                      getLabel: (i) => i['descricao'],
                                    ),
                                    isMobile),
                                _box(_buildAutorAutocomplete(), isMobile),
                                _box(
                                    _buildDropdown(
                                      label: 'Estado de Conservação',
                                      items: _estados,
                                      value: estadoConservacao,
                                      onChanged: (v) =>
                                          setState(() => estadoConservacao = v),
                                      getId: (i) => i['id'],
                                      getLabel: (i) => i['descricao'],
                                    ),
                                    isMobile),
                                _box(
                                    _buildDropdown(
                                      label: 'Editora',
                                      items: _editoras,
                                      value: editora,
                                      onChanged: (v) =>
                                          setState(() => editora = v),
                                      getId: (i) => i['id'],
                                      getLabel: (i) => i['descricao'],
                                    ),
                                    isMobile),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // 🔹 BOTÕES
                            Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: limpar,
                                  icon: const Icon(Icons.cleaning_services),
                                  label: const Text("Limpar"),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: _loadingLista ? null : buscar,
                                  icon: const Icon(Icons.picture_as_pdf),
                                  label: const Text("Gerar PDF"),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: visualizar,
                                  icon: const Icon(Icons.visibility),
                                  label: const Text("Visualizar"),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // 🔥 ÁREA FIXA DE RESULTADO
                            _buildAreaResultado(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

// 🔹 helper pra manter largura padrão
  Widget _box(Widget child, bool isMobile) {
    return SizedBox(
      width: isMobile ? double.infinity : 250,
      child: child,
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _tituloController.dispose();
    super.dispose();
  }
}
