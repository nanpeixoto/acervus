// lib/widgets/celula_taxa_editavel.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CelulaTaxaEditavel extends StatefulWidget {
  final String? valor;
  final bool confirmada;
  final String tooltipTexto;
  final Function(String novoValor, String motivo)? onSalvar;
  final Color? corTexto;
  final bool centralizado;

  const CelulaTaxaEditavel({
    super.key,
    this.valor,
    required this.confirmada,
    required this.tooltipTexto,
    this.onSalvar,
    this.corTexto,
    this.centralizado = true,
  });

  @override
  State<CelulaTaxaEditavel> createState() => _CelulaTaxaEditavelState();
}

class _CelulaTaxaEditavelState extends State<CelulaTaxaEditavel> {
  bool _editando = false;
  late TextEditingController _valorController;
  late TextEditingController _motivoController;
  final FocusNode _valorFocusNode = FocusNode();
  final FocusNode _motivoFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController(text: widget.valor ?? '0,00');
    _motivoController = TextEditingController();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _motivoController.dispose();
    _valorFocusNode.dispose();
    _motivoFocusNode.dispose();
    super.dispose();
  }

  String _valorInicial() {
    return widget.valor?.replaceAll('R\$ ', '').trim() ?? '0,00';
  }

  Future<void> _iniciarEdicao(BuildContext context) async {
    if (widget.confirmada || widget.onSalvar == null || !mounted) return;

    final valorCtrl = TextEditingController(text: _valorInicial());
    final motivoCtrl = TextEditingController();

    final resultado = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Editar valor da taxa',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campos do formulário
            TextFormField(
              controller: valorCtrl,
              decoration: const InputDecoration(
                labelText: 'Novo Valor',
                prefixText: 'R\$ ',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: motivoCtrl,
              decoration: const InputDecoration(
                labelText: 'Motivo da Alteração',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Botões
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final valorText = valorCtrl.text.trim();
                      final motivoText = motivoCtrl.text.trim();

                      // Normaliza pt-BR -> double
                      final normalizado =
                          valorText.replaceAll('.', '').replaceAll(',', '.');

                      final valor = double.tryParse(normalizado);

                      if (valor == null || valor < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Informe um valor válido.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (motivoText.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Informe o motivo da alteração.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context, {
                        'valor': valor.toStringAsFixed(2),
                        'motivo': motivoText,
                      });
                    },
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (resultado != null && mounted && widget.onSalvar != null) {
      widget.onSalvar!(resultado['valor']!, resultado['motivo']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editando) {
      return _buildModoEdicao();
    }

    return _buildModoVisualizacao();
  }

  Widget _buildModoVisualizacao() {
    return Tooltip(
      message: widget.tooltipTexto,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: () => _iniciarEdicao(context),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          alignment:
              widget.centralizado ? Alignment.center : Alignment.centerLeft,
          decoration: widget.confirmada
              ? null
              : BoxDecoration(
                  border: Border.all(color: Colors.transparent),
                  borderRadius: BorderRadius.circular(4),
                ),
          child: MouseRegion(
            cursor: widget.confirmada
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: Text(
              widget.valor ?? '-',
              style: TextStyle(
                fontSize: 12,
                color: widget.corTexto ?? Colors.black87,
                fontWeight:
                    widget.confirmada ? FontWeight.normal : FontWeight.w500,
              ),
              textAlign:
                  widget.centralizado ? TextAlign.center : TextAlign.left,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModoEdicao() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Campo de valor
          TextField(
            controller: _valorController,
            focusNode: _valorFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(),
              labelText: 'Valor',
              prefixText: 'R\$ ',
            ),
            style: const TextStyle(fontSize: 12),
            onSubmitted: (_) {
              // Ao pressionar Enter no valor, foca no motivo
              if (_motivoController.text.trim().isEmpty) {
                _motivoFocusNode.requestFocus();
              } else {
                _salvar();
              }
            },
          ),
          const SizedBox(height: 4),
          // Campo de motivo
          TextField(
            controller: _motivoController,
            focusNode: _motivoFocusNode,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(),
              labelText: 'Motivo',
              hintText: 'Digite o motivo da alteração',
            ),
            style: const TextStyle(fontSize: 11),
            maxLines: 2,
            minLines: 1,
            onSubmitted: (_) => _salvar(),
          ),
          const SizedBox(height: 4),
          // Botões de ação
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelarEdicao,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(50, 24),
                ),
                child: const Text('Esc', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(50, 24),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Enter', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _salvar() {
    final valorText =
        _valorController.text.replaceAll('.', '').replaceAll(',', '.');
    final motivoText = _motivoController.text.trim();

    final valorNumerico = double.tryParse(valorText);

    if (valorNumerico == null || valorNumerico < 0) {
      // Você pode mostrar um erro usando um SnackBar ou outro método
      return;
    }
    if (motivoText.isEmpty) {
      // Você pode mostrar um erro usando um SnackBar ou outro método
      return;
    }

    if (widget.onSalvar != null) {
      widget.onSalvar!(valorNumerico.toStringAsFixed(2), motivoText);
    }
    setState(() {
      _editando = false;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _editando = false;
    });
  }
}

// Widget para Checkmark de confirmação com tooltip
class CheckmarkConfirmacao extends StatelessWidget {
  final bool confirmada;
  final String tooltipTexto;
  final VoidCallback? onToggle;

  const CheckmarkConfirmacao({
    super.key,
    required this.confirmada,
    required this.tooltipTexto,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipTexto,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          child: Icon(
            confirmada ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: confirmada ? Colors.green[700] : Colors.red[700],
          ),
        ),
      ),
    );
  }
}

// Widget para célula de data com tooltip
class CelulaDataComTooltip extends StatelessWidget {
  final String dataFormatada;
  final String tooltipTexto;
  final bool centralizado;

  const CelulaDataComTooltip({
    super.key,
    required this.dataFormatada,
    required this.tooltipTexto,
    this.centralizado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipTexto,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        alignment: centralizado ? Alignment.center : Alignment.centerLeft,
        child: SelectableText(
          dataFormatada,
          style: const TextStyle(fontSize: 12),
          textAlign: centralizado ? TextAlign.center : TextAlign.left,
        ),
      ),
    );
  }
}
