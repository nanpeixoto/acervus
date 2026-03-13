import 'package:flutter/material.dart';
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
  List _autores = [];
  List _estados = [];
  List _editoras = [];
  List<Autor> _sugestoesAutores = [];

  List obras = [];

  @override
  initState() {
    super.initState();
    Future.microtask(_loadFiltros);
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
      if (mounted) {
        setState(() => _loadingFiltros = false);
      }
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
          child: Text(
            getLabel(item),
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Future<void> buscar() async {
    if (_contarFiltrosPreenchidos() < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Informe pelo menos 2 filtros para gerar a lista."),
        ),
      );
      return;
    }

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

      if (!mounted) return;
    } catch (e) {
      debugPrint('Erro buscando lista resumida: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar lista: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingLista = false);
      }
    }
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

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista Resumida de Obras'),
      ),
      body: _loadingFiltros
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Center(
              child: SizedBox(
                width: 900,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          TextField(
                            controller: _tituloController,
                            decoration: const InputDecoration(
                              labelText: "Título ou Subtítulo",
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 250,
                                child: _buildDropdown(
                                  label: 'Tipo',
                                  items: _tipos,
                                  value: tipo,
                                  onChanged: (v) => setState(() => tipo = v),
                                  getId: (item) => item['id'],
                                  getLabel: (item) => item['descricao'],
                                ),
                              ),
                              SizedBox(
                                width: 250,
                                child: _buildDropdown(
                                  label: 'Subtipo',
                                  items: _subtipos,
                                  value: subtipo,
                                  onChanged: (v) => setState(() => subtipo = v),
                                  getId: (item) => item['id'],
                                  getLabel: (item) => item['descricao'],
                                ),
                              ),
                              SizedBox(
                                width: 250,
                                child: _buildDropdown(
                                  label: 'Assunto',
                                  items: _assuntos,
                                  value: assunto,
                                  onChanged: (v) => setState(() => assunto = v),
                                  getId: (item) => item['id'],
                                  getLabel: (item) => item['descricao'],
                                ),
                              ),
                              SizedBox(
                                width: 250,
                                child: _buildDropdown(
                                  label: 'Idioma',
                                  items: _idiomas,
                                  value: idioma,
                                  onChanged: (v) => setState(() => idioma = v),
                                  getId: (item) => item['id'],
                                  getLabel: (item) => item['descricao'],
                                ),
                              ),
                              SizedBox(
                                width: 250,
                                child: _buildDropdown(
                                  label: 'Material',
                                  items: _materiais,
                                  value: material,
                                  onChanged: (v) =>
                                      setState(() => material = v),
                                  getId: (item) => item['id'],
                                  getLabel: (item) => item['descricao'],
                                ),
                              ),
                              SizedBox(
                                width: 250,
                                child: _buildDropdown(
                                  label: 'Localização',
                                  items: _localizacoes,
                                  value: localizacao,
                                  onChanged: (v) =>
                                      setState(() => localizacao = v),
                                  getId: (item) => item['id'],
                                  getLabel: (item) => item['descricao'],
                                ),
                              ),
                              SizedBox(
                                width: 250,
                                child: _buildAutorAutocomplete(),
                              ),
                              SizedBox(
                                width: 250,
                                child: _buildDropdown(
                                  label: 'Estado de Conservação',
                                  items: _estados,
                                  value: estadoConservacao,
                                  onChanged: (v) =>
                                      setState(() => estadoConservacao = v),
                                  getId: (item) => item['id'],
                                  getLabel: (item) => item['descricao'],
                                ),
                              ),
                              SizedBox(
                                width: 250,
                                child: _buildDropdown(
                                  label: 'Editora',
                                  items: _editoras,
                                  value: editora,
                                  onChanged: (v) => setState(() => editora = v),
                                  getId: (item) => item['id'],
                                  getLabel: (item) => item['descricao'],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: limpar,
                                icon: const Icon(Icons.cleaning_services),
                                label: const Text("Limpar"),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: _loadingLista ? null : buscar,
                                icon: _loadingLista
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf),
                                label: Text(
                                    _loadingLista ? "Gerando..." : "Gerar PDF"),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAutorAutocomplete() {
    return Autocomplete<Autor>(
      displayStringForOption: (Autor option) => option.nome,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 3) {
          return const Iterable<Autor>.empty();
        }

        final resultados =
            await AutorService.buscarAutores(textEditingValue.text);

        return resultados;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Autor',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        );
      },
      onSelected: (Autor selection) {
        setState(() {
          autor = selection.id;
        });
      },
    );
  }
}
