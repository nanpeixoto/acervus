import 'package:http/http.dart' as http;
import 'package:sistema_estagio/utils/app_config.dart';
import '../../../models/_core/endereco.dart';

class EnderecoService {
  final String baseUrl = AppConfig.devBaseUrl;

  Future<List<Endereco>> getEnderecos() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((e) => Endereco.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao carregar endereços');
    }
  }

  Future<Endereco> getEnderecoById(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return Endereco.fromJson(json.decode(response.body));
    } else {
      throw Exception('Endereço não encontrado');
    }
  }

  Future<Endereco> createEndereco(Endereco endereco) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(endereco.toJson()),
    );
    if (response.statusCode == 201) {
      return Endereco.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erro ao criar endereço');
    }
  }

  Future<Endereco> buscarPorId(
    String tipo,
    int id,
  ) async {
    final response = await http.get(Uri.parse(
        '$baseUrl/endereco/listar?tipo=$tipo&id=$id&page=1&limit=20'));
    if (response.statusCode == 200) {
      return Endereco.fromJson(json.decode(response.body));
    } else {
      throw Exception('Endereço não encontrado');
    }
  }

  Future<Endereco> updateEndereco(int id, Endereco endereco) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(endereco.toJson()),
    );
    if (response.statusCode == 200) {
      return Endereco.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erro ao atualizar endereço');
    }
  }

  Future<void> deleteEndereco(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 204) {
      throw Exception('Erro ao deletar endereço');
    }
  }
}
