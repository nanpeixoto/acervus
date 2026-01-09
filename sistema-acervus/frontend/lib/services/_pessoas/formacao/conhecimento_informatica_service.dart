import 'package:http/http.dart' as http;
import 'package:sistema_estagio/utils/app_config.dart';

class ConhecimentoInformatica {
  final String software;
  final String versao;
  final String certificacao;
  final bool ativo;
  final int cdCandidato;

  ConhecimentoInformatica({
    required this.software,
    required this.versao,
    required this.certificacao,
    required this.ativo,
    required this.cdCandidato,
  });

  factory ConhecimentoInformatica.fromJson(Map<String, dynamic> json) {
    return ConhecimentoInformatica(
      software: json['software'] ?? '',
      versao: json['versao'] ?? '',
      certificacao: json['certificacao'] ?? '',
      ativo: json['ativo'] ?? false,
      cdCandidato: json['cd_candidato'] ?? 0,
    );
  }
}

class ConhecimentoInformaticaService {
  static const String baseUrl = AppConfig.devBaseUrl;

  static Future<List<ConhecimentoInformatica>> buscarConhecimentosPorCandidato(
      int candidatoId) async {
    final url = Uri.parse('$baseUrl/candidato/$candidatoId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) =>
              ConhecimentoInformatica.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Erro ao buscar conhecimentos do candidato');
    }
  }
}
