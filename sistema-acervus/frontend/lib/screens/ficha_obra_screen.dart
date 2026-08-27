import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_estagio/services/obra_service.dart';
import 'package:sistema_estagio/theme/acervus_colors.dart';

class FichaObraScreen extends StatefulWidget {
  final int obraId;

  const FichaObraScreen({super.key, required this.obraId});

  @override
  State<FichaObraScreen> createState() => _FichaObraScreenState();
}

class _FichaObraScreenState extends State<FichaObraScreen> {
  Map<String, dynamic>? _ficha;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarFicha();
  }

  Future<void> _carregarFicha() async {
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final dados = await ObraService.buscarFichaRelatorio(widget.obraId);

      if (!mounted) return;
      setState(() => _ficha = dados);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = 'Erro ao carregar a ficha: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AcervusColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erro != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    _erro!,
                    style: const TextStyle(color: AcervusColors.danger),
                  ),
                ),
              )
            else if (_ficha != null)
              _buildFicha(_ficha!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titulo = _ficha?['titulo'] as String?;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AcervusColors.textPrimary),
          tooltip: 'Voltar',
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ficha da Obra',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AcervusColors.textPrimary,
                ),
              ),
              if (titulo != null && titulo.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AcervusColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          tooltip: 'Recarregar',
          icon: const Icon(Icons.refresh, color: AcervusColors.textSecondary),
          onPressed: _carregarFicha,
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => ObraService.baixarFichaPdf(widget.obraId),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: const Text('Baixar PDF'),
        ),
      ],
    );
  }

  Widget _buildFicha(Map<String, dynamic> f) {
    final capa = f['imagem_capa'];
    final capaUrl = capa != null && capa.toString().isNotEmpty
        ? '${ObraService.baseUrl}/uploads/obras/${widget.obraId}/$capa'
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AcervusColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AcervusColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                (f['carimbo'] ?? '').toString(),
                style: const TextStyle(
                  color: AcervusColors.textMuted,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                '${f['cd_obra'] ?? ''}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AcervusColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Column(
              children: [
                Text(
                  f['titulo'] ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if ((f['subtitulo'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      f['subtitulo'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AcervusColors.textSecondary,
                      ),
                    ),
                  ),
                if ((f['autor'] ?? '').toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      f['autor'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AcervusColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _sectionTitle('Dados da Obra'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dado('Tipo de Obra', f['tipo_obra']),
                    _dado('Subtipo de Obra', f['subtipo_obra']),
                    _dado('Assunto', f['assunto']),
                    _dado('Idioma', f['idioma']),
                    _dado('Localização', f['ds_localizacao']),
                    _dado('Editora', f['editora']),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dado('Conservação', f['conservacao']),
                    _dado('Medida', f['medida']),
                    _dado('Origem', f['origem']),
                    _dado('Nº Edição', f['numero_edicao']),
                    _dado('Volume', f['volume']),
                    _dado('Qtd Páginas', f['qtd_paginas']),
                  ],
                ),
              ),
              if (capaUrl != null) ...[
                const SizedBox(width: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    capaUrl,
                    width: 120,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 160,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('Autor'),
          const SizedBox(height: 12),
          _dado('Autor', f['autor']),
          const SizedBox(height: 20),
          _sectionTitle('Resumo'),
          const SizedBox(height: 12),
          Text(
            (f['resumo'] ?? '').toString(),
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Informações Complementares'),
          const SizedBox(height: 12),
          _dado('Data da Compra', f['data_compra']),
          _dado('Data Histórica', f['data_historica']),
          _dado('Nº Apólice', f['numero_apolice']),
          _dado('Valor', f['valor']),
          _dado('Observações', f['observacao']),
        ],
      ),
    );
  }

  Widget _sectionTitle(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AcervusColors.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        texto.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: AcervusColors.primary,
        ),
      ),
    );
  }

  Widget _dado(String label, dynamic valor) {
    final texto = (valor ?? '').toString();
    if (texto.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          style:
              const TextStyle(fontSize: 13, color: AcervusColors.textPrimary),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AcervusColors.primary,
              ),
            ),
            TextSpan(text: texto),
          ],
        ),
      ),
    );
  }
}
