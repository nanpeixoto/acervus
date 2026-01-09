import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CKEditorWidget extends StatefulWidget {
  final Function(String) onContentChanged;
  final String initialContent;
  final double height;
  final bool showFullscreenButton;
  final String title;

  const CKEditorWidget({
    super.key,
    required this.onContentChanged,
    this.initialContent = '',
    this.height = 400,
    this.showFullscreenButton = true,
    this.title = 'Editor de Contrato',
  });

  @override
  State<CKEditorWidget> createState() => _CKEditorWidgetState();
}

class _CKEditorWidgetState extends State<CKEditorWidget> {
  static const Color _primaryColor = Color(0xFF82265C);

  bool _isEditorReady = false;
  bool _isLoading = true;
  String _currentContent = '';
  html.IFrameElement? _iframe;
  String? _viewType;
  bool _isViewRegistered = false;
  StreamSubscription? _messageSubscription;
  bool _contentSetPending = false;

  @override
  void initState() {
    super.initState();
    _currentContent = widget.initialContent;

    if (kIsWeb) {
      _setupWebEditor();
    }
  }

  @override
  void didUpdateWidget(CKEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se o conteúdo inicial mudou, atualizar o editor
    if (widget.initialContent != oldWidget.initialContent &&
        widget.initialContent != _currentContent) {
      print('🔄 Conteúdo inicial alterado, atualizando editor...');
      _updateEditorContent(widget.initialContent);
    }
  }

  void _setupWebEditor() {
    _viewType = 'ckeditor-widget-${DateTime.now().millisecondsSinceEpoch}';
    _registerWebView();
  }

  void _registerWebView() {
    if (_isViewRegistered) return;

    try {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewType!,
        (int viewId) {
          _iframe = html.IFrameElement()
            ..width = '100%'
            ..height = '100%'
            ..style.border = 'none'
            ..srcdoc = _loadCKEditorHtml();

          _setupMessageListener();
          return _iframe!;
        },
      );
      _isViewRegistered = true;
      print('✅ WebView registrada: $_viewType');
    } catch (e) {
      print('⚠️ ViewType já registrado ou erro: $e');
    }
  }

  void _setupMessageListener() {
    _messageSubscription?.cancel();
    _messageSubscription = html.window.onMessage.listen((event) {
      if (event.data is Map) {
        final data = event.data as Map;

        // Filtrar apenas mensagens do nosso iframe
        if (event.source != _iframe?.contentWindow) return;

        switch (data['type']) {
          case 'ckeditor-ready':
            print('📨 Editor pronto recebido');
            setState(() {
              _isEditorReady = true;
              _isLoading = false;
            });

            // Definir conteúdo inicial se houver
            if (widget.initialContent.isNotEmpty) {
              print(
                  '📝 Definindo conteúdo inicial: ${widget.initialContent.length} chars');
              _setContentInternal(widget.initialContent);
            }
            break;

          case 'ckeditor-change':
            final content = data['content'] as String? ?? '';
            if (content != _currentContent) {
              setState(() {
                _currentContent = content;
              });
              widget.onContentChanged(content);
              print('🔄 Conteúdo alterado: ${content.length} chars');
            }
            break;

          case 'ckeditor-content-set':
            print('✅ Conteúdo definido com sucesso');
            _contentSetPending = false;
            break;

          case 'ckeditor-fullscreen-request':
            _openFullscreenEditor();
            break;
        }
      }
    });
  }

  String _loadCKEditorHtml() {
    return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8" />
<title>CKEditor Widget</title>
<script src="https://cdn.ckeditor.com/4.22.1/full/ckeditor.js"></script>
<style>
  body { 
    margin: 0; 
    padding: 0; 
    font-family: Arial, sans-serif;
    background: white;
  }
  .editor-container { 
    position: relative; 
    height: 100vh; 
    display: flex; 
    flex-direction: column; 
    background: white;
  }
  .toolbar-custom { 
    background: #f5f5f5; 
    padding: 8px; 
    border-bottom: 1px solid #ddd;
    display: flex;
    justify-content: space-between;
    align-items: center;
    flex-shrink: 0;
  }
  .fullscreen-btn {
    background: #82265C;
    color: white;
    border: none;
    padding: 6px 12px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 12px;
  }
  .fullscreen-btn:hover {
    background: #6b1e4a;
  }
  .editor-content { 
    flex: 1; 
    background: white;
    min-height: 300px;
  }
</style>
</head>
<body>
<div class="editor-container">
  <div class="toolbar-custom">
    <span style="font-size: 12px; color: #666;">Editor de Modelo</span>
    ${widget.showFullscreenButton ? '<button class="fullscreen-btn" onclick="requestFullscreen()">📺 Tela Cheia</button>' : ''}
  </div>
  <div class="editor-content">
    <textarea id="editor" style="width: 100%; height: 100%;"></textarea>
  </div>
</div>

<script>
    let editorInstance = null;
    let currentContent = '';
    let isReady = false;
    
    function sendToFlutter(data) {
      try {
        if (window.parent && window.parent.postMessage) {
          window.parent.postMessage(data, '*');
        }
      } catch (e) {
        console.error('Erro ao enviar mensagem:', e);
      }
    }

    function setContent(content) {
      console.log('📥 setContent chamado:', content ? content.length : 0, 'chars');
      
      if (!editorInstance || !isReady) {
        console.warn('⚠️ Editor não está pronto');
        return false;
      }

      try {
        // Limpar e definir novo conteúdo
        editorInstance.setData(content || '', {
          callback: function() {
            console.log('✅ Conteúdo definido via callback');
            currentContent = content || '';
            sendToFlutter({
              type: 'ckeditor-content-set',
              success: true
            });
          }
        });
        return true;
      } catch (error) {
        console.error('❌ Erro ao definir conteúdo:', error);
        return false;
      }
    }

    function getContent() {
      if (editorInstance && isReady) {
        try {
          currentContent = editorInstance.getData();
          return currentContent;
        } catch (e) {
          console.error('Erro ao obter conteúdo:', e);
        }
      }
      return currentContent;
    }

    function requestFullscreen() {
      const content = getContent();
      sendToFlutter({
        type: 'ckeditor-fullscreen-request',
        content: content
      });
    }

    // Listener para mensagens do Flutter
    window.addEventListener('message', function(event) {
      try {
        const data = event.data;
        
        if (data.action === 'setContent') {
          console.log('📨 Comando setContent recebido');
          const success = setContent(data.content);
          if (!success) {
            console.log('⚠️ Falha ao definir conteúdo, tentando novamente...');
            setTimeout(() => setContent(data.content), 500);
          }
        } else if (data.action === 'getContent') {
          const content = getContent();
          sendToFlutter({
            type: 'ckeditor-content',
            content: content
          });
        } else if (data.action === 'ping') {
          sendToFlutter({
            type: 'ckeditor-pong',
            ready: isReady,
            hasInstance: !!editorInstance
          });
        }
      } catch (error) {
        console.error('❌ Erro no listener:', error);
      }
    });

    // Inicializar CKEditor
    try {
      console.log('🚀 Inicializando CKEditor...');
      
      editorInstance = CKEDITOR.replace('editor', {
        height: 300,
        removeButtons: 'Save,NewPage,Preview',
        language: 'pt-br',
        startupFocus: false,
        allowedContent: true,
        extraAllowedContent: '*(*){*}[*]',
        toolbar: [
          { name: 'document', items: ['Source'] },
          { name: 'clipboard', items: ['Cut', 'Copy', 'Paste', 'PasteText', 'Undo', 'Redo'] },
          { name: 'editing', items: ['Find', 'Replace'] },
          '/',
          { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Strike'] },
          { name: 'paragraph', items: ['NumberedList', 'BulletedList', 'Blockquote'] },
          { name: 'links', items: ['Link', 'Unlink'] },
          { name: 'insert', items: ['Image', 'Table'] },
          '/',
          { name: 'styles', items: ['Format', 'Font', 'FontSize'] },
          { name: 'colors', items: ['TextColor', 'BGColor'] }
        ]
      });
      
      editorInstance.on('instanceReady', function(evt) {
        console.log('🎯 CKEditor instanceReady');
        isReady = true;
        currentContent = editorInstance.getData();
        
        sendToFlutter({
          type: 'ckeditor-ready',
          content: currentContent
        });
      });
      
      editorInstance.on('change', function(evt) {
        if (!isReady) return;
        
        try {
          const newContent = evt.editor.getData();
          if (newContent !== currentContent) {
            currentContent = newContent;
            sendToFlutter({
              type: 'ckeditor-change', 
              content: currentContent
            });
          }
        } catch (e) {
          console.error('Erro no evento change:', e);
        }
      });

      // Capturar mudanças adicionais
      editorInstance.on('key', function(evt) {
        setTimeout(() => {
          if (isReady) {
            try {
              const newContent = editorInstance.getData();
              if (newContent !== currentContent) {
                currentContent = newContent;
                sendToFlutter({
                  type: 'ckeditor-change', 
                  content: currentContent
                });
              }
            } catch (e) {
              console.error('Erro no evento key:', e);
            }
          }
        }, 100);
      });

      // Remove notificações de segurança
      setInterval(() => {
        try {
          const warning = document.querySelector('.cke_notification_warning');
          if (warning) {
            warning.remove();
          }
        } catch (e) {
          // Ignorar erros de notificação
        }
      }, 1000);

    } catch (error) {
      console.error('❌ Erro ao inicializar CKEditor:', error);
      sendToFlutter({
        type: 'ckeditor-error',
        error: error.toString()
      });
    }
</script>
</body>
</html>
    ''';
  }

  void _setContentInternal(String content) {
    if (_iframe != null && _isEditorReady && !_contentSetPending) {
      _contentSetPending = true;
      print('📤 Enviando conteúdo para o editor: ${content.length} chars');

      _iframe!.contentWindow
          ?.postMessage({'action': 'setContent', 'content': content}, '*');
    } else {
      print('⚠️ Editor não pronto para receber conteúdo');
    }
  }

  void _updateEditorContent(String content) {
    setState(() {
      _currentContent = content;
    });

    if (_isEditorReady) {
      _setContentInternal(content);
    }
  }

  void _openFullscreenEditor() {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => FullscreenEditorDialog(
        initialContent: _currentContent,
        title: widget.title,
        onSave: (content) {
          _updateEditorContent(content);
          widget.onContentChanged(content);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Stack(
        children: [
          if (kIsWeb && _viewType != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: HtmlElementView(viewType: _viewType!),
            )
          else
            const Center(
              child: Text('Editor não suportado nesta plataforma'),
            ),
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Carregando editor...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _iframe = null;
    super.dispose();
  }
}

// Classe do modal de tela cheia (mantida igual)
class FullscreenEditorDialog extends StatefulWidget {
  final String initialContent;
  final String title;
  final Function(String) onSave;

  const FullscreenEditorDialog({
    super.key,
    required this.initialContent,
    required this.title,
    required this.onSave,
  });

  @override
  State<FullscreenEditorDialog> createState() => _FullscreenEditorDialogState();
}

class _FullscreenEditorDialogState extends State<FullscreenEditorDialog> {
  static const Color _primaryColor = Color(0xFF82265C);

  String _currentContent = '';
  bool _isEditorReady = false;
  html.IFrameElement? _iframe;
  String? _viewType;
  bool _isViewRegistered = false;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _currentContent = widget.initialContent;

    if (kIsWeb) {
      _setupFullscreenEditor();
    }
  }

  void _setupFullscreenEditor() {
    _viewType = 'ckeditor-fullscreen-${DateTime.now().millisecondsSinceEpoch}';
    _registerFullscreenWebView();
  }

  void _registerFullscreenWebView() {
    if (_isViewRegistered) return;

    try {
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewType!,
        (int viewId) {
          _iframe = html.IFrameElement()
            ..width = '100%'
            ..height = '100%'
            ..style.border = 'none'
            ..srcdoc = _loadFullscreenCKEditorHtml();

          _setupFullscreenMessageListener();
          return _iframe!;
        },
      );
      _isViewRegistered = true;
    } catch (e) {
      print('ViewType fullscreen já registrado ou erro: $e');
    }
  }

  void _setupFullscreenMessageListener() {
    _messageSubscription?.cancel();
    _messageSubscription = html.window.onMessage.listen((event) {
      if (event.data is Map && event.source == _iframe?.contentWindow) {
        final data = event.data as Map;

        switch (data['type']) {
          case 'ckeditor-fullscreen-ready':
            setState(() {
              _isEditorReady = true;
            });

            // Definir conteúdo inicial
            if (widget.initialContent.isNotEmpty) {
              _setFullscreenContent(widget.initialContent);
            }
            break;

          case 'ckeditor-fullscreen-change':
            _currentContent = data['content'] as String? ?? '';
            break;
        }
      }
    });
  }

  String _loadFullscreenCKEditorHtml() {
    return '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8" />
<title>CKEditor Fullscreen</title>
<script src="https://cdn.ckeditor.com/4.22.1/full/ckeditor.js"></script>
<style>
  body { margin: 0; padding: 0; font-family: Arial, sans-serif; height: 100vh; background: white; }
  .editor-container { height: 100vh; display: flex; flex-direction: column; background: white; }
  .editor-content { flex: 1; background: white; }
</style>
</head>
<body>
<div class="editor-container">
  <div class="editor-content">
    <textarea id="editor"></textarea>
  </div>
</div>

<script>
    let editorInstance = null;
    let currentContent = '';
    let isReady = false;
    
    function sendToFlutter(data) {
      if (window.parent && window.parent.postMessage) {
        window.parent.postMessage(data, '*');
      }
    }

    function setContent(content) {
      if (editorInstance && isReady && content !== undefined) {
        try {
          editorInstance.setData(content || '');
          currentContent = content || '';
          return true;
        } catch (error) {
          console.error('Erro ao definir conteúdo:', error);
          return false;
        }
      }
      return false;
    }

    function getContent() {
      if (editorInstance && isReady) {
        try {
          currentContent = editorInstance.getData();
          return currentContent;
        } catch (e) {
          console.error('Erro ao obter conteúdo:', e);
        }
      }
      return currentContent;
    }

    window.addEventListener('message', function(event) {
      try {
        const data = event.data;
        
        if (data.action === 'setContent') {
          setContent(data.content);
        } else if (data.action === 'getContent') {
          const content = getContent();
          sendToFlutter({
            type: 'ckeditor-fullscreen-content',
            content: content
          });
        }
      } catch (error) {
        console.error('Erro no listener:', error);
      }
    });

    try {
      editorInstance = CKEDITOR.replace('editor', {
        height: '100%',
        removeButtons: 'Save,NewPage,Preview',
        language: 'pt-br',
        startupFocus: true,
        allowedContent: true,
        extraAllowedContent: '*(*){*}[*]',
      });
      
      editorInstance.on('instanceReady', function(evt) {
        isReady = true;
        currentContent = editorInstance.getData();
        sendToFlutter({
          type: 'ckeditor-fullscreen-ready',
          content: currentContent
        });
      });
      
      editorInstance.on('change', function(evt) {
        if (isReady) {
          currentContent = evt.editor.getData();
          sendToFlutter({
            type: 'ckeditor-fullscreen-change', 
            content: currentContent
          });
        }
      });

      setInterval(() => {
        const warning = document.querySelector('.cke_notification_warning');
        if (warning) {
          warning.remove();
        }
      }, 500);

    } catch (error) {
      console.error('Erro ao inicializar CKEditor fullscreen:', error);
    }
</script>
</body>
</html>
    ''';
  }

  void _setFullscreenContent(String content) {
    if (_iframe != null && _isEditorReady) {
      _iframe!.contentWindow
          ?.postMessage({'action': 'setContent', 'content': content}, '*');
    }
  }

  Future<String> _getFullscreenContent() async {
    if (_iframe != null) {
      _iframe!.contentWindow?.postMessage({'action': 'getContent'}, '*');

      await Future.delayed(const Duration(milliseconds: 500));
    }
    return _currentContent;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _primaryColor,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final content = await _getFullscreenContent();
                widget.onSave(content);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _primaryColor,
              ),
              child: const Text('Salvar e Fechar'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                if (kIsWeb && _viewType != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: HtmlElementView(viewType: _viewType!),
                  )
                else
                  const Center(
                    child: Text('Editor não suportado nesta plataforma'),
                  ),
                if (!_isEditorReady)
                  Container(
                    color: Colors.white.withOpacity(0.9),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Carregando editor...'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _iframe = null;
    super.dispose();
  }
}
