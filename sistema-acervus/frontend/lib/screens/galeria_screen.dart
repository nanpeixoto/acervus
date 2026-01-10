import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sistema_estagio/services/obra_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/utils/app_utils.dart';

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

class GaleriaScreen extends StatefulWidget {
  final int? obraId;
  final String? obraTitulo;

  const GaleriaScreen({super.key, required this.obraId, this.obraTitulo});

  @override
  State<GaleriaScreen> createState() => _GaleriaScreenState();
}

class _GaleriaScreenState extends State<GaleriaScreen> {
  final List<_ObraImagem> _imagens = [];
  bool _loading = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _carregarGaleria();
  }

  Future<void> _carregarGaleria() async {
    setState(() => _loading = true);
    try {
      if (widget.obraId == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }
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
      if (mounted) setState(() => _loading = false);
    }
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
        await _salvarImagem(bytes, file.name);
      }
    }
  }

  Future<void> _salvarImagem(Uint8List bytes, String nomeArquivo) async {
    if (widget.obraId == null) {
      AppUtils.showErrorSnackBar(context, 'Salve a obra antes de enviar imagens');
      return;
    }

    final ext = nomeArquivo.contains('.')
        ? nomeArquivo.substring(nomeArquivo.lastIndexOf('.'))
        : '';

    setState(() => _uploading = true);
    try {
      final saved = await ObraService.salvarImagemGaleria(widget.obraId!, {
        'nome': nomeArquivo,
        'extensao': ext,
        'imagem_base64': base64Encode(bytes),
        'ds_imagem': null,
        'sts_principal': false,
      });

      final imagem = _ObraImagem(
        id: saved['id'] as int?,
        bytes: null,
        url: saved['id'] != null
            ? ObraService.galeriaArquivoUrl(saved['id'] as int)
            : null,
        name: saved['nome'] as String? ?? nomeArquivo,
        descricao: saved['ds_imagem'] as String?,
        extensao: saved['extensao'] as String? ?? ext,
        isPrincipal: saved['sts_principal'] == true,
        rotationDeg: saved['rotacao'] is num
            ? (saved['rotacao'] as num).toDouble()
            : 0,
      );

      setState(() {
        _imagens.insert(0, imagem);
      });
      AppUtils.showSuccessSnackBar(context, 'Imagem adicionada na galeria');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao salvar imagem na galeria');
    } finally {
      if (mounted) setState(() => _uploading = false);
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
              final newRot = tempRotation % 360;
              setState(() => item.rotationDeg = newRot);
              Navigator.pop(ctx);
              _persistirEdicao(item, rotacao: newRot);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _persistirEdicao(
    _ObraImagem item, {
    double? rotacao,
    String? descricao,
    bool? principal,
  }) async {
    if (item.id == null) return; // ainda não salvo

    final payload = <String, dynamic>{};
    if (rotacao != null) payload['rotacao'] = rotacao;
    if (descricao != null) payload['ds_imagem'] = descricao;
    if (principal != null) payload['sts_principal'] = principal;

    if (payload.isEmpty) return;

    try {
      await ObraService.atualizarImagemGaleria(item.id!, payload);
    } catch (_) {
      AppUtils.showErrorSnackBar(context, 'Erro ao atualizar imagem');
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.obraTitulo;
    return Scaffold(
      appBar: AppBar(
        title: Text(titulo != null ? 'Galeria - $titulo' : 'Galeria da Obra'),
        actions: [
          IconButton(
            tooltip: 'Recarregar',
            icon: const Icon(Icons.refresh),
            onPressed: _carregarGaleria,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      onPressed: _uploading ? null : _adicionarImagemArquivoWeb,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Adicionar URL'),
                      onPressed: _uploading ? null : _adicionarImagemPorUrl,
                    ),
                  ],
                ),
              ],
            ),
            if (_loading || _uploading) ...[
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
      ),
    );
  }
}
