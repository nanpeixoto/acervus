// lib/services/contrato_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/models/_contratos/contrato/contrato.dart';
import '../../_core/storage_service.dart';
import '../../../utils/app_config.dart';

class ContratoService {
  static String get baseUrl => AppConfig.apiURLPRD;

  // Headers com autenticação
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // CRUD BÁSICO
  static Future<Map<String, dynamic>> listarContratos({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? tipo,
    String? empresaId,
    String? estudanteId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (empresaId != null) {
        queryParams['empresaId'] = empresaId;
      }
      if (estudanteId != null) {
        queryParams['estudanteId'] = estudanteId;
      }
      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String();
      }

      final uri =
          Uri.parse('$baseUrl/contratos').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'contratos': (data['data']['contratos'] as List)
              .map((json) => Contrato.fromJson(json))
              .toList(),
          'pagination': data['data']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar contratos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar contratos: $e');
    }
  }

  static Future<Contrato> buscarContrato(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contratos/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Contrato.fromJson(data['data']);
      } else {
        throw Exception('Contrato não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao buscar contrato: $e');
    }
  }

  static Future<bool> criarContrato(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contratos'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao criar contrato: $e');
    }
  }

  // GERAR PDF DO CONTRATO
  static Future<List<int>> gerarPDF(String contratoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contratos/$contratoId/pdf'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erro ao gerar PDF do contrato');
      }
    } catch (e) {
      throw Exception('Erro ao gerar PDF do contrato: $e');
    }
  }

  static Future<bool> atualizarContrato(
      String id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contratos/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar contrato: $e');
    }
  }

  static Future<bool> deletarContrato(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/contratos/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao deletar contrato: $e');
    }
  }

  // EXPORTAÇÃO DE DADOS
  static Future<String> exportarContratosCSV({
    String? status,
    String? tipo,
    String? empresaId,
    String? estudanteId,
  }) async {
    try {
      final queryParams = <String, String>{
        'format': 'csv',
      };

      if (status != null) {
        queryParams['status'] = status;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (empresaId != null) {
        queryParams['empresaId'] = empresaId;
      }
      if (estudanteId != null) {
        queryParams['estudanteId'] = estudanteId;
      }

      final uri = Uri.parse('$baseUrl/contratos/export')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Erro ao exportar dados');
      }
    } catch (e) {
      throw Exception('Erro ao exportar dados: $e');
    }
  }

  static Future<List<int>> exportarContratosPDF({
    String? status,
    String? tipo,
    String? empresaId,
    String? estudanteId,
  }) async {
    try {
      final queryParams = <String, String>{
        'format': 'pdf',
      };

      if (status != null) {
        queryParams['status'] = status;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (empresaId != null) {
        queryParams['empresaId'] = empresaId;
      }
      if (estudanteId != null) {
        queryParams['estudanteId'] = estudanteId;
      }

      final uri = Uri.parse('$baseUrl/contratos/export')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erro ao exportar PDF');
      }
    } catch (e) {
      throw Exception('Erro ao exportar PDF: $e');
    }
  }

  // ESTATÍSTICAS E RELATÓRIOS
  static Future<Map<String, dynamic>> getEstatisticasContratos() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contratos/estatisticas'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getRelatorioContratos({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? status,
    String? tipo,
    String? empresaId,
    String? estudanteId,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String();
      }
      if (status != null) {
        queryParams['status'] = status;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (empresaId != null) {
        queryParams['empresaId'] = empresaId;
      }
      if (estudanteId != null) {
        queryParams['estudanteId'] = estudanteId;
      }

      final uri = Uri.parse('$baseUrl/contratos/relatorio')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Erro ao gerar relatório');
      }
    } catch (e) {
      throw Exception('Erro ao gerar relatório: $e');
    }
  }

  // ATIVAÇÃO E CANCELAMENTO
  static Future<bool> ativarContrato(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/contratos/$id/ativar'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao ativar contrato: $e');
    }
  }

  static Future<bool> cancelarContrato(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/contratos/$id/cancelar'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao cancelar contrato: $e');
    }
  }

  // UTILS E HELPERS
  static String formatarNumeroContrato(String numero) {
    final numbers = numero.replaceAll(RegExp(r'\D'), '');
    if (numbers.length >= 8) {
      return '${numbers.substring(0, 4)}-${numbers.substring(4, 8)}';
    }
    return numero;
  }

  // ERROR HANDLING
  static Exception _handleError(dynamic error, String operation) {
    if (error is http.ClientException) {
      return Exception('Erro de conexão durante $operation');
    } else if (error.toString().contains('SocketException')) {
      return Exception('Sem conexão com internet durante $operation');
    } else if (error.toString().contains('TimeoutException')) {
      return Exception('Timeout durante $operation');
    } else {
      return Exception('Erro inesperado durante $operation: $error');
    }
  }
}
