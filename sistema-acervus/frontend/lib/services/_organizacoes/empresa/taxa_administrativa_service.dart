// lib/services/taxa_administrativa_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:sistema_estagio/services/_organizacoes/empresa/empresa_service.dart';
import '../../../models/_financeiro/taxa_administrativa.dart';
import '../../../utils/app_config.dart';
import '../../_core/storage_service.dart';

class CompetenciaDetalhada {
  final String competencia;
  final String tipoTaxa;
  final int quantidadeTaxas;

  CompetenciaDetalhada({
    required this.competencia,
    required this.tipoTaxa,
    this.quantidadeTaxas = 0,
  });

  factory CompetenciaDetalhada.fromJson(Map<String, dynamic> json) {
    return CompetenciaDetalhada(
      competencia: json['competencia']?.toString() ?? '',
      tipoTaxa: json['tipo_taxa']?.toString() ?? '',
      quantidadeTaxas: json['quantidade']?.toInt() ?? 0,
    );
  }

  String get tipoFormatado {
    switch (tipoTaxa.toLowerCase()) {
      case 'estagio':
        return 'Estágio';
      case 'aprendiz':
        return 'Jovem Aprendiz';
      default:
        return tipoTaxa;
    }
  }
}

class TaxaAdministrativaService {
  static const String baseUrl = AppConfig.devBaseUrl;

  // Headers com autenticação
  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Lista todas as taxas administrativas com paginação e filtros
  static Future<Map<String, dynamic>> listarTaxas({
    int page = 1,
    int limit = 10,
    String? search,
    String? tipoTaxa,
    String? status,
    String? empresa,
    String? competencia,
    DateTime? dataVencimentoInicio,
    DateTime? dataVencimentoFim,
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
      if (tipoTaxa != null && tipoTaxa.isNotEmpty) {
        queryParams['tipo_taxa'] = tipoTaxa;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (empresa != null && empresa.isNotEmpty) {
        queryParams['empresa'] = empresa;
      }
      if (competencia != null && competencia.isNotEmpty) {
        queryParams['competencia'] = competencia;
      }
      if (dataVencimentoInicio != null) {
        queryParams['data_vencimento_inicio'] =
            dataVencimentoInicio.toIso8601String();
      }
      if (dataVencimentoFim != null) {
        queryParams['data_vencimento_fim'] =
            dataVencimentoFim.toIso8601String();
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri = Uri.parse('$baseUrl/taxa-administrativa')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // CORREÇÃO: Usar novo formato de resposta baseado no seu JSON
        final dados = data['dados'] as List? ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

        return {
          'taxas':
              dados.map((item) => TaxaAdministrativa.fromJson(item)).toList(),
          'total': pagination['totalItems'] ?? 0,
          'currentPage': pagination['currentPage'] ?? page,
          'totalPages': pagination['totalPages'] ?? 1,
          'hasNextPage': pagination['hasNextPage'] ?? false,
          'hasPreviousPage': pagination['hasPrevPage'] ?? false,
        };
      } else {
        throw Exception(
            'Erro ao carregar taxas administrativas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar taxas administrativas: $e');
    }
  }

  /// Atualiza valor da taxa com motivo
  static Future<void> atualizarValorComMotivo(
    String taxaId,
    double novoValor,
    String motivo,
  ) async {
    try {
      // Validação adicional
      if (novoValor < 0) {
        throw Exception('Valor não pode ser negativo');
      }

      print(
          '📤 Enviando para API - ID: $taxaId, Valor: $novoValor, Motivo: $motivo');

      final response = await http.put(
        Uri.parse('$baseUrl/taxa-administrativa/$taxaId/valor'),
        headers: await _getHeaders(),
        body: json.encode({
          'valor': novoValor,
          'motivo': motivo,
        }),
      );

      print('📥 Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao atualizar valor da taxa');
      }
    } catch (e) {
      print('❌ Erro no service: $e');
      throw Exception('Erro ao atualizar valor da taxa: $e');
    }
  }

  /// Confirma uma competência (bloqueia edição)
  static Future<void> confirmarCompetencia(String taxaId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/taxa-administrativa/$taxaId/confirmar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao confirmar competência');
      }
    } catch (e) {
      throw Exception('Erro ao confirmar competência: $e');
    }
  }

  /// Desconfirma uma competência (libera edição)
  static Future<void> desconfirmarCompetencia(String taxaId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/taxa-administrativa/$taxaId/desconfirmar'),
        headers: await _getHeaders(),
      );

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao desconfirmar competência');
      }
    } catch (e) {
      throw Exception('Erro ao desconfirmar competência: $e');
    }
  }

  /// Busca histórico de alterações de uma taxa
  static Future<List<Map<String, dynamic>>> buscarHistoricoAlteracoes(
      String taxaId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/taxa-administrativa/$taxaId/historico'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['historico'] ?? []);
      } else {
        throw Exception('Erro ao buscar histórico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar histórico de alterações: $e');
    }
  }

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

  /// Busca uma taxa administrativa por ID
  static Future<TaxaAdministrativa> buscarTaxaPorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/taxa-administrativa/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TaxaAdministrativa.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Taxa administrativa não encontrada');
      } else {
        throw Exception(
            'Erro ao buscar taxa administrativa: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar taxa administrativa: $e');
    }
  }

  /// Cria uma nova taxa administrativa
  static Future<TaxaAdministrativa> criarTaxa(TaxaAdministrativa taxa) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/taxa-administrativa'),
        headers: await _getHeaders(),
        body: json.encode(taxa.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return TaxaAdministrativa.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao criar taxa administrativa');
      }
    } catch (e) {
      throw Exception('Erro ao criar taxa administrativa: $e');
    }
  }

  /// Atualiza uma taxa administrativa existente
  static Future<TaxaAdministrativa> atualizarTaxa(
      String id, TaxaAdministrativa taxa) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/taxa-administrativa/$id'),
        headers: await _getHeaders(),
        body: json.encode(taxa.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TaxaAdministrativa.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao atualizar taxa administrativa');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar taxa administrativa: $e');
    }
  }

  /// Exclui uma taxa administrativa
  static Future<bool> excluirTaxa(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/taxa-administrativa/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao excluir taxa administrativa');
      }
    } catch (e) {
      throw Exception('Erro ao excluir taxa administrativa: $e');
    }
  }

  /// Gera taxas consolidadas para uma competência específica
  static Future<Map<String, dynamic>> gerarTaxasConsolidadas({
    required String competencia,
    String? tipoTaxa,
  }) async {
    try {
      final queryParams = <String, String>{
        'competencia': competencia,
      };

      if (tipoTaxa != null && tipoTaxa.isNotEmpty) {
        queryParams['tipo_taxa'] = tipoTaxa;
      }

      final uri = Uri.parse('$baseUrl/taxa-administrativa/gerar-consolidadas')
          .replace(queryParameters: queryParams);
      final response = await http.post(uri, headers: await _getHeaders());

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'sucesso': true,
          'mensagem': data['message'] ?? 'Taxas geradas com sucesso',
          'taxasGeradas': data['taxas_geradas'] ?? 0,
          'valorTotal': data['valor_total'] ?? 0.0,
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao gerar taxas consolidadas');
      }
    } catch (e) {
      throw Exception('Erro ao gerar taxas consolidadas: $e');
    }
  }

  //criar método atualizarTaxasAdministrativas passando o ID da empresa
  static Future<void> atualizarTaxasAdministrativas(
      String empresaId, String tipoTaxa, String competencia) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/taxa-administrativa/gerar-consolidadas/$empresaId'),
        headers: await _getHeaders(),
        body: json.encode({
          'tipo_contrato': tipoTaxa,
          'competencia': competencia,
        }),
      );

      if (response.statusCode == 200) {
        // Sucesso
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao atualizar taxas administrativas');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar taxas administrativas: $e');
    }
  }

  static Future<void> atualizarValorTaxa(
      String taxaId, double novoValor) async {
    // Implementar chamada para o endpoint
    // PUT /api/taxas-administrativas/{id}/valor
    // Body: { "valor": novoValor }
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/taxa-administrativa/$taxaId/valor'),
        headers: await _getHeaders(),
        body: json.encode({'valor': novoValor}),
      );

      if (response.statusCode == 200) {
        // Sucesso
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao atualizar valor da taxa');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar valor da taxa: $e');
    }
  }

  /// Marca uma taxa como paga
  static Future<TaxaAdministrativa> marcarComoPaga(
    String id, {
    DateTime? dataPagamento,
    String? formaPagamento,
    String? numeroTransacao,
    String? observacoes,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': 'pago',
        'data_pagamento': (dataPagamento ?? DateTime.now()).toIso8601String(),
      };

      if (formaPagamento != null && formaPagamento.isNotEmpty) {
        body['forma_pagamento'] = formaPagamento;
      }
      if (numeroTransacao != null && numeroTransacao.isNotEmpty) {
        body['numero_transacao'] = numeroTransacao;
      }
      if (observacoes != null && observacoes.isNotEmpty) {
        body['observacoes'] = observacoes;
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/taxa-administrativa/$id/marcar-paga'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TaxaAdministrativa.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
            errorData['message'] ?? 'Erro ao marcar taxa como paga');
      }
    } catch (e) {
      throw Exception('Erro ao marcar taxa como paga: $e');
    }
  }

  /// Cancela uma taxa administrativa
  static Future<TaxaAdministrativa> cancelarTaxa(
      String id, String motivo) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/taxa-administrativa/$id/cancelar'),
        headers: await _getHeaders(),
        body: json.encode({
          'status': 'cancelado',
          'observacoes': motivo,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TaxaAdministrativa.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao cancelar taxa');
      }
    } catch (e) {
      throw Exception('Erro ao cancelar taxa: $e');
    }
  }

  /// Busca empresas para o dropdown (implementação específica para taxas)
  static Future<List<Map<String, dynamic>>> buscarEmpresas2({
    String? search,
    bool? ativo = true,
  }) async {
    try {
      final queryParams = <String, String>{
        'limit': '100', // Limite alto para dropdown
        'fields':
            'cd_empresa,razao_social,nome_fantasia,cnpj', // Campos específicos
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (ativo != null) {
        queryParams['ativo'] = ativo.toString();
      }

      final uri =
          Uri.parse('$baseUrl/empresas').replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final empresas = data['empresas'] as List? ?? [];

        return empresas.map<Map<String, dynamic>>((empresa) {
          final cnpj = empresa['cnpj']?.toString() ?? '';
          final cnpjFormatted = _formatCNPJ(cnpj);
          final nomeExibicao = empresa['nome_fantasia']?.toString() ??
              empresa['razao_social']?.toString() ??
              'Empresa sem nome';

          return {
            'id': empresa['cd_empresa']?.toString() ?? '',
            'nome': nomeExibicao,
            'razao_social': empresa['razao_social']?.toString() ?? '',
            'cnpj': cnpj,
            'cnpj_formatted': cnpjFormatted,
            'display_text': '$nomeExibicao - $cnpjFormatted',
          };
        }).toList();
      } else {
        throw Exception('Erro ao carregar empresas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar empresas: $e');
    }
  }

  /// Obtém estatísticas das taxas administrativas
  static Future<Map<String, dynamic>> obterEstatisticas({
    String? competencia,
    String? tipoTaxa,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (competencia != null && competencia.isNotEmpty) {
        queryParams['competencia'] = competencia;
      }
      if (tipoTaxa != null && tipoTaxa.isNotEmpty) {
        queryParams['tipo_taxa'] = tipoTaxa;
      }

      final uri = Uri.parse('$baseUrl/taxa-administrativa/estatisticas')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erro ao obter estatísticas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao obter estatísticas: $e');
    }
  }

  /// Exporta relatório de taxas em PDF
  static Future<List<int>> exportarRelatorioPDF({
    String? tipoTaxa,
    String? status,
    String? competencia,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (tipoTaxa != null && tipoTaxa.isNotEmpty) {
        queryParams['tipo_taxa'] = tipoTaxa;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (competencia != null && competencia.isNotEmpty) {
        queryParams['competencia'] = competencia;
      }
      if (dataInicio != null) {
        queryParams['data_inicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['data_fim'] = dataFim.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/taxa-administrativa/relatorio/pdf')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Erro ao gerar relatório PDF: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao exportar relatório PDF: $e');
    }
  }

  /// Gera PDF com as taxas administrativas
  static Future<void> gerarPdfTaxas({
    required List<String> competencias,
    required List<TaxaAdministrativa> taxas,
    String? competenciaSelecionada,
    String? observacoes,
  }) async {
    try {
      debugPrint('🟢 Iniciando geração do PDF...');

      // Filtrar taxas pela competência selecionada (prioriza competência de faturamento)
      final taxasFiltradas = competenciaSelecionada != null
          ? taxas.where((t) {
              final compFat = t.competenciaFaturamentoFormatted;              
              return compFat == competenciaSelecionada;              
            }).toList()
          : taxas;

      debugPrint('📋 Taxas filtradas: ${taxasFiltradas.length}');

      // ✅ Agrupar por CPF (fallback para nome) e somar valores
      final Map<String, Map<String, dynamic>> taxasPorCandidato = {};
      for (final taxa in taxasFiltradas) {
        final nome = (taxa.nomeCandidato ?? 'Sem nome').trim().toUpperCase();
        String chaveCpf = nome;

        if (taxasPorCandidato.containsKey(chaveCpf)) {
          final dadosExistentes = taxasPorCandidato[chaveCpf]!;
          final valorAtual = dadosExistentes['valor_total'] as double;
          final novoValorTotal = valorAtual + (taxa.valorCalculado ?? 0.0);

          dadosExistentes['valor_total'] = novoValorTotal;
          dadosExistentes['valor_formatado'] =
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(novoValorTotal);

          debugPrint(
              '🔄 Soma candidato $chaveCpf: ${valorAtual.toStringAsFixed(2)} + ${(taxa.valorCalculado ?? 0.0).toStringAsFixed(2)} = ${novoValorTotal.toStringAsFixed(2)}');
        } else {
          final valorInicial = taxa.valorCalculado ?? 0.0;
          taxasPorCandidato[chaveCpf] = {
            'taxa_principal': taxa, // referência p/ dados pessoais
            'valor_total': valorInicial,
            'valor_formatado':
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                    .format(valorInicial),
          };

          debugPrint(
              '➕ Novo candidato $chaveCpf: ${valorInicial.toStringAsFixed(2)}');
        }
      }

      debugPrint(
          '👥 Candidatos únicos após agrupamento: ${taxasPorCandidato.length}');

      final empresa = taxasFiltradas.isNotEmpty
          ? (taxasFiltradas.first.empresa ?? 'Todas')
          : 'Todas';
      final cnpjEmpresa =
          taxasFiltradas.isNotEmpty ? (taxasFiltradas.first.cnpj ?? '-') : '-';

      // Total geral usando os valores agrupados
      final total = taxasPorCandidato.values.fold<double>(
        0.0,
        (soma, dados) => soma + (dados['valor_total'] as double),
      );

      debugPrint('💰 Total geral calculado: R\$${total.toStringAsFixed(2)}');

      // ✅ DIVIDIR EM LOTES DE 30 REGISTROS POR PÁGINA
      const registrosPorPagina = 30;
      final candidatos = taxasPorCandidato.entries.toList();
      final totalPaginas = (candidatos.length / registrosPorPagina).ceil();

      debugPrint('📄 Total de páginas necessárias: $totalPaginas');

      final pdf = pw.Document();

      // Carregar logo UMA VEZ
      final logoBytes = await rootBundle.load('assets/logo_cide.png');
      final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // ✅ GERAR PÁGINAS EM LOTES
      for (var pagina = 0; pagina < totalPaginas; pagina++) {
        final inicio = pagina * registrosPorPagina;
        final fim = (inicio + registrosPorPagina > candidatos.length)
            ? candidatos.length
            : inicio + registrosPorPagina;

        final candidatosPagina = candidatos.sublist(inicio, fim);

        debugPrint(
            '📝 Processando página ${pagina + 1}/$totalPaginas (registros $inicio-$fim)');

        // ✅ CORREÇÃO: Preparar dados usando valores agrupados
        final List<List<String>> dadosTabelaPagina = [
          ['ITEM', 'NOME', 'CPF', 'INÍCIO', 'TÉRMINO', 'VALOR'],
          ...candidatosPagina.asMap().entries.map((entry) {
            final indiceGlobal = inicio + entry.key;
            final candidato = entry.value.key;
            final dadosCandidato = entry.value.value;
            final taxaPrincipal =
                dadosCandidato['taxa_principal'] as TaxaAdministrativa;
            final valorFormatado = dadosCandidato['valor_formatado'] as String;

            return [
              '${indiceGlobal + 1}',
              candidato,
              taxaPrincipal.cpfCandidato ?? '-',
              taxaPrincipal.dataInicioFormatted,
              taxaPrincipal.dataFimFormatted,
              valorFormatado,
            ];
          }).toList(),
        ];

        // ✅ CORREÇÃO: Calcular subtotal usando valores agrupados
        final subtotalPagina = candidatosPagina.fold<double>(
          0.0,
          (soma, entry) {
            final dadosCandidato = entry.value;
            return soma + (dadosCandidato['valor_total'] as double);
          },
        );

        debugPrint(
            '📊 Subtotal página ${pagina + 1}: R\$${subtotalPagina.toStringAsFixed(2)}');

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            build: (context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Cabeçalho
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Image(logo, width: 133, height: 80),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'CIDE - CAPACITAÇÃO, INSERÇÃO E',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'DESENVOLVIMENTO',
                            style: pw.TextStyle(
                                fontSize: 8, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            'CNPJ: 03.935.660-00001-52',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'COMPETÊNCIA: ${competenciaSelecionada ?? '-'}',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            empresa,
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            cnpjEmpresa,
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Divider(thickness: 1.5),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'FATURA',
                        style: pw.TextStyle(
                            fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'Página ${pagina + 1} de $totalPaginas',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),

                  // Tabela
                  pw.TableHelper.fromTextArray(
                    data: dadosTabelaPagina,
                    border: pw.TableBorder.all(
                        color: PdfColors.grey800, width: 0.8),
                    headerStyle: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.grey700,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 7),
                    cellHeight: 16,
                    cellAlignments: {
                      0: pw.Alignment.center,
                      1: pw.Alignment.centerLeft,
                      2: pw.Alignment.center,
                      3: pw.Alignment.center,
                      4: pw.Alignment.center,
                      5: pw.Alignment.centerRight,
                    },
                    columnWidths: {
                      0: const pw.FixedColumnWidth(35),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.5),
                      5: const pw.FlexColumnWidth(1.5),
                    },
                    oddRowDecoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                  ),

                  pw.Spacer(),

                  pw.SizedBox(height: 8),

                  // Subtotal da página (exceto na última)
                  if (pagina < totalPaginas - 1)
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        border:
                            pw.Border.all(color: PdfColors.grey800, width: 1),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Subtotal página: ',
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(width: 8),
                          pw.Text(
                            NumberFormat.currency(
                                    locale: 'pt_BR', symbol: 'R\$')
                                .format(subtotalPagina),
                            style: pw.TextStyle(
                                fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  // Total geral (apenas na última página)
                  if (pagina == totalPaginas - 1) ...[
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey300,
                        border:
                            pw.Border.all(color: PdfColors.grey800, width: 1.5),
                      ),
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.end,
                        children: [
                          pw.Text(
                            'TOTAL GERAL: ',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(width: 16),
                          pw.Text(
                            NumberFormat.currency(
                                    locale: 'pt_BR', symbol: 'R\$')
                                .format(total),
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Observações:',
                      style: pw.TextStyle(
                          fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      constraints: const pw.BoxConstraints(minHeight: 40),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Text(
                        observacoes?.trim().isNotEmpty == true
                            ? observacoes!
                            : '',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                  pw.Spacer(),

                  // Rodapé
                  pw.Divider(thickness: 1),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'ENDEREÇO: AV. TANCREDO NEVES, CAMINHO DAS ÁRVORES, SALVADOR/BA - CEP: 41820-020',
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'TELEFONE: (71)3451-8783 | INSTAGRAM: @CIDERH | E-MAIL: COBRANCA@CIDEESTAGIO.COM.BR',
                    style: const pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              );
            },
          ),
        );
      }

      debugPrint(
          '✅ PDF criado com ${pdf.document.pdfPageList.pages.length} páginas');
      debugPrint('🖨️ Abrindo visualização de impressão...');

      // Imprimir ou salvar
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name:
            'fatura_${competenciaSelecionada ?? 'todas'}_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      debugPrint('✅ PDF gerado com sucesso!');
    } catch (e, stack) {
      debugPrint('❌ Erro ao gerar PDF: $e');
      debugPrint('📍 Stack trace: $stack');
      rethrow;
    }
  }

  static pw.Widget _buildPdfCell(
    String texto, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : (align == pw.TextAlign.right
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  /// Exporta dados em Excel
  static Future<List<int>> exportarExcel({
    String? tipoTaxa,
    String? status,
    String? competencia,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (tipoTaxa != null && tipoTaxa.isNotEmpty) {
        queryParams['tipo_taxa'] = tipoTaxa;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (competencia != null && competencia.isNotEmpty) {
        queryParams['competencia'] = competencia;
      }
      if (dataInicio != null) {
        queryParams['data_inicio'] = dataInicio.toIso8601String();
      }
      if (dataFim != null) {
        queryParams['data_fim'] = dataFim.toIso8601String();
      }

      final uri = Uri.parse('$baseUrl/taxa-administrativa/relatorio/excel')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
            'Erro ao gerar relatório Excel: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao exportar relatório Excel: $e');
    }
  }

  /// Verifica taxas vencidas e próximas ao vencimento
  static Future<Map<String, dynamic>> verificarTaxasVencimento() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/taxa-administrativa/verificar-vencimento'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'taxas_vencidas': (data['taxas_vencidas'] as List? ?? [])
              .map((item) => TaxaAdministrativa.fromJson(item))
              .toList(),
          'taxas_vencendo': (data['taxas_vencendo'] as List? ?? [])
              .map((item) => TaxaAdministrativa.fromJson(item))
              .toList(),
          'total_vencidas': data['total_vencidas'] ?? 0,
          'total_vencendo': data['total_vencendo'] ?? 0,
          'valor_total_vencidas': data['valor_total_vencidas'] ?? 0.0,
          'valor_total_vencendo': data['valor_total_vencendo'] ?? 0.0,
        };
      } else {
        throw Exception(
            'Erro ao verificar vencimentos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao verificar vencimentos: $e');
    }
  }

  /// Busca taxas por competência
  static Future<List<TaxaAdministrativa>> buscarTaxasPorCompetencia(
      String competencia) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/taxa-administrativa/competencia/$competencia'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['taxas'] as List)
            .map((item) => TaxaAdministrativa.fromJson(item))
            .toList();
      } else {
        throw Exception(
            'Erro ao buscar taxas por competência: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar taxas por competência: $e');
    }
  }

  static Future<List<CompetenciaDetalhada>> obterCompetenciasDetalhadas({
    String? tipo,
    String? empresa,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (tipo != null && tipo.isNotEmpty) {
        queryParams['tipo_taxa'] = tipo;
      }

      if (empresa != null && empresa.isNotEmpty) {
        queryParams['empresa'] = empresa;
      }

      final uri = Uri.parse('$baseUrl/taxa-administrativa/competencias')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final competenciasArray = data['competencias'] as List? ?? [];

        return competenciasArray
            .whereType<Map<String, dynamic>>()
            .map((item) =>
                CompetenciaDetalhada.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      throw Exception('Erro ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao obter competências detalhadas: $e');
    }
  }

  /// Obtém competências disponíveis
  static Future<List<String>> obterCompetencias() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/taxa-administrativa/competencias'),
        headers: await _getHeaders(),
      );

      print('🔍 [COMPETENCIAS] Status: ${response.statusCode}');
      print('📦 [COMPETENCIAS] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 [COMPETENCIAS] Data parsed: $data');

        // ✅ CORREÇÃO: O backend retorna { "competencias": [...], "total": 6 }
        // Não um array direto de strings

        if (data is Map<String, dynamic>) {
          // Caso 1: Resposta com objeto contendo array
          final competenciasArray = data['competencias'] as List?;

          if (competenciasArray == null) {
            print('⚠️ [COMPETENCIAS] Array "competencias" não encontrado');
            return [];
          }

          // Extrair apenas as strings de competência
          final competencias = competenciasArray
              .map((item) {
                if (item is String) {
                  // Se o item já é string, retorna direto
                  return item;
                } else if (item is Map<String, dynamic>) {
                  // Se é um objeto, pega o campo 'competencia'
                  return item['competencia']?.toString() ?? '';
                } else {
                  return '';
                }
              })
              .where((comp) => comp.isNotEmpty)
              .toList();

          print(
              '✅ [COMPETENCIAS] ${competencias.length} competências encontradas');
          return competencias;
        } else if (data is List) {
          // Caso 2: Resposta é array direto
          final competencias = data
              .map((item) {
                if (item is String) {
                  return item;
                } else if (item is Map<String, dynamic>) {
                  return item['competencia']?.toString() ?? '';
                } else {
                  return '';
                }
              })
              .where((comp) => comp.isNotEmpty)
              .toList();

          print(
              '✅ [COMPETENCIAS] ${competencias.length} competências encontradas (array direto)');
          return competencias;
        }

        print('⚠️ [COMPETENCIAS] Formato de resposta não reconhecido');
        return [];
      } else {
        throw Exception('Erro ao obter competências: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ [COMPETENCIAS] Erro: $e');
      print('📍 [COMPETENCIAS] Stack: $stackTrace');
      throw Exception('Erro ao obter competências: $e');
    }
  }

  /// Envia lembrete por email para taxas vencidas/vencendo
  static Future<Map<String, dynamic>> enviarLembreteEmail({
    List<String>? taxaIds,
    String? tipoLembrete, // 'vencidas' ou 'vencendo'
  }) async {
    try {
      final body = <String, dynamic>{};

      if (taxaIds != null && taxaIds.isNotEmpty) {
        body['taxa_ids'] = taxaIds;
      }
      if (tipoLembrete != null) {
        body['tipo_lembrete'] = tipoLembrete;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/taxa-administrativa/enviar-lembrete'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'sucesso': true,
          'mensagem': data['message'] ?? 'Lembretes enviados com sucesso',
          'emails_enviados': data['emails_enviados'] ?? 0,
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Erro ao enviar lembretes');
      }
    } catch (e) {
      throw Exception('Erro ao enviar lembretes: $e');
    }
  }

  // ==========================================
  // MÉTODOS AUXILIARES
  // ==========================================

  /// Formata CNPJ para exibição
  static String _formatCNPJ(String cnpj) {
    if (cnpj.length != 14) return cnpj;
    return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
  }

  /// Gera uma nova competência baseada na data atual
  static String gerarCompetenciaAtual() {
    final agora = DateTime.now();
    return '${agora.month.toString().padLeft(2, '0')}/${agora.year}';
  }

  /// Gera competência do mês anterior
  static String gerarCompetenciaAnterior() {
    final agora = DateTime.now();
    final mesAnterior = DateTime(agora.year, agora.month - 1);
    return '${mesAnterior.month.toString().padLeft(2, '0')}/${mesAnterior.year}';
  }

  /// Valida formato de competência
  static bool validarCompetencia(String competencia) {
    if (!RegExp(r'^\d{2}/\d{4}$').hasMatch(competencia)) {
      return false;
    }

    final parts = competencia.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    return month != null &&
        month >= 1 &&
        month <= 12 &&
        year != null &&
        year >= 2020 &&
        year <= 2050;
  }

  /// Calcula data de vencimento padrão (10º dia útil do mês seguinte)
  static DateTime calcularDataVencimentoPadrao(String competencia) {
    final parts = competencia.split('/');
    final month = int.parse(parts[0]);
    final year = int.parse(parts[1]);

    // Próximo mês
    final proximoMes = month == 12 ? 1 : month + 1;
    final proximoAno = month == 12 ? year + 1 : year;

    // 10º dia do próximo mês (simplificado)
    return DateTime(proximoAno, proximoMes, 10);
  }

  // ==========================================
  // MÉTODOS DE CACHE
  // ==========================================

  static const Duration _cacheTimeout = Duration(minutes: 5);
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

  /// Obtém empresas com cache
  static Future<List<Map<String, dynamic>>> getCachedEmpresas({
    String? search,
    bool? ativo = true,
  }) async {
    final cacheKey = 'empresas_taxa_${search ?? ''}_${ativo ?? true}';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return List<Map<String, dynamic>>.from(cached);
    }

    final empresas = await buscarEmpresas2(search: search, ativo: ativo);
    _setCache(cacheKey, empresas);
    return empresas;
  }

  /// Obtém estatísticas com cache
  static Future<Map<String, dynamic>> getCachedEstatisticas({
    String? competencia,
    String? tipoTaxa,
  }) async {
    final cacheKey = 'estatisticas_taxa_${competencia ?? ''}_${tipoTaxa ?? ''}';
    final cached = _getCache(cacheKey);

    if (cached != null) {
      return cached;
    }

    final stats = await obterEstatisticas(
      competencia: competencia,
      tipoTaxa: tipoTaxa,
    );
    _setCache(cacheKey, stats);
    return stats;
  }
}
