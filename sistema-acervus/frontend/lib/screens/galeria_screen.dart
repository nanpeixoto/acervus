import 'package:file_picker/file_picker.dart';
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
  bool isPrincipal;
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

        final rawUrl = item['url'] ?? item['caminho'] ?? item['arquivo'];
        final formattedUrl = rawUrl is String && rawUrl.isNotEmpty
            ? (rawUrl.startsWith('http')
                ? rawUrl
                : '${AppConfig.devBaseUrl}/$rawUrl')
            : null;
        final rotationRaw = item['rotacao'] ?? item['grau_rotacao'] ?? 0;

        imagens.add(
          _ObraImagem(
            id: id,
            url: formattedUrl,
            bytes: bytes,
            name: item['nm_imagem'] ?? item['nome'],
            descricao: item['ds_imagem'] ?? item['descricao'],
            extensao: item['extensao'],
            rotationDeg: rotationRaw is num ? rotationRaw.toDouble() : 0,
            isPrincipal:
                (item['principal'] ?? item['sts_principal'] ?? false) == true,
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

    // Se tem ID, buscar pela API com autenticação
    if (item.id != null) {
      return FutureBuilder<Uint8List?>(
        future: ObraService.buscarImagemGaleria(item.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: fit,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          }

          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          );
        },
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
          GestureDetector(
            onTap: () => _visualizarImagem(item),
            child: AspectRatio(
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
          Wrap(
            spacing: 4, // espaçamento horizontal entre botões
            runSpacing: 4, // espaçamento vertical se quebrar linha
            alignment: WrapAlignment.start,
            children: [
              IconButton(
                iconSize: 20, // reduzir tamanho do ícone
                tooltip:
                    item.isPrincipal ? 'Remover como capa' : 'Marcar como capa',
                icon: Icon(
                  item.isPrincipal ? Icons.star : Icons.star_border,
                  color: item.isPrincipal ? Colors.amber : Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    item.isPrincipal = !item.isPrincipal;
                  });
                  _persistirEdicao(item, principal: item.isPrincipal);
                },
              ),
              IconButton(
                iconSize: 20,
                tooltip: 'Rotacionar -90º',
                icon: const Icon(Icons.rotate_left),
                onPressed: () {
                  final newRotation = (item.rotationDeg - 90) % 360;
                  setState(() {
                    item.rotationDeg = newRotation;
                  });
                  _persistirEdicao(item, rotacao: newRotation);
                },
              ),
              IconButton(
                iconSize: 20,
                tooltip: 'Rotacionar +90º',
                icon: const Icon(Icons.rotate_right),
                onPressed: () {
                  final newRotation = (item.rotationDeg + 90) % 360;
                  setState(() {
                    item.rotationDeg = newRotation;
                  });
                  _persistirEdicao(item, rotacao: newRotation);
                },
              ),
              IconButton(
                iconSize: 20,
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

  Future<void> _visualizarImagem(_ObraImagem item) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Transform.rotate(
                  angle: item.rotationDeg * 3.1415926535 / 180,
                  child: _buildImagemPreview(item, BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
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
        await ObraService.salvarImagemGaleria(
          widget.obraId!,
          bytes: bytes, // Mudança aqui: bytes -> fileBytes
          filePath: file.relativePath, // Mudança aqui: adicionar filePath
          fileName: file.name,
        );
      }
    }
  }

  Future<void> adicionarArquivo(int obraId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result == null) return;

      final file = result.files.single;
      const maxSize = 10 * 1024 * 1024;

      if (file.size > maxSize) {
        if (mounted) {
          AppUtils.showErrorSnackBar(
            context,
            'O arquivo deve ter no máximo 10MB.',
          );
        }
        return;
      }

      final bytes = kIsWeb ? file.bytes : null;
      final path = !kIsWeb ? file.path : null;

      if (bytes == null && (path == null || path.isEmpty)) {
        if (mounted) {
          AppUtils.showErrorSnackBar(
            context,
            'Não foi possível ler o arquivo selecionado.',
          );
        }
        return;
      }

      setState(() => _uploading = true);

      await ObraService.salvarImagemGaleria(
        obraId,
        bytes: bytes, // Mudança aqui: bytes -> fileBytes
        filePath: path, // Mudança aqui: adicionar filePath
        fileName: file.name,
      );

      await _carregarGaleria();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagem adicionada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Erro ao adicionar arquivo: $e');
      if (mounted) {
        AppUtils.showErrorSnackBar(
          context,
          'Erro ao adicionar imagem. Tente novamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _abrirEditorImagem(int index, _ObraImagem item) async {
    double tempRotation = item.rotationDeg;
    bool tempPrincipal = item.isPrincipal; // Adicionar esta linha

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // Mudança: AlertDialog -> StatefulBuilder
        builder: (context, setDialogState) => AlertDialog(
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
                      onChanged: (v) => setDialogState(() {
                        tempRotation = v;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Adicionar checkbox para marcar como principal
              CheckboxListTile(
                title: const Text('Marcar como capa principal'),
                subtitle: const Text('Esta será a imagem de destaque da obra'),
                value: tempPrincipal,
                onChanged: (value) => setDialogState(() {
                  tempPrincipal = value ?? false;
                }),
                controlAffinity: ListTileControlAffinity.leading,
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
                setState(() {
                  item.rotationDeg = newRot;
                  item.isPrincipal = tempPrincipal;
                });
                Navigator.pop(ctx);
                _persistirEdicao(
                  item,
                  rotacao: newRot,
                  principal: tempPrincipal,
                );
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
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
                OutlinedButton.icon(
                  onPressed: widget.obraId == null || _uploading
                      ? null
                      : () => adicionarArquivo(widget.obraId!),
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload),
                  label: Text(
                    _uploading ? 'Enviando...' : 'Adicionar arquivo',
                  ),
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
