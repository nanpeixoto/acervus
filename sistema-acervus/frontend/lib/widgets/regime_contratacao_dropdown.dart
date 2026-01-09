import 'package:flutter/material.dart';
import '../models/_pessoas/candidato/regime_contratacao.dart';
import '../services/_pessoas/candidato/candidato_service.dart';

class RegimeContratacaoDropdown extends StatefulWidget {
  final int? selectedId; // ID selecionado
  final String? selectedDescricao; // Descrição selecionada
  final Function(int? id, String? descricao)? onChanged;
  final String? label;
  final String? hint;
  final bool isRequired;
  final String? Function(String?)? validator;

  const RegimeContratacaoDropdown({
    super.key,
    this.selectedId,
    this.selectedDescricao,
    this.onChanged,
    this.label,
    this.hint,
    this.isRequired = false,
    this.validator,
  });

  @override
  State<RegimeContratacaoDropdown> createState() =>
      _RegimeContratacaoDropdownState();
}

class _RegimeContratacaoDropdownState extends State<RegimeContratacaoDropdown> {
  List<RegimeContratacao> _regimes = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedDescricao;

  @override
  void initState() {
    super.initState();
    _selectedDescricao = widget.selectedDescricao;
    _loadRegimes();
  }

  Future<void> _loadRegimes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final regimes = await CandidatoService.buscarRegimeContratacao();
      final List<RegimeContratacao> regimeList =
          regimes.cast<RegimeContratacao>();
      setState(() {
        _regimes = regimeList;
        _isLoading = false;

        // Se foi passado um ID inicial, encontra a descrição correspondente
        if (widget.selectedId != null && _selectedDescricao == null) {
          final regime = regimeList.firstWhere(
            (r) => r.id == widget.selectedId,
            orElse: () => RegimeContratacao(id: 0, descricao: ''),
          );
          if (regime.id != 0) {
            _selectedDescricao = regime.descricao;
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              if (widget.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _buildDropdown(),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Erro: $_error',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
              IconButton(
                onPressed: _loadRegimes,
                icon: const Icon(Icons.refresh, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Carregando regimes...'),
          ],
        ),
      );
    }

    if (_error != null || _regimes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            const Icon(Icons.error, color: Colors.red, size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('Erro ao carregar regimes')),
            IconButton(
              onPressed: _loadRegimes,
              icon: const Icon(Icons.refresh, size: 16),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedDescricao,
      decoration: InputDecoration(
        hintText: widget.hint ?? 'Selecione um regime',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: _regimes.map((regime) {
        return DropdownMenuItem<String>(
          value: regime.descricao,
          child: Text(regime.descricao),
        );
      }).toList(),
      onChanged: (descricao) {
        setState(() {
          _selectedDescricao = descricao;
        });

        // Encontra o ID correspondente
        int? selectedId;
        if (descricao != null) {
          final regime = _regimes.firstWhere(
            (r) => r.descricao == descricao,
            orElse: () => RegimeContratacao(id: 0, descricao: ''),
          );
          selectedId = regime.id != 0 ? regime.id : null;
        }

        // Chama o callback com ID e descrição
        widget.onChanged?.call(selectedId, descricao);

        // Debug
        print('Regime selecionado: $descricao (ID: $selectedId)');
      },
      validator: widget.validator ??
          (widget.isRequired
              ? (value) =>
                  value == null || value.isEmpty ? 'Campo obrigatório' : null
              : null),
    );
  }
}
