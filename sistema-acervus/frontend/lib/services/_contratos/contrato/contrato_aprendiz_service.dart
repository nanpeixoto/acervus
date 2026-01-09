// lib/services/contrato_aprendiz_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/models/_contratos/modelo/modelo_contrato.dart';
import 'package:sistema_estagio/models/_financeiro/plano_pagamento.dart';
import 'package:sistema_estagio/models/_pessoas/candidato/candidato.dart';
import 'package:sistema_estagio/services/_pessoas/candidato/candidato_service.dart';
import 'package:sistema_estagio/services/_organizacoes/empresa/empresa_service.dart';
import 'package:sistema_estagio/services/_organizacoes/instituicao/instituicao_service.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import '../../../utils/app_config.dart';
import '../../../models/_contratos/contrato/contrato_aprendiz.dart';
import '../../_core/storage_service.dart';

class ContratoAprendizService {
  static String baseUrl = AppConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Lista contratos de jovem aprendiz com filtros
  static Future<Map<String, dynamic>> listarContratos({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
    String? numero,
    bool? apenasComAditivo,
    String? instituicao,
    String? dataInicioVigenciaDe,
    String? dataInicioVigenciaAte,
    String? dataFinalVigenciaDe,
    String? dataFinalVigenciaAte,
    String? dataEncerramentoDe,
    String? dataEncerramentoAte,
  }) async {
    try {
      final token = await StorageService.getToken();

      // Montar query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (numero != null && numero.isNotEmpty) {
        queryParams['numero'] = numero;
      }
      if (apenasComAditivo != null) {
        queryParams['apenas_com_aditivo'] = apenasComAditivo.toString();
      }

      if (instituicao != null && instituicao.isNotEmpty) {
        queryParams['instituicao'] = instituicao;
      }
      if (dataInicioVigenciaDe != null && dataInicioVigenciaDe.isNotEmpty) {
        queryParams['dataInicioVigenciaDe'] = dataInicioVigenciaDe;
      }
      if (dataInicioVigenciaAte != null && dataInicioVigenciaAte.isNotEmpty) {
        queryParams['dataInicioVigenciaAte'] = dataInicioVigenciaAte;
      }
      if (dataFinalVigenciaDe != null && dataFinalVigenciaDe.isNotEmpty) {
        queryParams['dataFinalVigenciaDe'] = dataFinalVigenciaDe;
      }
      if (dataFinalVigenciaAte != null && dataFinalVigenciaAte.isNotEmpty) {
        queryParams['dataFinalVigenciaAte'] = dataFinalVigenciaAte;
      }
      if (dataEncerramentoDe != null && dataEncerramentoDe.isNotEmpty) {
        queryParams['dataEncerramentoDe'] = dataEncerramentoDe;
      }
      if (dataEncerramentoAte != null && dataEncerramentoAte.isNotEmpty) {
        queryParams['dataEncerramentoAte'] = dataEncerramentoAte;
      }

      final uri = Uri.parse('$baseUrl/contrato-aprendiz/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'contratos': (data['dados'] as List)
              .map((json) => ContratoAprendiz.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar contratos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar contratos: $e');
    }
  }

  /// Busca um contrato específico por ID
  static Future<ContratoAprendiz?> buscarContrato(String contratoId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/contrato-aprendiz/listar/$contratoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contratoData = data['dados'] ?? data['data'] ?? data;
        return ContratoAprendiz.fromJson(contratoData);
      } else {
        throw Exception('Contrato não encontrado');
      }
    } catch (e) {
      print('❌ Erro ao buscar contrato de aprendiz: $e');
      rethrow;
    }
  }

  /// Cria um novo contrato de jovem aprendiz
  static Future<bool> criarContrato(Map<String, dynamic> dados) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/contrato-aprendiz'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      print(
          '📡 Response status criar contrato aprendiz: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Erro ao criar contrato de aprendiz: $e');
      rethrow;
    }
  }

  /// Atualiza um contrato existente
  static Future<bool> atualizarContrato(
      String id, Map<String, dynamic> dados) async {
    try {
      ////print('📝 Atualizando contrato: $id');

      final response = await http.put(
        Uri.parse('$baseUrl/contrato-aprendiz/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      ////print('❌ Erro ao atualizar contrato: $e');
      throw Exception('Erro ao atualizar contrato: $e');
    }
  }

  /// Cria um novo contrato de jovem aprendiz
  static Future<dynamic> criarContratoJovemAprendiz(
      Map<String, dynamic> dados) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/contrato-aprendiz/cadastrar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final contratoData = data['dados'] ?? data['data'] ?? data;
        return ContratoAprendiz.fromJson(contratoData);
      } else {
        String errorMsg = 'Erro ao criar contrato';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['mensagem'] != null) {
            errorMsg = data['mensagem'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      ////print('❌ Erro ao criar contrato: $e');
      throw Exception('Erro ao criar contrato: $e');
    }
  }

  /// Atualiza um contrato de jovem aprendiz existente
  static Future<bool> atualizarContratoJovemAprendiz(
      String contratoId, Map<String, dynamic> dados) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/contrato-aprendiz/alterar/$contratoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sucesso'] == true || data['success'] == true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['mensagem'] ??
            errorData['message'] ??
            'Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar contrato: $e');
    }
  }

  /// Busca um contrato de jovem aprendiz por ID
  static Future<dynamic> buscarContratoJovemAprendiz(String contratoId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/contrato-aprendiz/listar/$contratoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['dados'] ?? data['data'] ?? data;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar contrato: $e');
    }
  }

  /// Exclui um contrato
  static Future<bool> excluirContrato(String contratoId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/contrato-aprendiz/$contratoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          '📡 Response status excluir contrato aprendiz: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Erro ao excluir contrato de aprendiz: $e');
      rethrow;
    }
  }

  /// Altera o status de um contrato
  static Future<bool> alterarStatusContrato(
    String id,
    String novoStatus,
    DateTime? dataDesligamento,
  ) async {
    try {
      ////print('🔄 Alterando status do contrato $id para: $novoStatus');

      final response = await http.put(
        Uri.parse('$baseUrl/contrato-aprendiz/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'status': novoStatus,
          'data_desligamento': dataDesligamento?.toIso8601String()
        }),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      ////print('❌ Erro ao alterar status: $e');
      throw Exception('Erro ao alterar status: $e');
    }
  }

  /// Busca jovens aprendizes para seleção no contrato
  static Future<List<Map<String, dynamic>>> buscarAprendizes(
      String query) async {
    try {
      ////print('🎓 Buscando aprendizes: $query');

      // ✅ AGORA buscarCandidato retorna Map, não List
      final resultado = await CandidatoService.buscarCandidato(
        query,
        tipoRegime: 1, // 1 = Aprendiz
      );

      // ✅ EXTRAIR A LISTA DE CANDIDATOS DO MAP
      final candidatos = resultado['candidatos'] as List<Candidato>;

      List<Map<String, dynamic>> aprendizesFormatados = [];
      for (var candidato in candidatos) {
        print('🎓 Aprendizes formatados: $candidato');
        aprendizesFormatados.add({
          'id': candidato.id?.toString(),
          'nome': candidato.nomeCompleto ?? '',
          'cpf': candidato.cpf ?? '',
          'email': candidato.email ?? '',
          'curso': candidato.formacoesAcademicas?.isNotEmpty == true
              ? candidato.formacoesAcademicas!.first.curso
              : '',
          'cursoAtual': candidato.cursoAtual ?? '',
          // Dados da instituição vindos diretamente do JSON do backend
          'cd_instituicao_ensino': candidato.formacoesAcademicas?.isNotEmpty ==
                  true
              ? candidato.formacoesAcademicas!.first.instituicaoId?.toString()
              : null,
          'instituicao_ensino_nome':
              candidato.formacoesAcademicas?.isNotEmpty == true
                  ? candidato.formacoesAcademicas!.first.instituicaoNaoListada
                  : null,
          // Dados extras para auto-preenchimento
          'nivel_formacao': candidato.formacoesAcademicas?.isNotEmpty == true
              ? candidato.formacoesAcademicas!.first.nivel
              : '',
          'status_curso': candidato.formacoesAcademicas?.isNotEmpty == true
              ? candidato.formacoesAcademicas!.first.statusCurso
              : '',
          'semestre_ano': candidato.formacoesAcademicas?.isNotEmpty == true
              ? candidato.formacoesAcademicas!.first.semestreAnoInicial
              : '',
          'turno': candidato.formacoesAcademicas?.isNotEmpty == true
              ? candidato.formacoesAcademicas!.first.turno
              : '',
          'modalidade_ensino': candidato.formacoesAcademicas?.isNotEmpty == true
              ? candidato.formacoesAcademicas!.first.modalidade
              : '',
          'display_name':
              '${candidato.nomeCompleto ?? ''} - ${candidato.cpf ?? ''}',
        });
      }

      return aprendizesFormatados;
    } catch (e) {
      ////print('❌ Erro ao buscar aprendizes: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> buscarEmpresas(String query) async {
    try {
      ////print('🏢 Buscando empresas: $query');

      final empresas = await EmpresaService.buscarEmpresa(query);

      List<Map<String, dynamic>> empresasFormatadas = [];
      for (var empresa in empresas) {
        // Garantir que o ID nunca seja null
        String empresaId = empresa.id?.toString() ?? '0';

        empresasFormatadas.add({
          'id': empresaId, // ✅ Usar 'id' em vez de 'cd_empresa'
          'cd_empresa': empresaId, // ✅ Manter para compatibilidade
          'razao_social': empresa.razaoSocial ?? '',
          'nome_fantasia': empresa.nomeFantasia ?? '',
          'cnpj': empresa.cnpj ?? '',
          'display_name':
              '${empresa.razaoSocial ?? ''} - ${empresa.cnpj ?? ''}',
          'endereco_completo': empresa.enderecoCompleto ?? '',
        });

        // Debug para verificar os dados
        print(
            '📄 Empresa formatada: ID=$empresaId, Razão=${empresa.razaoSocial}, Endereco=${empresa.enderecoCompleto}');
      }

      return empresasFormatadas;
    } catch (e) {
      ////print('❌ Erro ao buscar empresas: $e');
      return [];
    }
  }

  /// Busca instituições de ensino para dropdown
  /// Usa o InstituicaoService existente
  static Future<List<Map<String, dynamic>>> buscarInstituicoes(
      String query) async {
    try {
      ////print('🏫 Buscando instituições: $query');

      final instituicoes = await InstituicaoService.buscarInstituicao(query);

      List<Map<String, dynamic>> instituicoesFormatadas = [];
      for (var instituicao in instituicoes) {
        instituicoesFormatadas.add({
          'id': instituicao.id?.toString(),
          'razao_social': instituicao.razaoSocial ?? '',
          'nome_fantasia': instituicao.nomeFantasia ?? '',
          'campus': instituicao.campus ?? '',
          'cnpj': instituicao.cnpj ?? '',
          'display_name':
              '${instituicao.razaoSocial ?? ''} - ${instituicao.campus ?? ''}',
          'endereco_completo': instituicao.enderecoCompleto ?? '',
        });
      }

      return instituicoesFormatadas;
    } catch (e) {
      ////print('❌ Erro ao buscar instituições: $e');
      return [];
    }
  }

  /// Busca instituição por ID específico
  /// Para auto-carregamento quando estudante é selecionado
  static Future<Map<String, dynamic>?> buscarInstituicaoPorId(
      String instituicaoId) async {
    try {
      ////print('🏫 Buscando instituição por ID: $instituicaoId');

      final response = await http.get(
        Uri.parse('$baseUrl/instituicao/buscar/$instituicaoId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final instituicaoData = data['dados'] ?? data['data'] ?? data;

        if (instituicaoData != null) {
          return {
            'id': instituicaoData['id']?.toString() ??
                instituicaoData['cd_instituicao_ensino']?.toString(),
            'razao_social': instituicaoData['razao_social'] ?? '',
            'nome_fantasia': instituicaoData['nome_fantasia'] ?? '',
            'campus': instituicaoData['campus'] ?? '',
            'cnpj': instituicaoData['cnpj'] ?? '',
            'display_name':
                '${instituicaoData['razao_social'] ?? ''} - ${instituicaoData['campus'] ?? ''}',
          };
        }
      }
      return null;
    } catch (e) {
      ////print('❌ Erro ao buscar instituição por ID: $e');
      return null;
    }
  }

  /// Busca supervisores por empresa
  static Future<List<Map<String, dynamic>>> buscarSupervisoresPorEmpresa(
      String empresaId) async {
    try {
      ////print('👨‍💼 Buscando supervisores da empresa: $empresaId');

      final response = await http.get(
        Uri.parse('$baseUrl/supervisor/empresa/listar/$empresaId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final supervisoresData =
            data['dados'] ?? data['data'] ?? data['supervisores'] ?? [];

        List<Map<String, dynamic>> supervisores = [];
        for (var supervisorJson in supervisoresData) {
          supervisores.add({
            'id': supervisorJson['id']?.toString() ??
                supervisorJson['cd_supervisor']?.toString(),
            'nome': supervisorJson['nome'] ?? '',
            'cargo': supervisorJson['cargo'] ?? '',
            'email': supervisorJson['email'] ?? '',
            'formacao': supervisorJson['formacao'] ?? '',
            'cpf': supervisorJson['cpf'] ?? '',
            'display_name':
                '${supervisorJson['nome'] ?? ''} - ${supervisorJson['cargo'] ?? ''}',
          });
        }

        return supervisores;
      } else {
        throw Exception('Erro ao buscar supervisores');
      }
    } catch (e) {
      ////print('❌ Erro ao buscar supervisores: $e');
      return [];
    }
  }

  /// Busca modelos de contrato
  static Future<Map<String, dynamic>> listarModelosContrato({
    int page = 1,
    int limit = 20,
    String? search,
    int? idTipoModelo,
    bool? ativo,
    bool? modelo,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (idTipoModelo != null) {
        queryParams['id_tipo_modelo'] = idTipoModelo.toString();
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (modelo != null) {
        queryParams['modelo'] = modelo.toString();
      }

      final uri = Uri.parse('$baseUrl/modelo/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      ////print('Response status: ${response.statusCode}');
      ////print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'modelos': (data['dados'] as List)
              .map((json) => ModeloContrato.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar modelos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar modelos: $e');
    }
  }

  /// Busca taxa financeira da empresa
  static Future<List> buscarPlanoPagamento(String empresaId) async {
    try {
      ////print('💰 Buscando planos de pagamento da empresa: $empresaId');

      final response = await http.get(
        Uri.parse('$baseUrl/empresa_plano/empresa/listar/$empresaId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dados = data['dados'] ?? [];

        if (dados is List) {
          return dados.map((json) => PlanoPagamento.fromJson(json)).toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Erro ao buscar planos de pagamento');
      }
    } catch (e) {
      ////print('❌ Erro ao buscar planos de pagamento: $e');
      throw Exception('Erro ao buscar planos de pagamento: $e');
    }
  }

  /// Cria um aditivo para o contrato de estágio
  static Future<bool> criarAditivo(
      String contratoId, Map<String, dynamic> dados) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse(
            '${AppConfig.baseUrl}/contrato-aprendiz/$contratoId/aditivos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      print('📡 Response status criar aditivo: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Tentar extrair mensagem de erro estruturada do response
        String errorMessage =
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}';

        try {
          if (response.body.isNotEmpty) {
            final errorData = json.decode(response.body);

            // Verificar se existe campo 'erro' na resposta
            if (errorData['erro'] != null) {
              errorMessage = errorData['erro'].toString();
            }
            // Se não houver campo 'erro', tentar 'message' ou outros campos comuns
            else if (errorData['message'] != null) {
              errorMessage = errorData['message'].toString();
            }
            // Se a resposta for apenas uma string
            else if (errorData is String) {
              errorMessage = errorData;
            }
          }
        } catch (parseError) {
          print('❌ Erro ao fazer parse da resposta de erro: $parseError');
          // Manter mensagem de erro HTTP padrão se não conseguir fazer parse
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erro ao criar aditivo: $e');
      rethrow;
    }
  }

  /// Exporta contrato para PDF
  /// NOTA: Este método precisa ser implementado no backend
  static Future<String?> exportarCSV({
    int page = 1,
    int limit = 20,
    bool? ativo,
    bool? isDefault,
    String? search,
    String? status,
    String? numero,
    bool? apenasComAditivo,
    String? instituicao,
    String? dataInicioVigenciaDe,
    String? dataInicioVigenciaAte,
    String? dataFinalVigenciaDe,
    String? dataFinalVigenciaAte,
    String? dataEncerramentoDe,
    String? dataEncerramentoAte,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (numero != null && numero.isNotEmpty) {
        queryParams['numero'] = numero;
      }
      if (apenasComAditivo != null) {
        queryParams['apenas_com_aditivo'] = apenasComAditivo.toString();
      }

      if (instituicao != null && instituicao.isNotEmpty) {
        queryParams['instituicao'] = instituicao;
      }
      if (dataInicioVigenciaDe != null && dataInicioVigenciaDe.isNotEmpty) {
        queryParams['dataInicioVigenciaDe'] = dataInicioVigenciaDe;
      }
      if (dataInicioVigenciaAte != null && dataInicioVigenciaAte.isNotEmpty) {
        queryParams['dataInicioVigenciaAte'] = dataInicioVigenciaAte;
      }
      if (dataFinalVigenciaDe != null && dataFinalVigenciaDe.isNotEmpty) {
        queryParams['dataFinalVigenciaDe'] = dataFinalVigenciaDe;
      }
      if (dataFinalVigenciaAte != null && dataFinalVigenciaAte.isNotEmpty) {
        queryParams['dataFinalVigenciaAte'] = dataFinalVigenciaAte;
      }
      if (dataEncerramentoDe != null && dataEncerramentoDe.isNotEmpty) {
        queryParams['dataEncerramentoDe'] = dataEncerramentoDe;
      }
      if (dataEncerramentoAte != null && dataEncerramentoAte.isNotEmpty) {
        queryParams['dataEncerramentoAte'] = dataEncerramentoAte;
      }

      final uri = Uri.parse('$baseUrl/contrato-aprendiz/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename = _extrairFilename(
                response.headers['content-disposition']) ??
            'contrato_aprendiz_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        // Usa o helper condicional (Web = download, Mobile/Desktop = salva no disco)
        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(bytes, filename: filename);

        return savedPath; // Na Web será null, no mobile/desktop será o path
      } else {
        throw Exception('Erro ao exportar CSV (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao exportar status de turnos: $e');
    }
  }

  static Future<String?> exportarCSVSeguradora({
    int page = 1,
    int limit = 20,
    bool? ativo,
    bool? isDefault,
    String? search,
    String? status,
    String? numero,
    bool? apenasComAditivo,
    String? instituicao,
    String? dataInicioVigenciaDe,
    String? dataInicioVigenciaAte,
    String? dataFinalVigenciaDe,
    String? dataFinalVigenciaAte,
    String? dataEncerramentoDe,
    String? dataEncerramentoAte,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (numero != null && numero.isNotEmpty) {
        queryParams['numero'] = numero;
      }
      if (apenasComAditivo != null) {
        queryParams['apenas_com_aditivo'] = apenasComAditivo.toString();
      }

      if (instituicao != null && instituicao.isNotEmpty) {
        queryParams['instituicao'] = instituicao;
      }
      if (dataInicioVigenciaDe != null && dataInicioVigenciaDe.isNotEmpty) {
        queryParams['dataInicioVigenciaDe'] = dataInicioVigenciaDe;
      }
      if (dataInicioVigenciaAte != null && dataInicioVigenciaAte.isNotEmpty) {
        queryParams['dataInicioVigenciaAte'] = dataInicioVigenciaAte;
      }
      if (dataFinalVigenciaDe != null && dataFinalVigenciaDe.isNotEmpty) {
        queryParams['dataFinalVigenciaDe'] = dataFinalVigenciaDe;
      }
      if (dataFinalVigenciaAte != null && dataFinalVigenciaAte.isNotEmpty) {
        queryParams['dataFinalVigenciaAte'] = dataFinalVigenciaAte;
      }
      if (dataEncerramentoDe != null && dataEncerramentoDe.isNotEmpty) {
        queryParams['dataEncerramentoDe'] = dataEncerramentoDe;
      }
      if (dataEncerramentoAte != null && dataEncerramentoAte.isNotEmpty) {
        queryParams['dataEncerramentoAte'] = dataEncerramentoAte;
      }

      final uri =
          Uri.parse('$baseUrl/contrato-aprendiz/exportar/contratos-seguro')
              .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename = _extrairFilename(
                response.headers['content-disposition']) ??
            'contrato_aprendiz_seguro${DateTime.now().toIso8601String().substring(0, 10)}.csv';

        // Usa o helper condicional (Web = download, Mobile/Desktop = salva no disco)
        final downloader = getCsvDownloader();
        final savedPath = await downloader.saveCsv(bytes, filename: filename);

        return savedPath; // Na Web será null, no mobile/desktop será o path
      } else {
        throw Exception('Erro ao exportar CSV (HTTP ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Erro ao exportar status de turnos: $e');
    }
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

  /// Constrói endereço completo a partir dos dados do jovem
  static String _buildEnderecoCompleto(Map<String, dynamic> jovem) {
    List<String> enderecoParts = [];

    if (jovem['logradouro'] != null &&
        jovem['logradouro'].toString().isNotEmpty) {
      enderecoParts.add(jovem['logradouro'].toString());
    }

    if (jovem['numero'] != null && jovem['numero'].toString().isNotEmpty) {
      enderecoParts.add('nº ${jovem['numero']}');
    }

    if (jovem['bairro'] != null && jovem['bairro'].toString().isNotEmpty) {
      enderecoParts.add(jovem['bairro'].toString());
    }

    if (jovem['cidade'] != null && jovem['cidade'].toString().isNotEmpty) {
      enderecoParts.add(jovem['cidade'].toString());
    }

    if (jovem['estado'] != null && jovem['estado'].toString().isNotEmpty) {
      enderecoParts.add(jovem['estado'].toString());
    }

    if (jovem['cep'] != null && jovem['cep'].toString().isNotEmpty) {
      enderecoParts.add('CEP: ${jovem['cep']}');
    }

    return enderecoParts.isNotEmpty
        ? enderecoParts.join(', ')
        : 'Endereço não informado';
  }

  /// Gera PDF do contrato
  //POST /gerar-pdf-contrato
  static Future<Uint8List> gerarPdfContrato({
    required int id,
    required bool download,
    required int? idModelo,
  }) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/gerarTemplate/montar-pdf-contrato'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id': id,
          'download': download,
          'idModelo': idModelo,
        }),
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Retorna os bytes do PDF
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        throw Exception('Contrato não encontrado');
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Erro ao gerar PDF: $e');
      throw Exception('Erro ao gerar PDF do contrato: $e');
    }
  }

  //Gerar PDF Documento Complementar
  static Future<Uint8List> gerarPdfDocComplementar({
    required int id,
    required bool download,
    required int? idModelo,
  }) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse(
            '${AppConfig.baseUrl}/documentos-complementares/contratos/$id/pdf'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id': id,
          'download': download,
          'cd_template_modelo': idModelo,
        }),
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Retorna os bytes do PDF
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        throw Exception('Contrato não encontrado');
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Erro ao gerar PDF: $e');
      throw Exception('Erro ao gerar PDF do contrato: $e');
    }
  }

  /// Busca aditivo específico
  static Future<Map<String, dynamic>?> buscarAditivo(String aditivoId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/contrato-aprendiz/aditivos/$aditivoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map && data['dados'] != null) {
          return data['dados'];
        } else if (data is Map) {
          return data.cast<String, dynamic>();
        }

        return null;
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Erro ao buscar aditivo de aprendiz: $e');
      rethrow;
    }
  }

  /// Atualiza aditivo
  static Future<bool> atualizarAditivo(
      String aditivoId, Map<String, dynamic> dados) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/contrato-aprendiz/aditivos/$aditivoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      print(
          '📡 Response status atualizar aditivo aprendiz: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Erro ao atualizar aditivo de aprendiz: $e');
      rethrow;
    }
  }

  /// Altera status do aditivo
  static Future<bool> alterarStatusAditivo(
      String aditivoId, String novoStatus, DateTime? dataDesligamento) async {
    try {
      final token = await StorageService.getToken();

      final Map<String, dynamic> dados = {
        'status': novoStatus,
      };

      if (dataDesligamento != null) {
        dados['data_desligamento'] = dataDesligamento.toIso8601String();
      }

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/contrato-aprendiz/aditivos/$aditivoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      print(
          '📡 Response status alterar status aditivo: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Erro ao alterar status do aditivo: $e');
      rethrow;
    }
  }

  /// Gera PDF do aditivo
  static Future<Uint8List> gerarPdfAditivo({
    required int aditivoId,
    required bool download,
    required int cdTemplateModelo,
  }) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/gerarTemplate/gerar-pdf-aditivo'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'id': aditivoId,
          'download': download,
          'cd_template_modelo': cdTemplateModelo
        }),
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Retorna os bytes do PDF
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        throw Exception('Contrato não encontrado');
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Erro ao gerar PDF do aditivo: $e');
      throw Exception('Erro ao gerar PDF do aditivo: $e');
    }
  }

  /// Lista contratos do candidato (Jovem Aprendiz) com paginação
  static Future<Map<String, dynamic>> listarPorCandidato(
    String candidatoId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri =
          Uri.parse('${AppConfig.baseUrl}/contrato/candidato/$candidatoId')
              .replace(queryParameters: {'page': '$page', 'limit': '$limit'});

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lista =
            (data is Map ? (data['dados'] ?? data['data'] ?? data) : data);

        final items = (lista is List ? lista : (lista['items'] ?? [])) as List;
        final pagination = (data is Map ? (data['pagination'] ?? {}) : {});

        return {
          'contratos': items.map((e) => ContratoAprendiz.fromJson(e)).toList(),
          'pagination': {
            'currentPage': pagination['currentPage'] ?? page,
            'totalPages': pagination['totalPages'] ?? 1,
            'totalItems': pagination['totalItems'] ?? items.length,
          },
        };
      }

      throw Exception(
          'Erro ao listar contratos do candidato (${response.statusCode})');
    } catch (e) {
      throw Exception('Erro ao listar contratos do candidato: $e');
    }
  }
}
