import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/_auxiliares/cidade.dart';
import 'package:sistema_estagio/models/_auxiliares/estado.dart';
import 'package:sistema_estagio/models/_auxiliares/pais.dart';
import 'package:sistema_estagio/services/_auxiliares/cidade_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/estado_service.dar.dart';
import 'package:sistema_estagio/services/_auxiliares/pais_service.dar.dart';
import 'package:sistema_estagio/services/obra_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';

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
}

class MovimentacoesScreen extends StatefulWidget {
  final int? obraId;
  final String? obraTitulo;

  const MovimentacoesScreen({super.key,required this.obraId, this.obraTitulo});

  @override
  State<MovimentacoesScreen> createState() => _MovimentacoesScreenState();
}

class _MovimentacoesScreenState extends State<MovimentacoesScreen> {
  final List<_Movimentacao> _movimentacoes = [];
  bool _loading = false;

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
    _loadPaises();
    _loadMovimentacoes();
  }

  Future<void> _loadMovimentacoes() async {
    if (widget.obraId == null) return;
    setState(() => _loading = true);
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
          valor: m['valor'] != null ? double.tryParse(m['valor'].toString()) : null,
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
      if (mounted) setState(() => _loading = false);
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

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Widget _buildMovimentacaoCard(_Movimentacao mov) {
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
            Text('Datas: ${_formatDate(mov.dataInicial)} - ${_formatDate(mov.dataFinal)}'),
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
                    if (widget.obraId == null) {
                      AppUtils.showErrorSnackBar(context, 'ID da obra não disponível');
                      return;
                    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.obraTitulo ?? 'Movimentações da Obra'),
      ),
      body: Padding(
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
            if (_loading || _loadingPaises) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 3),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _movimentacoes.isEmpty
                  ? const Text(
                      'Nenhuma movimentação cadastrada.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : ListView(
                      children: _movimentacoes
                          .map((m) => _buildMovimentacaoCard(m))
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
