import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/utils/app_config.dart';
import '../../../models/_core/contato.dart';

class ContatoService {
  static const String baseUrl = AppConfig.devBaseUrl;

  static Future<List<Contato>> buscarPorCandidato(
      String tipo, int candidatoId) async {
    final url = Uri.parse(
        '$baseUrl/contato/listar?tipo=$tipo&id=$candidatoId&page=1&limit=20');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Contato.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar contato');
    }
  }

  static Future<Contato?> buscarPorId(int id) async {
    final url = Uri.parse('$baseUrl/contato/$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return Contato.fromJson(jsonDecode(response.body));
    } else {
      return null;
    }
  }

  static Future<void> criarContato(Contato contato) async {
    final url = Uri.parse('$baseUrl/contato/cadastrar');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(contato.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar contato');
    }
  }

  static Future<void> atualizarContatoCandidato(Contato contato) async {
    final url = Uri.parse('$baseUrl/contato/alterar/${contato.id}');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(contato.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar contato');
    }
  }

  static Future<void> deletarContato(int id) async {
    final url = Uri.parse('$baseUrl/contato/$id');
    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception('Erro ao deletar contato');
    }
  }
}
