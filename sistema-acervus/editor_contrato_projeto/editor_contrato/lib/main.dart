import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(home: EditorContrato()));
}

class EditorContrato extends StatefulWidget {
  @override
  _EditorContratoState createState() => _EditorContratoState();
}

class _EditorContratoState extends State<EditorContrato> {
  quill.QuillController _controller = quill.QuillController.basic();

  Future<void> _uploadAndLoad() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );
    if (result != null && result.files.single.bytes != null) {
      final req = http.MultipartRequest(
          'POST', Uri.parse('http://localhost:3000/upload'));
      req.files.add(http.MultipartFile.fromBytes(
          'arquivo', result.files.single.bytes!,
          filename: result.files.single.name));
      final resp = await req.send();
      if (resp.statusCode == 200) {
        final str = await resp.stream.bytesToString();
        final decoded = json.decode(str);
        final delta = Delta.fromJson(decoded['delta']['ops']);
        setState(() {
          _controller = quill.QuillController(
            document: quill.Document.fromDelta(delta),
            selection: TextSelection.collapsed(offset: 0),
          );
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro no upload.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editor Contrato (.docx → Quill)')),
      body: Column(
        children: [
          ElevatedButton(
              onPressed: _uploadAndLoad, child: Text('Upload .docx')),
          const Divider(),
          quill.QuillToolbar.simple(
            configurations: quill.QuillSimpleToolbarConfigurations(
              controller: _controller,
            ),
          ),
          Expanded(
            child: quill.QuillEditor.basic(
              configurations: quill.QuillEditorConfigurations(
                controller: _controller,
                // readOnly: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
