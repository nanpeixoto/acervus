// lib/services/candidato_service.dart
import 'dart:async';
import 'dart:convert';
//import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sistema_estagio/models/_pessoas/candidato/regime_contratacao.dart';
import '../../../models/_pessoas/candidato/candidato.dart';
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';
import 'dart:io';

import 'dart:html' as html;
import 'package:open_filex/open_filex.dart';

// Somente Mobile
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CandidatoService {
  static const String baseUrl = AppConfig.devBaseUrl;

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Método para buscar candidato por ID
  /// Busca candidatos com base em um termo de pesquisa.
  /// Retorna uma lista de objetos Candidato.
  /// Lança uma exceção se não encontrar candidatos ou ocorrer erro.
  static Future<Map<String, dynamic>> buscarCandidato(
    String termo, {
    int? tipoRegime,
    String? cidade,
    String? curso,
    int page = 1, // ⬅️ ADICIONAR
    int limit = 10, // ⬅️ ADICIONAR
  }) async {
    try {
      final queryParams = {
        'nome': termo,
        'cpf': termo,
        'email': termo,
        'ativo': 'true',
        'page': page.toString(), // ⬅️ ADICIONAR
        'limit': limit.toString(), // ⬅️ ADICIONAR
      };

      if (tipoRegime != null && tipoRegime > 0) {
        queryParams['tipoRegime'] = tipoRegime.toString();
        queryParams['tipo'] = tipoRegime.toString();
      }

      if (cidade != null && cidade.isNotEmpty) {
        queryParams['cidade'] = cidade;
      }

      if (curso != null && curso.isNotEmpty) {
        queryParams['curso'] = curso;
      }

      final uri = Uri.parse('$baseUrl/candidato/buscar')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        throw Exception('Candidato não encontrado');
      }

      final data = jsonDecode(response.body);
      print('📊 Dados Candidato: ${data['dados']}');

      // ✅ PROCESSAR CANDIDATOS
      final candidatos = (data['dados'] as List).map((json) {
        return Candidato.fromJson(json);
      }).toList();

      // ✅ EXTRAIR PAGINAÇÃO
      final pagination = data['pagination'] ?? {};

      // ✅ RETORNAR NO MESMO FORMATO DE listarCandidatos()
      return {
        'candidatos': candidatos,
        'pagination': pagination,
      };
    } catch (e) {
      throw Exception('Erro ao buscar candidato: $e');
    }
  }

  static Future<bool> verificarCandidatoExiste(int candidatoId) async {
    try {
      print(
          '🔍 [VERIFICAR_CANDIDATO] Verificando existência - ID: $candidatoId');

      final uri = Uri.parse('$baseUrl/candidato/exists/$candidatoId');
      print('🌐 [VERIFICAR_CANDIDATO] URL: $uri');

      // ✅ ADICIONAR TIMEOUT
      final response = await http
          .get(
        uri,
        headers: await _getHeaders(),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ [VERIFICAR_CANDIDATO] Timeout após 10 segundos');
          throw TimeoutException('Timeout ao verificar candidato');
        },
      );

      print('📨 [VERIFICAR_CANDIDATO] Resposta recebida:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');
      print('   Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 [VERIFICAR_CANDIDATO] Data decodificado: $data');

        if (data is Map<String, dynamic>) {
          final existe = data['existe'] ??
              data['exists'] ??
              data['data']?['existe'] ??
              data['data']?['exists'] ??
              false;

          print('✅ [VERIFICAR_CANDIDATO] Candidato existe: $existe');
          print('   Tipo do valor: ${existe.runtimeType}');

          return existe == true;
        }

        print('⚠️ [VERIFICAR_CANDIDATO] Response não é Map, assumindo true');
        return true;
      } else if (response.statusCode == 404) {
        print('❌ [VERIFICAR_CANDIDATO] Candidato não encontrado (404)');
        return false;
      } else {
        print(
            '⚠️ [VERIFICAR_CANDIDATO] Status inesperado: ${response.statusCode}');
        print('   Body: ${response.body}');
        return false;
      }
    } on TimeoutException catch (e) {
      print('⏱️ [VERIFICAR_CANDIDATO] Erro de timeout: $e');
      // ✅ Em caso de timeout, assumir que existe (já que acabou de ser criado)
      return true;
    } catch (e, stackTrace) {
      print('💥 [VERIFICAR_CANDIDATO] Erro ao verificar candidato: $e');
      print('   Tipo do erro: ${e.runtimeType}');
      print(
          '   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      // ✅ Em caso de erro, assumir que existe (já que acabou de ser criado)
      return true;
    }
  }

  ///Criar método para buscar candidato por ID
  /// Busca candidato por ID
  /// Retorna um objeto Candidato ou lança uma exceção se não encontrar.
  /// Lança uma exceção se ocorrer erro.
  /// @param id O ID do candidato a ser buscado.
  /// @return Um objeto Candidato ou null se não encontrado.
  ///
  static Future<Candidato?> buscarCandidatoPorId(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/candidato/listar/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Tenta encontrar o objeto candidato na resposta
        Map<String, dynamic>? candidatoData;
        if (data['dados'] != null) {
          candidatoData = data['dados'];
        } else if (data['data'] != null) {
          candidatoData = data['data'];
        } else if (data is Map<String, dynamic>) {
          candidatoData = data;
        }

        if (candidatoData != null) {
          return Candidato.fromJson(candidatoData);
        }
      }

      return null;
    } catch (e) {
      throw Exception('Erro ao buscar candidato: $e');
    }
  }

  static Future<Candidato?> editarCandidato(
      int id, Map<String, dynamic> dados) async {
    try {
      print('📤 [EDITAR_CANDIDATO] Enviando dados para edição - ID: $id');
      print('   Dados: ${jsonEncode(dados)}');

      final response = await http.put(
        // ALTERADO de POST para PUT
        Uri.parse('$baseUrl/candidato/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      print('📨 [EDITAR_CANDIDATO] Resposta recebida:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        Map<String, dynamic>? candidatoData;
        if (data['dados'] != null) {
          candidatoData = data['dados'];
        } else if (data['data'] != null) {
          candidatoData = data['data'];
        } else if (data is Map<String, dynamic>) {
          candidatoData = data;
        }

        if (candidatoData != null) {
          print('✅ [EDITAR_CANDIDATO] Candidato editado com sucesso');
          return Candidato.fromJson(candidatoData);
        }
      }

      print(
          '❌ [EDITAR_CANDIDATO] Falha na edição - Status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('💥 [EDITAR_CANDIDATO] Erro ao editar candidato: $e');
      rethrow;
    }
  }

  // Método para criar candidato
  static Future<Candidato?> criarCandidato(Map<String, dynamic> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/candidato'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      // Sempre tenta exibir o conteúdo do response, independente do status
      String responseBody = response.body;
      dynamic data;
      try {
        data = jsonDecode(responseBody);
      } catch (_) {
        data = responseBody;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        Map<String, dynamic>? candidatoData;
        if (data is Map) {
          if (data['dados'] != null) {
            candidatoData = data['dados'];
          } else if (data['data'] != null) {
            candidatoData = data['data'];
          } else if (data is Map<String, dynamic>) {
            candidatoData = data;
          }
        }

        if (candidatoData != null) {
          return Candidato.fromJson(candidatoData);
        }
      } else {
        // Se possível, mostra o erro detalhado
        String bRetorno = '';
        if (data is Map && data.containsKey('erro')) {
          bRetorno = data['erro'];
        } else {
          bRetorno = responseBody;
        }
        throw Exception(bRetorno);
      }

      return null;
    } catch (e) {
      // Se é uma Exception já tratada acima, propaga ela
      if (e is Exception &&
          e.toString().startsWith('Exception: ') &&
          !e.toString().contains('Erro ao criar candidato')) {
        rethrow;
      }
      print('Erro ao criar candidato: $e');
      throw Exception('Erro ao criar candidato: $e');
    }
  }

  //Criar Método bloquear candidato
  static Future<bool> bloquearCandidato(int id,
      {bool bloqueado = false}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/candidato/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({"ativo": bloqueado}),
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

  // ATIVAÇÃO E DESATIVAÇÃO DE CANDIDATO
  static Future<bool> ativarCandidato(int id, {bool bloqueado = true}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/candidato/alterar/$id'),
        headers: await _getHeaders(),
        body: jsonEncode({"ativo": bloqueado}),
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
      throw Exception('Erro ao ativar candidato: $e');
    }
  }

  static Future<bool> desativarCandidato(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/candidato/$id/desativar'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Erro ao desativar candidato: $e');
    }
  }

  //Método para buscar o regime de contratação
  // Busca todos os regimes de contratação (objetos completos)
  static Future<List<RegimeContratacao>> buscarRegimesContratacao() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/regime_contratacao/buscar'),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Encontra a lista de regimes
        List<dynamic>? regimesRaw;
        if (data['dados'] is List) {
          regimesRaw = data['dados'];
        } else if (data['data'] is List)
          regimesRaw = data['data'];
        else if (data is List) regimesRaw = data;

        if (regimesRaw == null || regimesRaw.isEmpty) {
          print('⚠️ Nenhum regime encontrado na resposta');
          return [];
        }

        final regimes = <RegimeContratacao>[];

        for (var item in regimesRaw) {
          try {
            int? id;
            String? descricao;

            if (item is Map<String, dynamic>) {
              // Formato objeto: {"id_regime_contratacao": 1, "descricao": "Estágio"}
              id = item['id_regime_contratacao'] ?? item['id'];
              descricao = item['descricao']?.toString();
            } else if (item is String) {
              // Formato string: "{id_regime_contratacao: 1, descricao: Estágio}"
              final idMatch =
                  RegExp(r'id_regime_contratacao:\s*(\d+)').firstMatch(item);
              final descMatch =
                  RegExp(r'descricao:\s*([^,}]+)').firstMatch(item);

              if (idMatch != null) id = int.tryParse(idMatch.group(1)!);
              if (descMatch != null) descricao = descMatch.group(1)?.trim();
            }

            if (id != null && descricao != null && descricao.isNotEmpty) {
              regimes.add(RegimeContratacao(id: id, descricao: descricao));
            }
          } catch (e) {
            print('Erro ao processar regime: $item - $e');
          }
        }

        print('✅ Regimes processados: ${regimes.length}');
        for (var regime in regimes) {
          print('   ID: ${regime.id} - Descrição: ${regime.descricao}');
        }

        return regimes;
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erro ao buscar regimes: $e');
      return [];
    }
  }

  /// Busca apenas as descrições (para manter compatibilidade)
  static Future<List<String>> buscarRegimeContratacao() async {
    try {
      final regimes = await buscarRegimesContratacao();
      return regimes.map((regime) => regime.descricao).toList();
    } catch (e) {
      print('Erro ao buscar descrições de regime: $e');
      return [];
    }
  }

  /// Busca ID do regime pela descrição
  static Future<int?> buscarIdRegimePorDescricao(String descricao) async {
    try {
      final regimes = await buscarRegimesContratacao();
      final regime = regimes.firstWhere(
        (regime) => regime.descricao == descricao,
        orElse: () => throw StateError('Regime não encontrado'),
      );
      return regime.id;
    } catch (e) {
      print('Regime com descrição "$descricao" não encontrado: $e');
      return null;
    }
  }

  /// Busca descrição do regime pelo ID
  static Future<String?> buscarDescricaoRegimePorId(int id) async {
    try {
      final regimes = await buscarRegimesContratacao();
      final regime = regimes.firstWhere(
        (regime) => regime.id == id,
        orElse: () => throw StateError('Regime não encontrado'),
      );
      return regime.descricao;
    } catch (e) {
      print('Regime com ID "$id" não encontrado: $e');
      return null;
    }
  }

  /// Cria um mapa de descrição -> ID
  static Future<Map<String, int>> criarMapaRegimes() async {
    try {
      final regimes = await buscarRegimesContratacao();
      return {for (var regime in regimes) regime.descricao: regime.id};
    } catch (e) {
      print('Erro ao criar mapa de regimes: $e');
      return {};
    }
  }

  // Método para atualizar candidato
  static Future<Candidato?> atualizarCandidato(
      int id, Map<String, dynamic> dados) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/candidato/$id'),
        headers: await _getHeaders(),
        body: jsonEncode(dados),
      );

      // Sempre tenta exibir o conteúdo do response, independente do status
      String responseBody = response.body;
      dynamic data;
      try {
        data = jsonDecode(responseBody);
      } catch (_) {
        data = responseBody;
      }

      if (response.statusCode == 200) {
        Map<String, dynamic>? candidatoData;
        if (data is Map) {
          if (data['dados'] != null) {
            candidatoData = data['dados'];
          } else if (data['data'] != null) {
            candidatoData = data['data'];
          } else if (data is Map<String, dynamic>) {
            candidatoData = data;
          }
        }

        if (candidatoData != null) {
          return Candidato.fromJson(candidatoData);
        }
      } else {
        // Se possível, mostra o erro detalhado
        String bRetorno = '';
        if (data is Map && data.containsKey('erro')) {
          bRetorno = data['erro'];
        } else {
          bRetorno = responseBody;
        }
        throw Exception(bRetorno);
      }

      return null;
    } catch (e) {
      // Se é uma Exception já tratada acima, propaga ela
      if (e is Exception &&
          e.toString().startsWith('Exception: ') &&
          !e.toString().contains('Erro ao atualizar candidato')) {
        rethrow;
      }
      print('Erro ao atualizar candidato: $e');
      throw Exception('Erro ao atualizar candidato: $e');
    }
  }

  // Método para deletar candidato
  static Future<bool> deletarCandidato(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/candidato/$id'),
        headers: await _getHeaders(),
      );

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Erro ao deletar candidato: $e');
      return false;
    }
  }

  // Método para validar CPF
  static bool validarCPF(String cpf) {
    // Remove caracteres não numéricos
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');

    // Verifica se tem 11 dígitos
    if (cpf.length != 11) return false;

    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    // Validação dos dígitos verificadores
    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    int primeiroDigito = (soma * 10) % 11;
    if (primeiroDigito >= 10) primeiroDigito = 0;

    if (int.parse(cpf[9]) != primeiroDigito) return false;

    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    int segundoDigito = (soma * 10) % 11;
    if (segundoDigito >= 10) segundoDigito = 0;

    return int.parse(cpf[10]) == segundoDigito;
  }

  // Método para formatar CPF
  static String formatarCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length == 11) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
    }
    return cpf;
  }

  // Método para buscar candidatos por CPF
  static Future<List<Candidato>> buscarPorCPF(String cpf) async {
    final resultado = await listarCandidatos(cpf: cpf, limit: 100);
    return List<Candidato>.from(resultado['candidatos'] ?? []);
  }

  // Método para buscar candidatos por email
  static Future<List<Candidato>> buscarPorEmail(String email) async {
    final resultado = await listarCandidatos(search: email, limit: 100);
    return List<Candidato>.from(resultado['candidatos'] ?? []);
  }

  // Salvar formação acadêmica (POST /candidato/formacao/cadastrar)
  /// Cadastrar formação acadêmica (POST /candidato/formacao/cadastrar)
  /// Suporta tanto File (mobile) quanto Uint8List (web)
  static Future<bool> cadastrarFormacaoAcademica({
    required Map<String, String> campos,
    File? comprovanteFile, // Para mobile
    Uint8List? comprovanteBytes, // Para web
    String? nomeArquivo,
    Function(double)? onProgress, // Callback para progresso do upload
  }) async {
    try {
      final token = await StorageService.getToken();
      final uri = Uri.parse('$baseUrl/candidato/formacao/cadastrar');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Adicionar campos
      campos.forEach((key, value) {
        if (value.isNotEmpty) {
          request.fields[key] = value;
        }
      });

      // ✅ ADICIONAR ARQUIVO BASEADO NA PLATAFORMA
      if (kIsWeb && comprovanteBytes != null) {
        // Para Web: usar bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'comprovante',
            comprovanteBytes,
            filename: nomeArquivo ??
                'comprovante_matricula.${_obterExtensaoDoNome(nomeArquivo)}',
          ),
        );
      } else if (!kIsWeb && comprovanteFile != null) {
        // Para Mobile: usar file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'comprovante',
            comprovanteFile.path,
            filename: nomeArquivo,
          ),
        );
      }

      print('📤 Enviando formação acadêmica...');
      print('   Campos: ${request.fields}');
      print('   Arquivos: ${request.files.length}');

      // Enviar requisição
      final streamedResponse = await request.send();

      // Processar resposta com callback de progresso
      if (onProgress != null) {
        streamedResponse.stream.listen(
          (data) {
            // Simular progresso (em uma implementação real, você calcularia baseado no tamanho)
            onProgress(0.8);
          },
          onDone: () => onProgress(1.0),
        );
      }

      final response = await http.Response.fromStream(streamedResponse);

      print('📨 Resposta do cadastro de formação:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Formação acadêmica cadastrada com sucesso');
        return true;
      } else {
        print('❌ Erro ao cadastrar formação: ${response.statusCode}');
        print('   Detalhes: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 Erro no cadastro de formação acadêmica:');
      print('   Erro: $e');
      print(
          '   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      return false;
    }
  }

  /// Alterar formação acadêmica (PUT /candidato/formacao/alterar/<id_formacao>)
  /// Suporta tanto File (mobile) quanto Uint8List (web)
  static Future<bool> alterarFormacaoAcademica({
    required int idFormacao,
    required Map<String, String> campos,
    File? comprovanteFile, // Para mobile
    Uint8List? comprovanteBytes, // Para web
    String? nomeArquivo,
    Function(double)? onProgress, // Callback para progresso do upload
  }) async {
    try {
      final token = await StorageService.getToken();
      final uri = Uri.parse('$baseUrl/candidato/formacao/alterar/$idFormacao');

      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Adicionar campos
      campos.forEach((key, value) {
        if (value.isNotEmpty) {
          request.fields[key] = value;
        }
      });

      // ✅ ADICIONAR ARQUIVO BASEADO NA PLATAFORMA
      if (kIsWeb && comprovanteBytes != null) {
        // Para Web: usar bytes
        request.files.add(
          http.MultipartFile.fromBytes(
            'comprovante',
            comprovanteBytes,
            filename: nomeArquivo ??
                'comprovante_matricula.${_obterExtensaoDoNome(nomeArquivo)}',
          ),
        );
      } else if (!kIsWeb && comprovanteFile != null) {
        // Para Mobile: usar file path
        request.files.add(
          await http.MultipartFile.fromPath(
            'comprovante',
            comprovanteFile.path,
            filename: nomeArquivo,
          ),
        );
      }

      print('📤 Alterando formação acadêmica ID: $idFormacao');
      print('   Campos: ${request.fields}');
      print('   Arquivos: ${request.files.length}');

      // Enviar requisição
      final streamedResponse = await request.send();

      // Processar resposta com callback de progresso
      if (onProgress != null) {
        streamedResponse.stream.listen(
          (data) {
            onProgress(0.8);
          },
          onDone: () => onProgress(1.0),
        );
      }

      final response = await http.Response.fromStream(streamedResponse);

      print('📨 Resposta da alteração de formação:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Formação acadêmica alterada com sucesso');
        return true;
      } else {
        print('❌ Erro ao alterar formação: ${response.statusCode}');
        print('   Detalhes: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      print('💥 Erro na alteração de formação acadêmica:');
      print('   Erro: $e');
      print(
          '   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      return false;
    }
  }

  // Buscar formação acadêmica por candidato
  static Future<FormacaoAcademica?> buscarFormacaoPorCandidato(
      int candidatoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/candidato/formacao/buscar/$candidatoId'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Tenta encontrar o objeto de formação acadêmica na resposta
        Map<String, dynamic>? formacaoData;
        if (data['dados'] != null) {
          formacaoData = data['dados'];
        } else if (data['data'] != null) {
          formacaoData = data['data'];
        } else if (data is Map<String, dynamic>) {
          formacaoData = data;
        }

        if (formacaoData != null) {
          return FormacaoAcademica.fromJson(formacaoData);
        }
      }
      return null;
    } catch (e) {
      print('Erro ao buscar formação acadêmica do candidato $candidatoId: $e');
      return null;
    }
  }

  // ========================================================================
  // MÉTODOS AUXILIARES PARA UPLOAD DE ARQUIVOS
  // ========================================================================

  /// Obtém a extensão do arquivo baseado no nome
  static String _obterExtensaoDoNome(String? nomeArquivo) {
    if (nomeArquivo == null || !nomeArquivo.contains('.')) {
      return 'pdf'; // Extensão padrão
    }
    return nomeArquivo.split('.').last.toLowerCase();
  }

  /// Valida o tipo de arquivo baseado na extensão
  static bool _validarTipoArquivo(String? nomeArquivo) {
    if (nomeArquivo == null) return false;

    final extensao = _obterExtensaoDoNome(nomeArquivo);
    final extensoesPermitidas = ['pdf', 'jpg', 'jpeg', 'png'];

    return extensoesPermitidas.contains(extensao);
  }

  /// Valida o tamanho do arquivo
  static bool _validarTamanhoArquivo(dynamic arquivo,
      {int maxSizeBytes = 10 * 1024 * 1024}) {
    int tamanho = 0;

    if (arquivo is File) {
      tamanho = arquivo.lengthSync();
    } else if (arquivo is Uint8List) {
      tamanho = arquivo.length;
    }

    return tamanho <= maxSizeBytes && tamanho > 0;
  }

  /// Método para validar arquivo antes do upload
  static Map<String, dynamic> validarArquivoComprovante({
    File? comprovanteFile,
    Uint8List? comprovanteBytes,
    String? nomeArquivo,
  }) {
    final resultado = {
      'valido': false,
      'erro': '',
    };

    // Verificar se tem algum arquivo
    if (comprovanteFile == null && comprovanteBytes == null) {
      resultado['erro'] = 'Nenhum arquivo selecionado';
      return resultado;
    }

    // Validar nome do arquivo
    if (!_validarTipoArquivo(nomeArquivo)) {
      resultado['erro'] =
          'Tipo de arquivo não permitido. Use: PDF, JPG, JPEG ou PNG';
      return resultado;
    }

    // Validar tamanho
    final arquivo = comprovanteFile ?? comprovanteBytes;
    if (!_validarTamanhoArquivo(arquivo)) {
      resultado['erro'] = 'Arquivo muito grande (máximo 10MB) ou vazio';
      return resultado;
    }

    resultado['valido'] = true;
    return resultado;
  }

  // ========================================================================
  // MÉTODOS EXISTENTES (mantidos inalterados)
  // ========================================================================

  static Future<Map<String, dynamic>> listarCandidatos({
    int page = 1,
    int limit = 10,
    String? search,
    String? nome,
    String? nomeSocial,
    String? rg,
    String? cpf,
    int? tipoRegime,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      // Adicionar parâmetros de busca apenas se não estiverem vazios
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      if (nome != null && nome.trim().isNotEmpty) {
        queryParams['nome'] = nome.trim();
      }
      if (nomeSocial != null && nomeSocial.trim().isNotEmpty) {
        queryParams['nomeSocial'] = nomeSocial.trim();
      }
      if (rg != null && rg.trim().isNotEmpty) {
        queryParams['rg'] = rg.trim();
      }
      if (cpf != null && cpf.trim().isNotEmpty) {
        queryParams['cpf'] = cpf.trim();
      }
      if (tipoRegime != null && tipoRegime > 0) {
        queryParams['tipo'] = tipoRegime.toString();
      }

      final uri = Uri.parse('$baseUrl/candidato/buscar')
          .replace(queryParameters: queryParams);

      print('🔍 Buscando candidatos - URI: $uri');

      final response = await http.get(uri, headers: await _getHeaders());

      print('📡 Resposta da API:');
      print('   Status: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print(
          '   Body (primeiros 500 chars): ${response.body.length > 500 ? "${response.body.substring(0, 500)}..." : response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 Dados decodificados: ${data.runtimeType}');

        // Estrutura para armazenar resultados
        List<dynamic> candidatosData = [];
        Map<String, dynamic> paginationData = {};

        // Estratégia de extração de dados mais robusta
        candidatosData = _extrairCandidatos(data);
        paginationData = _extrairPaginacao(data);

        print('📋 Candidatos encontrados: ${candidatosData.length}');

        // Processar candidatos com tratamento individual de erro
        final candidatos = <Candidato>[];
        final candidatosComErro = <Map<String, dynamic>>[];

        for (int i = 0; i < candidatosData.length; i++) {
          final item = candidatosData[i];
          try {
            if (item is Map<String, dynamic>) {
              final candidato = Candidato.fromJson(item);
              candidatos.add(candidato);
              print(
                  '✅ Candidato processado: ${candidato.nomeCompleto} (ID: ${candidato.id})');
            } else {
              print('⚠️ Item $i não é um mapa válido: $item');
            }
          } catch (e, stackTrace) {
            print('❌ Erro ao processar candidato $i:');
            print('   Dados: $item');
            print('   Erro: $e');
            print(
                '   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');

            candidatosComErro.add({
              'index': i,
              'dados': item,
              'erro': e.toString(),
            });
          }
        }

        print('✅ Resumo do processamento:');
        print('   Total de itens: ${candidatosData.length}');
        print('   Processados com sucesso: ${candidatos.length}');
        print('   Com erro: ${candidatosComErro.length}');

        // Log dos erros para debug
        if (candidatosComErro.isNotEmpty) {
          print('🔍 Detalhes dos erros:');
          for (var erro in candidatosComErro) {
            print('   Item ${erro['index']}: ${erro['erro']}');
          }
        }

        return {
          'candidatos': candidatos,
          'pagination': paginationData,
          'errors': candidatosComErro,
          'total_original': candidatosData.length,
          'total_processados': candidatos.length,
        };
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        print('   Body: ${response.body}');
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('💥 Erro geral em listarCandidatos:');
      print('   Erro: $e');
      print(
          '   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      throw Exception('Erro ao carregar candidatos: $e');
    }
  }

  // Método para extrair candidatos de diferentes estruturas de resposta
  static List<dynamic> _extrairCandidatos(dynamic data) {
    if (data == null) return [];

    // Possíveis caminhos para os dados dos candidatos
    final caminhos = [
      () => data['dados']?['candidatos'], // dados.candidatos
      () => data['candidatos'], // candidatos
      () => data['data']?['candidatos'], // data.candidatos
      () => data['data'], // data (se for lista)
      () => data['dados'], // dados (se for lista)
      () => data['result']?['candidatos'], // result.candidatos
      () => data['response']?['candidatos'], // response.candidatos
      () => data['items'], // items
      () => data, // data direto (se for lista)
    ];

    for (var getCaminho in caminhos) {
      try {
        var resultado = getCaminho();
        if (resultado is List && resultado.isNotEmpty) {
          print('📂 Candidatos encontrados em: ${getCaminho.toString()}');
          return resultado;
        }
      } catch (e) {
        // Continua tentando outros caminhos
        continue;
      }
    }

    print('⚠️ Nenhum candidato encontrado na resposta');
    return [];
  }

  // Método para extrair informações de paginação
  static Map<String, dynamic> _extrairPaginacao(dynamic data) {
    if (data == null || data is! Map) return {};

    // Possíveis caminhos para paginação
    final caminhos = [
      () => data['dados']?['pagination'],
      () => data['pagination'],
      () => data['data']?['pagination'],
      () => data['meta'],
      () => data['page_info'],
    ];

    for (var getCaminho in caminhos) {
      try {
        var resultado = getCaminho();
        if (resultado is Map<String, dynamic>) {
          return resultado;
        }
      } catch (e) {
        continue;
      }
    }

    // Paginação padrão se não encontrar
    return {
      'current_page': 1,
      'total_pages': 1,
      'total_items': 0,
      'per_page': 10,
    };
  }

  static Future<void> visualizarResumoEstudante(int cdCandidato) async {
    final url = "$baseUrl/candidato/pdf/$cdCandidato";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        print("Erro ao baixar PDF: ${response.statusCode}");
        return;
      }

      final Uint8List bytes = response.bodyBytes;

      if (kIsWeb) {
        // 🔹 WEB — forçar download, NÃO abrir aba
        final blob = html.Blob([bytes], 'application/pdf');
        final urlBlob = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: urlBlob)
          ..download = "resumo_estudante_$cdCandidato.pdf"
          ..click();
        html.Url.revokeObjectUrl(urlBlob);
        return;
      }

      // 🔹 MOBILE — salvar o arquivo e abrir (ou só salvar, você escolhe)
      final dir = await getTemporaryDirectory();
      final String filePath = "${dir.path}/resumo_estudante_$cdCandidato.pdf";

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      await OpenFilex.open(filePath);
    } catch (e) {
      print("Erro ao visualizar PDF do estudante: $e");
    }
  }

  static Future<String?> exportarCSV(
    String currentSearch, {
    String? tipo,
    bool? ativo,
    bool? isDefault,
    String? cidade,
    String? curso,
    int? tipoRegime,
  }) async {
    try {
      final queryParams = {
        'nome': currentSearch,
        'cpf': currentSearch,
        'email': currentSearch,
        'ativo': 'true',
      };
      // if (ativo != null) queryParams['ativo'] = ativo.toString();
      // if (isDefault != null) queryParams['is_default'] = isDefault.toString();
      //ESCRVER AQUI OS PARAMETROS QUE QUEREMOS PASSAR PARA FILTRAR O CSV
      if (tipo != null) queryParams['tipo'] = tipo;
      if (ativo != null) queryParams['ativo'] = ativo.toString();
      if (cidade != null) queryParams['cidade'] = cidade;
      if (curso != null) queryParams['curso'] = curso;
      if (tipoRegime != null) {
        queryParams['tipo_regime'] = tipoRegime.toString();
      }
      if (currentSearch != null && currentSearch.isNotEmpty) {
        queryParams['search'] = currentSearch;
      }

      final uri = Uri.parse('$baseUrl/candidato/exportar/csv')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Extrai o nome do arquivo do Content-Disposition (se o backend enviar)
        final filename = _extrairFilename(
                response.headers['content-disposition']) ??
            'Candidato_${DateTime.now().toIso8601String().substring(0, 10)}.csv';

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
}
