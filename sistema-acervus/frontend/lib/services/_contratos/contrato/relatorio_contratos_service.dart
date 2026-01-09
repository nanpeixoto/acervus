// lib/services/relatorio_contratos_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../models/_contratos/contrato/contrato_vencer.dart';
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';

class RelatorioContratosService {
  static const String baseUrl = AppConfig.devBaseUrl;

  static Future<Map<String, String>> _headers() async {
    final tk = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${tk ?? ''}',
    };
  }

  /// Lista/pagina os contratos a vencer (JSON)
  static Future<Map<String, dynamic>> listar({
    required String terminoIni, // DD/MM/YYYY
    required String terminoFim, // DD/MM/YYYY
    String tipo = 'estagio', // 'estagio' | 'aprendiz'
    String? unidadeGestora, // 'Todas' ou nome
    String? empresa, // busca por nome fantasia
    String? terminadosAte, // DD/MM/YYYY (opcional)
    int page = 1,
    int limit = 20,
  }) async {
    final q = <String, String>{
      'tipo': tipo,
      'terminoIni': terminoIni,
      'terminoFim': terminoFim,
      'formato': 'json',
      'page': '$page',
      'limit': '$limit',
    };
    if (unidadeGestora != null && unidadeGestora.isNotEmpty) {
      q['unidadeGestora'] = unidadeGestora;
    }
    if (empresa != null && empresa.isNotEmpty) q['empresa'] = empresa;
    if (terminadosAte != null && terminadosAte.isNotEmpty) {
      q['terminadosAte'] = terminadosAte;
    }

    final uri = Uri.parse('$baseUrl/relatorios/contratos-a-vencer')
        .replace(queryParameters: q);

    final resp = await http.get(uri, headers: await _headers());
    if (resp.statusCode != 200) {
      throw Exception('Erro ao carregar relatório (HTTP ${resp.statusCode})');
    }
    final data = jsonDecode(resp.body);
    final itens =
        (data['dados'] as List).map((e) => ContratoVencer.fromJson(e)).toList();

    return {
      'dados': itens,
      'pagination': data['pagination'] ??
          {
            'currentPage': 1,
            'totalPages': 1,
            'totalItems': itens.length,
            'hasNextPage': false,
            'hasPrevPage': false,
          }
    };
  }

  /// Exporta CSV
  static Future<String?> exportarCsv({
    required String terminoIni,
    required String terminoFim,
    String tipo = 'estagio',
    String? unidadeGestora,
    String? empresa,
    String? terminadosAte,
  }) async {
    final q = <String, String>{
      'tipo': tipo,
      'terminoIni': terminoIni,
      'terminoFim': terminoFim,
      'formato': 'csv',
    };
    if (unidadeGestora != null && unidadeGestora.isNotEmpty) {
      q['unidadeGestora'] = unidadeGestora;
    }
    if (empresa != null && empresa.isNotEmpty) q['empresa'] = empresa;
    if (terminadosAte != null && terminadosAte.isNotEmpty) {
      q['terminadosAte'] = terminadosAte;
    }

    final uri = Uri.parse('$baseUrl/relatorios/contratos-a-vencer')
        .replace(queryParameters: q);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
      final filename = _extrairFilename(
              response.headers['content-disposition']) ??
          'Contatos_A_Vencer_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

      // Usa o helper condicional (Web = download, Mobile/Desktop = salva no disco)
      final downloader = getCsvDownloader();
      final savedPath = await downloader.saveCsv(bytes, filename: filename);

      return savedPath; // Na Web será null, no mobile/desktop será o path
    }
    if (response.statusCode != 200) {
      throw Exception('Erro ao exportar CSV');
    }
    return null;
    // Na Web o download é feito pelo browser se você abrir uma nova aba com a URL.
    // Em mobile/desktop: use seu helper de salvar bytes (igual ao que você já usa).
  }

  /// Extrai o filename do header Content-Disposition, se presente
  static String? _extrairFilename(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.isEmpty) return null;

    // filename="turnos.csv"  |  filename=turnos.csv  |  filename*=UTF-8''turnos.csv
    final regex = RegExp('filename\\*?=(?:UTF-8\'\')?(")?([^";]+)\\1');

    final match = regex.firstMatch(contentDisposition);
    if (match != null) {
      final raw = match.group(2);
      if (raw == null) return null;
      try {
        return Uri.decodeFull(raw); // lida com %C3%B3 etc.
      } catch (_) {
        return raw;
      }
    }
    return null;
  }

  /// Exporta PDF (bytes)
  static Future<String?> exportarPdf({
    required String terminoIni,
    required String terminoFim,
    String tipo = 'estagio',
    String? unidadeGestora,
    String? empresa,
    String? terminadosAte,
  }) async {
    final q = <String, String>{
      'tipo': tipo,
      'terminoIni': terminoIni,
      'terminoFim': terminoFim,
      'formato': 'pdf',
    };
    if (unidadeGestora != null && unidadeGestora.isNotEmpty) {
      q['unidadeGestora'] = unidadeGestora;
    }
    if (empresa != null && empresa.isNotEmpty) q['empresa'] = empresa;
    if (terminadosAte != null && terminadosAte.isNotEmpty) {
      q['terminadosAte'] = terminadosAte;
    }

    final uri = Uri.parse('$baseUrl/relatorios/contratos-a-vencer')
        .replace(queryParameters: q);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
      final filename = _extrairFilename(
              response.headers['content-disposition']) ??
          'Contatos_A_Vencer_${DateTime.now().toIso8601String().substring(0, 10)}.pdf';

      // Usa o helper condicional (Web = download, Mobile/Desktop = salva no disco)
      final downloader = getCsvDownloader();
      final savedPath = await downloader.saveCsv(bytes, filename: filename);

      return savedPath; // Na Web será null, no mobile/desktop será o path
    }
    if (response.statusCode != 200) {
      throw Exception('Erro ao exportar PDF');
    }
    return null;
    // Na Web o download é feito pelo browser se você abrir uma nova aba com a URL.
    // Em mobile/desktop: use seu helper de salvar bytes (igual ao que você já usa).
  }

  /// Dispara e-mails (1 por empresa, lista no corpo)
  static Future<Map<String, dynamic>> enviarEmails({
    required String terminoIni,
    required String terminoFim,
    String tipo = 'estagio',
    String? unidadeGestora,
    String? empresa,
    String? terminadosAte,
    bool enviarParaSupervisor = true,
    String? cc,
  }) async {
    final body = <String, dynamic>{
      'tipo': tipo,
      'terminoIni': terminoIni,
      'terminoFim': terminoFim,
      'unidadeGestora': unidadeGestora,
      'empresa': empresa,
      'terminadosAte': terminadosAte,
      'enviarParaSupervisor': enviarParaSupervisor,
      'cc': cc,
    }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));

    final resp = await http.post(
      Uri.parse('$baseUrl/relatorios/contratos-a-vencer/disparar-emails'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (resp.statusCode != 200) {
      throw Exception('Erro ao enviar e-mails');
    }
    return jsonDecode(resp.body);
  }
}
