import 'package:flutter/material.dart';
import 'package:sistema_estagio/models/assunto.dart';
import 'package:sistema_estagio/models/material.dart';
import 'package:sistema_estagio/services/assunto_service.dart';
import 'package:sistema_estagio/services/material_service.dart';

class ObraCadastroController extends ChangeNotifier {
  bool loading = false;

  List<Assunto> assuntos = [];
  List<Materiais> materiais = [];

  int? cdAssunto;
  int? cdMaterial;

  Future<void> carregarAssuntos() async {
    loading = true;
    notifyListeners();

    final result = await AssuntoService.listarAssuntos(
      page: 1,
      limit: 999,
      ativo: true,
    );

    assuntos = result['Assuntos'];

    loading = false;
    notifyListeners();
  }

  Future<void> carregarMateriais() async {
    final result = await MateriaisService.listarMateriais(
      page: 1,
      limit: 999,
      ativo: true,
    );

    materiais = result['materiais'];
    notifyListeners();
  }
}
