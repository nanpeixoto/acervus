// lib/services/contrato_estagio_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/models/_contratos/modelo/modelo_contrato.dart';
import 'package:sistema_estagio/models/_financeiro/plano_pagamento.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/_contratos/contrato/contrato_estagio.dart';
import '../../../models/_organizacoes/empresa/empresa.dart';
import '../../../models/_pessoas/candidato/candidato.dart';
import '../../../models/_organizacoes/instituicao/instituicao.dart';
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';
import '../../_organizacoes/empresa/empresa_service.dart';
import '../../_pessoas/candidato/candidato_service.dart';
import '../../_organizacoes/instituicao/instituicao_service.dart';
import '../modelo/modelo_contrato_service.dart';

class ContratoEstagioService {
  static String baseUrl = AppConfig.baseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==========================================
  // MÉTODOS PRINCIPAIS DO CONTRATO
  // ==========================================

  /// Cria um novo contrato de estágio
  static Future<ContratoEstagio?> criarContrato(
      Map<String, dynamic> dados) async {
    try {
      ////print('📝 Criando contrato de estágio...');
      ////print('📊 Dados: ${jsonEncode(dados)}');

      final response = await http.post(
        Uri.parse('$baseUrl/contrato-estagio/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      ////print('📊 Resposta: ${response.statusCode}');
      ////print('📊 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final contratoData = data['dados'] ?? data['data'] ?? data;
        return ContratoEstagio.fromJson(contratoData);
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

  /// Busca contrato por ID
  static Future<ContratoEstagio?> buscarContrato(String id) async {
    try {
      ////print('🔍 Buscando contrato: $id');

      final response = await http.get(
        Uri.parse('$baseUrl/contrato-estagio/listar/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contratoData = data['dados'] ?? data['data'] ?? data;
        return ContratoEstagio.fromJson(contratoData);
      } else {
        throw Exception('Contrato não encontrado');
      }
    } catch (e) {
      ////print('❌ Erro ao buscar contrato: $e');
      throw Exception('Erro ao buscar contrato: $e');
    }
  }

  static Future<Map<String, dynamic>?> buscarConteudoModelo({
    required String contratoId,
    required String cdTemplateModelo,
  }) async {
    try {
      final url =
          '${AppConfig.baseUrl}/documentos-complementares/contratos/$contratoId/preview';
      final queryParams = {'cd_template_modelo': cdTemplateModelo};

      final uri = Uri.parse(url).replace(queryParameters: queryParams);

      print('📡 GET: $uri');

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      print('📨 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Dados recebidos: ${data.keys}');
        return data;
      } else {
        print('❌ Erro HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Erro ao buscar conteúdo: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro na requisição: $e');
      throw Exception('Erro ao buscar conteúdo do modelo: $e');
    }
  }

  static Future<Map<String, dynamic>?> salvarDocumentoComplementar({
    required String contratoId,
    required String cdTemplateModelo,
    required String conteudoHtml,
  }) async {
    try {
      final url =
          '${AppConfig.baseUrl}/documentos-complementares/contratos/$contratoId';

      final body = {
        'cd_template_modelo': int.parse(cdTemplateModelo),
        'conteudo_html': conteudoHtml,
      };

      print('📡 POST: $url');
      print(
          '📦 Body: cd_template_modelo=${body['cd_template_modelo']}, conteudo_html=${conteudoHtml.length} chars');

      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      print('📨 Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('✅ Documento salvo: ${data['mensagem']}');
        print(
            '📋 ID: ${data['cd_doc_complementar']}, Data: ${data['data_criacao']}');
        return data;
      } else {
        print('❌ Erro HTTP ${response.statusCode}: ${response.body}');
        throw Exception('Erro ao salvar documento: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro na requisição: $e');
      throw Exception('Erro ao salvar documento complementar: $e');
    }
  }

  //Criar método gerarPdfContrato para fazer o download do PDF do contrato passando ID do contrato e download = true
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

  /// Cria um aditivo para o contrato de estágio
  static Future<bool> criarAditivo(
      String contratoId, Map<String, dynamic> dados) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/contrato-estagio/$contratoId/aditivos'),
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

  static Future<Map<String, dynamic>?> criarAditivoComResposta(
    String contratoId,
    Map<String, dynamic> dados,
  ) async {
    try {
      final token = await StorageService.getToken();
      final url = '${AppConfig.baseUrl}/contrato-estagio/$contratoId/aditivos';

      print('📤 POST $url');
      print('📦 Dados: $dados');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      print('📡 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Retornar dados completos da resposta
        return responseData;
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao criar aditivo com resposta: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> listarAditivos(
      String contratoId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/contrato-estagio/$contratoId/aditivos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> aditivosList = [];

        if (data is Map && data['dados'] != null) {
          aditivosList = data['dados'];
        } else if (data is List) {
          aditivosList = data;
        }

        return aditivosList.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('❌ Erro ao listar aditivos: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> buscarAditivo(String aditivoId) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/contrato-estagio/aditivos/$aditivoId'),
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
      print('❌ Erro ao buscar aditivo: $e');
      rethrow;
    }
  }

  static Future<bool> atualizarAditivo(
      String aditivoId, Map<String, dynamic> dados) async {
    try {
      final token = await StorageService.getToken();
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/contrato-estagio/aditivos/$aditivoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(dados),
      );

      print('📡 Response status atualizar aditivo: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        // Mesma lógica de extração de erro
        String errorMessage =
            'Erro HTTP ${response.statusCode}: ${response.reasonPhrase}';

        try {
          if (response.body.isNotEmpty) {
            final errorData = json.decode(response.body);

            if (errorData['erro'] != null) {
              errorMessage = errorData['erro'].toString();
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'].toString();
            } else if (errorData is String) {
              errorMessage = errorData;
            }
          }
        } catch (parseError) {
          print('❌ Erro ao fazer parse da resposta de erro: $parseError');
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erro ao atualizar aditivo: $e');
      rethrow;
    }
  }

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

  /// Lista contratos com filtros
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

      final uri = Uri.parse('$baseUrl/contrato-estagio/listar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'contratos': (data['dados'] as List)
              .map((json) => ContratoEstagio.fromJson(json))
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

  /// Lista contratos do candidato (Estágio) com paginação
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
          'contratos': items.map((e) => ContratoEstagio.fromJson(e)).toList(),
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

  // ==========================================
  // MÉTODOS DE BUSCA PARA DROPDOWNS
  // ==========================================

  /// Busca empresas para dropdown (por primeiros 3 caracteres ou CNPJ)
  /// Usa o EmpresaService existente
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

  /// Busca supervisores por nome (caseado)
  static Future<List<Map<String, dynamic>>> buscarSupervisoresPorNome(
      String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/supervisor/listar?search=$query'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final supervisoresData = data['dados'] ?? data['data'] ?? [];

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
        throw Exception('Erro ao buscar supervisores por nome');
      }
    } catch (e) {
      ////print('❌ Erro ao buscar supervisores por nome: $e');
      return [];
    }
  }

  /// Busca estudantes para dropdown (por primeiros 3 caracteres ou CPF)
  /// Usa o CandidatoService existente e extrai dados da instituição
  static Future<List<Map<String, dynamic>>> buscarEstudantes(
      String query) async {
    try {
      ////print('🎓 Buscando estudantes: $query');

      // ✅ AGORA buscarCandidato retorna Map, não List
      final resultado = await CandidatoService.buscarCandidato(
        query // 2 = Estágio
      );

      // ✅ EXTRAIR A LISTA DE CANDIDATOS DO MAP
      final candidatos = resultado['candidatos'] as List<Candidato>;

      List<Map<String, dynamic>> estudantesFormatados = [];
      for (var candidato in candidatos) {
        print('🎓 Estudantes formatados: $candidato');
        estudantesFormatados.add({
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

      return estudantesFormatados;
    } catch (e) {
      ////print('❌ Erro ao buscar estudantes: $e');
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
        Uri.parse('$baseUrl/supervisor/empresa/listar/$empresaId?ativo=true'),
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

  static Future<Map<String, dynamic>> listarModelosContratoComplementar({
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

      queryParams['complementar'] = 'true';

      final uri = Uri.parse('$baseUrl/modelo/listar/')
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

  // ==========================================
  // MÉTODOS DE ATUALIZAÇÃO E EXCLUSÃO
  // ==========================================

  /// Atualiza contrato
  static Future<bool> atualizarContrato(
      String id, Map<String, dynamic> dados) async {
    try {
      ////print('📝 Atualizando contrato: $id');

      final response = await http.put(
        Uri.parse('$baseUrl/contrato-estagio/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      ////print('❌ Erro ao atualizar contrato: $e');
      throw Exception('Erro ao atualizar contrato: $e');
    }
  }

  /// Altera status do contrato
  static Future<bool> alterarStatusContrato(
    String id,
    String novoStatus,
    DateTime? dataDesligamento,
  ) async {
    try {
      ////print('🔄 Alterando status do contrato $id para: $novoStatus');

      final response = await http.put(
        Uri.parse('$baseUrl/contrato-estagio/alterar/$id'),
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
        Uri.parse('${AppConfig.baseUrl}/contrato-estagio/aditivos/$aditivoId'),
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

      final uri = Uri.parse('$baseUrl/contrato-estagio/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename = _extrairFilename(
                response.headers['content-disposition']) ??
            'contrato_estagio_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

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
          Uri.parse('$baseUrl/contrato-estagio/exportar/contratos-seguro')
              .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename = _extrairFilename(
                response.headers['content-disposition']) ??
            'contrato_estagio_seguro${DateTime.now().toIso8601String().substring(0, 10)}.csv';

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

  /// Exclui contrato (soft delete)
  static Future<bool> excluirContrato(String id) async {
    try {
      ////print('🗑️ Excluindo contrato: $id');

      final response = await http.delete(
        Uri.parse('$baseUrl/contrato-estagio/deletar/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      ////print('❌ Erro ao excluir contrato: $e');
      throw Exception('Erro ao excluir contrato: $e');
    }
  }
}
