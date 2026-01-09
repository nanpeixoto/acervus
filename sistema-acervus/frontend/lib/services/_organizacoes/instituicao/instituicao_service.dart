// lib/services/instituicao_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/utils/app_config.dart';
import '../../../models/_organizacoes/instituicao/instituicao.dart';
import '../../../models/_pessoas/candidato/candidato.dart' as estg;
import '../../../models/_pessoas/candidato/jovem_aprendiz.dart' as jovem;
import '../../../models/_contratos/contrato/contrato.dart' as contrato;
import '../../_core/storage_service.dart';

class InstituicaoService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers com autenticação
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Headers para upload de arquivos
  static Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  // CRUD BÁSICO
  static Future<Map<String, dynamic>> listarInstituicoes({
    int page = 1,
    int limit = 10,
    String? search,
    String? tipo,
    String? cidade,
    String? cnpj,
    String? estado,
    bool? ativo,
    String? nivel,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (cidade != null) {
        queryParams['cidade'] = cidade;
      }
      if (estado != null) {
        queryParams['estado'] = estado;
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }
      if (nivel != null) {
        queryParams['nivel'] = nivel;
      }

      final uri = Uri.parse('$baseUrl/instituicao/buscar')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'instituicoes': (data['dados'] as List)
              .map((json) => InstituicaoEnsino.fromJson(json))
              .toList(),
          'pagination': data['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar instituições');
      }
    } catch (e) {
      throw Exception('Erro ao carregar instituições: $e');
    }
  }

  static Future<List<InstituicaoEnsino>> buscarInstituicao(
      String string) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicao/buscar').replace(queryParameters: {
          'nome': string,
          'cnpj': string,
          'ativo': 'false'
        }),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // data['dados'] é uma lista!
        return (data['dados'] as List)
            .map((json) => InstituicaoEnsino.fromJson(json))
            .toList();
      } else {
        throw Exception('Instituição não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao buscar instituição: $e');
    }
  }

  // Método para buscar instituição completa por ID
  static Future<Map<String, dynamic>> buscarInstituicaoPorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicao/buscar/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Instituição não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao buscar instituição: $e');
    }
  }

// Método para buscar endereços da instituição
  static Future<List<Map<String, dynamic>>> buscarEnderecosInstituicao(
      String instituicaoId,
      {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/endereco/instituicao/listar/$instituicaoId?page=$page&limit=10'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
            data is List ? data : data['dados'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

// Método para buscar representantes legais
  static Future<List<Map<String, dynamic>>> buscarRepresentantesInstituicao(
      String instituicaoId,
      {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/representantelegal/instituicao/listar/$instituicaoId?page=$page&limit=10'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
            data is List ? data : data['dados'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

// Método para buscar orientadores
  static Future<List<Map<String, dynamic>>> buscarOrientadoresInstituicao(
      String instituicaoId,
      {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/orientador/instituicao/listar/$instituicaoId?page=$page&limit=10'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
            data is List ? data : data['dados'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

// Método para buscar usuários da instituição
  static Future<List<Map<String, dynamic>>> buscarUsuariosInstituicao(
      String instituicaoId,
      {int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/usuarioInstituicao/instituicao/listar/$instituicaoId?page=$page&limit=10'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
            data is List ? data : data['dados'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<InstituicaoEnsino>> buscarInstituicaoTodas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicao/buscar').replace(queryParameters: {
          'page': 1,
          'limit': 15000,
        }),
        headers: await _getHeaders(),
      );

      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // data['dados'] é uma lista!
        print('Response body: ${data['dados']}');
        return (data['dados'] as List)
            .map((json) => InstituicaoEnsino.fromJson(json))
            .toList();
      } else {
        throw Exception('Instituição não encontrada');
      }
    } catch (e) {
      throw Exception('Erro ao buscar instituição: $e');
    }
  }

  static Future<bool> criarInstituicao(Map<String, dynamic> dados) async {
    try {
      // Monta o JSON conforme o SWAGGER especifica
      final body = {
        "razao_social": dados["razao_social"],
        "nome_fantasia": dados["nome_fantasia"],
        "cnpj": dados["cnpj"],
        "email_principal": dados["email_principal"],
        "mantenedora": dados["mantenedora"],
        "campus": dados["campus"],
        "telefone": dados["telefone"],
        "celular": dados["celular"],
        "unidade": dados["unidade"],
        "cep": dados["cep"],
        "logradouro": dados["logradouro"],
        "numero": dados["numero"],
        "bairro": dados["bairro"],
        "cidade": dados["cidade"],
        "uf": dados["uf"],
        "representante_legal": dados["representante_legal"],
        "cpf": dados["cpf"],
        "data_criacao": dados["data_criacao"],
        "procedimento": dados["procedimento"],
        "nome_modelo": dados["nome_modelo"],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/instituicao/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        // Tenta extrair a mensagem do backend
        String errorMsg = 'Erro ao criar instituição';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['erro'] != null) {
            errorMsg = data['erro'].toString();
            print('Error message BackEnd: $errorMsg');
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Erro ao criar instituição: $e');
    }
  }

  static Future<bool> atualizarInstituicao(
      String id, Map<String, dynamic> dados) async {
    try {
      final body = {
        "razao_social": dados["razao_social"],
        "nome_fantasia": dados["nome_fantasia"],
        "cnpj": dados["cnpj"],
        "email_principal": dados["email_principal"],
        "mantenedora": dados["mantenedora"],
        "campus": dados["campus"],
        "telefone": dados["telefone"],
        "celular": dados["celular"],
        "unidade": dados["unidade"],
        "cep": dados["cep"],
        "logradouro": dados["logradouro"],
        "numero": dados["numero"],
        "bairro": dados["bairro"],
        "cidade": dados["cidade"],
        "uf": dados["uf"],
        "representante_legal": dados["representante_legal"],
        "cpf": dados["cpf"],
        "data_criacao": dados["data_criacao"],
        "procedimento": dados["procedimento"],
        "nome_modelo": dados["nome_modelo"],
      };

      final response = await http.put(
        Uri.parse('$baseUrl/instituicao/editar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        // Tenta extrair a mensagem do backend
        String errorMsg = 'Erro ao atualizar instituição';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['erro'] != null) {
            errorMsg = data['erro'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Erro ao atualizar instituição: $e');
    }
  }

  static Future<Map<String, dynamic>> obterResumoDashboardIE(String id) async {
    final uri = Uri.parse('${AppConfig.devBaseUrl}/dashboard/ie/$id');
    final response = await http.get(uri, headers: await _getHeaders());

    if (response.statusCode != 200) {
      throw Exception(
        'Erro ${response.statusCode} ao carregar resumo institucional.',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return {
      'totalVagasAbertas': data['totalVagasAbertas'] ?? 0,
      'totalEstudantesIE': data['totalEstudantesIE'] ?? 0,
    };
  }

  //POST /gerar-pdf-contrato
  static Future<Uint8List> gerarPdfContratoIE({
    required int id,
    required bool download,
    required int idModelo,
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
          "idModelo": idModelo,
          'download': download,
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

  static Future<bool> deletarInstituicao(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/instituicoes/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao deletar instituição: $e');
    }
  }

  //Criar Método bloquear instituição
  static Future<bool> bloquearInstituicao(String id,
      {bool bloqueado = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/instituicao/bloquear/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({"bloqueado": bloqueado}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Tenta extrair mensagem de erro do backend
        String errorMsg = 'Erro ao bloquear instituição';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['mensagem'] != null) {
            errorMsg = data['mensagem'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Erro ao bloquear instituição: $e');
    }
  }

  // VALIDAÇÃO DE CNPJ
  // VALIDAÇÃO E CONSULTA DE CNPJ MELHORADA
  static Future<Map<String, dynamic>> validarCNPJ(String cnpj) async {
    print('[validarCNPJ] Iniciando validação para CNPJ: $cnpj');
    try {
      final cnpjLimpo = cnpj.replaceAll(RegExp(r'\D'), '');
      print('[validarCNPJ] CNPJ limpo: $cnpjLimpo');

      // Validação local primeiro
      /* if (!validarCNPJLocal(cnpjLimpo)) {
        print('[validarCNPJ] CNPJ inválido localmente');
        return {
          'valido': false,
          'erro': 'CNPJ inválido',
          'dados': null,
        };
      }*/

      // Consultar Receita Federal
      print(
          '[validarCNPJ] CNPJ válido localmente, consultando Receita Federal...');
      final dadosReceita = await consultarReceitaFederal(cnpjLimpo);

      print('[validarCNPJ] Resultado consulta Receita Federal: $dadosReceita');

      if (dadosReceita['sucesso'] == true) {
        print('[validarCNPJ] CNPJ válido na Receita Federal');
        return {
          'valido': true,
          'erro': null,
          'dados': dadosReceita['dados'],
        };
      } else {
        print(
            '[validarCNPJ] CNPJ válido localmente, mas erro na Receita Federal: ${dadosReceita['erro']}');
        return {
          'valido': true, // CNPJ é válido localmente
          'erro': dadosReceita['erro'],
          'dados': null,
        };
      }
    } catch (e) {
      print('[validarCNPJ] Erro na validação: $e');
      return {
        'valido': true,
        'erro': 'Erro na validação: $e',
        'dados': null,
      };
    }
  }

// CONSULTA MELHORADA À RECEITA FEDERAL
  static Future<Map<String, dynamic>> consultarReceitaFederal(
      String cnpj) async {
    try {
      final cnpjLimpo = cnpj.replaceAll(RegExp(r'\D'), '');

      // Timeout de 10 segundos
      final response = await http.get(
        Uri.parse('$baseUrl/receita/consulta-cnpj/$cnpjLimpo'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dados = data['dados'];

        // Verificar se retornou erro da API
        if (dados['status'] == 'ERROR') {
          return {
            'sucesso': false,
            'erro':
                dados['message'] ?? 'CNPJ não encontrado na Receita Federal',
            'dados': null,
          };
        }

        // Verificar se o CNPJ está ativo
        if (dados['situacao'] != 'ATIVA') {
          return {
            'sucesso': false,
            'erro': 'CNPJ está inativo: ${dados['situacao']}',
            'dados': dados,
          };
        }

        return {
          'sucesso': true,
          'erro': null,
          'dados': dados,
        };
      } else if (response.statusCode == 429) {
        return {
          'sucesso': false,
          'erro':
              'Muitas consultas realizadas. Tente novamente em alguns minutos.',
          'dados': null,
        };
      } else {
        return {
          'sucesso': false,
          'erro':
              'Erro ao consultar a Receita Federal (${response.statusCode})',
          'dados': null,
        };
      }
    } on TimeoutException {
      return {
        'sucesso': false,
        'erro': 'Timeout na consulta à Receita Federal. Tente novamente.',
        'dados': null,
      };
    } catch (e) {
      return {
        'sucesso': false,
        'erro': 'Erro na consulta: $e',
        'dados': null,
      };
    }
  }

  // MÉTODO PARA BUSCAR E FORMATAR DADOS DO CNPJ
  static Future<Map<String, dynamic>> buscarDadosCNPJ(String cnpj) async {
    try {
      final resultado = await validarCNPJ(cnpj);

      if (!resultado['valido']) {
        return {
          'sucesso': false,
          'erro': resultado['erro'],
          'dadosFormatados': null,
        };
      }

      final dadosReceita = resultado['dados'];

      if (dadosReceita == null) {
        return {
          'sucesso': false,
          'erro': resultado['erro'] ??
              'Não foi possível obter dados da Receita Federal',
          'dadosFormatados': null,
        };
      }

      // Formatar dados para preenchimento automático
      final dadosFormatados = {
        // Dados básicos
        'cnpj': dadosReceita['cnpj'] ?? cnpj,
        'razaoSocial': dadosReceita['nome'] ?? '',
        'nomeFantasia': dadosReceita['fantasia'] ?? '',
        'situacao': dadosReceita['situacao'] ?? '',
        'abertura': dadosReceita['abertura'] ?? '',
        'porte': dadosReceita['porte'] ?? '',
        'naturezaJuridica': dadosReceita['natureza_juridica'] ?? '',

        // Endereço
        'endereco': {
          'cep': dadosReceita['cep']?.replaceAll(RegExp(r'\D'), '') ?? '',
          'logradouro': dadosReceita['logradouro'] ?? '',
          'numero': dadosReceita['numero'] ?? '',
          'complemento': dadosReceita['complemento'] ?? '',
          'bairro': dadosReceita['bairro'] ?? '',
          'cidade': dadosReceita['municipio'] ?? '',
          'uf': dadosReceita['uf'] ?? '',
        },

        // Contatos
        'contatos': {
          'email': dadosReceita['email'] ?? '',
          'telefone': dadosReceita['telefone'] ?? '',
        },

        // Atividades
        'atividadePrincipal': dadosReceita['atividade_principal'] != null &&
                dadosReceita['atividade_principal'].isNotEmpty
            ? dadosReceita['atividade_principal'][0]
            : null,
        'atividadesSecundarias': dadosReceita['atividades_secundarias'] ?? [],

        // Outros dados
        'capitalSocial': dadosReceita['capital_social'] ?? '',
        'simples': dadosReceita['simples'] ?? {},
        'simei': dadosReceita['simei'] ?? {},

        // Status da consulta
        'dataUltimaAtualizacao': dadosReceita['ultima_atualizacao'] ?? '',
      };

      return {
        'sucesso': true,
        'erro': null,
        'dadosFormatados': dadosFormatados,
        'dadosCompletos': dadosReceita,
      };
    } catch (e) {
      return {
        'sucesso': false,
        'erro': 'Erro ao processar dados do CNPJ: $e',
        'dadosFormatados': null,
      };
    }
  }

// MÉTODO PARA FORMATAR CNPJ
  static String formatarCNPJ(String cnpj) {
    final numbers = cnpj.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 14) {
      return '${numbers.substring(0, 2)}.${numbers.substring(2, 5)}.${numbers.substring(5, 8)}/${numbers.substring(8, 12)}-${numbers.substring(12, 14)}';
    }
    return cnpj;
  }

// MÉTODO DE VALIDAÇÃO LOCAL MELHORADO
  // Torna o método privado visível para outras classes (public)
  static bool validarCNPJLocal(String cnpj) {
    if (cnpj.length != 14) {
      print('CNPJ inválido: tamanho diferente de 14');
      return false;
    }

    // Verificar se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1+$').hasMatch(cnpj)) {
      print('CNPJ inválido: todos os dígitos iguais');
      return false;
    }

    List<int> weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    List<int> weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * weights1[i];
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cnpj[12]) != digit1) {
      print('CNPJ inválido: primeiro dígito verificador incorreto');
      return false;
    }

    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * weights2[i];
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;

    bool valido = int.parse(cnpj[13]) == digit2;
    print('Resultado da validação local do CNPJ: $valido');
    return valido;
  }

  // GESTÃO DE CURSOS
  static Future<Map<String, dynamic>> listarCursos(
    String instituicaoId, {
    int page = 1,
    int limit = 10,
    String? search,
    String? nivel,
    String? modalidade,
    bool? ativo,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (nivel != null) {
        queryParams['nivel'] = nivel;
      }
      if (modalidade != null) {
        queryParams['modalidade'] = modalidade;
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri = Uri.parse('$baseUrl/instituicoes/$instituicaoId/cursos')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'cursos': (data['dados']['cursos'] as List)
              .map((json) => Curso.fromJson(json))
              .toList(),
          'pagination': data['dados']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar cursos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar cursos: $e');
    }
  }

  static Future<bool> adicionarCurso(
      String instituicaoId, Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/cursos'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao adicionar curso: $e');
    }
  }

  static Future<bool> atualizarCurso(
      String instituicaoId, String cursoId, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/cursos/$cursoId'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar curso: $e');
    }
  }

  static Future<bool> removerCurso(String instituicaoId, String cursoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/cursos/$cursoId'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao remover curso: $e');
    }
  }

  // GESTÃO DE ESTUDANTES
  static Future<Map<String, dynamic>> listarEstudantes(
    String instituicaoId, {
    int page = 1,
    int limit = 10,
    String? search,
    String? tipo, // ESTAGIARIO ou JOVEM_APRENDIZ
    String? curso,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (curso != null) {
        queryParams['curso'] = curso;
      }
      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$baseUrl/instituicoes/$instituicaoId/estudantes')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'estudantes': data['dados']['estudantes'],
          'pagination': data['dados']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar estudantes');
      }
    } catch (e) {
      throw Exception('Erro ao carregar estudantes: $e');
    }
  }

  static Future<Map<String, dynamic>> listarEstagiarios(
    String instituicaoId, {
    int page = 1,
    int limit = 10,
    String? search,
    String? curso,
    String? semestre,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (curso != null) {
        queryParams['curso'] = curso;
      }
      if (semestre != null) {
        queryParams['semestre'] = semestre;
      }

      final uri = Uri.parse('$baseUrl/instituicoes/$instituicaoId/estagiarios')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'candidatos': (data['dados']['candidatos'] as List)
              .map((json) => estg.Candidato.fromJson(json))
              .toList(),
          'pagination': data['dados']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar candidatos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar candidatos: $e');
    }
  }

  static Future<Map<String, dynamic>> listarJovensAprendizes(
    String instituicaoId, {
    int page = 1,
    int limit = 10,
    String? search,
    String? curso,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (curso != null) {
        queryParams['curso'] = curso;
      }

      final uri =
          Uri.parse('$baseUrl/instituicoes/$instituicaoId/jovens-aprendizes')
              .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'jovensAprendizes': (data['dados']['jovensAprendizes'] as List)
              .map((json) => jovem.JovemAprendiz.fromJson(json))
              .toList(),
          'pagination': data['dados']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar jovens aprendizes');
      }
    } catch (e) {
      throw Exception('Erro ao carregar jovens aprendizes: $e');
    }
  }

  // GESTÃO DE CONTRATOS
  static Future<Map<String, dynamic>> listarContratos(
    String instituicaoId, {
    int page = 1,
    int limit = 10,
    String? status,
    String? tipo,
    String? estudante,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (estudante != null) {
        queryParams['estudante'] = estudante;
      }

      final uri = Uri.parse('$baseUrl/instituicoes/$instituicaoId/contratos')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'contratos': (data['dados']['contratos'] as List)
              .map((json) => contrato.Contrato.fromJson(json))
              .toList(),
          'pagination': data['dados']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar contratos');
      }
    } catch (e) {
      throw Exception('Erro ao carregar contratos: $e');
    }
  }

  // GESTÃO DE PROFESSORES ORIENTADORES
  static Future<Map<String, dynamic>> listarProfessores(
    String instituicaoId, {
    int page = 1,
    int limit = 10,
    String? search,
    String? departamento,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (departamento != null) {
        queryParams['departamento'] = departamento;
      }

      final uri = Uri.parse('$baseUrl/instituicoes/$instituicaoId/professores')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'professores': (data['dados']['professores'] as List)
              .map((json) => ProfessorOrientador.fromJson(json))
              .toList(),
          'pagination': data['dados']['pagination'],
        };
      } else {
        throw Exception('Erro ao carregar professores');
      }
    } catch (e) {
      throw Exception('Erro ao carregar professores: $e');
    }
  }

  static Future<bool> adicionarProfessor(
      String instituicaoId, Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/professores'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 201;
    } catch (e) {
      throw Exception('Erro ao adicionar professor: $e');
    }
  }

  static Future<bool> atualizarProfessor(String instituicaoId,
      String professorId, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/instituicoes/$instituicaoId/professores/$professorId'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao atualizar professor: $e');
    }
  }

  static Future<bool> removerProfessor(
      String instituicaoId, String professorId) async {
    try {
      final response = await http.delete(
        Uri.parse(
            '$baseUrl/instituicoes/$instituicaoId/professores/$professorId'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao remover professor: $e');
    }
  }

  // BUSCA AVANÇADA
  static Future<List<InstituicaoEnsino>> buscarInstituicoes(
    String query, {
    String? filtro,
    String? ordenacao,
  }) async {
    try {
      final queryParams = <String, String>{
        'q': query,
        'limit': '50',
      };

      if (filtro != null) {
        queryParams['filtro'] = filtro;
      }
      if (ordenacao != null) {
        queryParams['ordenacao'] = ordenacao;
      }

      final uri = Uri.parse('$baseUrl/instituicoes/search')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => InstituicaoEnsino.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<InstituicaoEnsino>> buscarInstituicoesPorCidade(
      String cidade) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicoes/por-cidade/$cidade'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => InstituicaoEnsino.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<InstituicaoEnsino>> buscarInstituicoesPorTipo(
      String tipo) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicoes/por-tipo/$tipo'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => InstituicaoEnsino.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // ESTATÍSTICAS E RELATÓRIOS
  static Future<Map<String, dynamic>> getEstatisticasInstituicao(
      String instituicaoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/estatisticas'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['dados'] ?? {};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getEstatisticasGerais() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicoes/estatisticas'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['dados'] ?? {};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> getRelatorioInstituicoes({
    DateTime? dataInicio,
    DateTime? dataFim,
    String? tipo,
    String? cidade,
    String? estado,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String();
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (cidade != null) {
        queryParams['cidade'] = cidade;
      }
      if (estado != null) {
        queryParams['estado'] = estado;
      }

      final uri = Uri.parse('$baseUrl/instituicoes/relatorio')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['dados'] ?? {};
      } else {
        throw Exception('Erro ao gerar relatório');
      }
    } catch (e) {
      throw Exception('Erro ao gerar relatório: $e');
    }
  }

  static Future<Map<String, dynamic>> getRelatorioEstudantes(
    String instituicaoId, {
    DateTime? dataInicio,
    DateTime? dataFim,
    String? curso,
    String? tipo,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (dataInicio != null) {
        queryParams['dataInicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['dataFim'] = dataFim.toIso8601String();
      }
      if (curso != null) {
        queryParams['curso'] = curso;
      }
      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }

      final uri =
          Uri.parse('$baseUrl/instituicoes/$instituicaoId/relatorio-estudantes')
              .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['dados'] ?? {};
      } else {
        throw Exception('Erro ao gerar relatório de estudantes');
      }
    } catch (e) {
      throw Exception('Erro ao gerar relatório de estudantes: $e');
    }
  }

  // EXPORTAÇÃO DE DADOS
  static Future<String> exportarInstituicoesCSV({
    String? tipo,
    String? cidade,
    String? estado,
    bool? ativo,
  }) async {
    try {
      final queryParams = <String, String>{
        'format': 'csv',
      };

      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (cidade != null) {
        queryParams['cidade'] = cidade;
      }
      if (estado != null) {
        queryParams['estado'] = estado;
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri = Uri.parse('$baseUrl/instituicoes/export')
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

  static Future<String> exportarEstudantesCSV(
    String instituicaoId, {
    String? tipo,
    String? curso,
  }) async {
    try {
      final queryParams = <String, String>{
        'format': 'csv',
      };

      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (curso != null) {
        queryParams['curso'] = curso;
      }

      final uri =
          Uri.parse('$baseUrl/instituicoes/$instituicaoId/estudantes/export')
              .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Erro ao exportar estudantes');
      }
    } catch (e) {
      throw Exception('Erro ao exportar estudantes: $e');
    }
  }

  static Future<List<int>> exportarInstituicoesPDF({
    String? tipo,
    String? cidade,
    String? estado,
  }) async {
    try {
      final queryParams = <String, String>{
        'format': 'pdf',
      };

      if (tipo != null) {
        queryParams['tipo'] = tipo;
      }
      if (cidade != null) {
        queryParams['cidade'] = cidade;
      }
      if (estado != null) {
        queryParams['estado'] = estado;
      }

      final uri = Uri.parse('$baseUrl/instituicoes/export')
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

  // CONVÊNIOS E DOCUMENTOS
  static Future<bool> gerarConvenio(String instituicaoId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/convenio'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao gerar convênio: $e');
    }
  }

  static Future<List<int>> downloadConvenio(String instituicaoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/convenio/download'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Convênio não encontrado');
      }
    } catch (e) {
      throw Exception('Erro ao baixar convênio: $e');
    }
  }

  static Future<bool> uploadDocumento(
      String instituicaoId, String tipoDocumento, String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/documentos'),
      );

      request.headers.addAll(await _getMultipartHeaders());
      request.fields['tipo'] = tipoDocumento;
      request.files
          .add(await http.MultipartFile.fromPath('documento', filePath));

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao fazer upload do documento: $e');
    }
  }

  // ATIVAÇÃO E DESATIVAÇÃO
  static Future<bool> ativarInstituicao(String id,
      {bool bloqueado = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/instituicao/bloquear/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({"bloqueado": bloqueado}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Tenta extrair mensagem de erro do backend
        String errorMsg = 'Erro ao ativar instituição';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['mensagem'] != null) {
            errorMsg = data['mensagem'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      throw Exception('Erro ao ativar instituição: $e');
    }
  }

  static Future<bool> desativarInstituicao(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/instituicoes/$id/desativar'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar instituição: $e');
    }
  }

  // GESTÃO DE TIPOS E NÍVEIS
  static Future<List<String>> listarTiposInstituicao() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicoes/tipos'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['dados']);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<String>> listarNiveisEnsino() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicoes/niveis'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['dados']);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, int>> getInstituicoesPorTipo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicoes/estatisticas/por-tipo'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Map<String, int>.from(data['dados']);
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  // RANKING E CLASSIFICAÇÕES
  static Future<List<InstituicaoEnsino>> getRankingInstituicoes({
    String criterio = 'estudantes', // estudantes, contratos, cursos
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'criterio': criterio,
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/instituicoes/ranking')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => InstituicaoEnsino.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // NOTIFICAÇÕES E ALERTAS
  static Future<bool> enviarNotificacao(
    String instituicaoId, {
    required String assunto,
    required String mensagem,
    String? tipo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/notificacoes'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'assunto': assunto,
          'mensagem': mensagem,
          'tipo': tipo,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao enviar notificação: $e');
    }
  }

  static Future<List<InstituicaoEnsino>> getInstituicoesComContratosVencendo({
    int dias = 30,
  }) async {
    try {
      final queryParams = <String, String>{
        'dias': dias.toString(),
      };

      final uri = Uri.parse('$baseUrl/instituicoes/contratos-vencendo')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['dados'] as List)
            .map((json) => InstituicaoEnsino.fromJson(json))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // AVALIAÇÕES E FEEDBACK
  static Future<bool> avaliarInstituicao(
    String instituicaoId, {
    required double nota,
    String? comentario,
    String? categoria,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/avaliacoes'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'nota': nota,
          'comentario': comentario,
          'categoria': categoria,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao avaliar instituição: $e');
    }
  }

  static Future<Map<String, dynamic>> getAvaliacoesInstituicao(
      String instituicaoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicoes/$instituicaoId/avaliacoes'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['dados'] ?? {};
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  // CACHE MANAGEMENT
  static const Duration _cacheTimeout = Duration(minutes: 10);
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  static void _setCache(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static dynamic _getCache(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheTimeout) {
      return _cache[key];
    }
    _cache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }

  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // MÉTODOS COM CACHE
  static Future<List<String>> getCachedTipos() async {
    const cacheKey = 'tipos_instituicao';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return List<String>.from(cached);
    }

    final tipos = await listarTiposInstituicao();
    _setCache(cacheKey, tipos);
    return tipos;
  }

  static Future<List<String>> getCachedNiveis() async {
    const cacheKey = 'niveis_ensino';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return List<String>.from(cached);
    }

    final niveis = await listarNiveisEnsino();
    _setCache(cacheKey, niveis);
    return niveis;
  }

  static Future<Map<String, dynamic>> getCachedEstatisticasGerais() async {
    const cacheKey = 'estatisticas_gerais_instituicoes';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final stats = await getEstatisticasGerais();
    _setCache(cacheKey, stats);
    return stats;
  }

  static List<InstituicaoEnsino> filtrarInstituicoes(
    List<InstituicaoEnsino> instituicoes, {
    String? tipo,
    String? cidade,
    String? estado,
    bool? ativo,
    String? nivel,
  }) {
    return instituicoes.where((instituicao) {
      if (tipo != null &&
          !instituicao.toString().toLowerCase().contains(tipo.toLowerCase())) {
        return false;
      }
      // if (cidade != null && !instituicao.endereco.cidade.toLowerCase().contains(cidade.toLowerCase())) {
      //   return false;
      // }
      // if (estado != null && instituicao.endereco.estado != estado.toUpperCase()) {
      //   return false;
      // }
      if (ativo != null && instituicao.ativo != ativo) {
        return false;
      }
      return true;
    }).toList();
  }

  static List<InstituicaoEnsino> ordenarInstituicoes(
      List<InstituicaoEnsino> instituicoes, String criterio) {
    switch (criterio.toLowerCase()) {
      case 'nome':
        return instituicoes
          ..sort((a, b) => a.nomeFantasia.compareTo(b.nomeFantasia));
      case 'cnpj':
        return instituicoes..sort((a, b) => a.cnpj.compareTo(b.cnpj));
      // case 'cidade':
      //   return instituicoes..sort((a, b) => a.endereco.cidade.compareTo(b.endereco.cidade));
      case 'data_cadastro':
        return instituicoes
          ..sort((a, b) => (b.createdAt ?? DateTime(2000))
              .compareTo(a.createdAt ?? DateTime(2000)));
      case 'estudantes':
        return instituicoes
          ..sort((a, b) => b.totalEstudantes.compareTo(a.totalEstudantes));
      default:
        return instituicoes;
    }
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

  static Future<InstituicaoEnsino?> obterInstituicaoPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/instituicao/buscar/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      final dados =
          decoded is Map<String, dynamic> ? decoded['dados'] ?? decoded : null;

      if (dados is Map<String, dynamic>) {
        return InstituicaoEnsino.fromJson(dados);
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
