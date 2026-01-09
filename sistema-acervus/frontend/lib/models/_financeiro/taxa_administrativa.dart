class TaxaAdministrativa {
  final String? id;
  final String? codigoCobranca;
  final int? cdEmpresa;
  final String? empresa;
  final DateTime? competencia;
  final String? tipoContrato;
  final DateTime? competenciaFaturamento;
  final int? cdContrato;
  final String? cpfCandidato;
  final String? nomeCandidato;
  final int? cdPlanoPagamento;
  final String? planoPagamento;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? regimeCobranca; // 'INTEGRAL', 'PARCIAL', 'ISENTO'
  final String? tipoCobranca;
  final double? valorBase;
  final double? valorCalculado;
  final DateTime? criadoEm;
  final String? regraOrigem; // 'VIGENCIA', 'ENCERRAMENTO', 'INICIO'
  final String? motivoRegra;

  // Campos adicionais para compatibilidade com sistema existente
  final String? cnpj;
  final String? status; // 'pendente', 'pago', 'vencido', 'cancelado'
  final String? observacoes;
  final DateTime? dataPagamento;
  final String? formaPagamento;
  final String? numeroTransacao;
  final DateTime? dataVencimento;
  final DateTime? updatedAt;
  final int? criadoPor;
  final int? alteradoPor;
  final bool ativo;

  // ✅ NOVOS: Campos para auditoria detalhada e controle de edição
  final bool? confirmada; // Se a competência foi confirmada (bloqueia edição)
  final int? confirmadaPor; // ID do usuário que confirmou
  final DateTime? confirmadaEm; // Data/hora da confirmação
  final String? nomeUsuarioCriador; // Nome de quem criou
  final String? nomeUsuarioModificador; // Nome de quem modificou por último
  final String? nomeUsuarioConfirmador; // Nome de quem confirmou
  final String? motivoUltimaAlteracao; // Motivo da última alteração de valor
  final String? setor; // Setor do estagiário/aprendiz

  TaxaAdministrativa({
    this.id,
    this.codigoCobranca,
    this.cdEmpresa,
    this.empresa,
    this.competencia,
    this.tipoContrato,
    this.competenciaFaturamento,
    this.cdContrato,
    this.nomeCandidato,
    this.cpfCandidato,
    this.cdPlanoPagamento,
    this.planoPagamento,
    this.dataInicio,
    this.dataFim,
    this.regimeCobranca,
    this.tipoCobranca,
    this.valorBase,
    this.valorCalculado,
    this.criadoEm,
    this.regraOrigem,
    this.motivoRegra,
    this.cnpj,
    this.status,
    this.observacoes,
    this.dataPagamento,
    this.formaPagamento,
    this.numeroTransacao,
    this.dataVencimento,
    this.updatedAt,
    this.criadoPor,
    this.alteradoPor,
    this.ativo = true,
    // ✅ NOVOS: Inicialização dos campos de auditoria
    this.confirmada = false,
    this.confirmadaPor,
    this.confirmadaEm,
    this.nomeUsuarioCriador,
    this.nomeUsuarioModificador,
    this.nomeUsuarioConfirmador,
    this.motivoUltimaAlteracao,
    this.setor,
  });

  factory TaxaAdministrativa.fromJson(Map<String, dynamic> json) {
    return TaxaAdministrativa(
      id: json['id']?.toString(),
      codigoCobranca: json['codigo_cobranca']?.toString(),
      cdEmpresa: json['cd_empresa'] is String
          ? int.tryParse(json['cd_empresa'])
          : json['cd_empresa'],
      empresa: json['empresa']?.toString(),
      competencia: json['competencia'] != null
          ? DateTime.tryParse(json['competencia'].toString())
          : null,
      tipoContrato: json['tipo_contrato']?.toString(),
      competenciaFaturamento: json['competencia_faturamento'] != null
          ? DateTime.tryParse(json['competencia_faturamento'].toString())
          : null,
      cdContrato: json['cd_contrato'] is String
          ? int.tryParse(json['cd_contrato'])
          : json['cd_contrato'],
      nomeCandidato: json['nome_candidato']?.toString(),
      cpfCandidato: json['cpf_candidato']?.toString(),
      cdPlanoPagamento: json['cd_plano_pagamento'] is String
          ? int.tryParse(json['cd_plano_pagamento'])
          : json['cd_plano_pagamento'],
      planoPagamento: json['plano_pagamento']?.toString(),
      dataInicio: json['data_inicio'] != null
          ? DateTime.tryParse(json['data_inicio'].toString())
          : null,
      dataFim: json['data_fim'] != null
          ? DateTime.tryParse(json['data_fim'].toString())
          : null,
      regimeCobranca: json['tipo_cobranca']?.toString(),
      tipoCobranca: json['tipo_cobranca']?.toString(),
      valorBase: json['valor_base'] is String
          ? double.tryParse(json['valor_base'])
          : json['valor_base']?.toDouble(),
      valorCalculado: json['valor_calculado'] is String
          ? double.tryParse(json['valor_calculado'])
          : json['valor_calculado']?.toDouble(),
      criadoEm: json['criado_em'] != null
          ? DateTime.tryParse(json['criado_em'].toString())
          : (json['data_criacao'] != null
              ? DateTime.tryParse(json['data_criacao'].toString())
              : null),
      regraOrigem: json['regra_origem']?.toString(),
      motivoRegra: json['motivo_regra']?.toString(),

      // Campos de compatibilidade
      cnpj: json['cnpj']?.toString(),
      status: json['status_descricao']?.toString(),
      observacoes: json['observacoes']?.toString(),
      dataPagamento: json['data_pagamento'] != null
          ? DateTime.tryParse(json['data_pagamento'].toString())
          : null,
      formaPagamento: json['plano_pagamento']?.toString(),
      numeroTransacao: json['numero_transacao']?.toString(),
      dataVencimento: json['data_vencimento'] != null
          ? DateTime.tryParse(json['data_vencimento'].toString())
          : json['competencia_faturamento'] != null
              ? DateTime.tryParse(json['competencia_faturamento'].toString())
              : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : (json['data_alteracao'] != null
              ? DateTime.tryParse(json['data_alteracao'].toString())
              : null),
      criadoPor: json['criado_por'] is String
          ? int.tryParse(json['criado_por'])
          : json['criado_por'],
      alteradoPor: json['alterado_por'] is String
          ? int.tryParse(json['alterado_por'])
          : json['alterado_por'],
      ativo: json['ativo'] == true ||
          json['ativo'] == 1 ||
          json['ativo'] == '1' ||
          json['ativo'] == null,

      // ✅ NOVOS: Parse dos campos de auditoria
      confirmada: json['confirmada'] == true ||
          json['confirmada'] == 1 ||
          json['confirmada'] == '1',
      confirmadaPor: json['confirmada_por'] is String
          ? int.tryParse(json['confirmada_por'])
          : json['confirmada_por'],
      confirmadaEm: json['confirmada_em'] != null
          ? DateTime.tryParse(json['confirmada_em'].toString())
          : null,
      nomeUsuarioCriador: json['nome_usuario_criador']?.toString(),
      // aceita 'usuario_alteracao' do backend
      nomeUsuarioModificador:
          (json['usuario_alteracao'] ?? json['nome_usuario_modificador'])
              ?.toString(),
      nomeUsuarioConfirmador: json['nome_usuario_confirmador']?.toString(),
      // aceita 'motivo' do backend
      motivoUltimaAlteracao:
          (json['motivo_ultima_alteracao'] ?? json['motivo'])?.toString(),
      setor: json['setor']?.toString(),
    );
  }

  // Método auxiliar para mapear regime de cobrança para status
  static String _getStatusFromRegime(String? regime) {
    switch (regime?.toUpperCase()) {
      case 'ISENTO':
        return 'isento';
      case 'INTEGRAL':
      case 'PARCIAL':
        return 'pendente';
      default:
        return 'pendente';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (codigoCobranca != null) 'codigo_cobranca': codigoCobranca,
      if (cdEmpresa != null) 'cd_empresa': cdEmpresa,
      if (empresa != null) 'empresa': empresa,
      if (competencia != null) 'competencia': competencia!.toIso8601String(),
      if (tipoContrato != null) 'tipo_contrato': tipoContrato,
      if (competenciaFaturamento != null)
        'competencia_faturamento': competenciaFaturamento!.toIso8601String(),
      if (cdContrato != null) 'cd_contrato': cdContrato,
      if (nomeCandidato != null) 'nome_candidato': nomeCandidato,
      if (cpfCandidato != null) 'cpf_candidato': cpfCandidato,
      if (cdPlanoPagamento != null) 'cd_plano_pagamento': cdPlanoPagamento,
      if (planoPagamento != null) 'plano_pagamento': planoPagamento,
      if (dataInicio != null) 'data_inicio': dataInicio!.toIso8601String(),
      if (dataFim != null) 'data_fim': dataFim!.toIso8601String(),
      if (regimeCobranca != null) 'regime_cobranca': regimeCobranca,
      if (tipoCobranca != null) 'tipo_cobranca': tipoCobranca,
      if (valorBase != null) 'valor_base': valorBase,
      if (valorCalculado != null) 'valor_calculado': valorCalculado,
      if (criadoEm != null) 'criado_em': criadoEm!.toIso8601String(),
      if (regraOrigem != null) 'regra_origem': regraOrigem,
      if (motivoRegra != null) 'motivo_regra': motivoRegra,
      if (cnpj != null) 'cnpj': cnpj,
      'status': status,
      if (observacoes != null) 'observacoes': observacoes,
      if (dataPagamento != null)
        'data_pagamento': dataPagamento!.toIso8601String(),
      if (formaPagamento != null) 'forma_pagamento': formaPagamento,
      if (numeroTransacao != null) 'numero_transacao': numeroTransacao,
      if (dataVencimento != null)
        'data_vencimento': dataVencimento!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (criadoPor != null) 'criado_por': criadoPor,
      if (alteradoPor != null) 'alterado_por': alteradoPor,
      'ativo': ativo,
      if (nomeUsuarioModificador != null)
        'usuario_alteracao': nomeUsuarioModificador,
      if (status != null) 'status_contrato': status,
      // ✅ NOVOS: Serialização dos campos de auditoria
      'confirmada': confirmada ?? false,
      if (confirmadaPor != null) 'confirmada_por': confirmadaPor,
      if (confirmadaEm != null)
        'confirmada_em': confirmadaEm!.toIso8601String(),
      if (motivoUltimaAlteracao != null)
        'motivo_ultima_alteracao': motivoUltimaAlteracao,
      if (setor != null) 'setor': setor,
    };
  }

  // Formatações e propriedades auxiliares
  String get tipoContratoFormatted {
    switch (tipoContrato) {
      case '1':
        return 'Estágio';
      case '2':
        return 'Jovem Aprendiz';
      default:
        return tipoContrato ?? '';
    }
  }

  String get regimeCobrancaFormatted {
    switch (regimeCobranca?.toUpperCase()) {
      case 'INTEGRAL':
        return 'Integral';
      case 'PARCIAL':
        return 'Parcial';
      case 'ISENTO':
        return 'Isento';
      default:
        return regimeCobranca ?? '';
    }
  }

  String get statusFormatted {
    switch (status?.toLowerCase()) {
      case 'pendente':
        return 'Pendente';
      case 'pago':
        return 'Pago';
      case 'vencido':
        return 'Vencido';
      case 'cancelado':
        return 'Cancelado';
      case 'isento':
        return 'Isento';
      default:
        return status ?? '';
    }
  }

  String get valorBaseFormatted {
    if (valorBase == null) return 'R\$ 0,00';
    return 'R\$ ${valorBase!.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get valorCalculadoFormatted {
    if (valorCalculado == null) return 'R\$ 0,00';
    return 'R\$ ${valorCalculado!.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String get cnpjFormatted {
    if (cnpj == null || cnpj!.isEmpty) return 'CNPJ não informado';

    // Remove caracteres não numéricos
    final cnpjNumeros = cnpj!.replaceAll(RegExp(r'[^0-9]'), '');

    if (cnpjNumeros.length != 14) return cnpj!;

    return '${cnpjNumeros.substring(0, 2)}.${cnpjNumeros.substring(2, 5)}.${cnpjNumeros.substring(5, 8)}/${cnpjNumeros.substring(8, 12)}-${cnpjNumeros.substring(12, 14)}';
  }

  String get competenciaFormatted {
    if (competencia == null) return '';
    return '${competencia!.month.toString().padLeft(2, '0')}/${competencia!.year}';
  }

  String get competenciaFaturamentoFormatted {
    if (competenciaFaturamento == null) return '';
    return '${competenciaFaturamento!.month.toString().padLeft(2, '0')}/${competenciaFaturamento!.year}';
  }

  String get dataInicioFormatted {
    if (dataInicio == null) return '';
    return '${dataInicio!.day.toString().padLeft(2, '0')}/${dataInicio!.month.toString().padLeft(2, '0')}/${dataInicio!.year}';
  }

  String get dataFimFormatted {
    if (dataFim == null) return '';
    return '${dataFim!.day.toString().padLeft(2, '0')}/${dataFim!.month.toString().padLeft(2, '0')}/${dataFim!.year}';
  }

  String get dataVencimentoFormatted {
    if (dataVencimento == null) return '';
    return '${dataVencimento!.day.toString().padLeft(2, '0')}/${dataVencimento!.month.toString().padLeft(2, '0')}/${dataVencimento!.year}';
  }

  String get dataPagamentoFormatted {
    if (dataPagamento == null) return '';
    return '${dataPagamento!.day.toString().padLeft(2, '0')}/${dataPagamento!.month.toString().padLeft(2, '0')}/${dataPagamento!.year}';
  }

  // ✅ NOVOS: Getters para tooltips de auditoria
  String get tooltipCriacao {
    if (nomeUsuarioCriador == null || criadoEm == null) {
      return 'Criado pelo sistema';
    }
    final dataFormatada =
        '${criadoEm!.day.toString().padLeft(2, '0')}/${criadoEm!.month.toString().padLeft(2, '0')}/${criadoEm!.year} às ${criadoEm!.hour.toString().padLeft(2, '0')}:${criadoEm!.minute.toString().padLeft(2, '0')}';
    return 'Criado por: $nomeUsuarioCriador\nEm: $dataFormatada';
  }

  String get tooltipModificacao {
    // Se não houver nenhuma info de modificação, mostra info básica
    if (nomeUsuarioModificador == null && updatedAt == null) {
      final List<String> parts = [];
      if (valorBase != null) {
        parts.add('Valor base: $valorBaseFormatted');
      }
      final tipoCobrancaDisplay = regimeCobrancaFormatted.isNotEmpty
          ? regimeCobrancaFormatted
          : (regimeCobranca ?? '');
      if (tipoCobrancaDisplay.isNotEmpty) {
        parts.add('Tipo cobrança: $tipoCobrancaDisplay');
      }
      if (motivoRegra != null && motivoRegra!.isNotEmpty) {
        parts.add('Motivo regra: $motivoRegra');
      }      
      return parts.join('\n');
    }

    final List<String> lines = [];
    if (nomeUsuarioModificador != null && nomeUsuarioModificador!.isNotEmpty) {
      lines.add('Modificado por: $nomeUsuarioModificador');
    }
    if (updatedAt != null) {
      final dataFormatada =
          '${updatedAt!.day.toString().padLeft(2, '0')}/${updatedAt!.month.toString().padLeft(2, '0')}/${updatedAt!.year} às ${updatedAt!.hour.toString().padLeft(2, '0')}:${updatedAt!.minute.toString().padLeft(2, '0')}';
      lines.add('Em: $dataFormatada');
    }

    if (valorBase != null) {
      lines.add('Valor base: $valorBaseFormatted');
    }

    final tipoCobranca = regimeCobranca ?? '';
    if (tipoCobranca.isNotEmpty) {
      lines.add('Tipo cobrança: $tipoCobranca');
    }

    if (motivoRegra != null && motivoRegra!.isNotEmpty) {
      lines.add('Motivo regra: $motivoRegra');
    }

    if (motivoUltimaAlteracao != null && motivoUltimaAlteracao!.isNotEmpty) {
      lines.add('Motivo alteração: $motivoUltimaAlteracao');
    }

    return lines.join('\n');
  }

  String get tooltipConfirmacao {
    if (confirmada != true) {
      return 'Competência não confirmada\nClique para confirmar e bloquear edição';
    }
    if (nomeUsuarioConfirmador == null || confirmadaEm == null) {
      return 'Competência confirmada\nEdição bloqueada';
    }
    final dataFormatada =
        '${confirmadaEm!.day.toString().padLeft(2, '0')}/${confirmadaEm!.month.toString().padLeft(2, '0')}/${confirmadaEm!.year} às ${confirmadaEm!.hour.toString().padLeft(2, '0')}:${confirmadaEm!.minute.toString().padLeft(2, '0')}';
    return 'Confirmado por: $nomeUsuarioConfirmador\nEm: $dataFormatada\n\nClique para desconfirmar e liberar edição';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaxaAdministrativa && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TaxaAdministrativa(id: $id, empresa: $empresa, candidato: $nomeCandidato, regime: $regimeCobranca, valor: $valorCalculado)';
  }
}

// Enum para tipos de contrato
enum TipoContrato {
  estagio,
  aprendiz,
}

extension TipoContratoExtension on TipoContrato {
  String get value {
    switch (this) {
      case TipoContrato.estagio:
        return '1';
      case TipoContrato.aprendiz:
        return '2';
    }
  }

  String get displayName {
    switch (this) {
      case TipoContrato.estagio:
        return 'Estágio';
      case TipoContrato.aprendiz:
        return 'Jovem Aprendiz';
    }
  }
}

// Enum para regime de cobrança
enum RegimeCobranca {
  integral,
  parcial,
  isento,
}

extension RegimeCobrancaExtension on RegimeCobranca {
  String get value {
    switch (this) {
      case RegimeCobranca.integral:
        return 'INTEGRAL';
      case RegimeCobranca.parcial:
        return 'PARCIAL';
      case RegimeCobranca.isento:
        return 'ISENTO';
    }
  }

  String get displayName {
    switch (this) {
      case RegimeCobranca.integral:
        return 'Integral';
      case RegimeCobranca.parcial:
        return 'Parcial';
      case RegimeCobranca.isento:
        return 'Isento';
    }
  }
}

// Enum para regra de origem
enum RegraOrigem {
  vigencia,
  encerramento,
  inicio,
}

extension RegraOrigemExtension on RegraOrigem {
  String get value {
    switch (this) {
      case RegraOrigem.vigencia:
        return 'VIGENCIA';
      case RegraOrigem.encerramento:
        return 'ENCERRAMENTO';
      case RegraOrigem.inicio:
        return 'INICIO';
    }
  }

  String get displayName {
    switch (this) {
      case RegraOrigem.vigencia:
        return 'Vigência';
      case RegraOrigem.encerramento:
        return 'Encerramento';
      case RegraOrigem.inicio:
        return 'Início';
    }
  }
}

// Enum para status da taxa (mantido para compatibilidade)
enum StatusTaxa {
  pendente,
  pago,
  vencido,
  cancelado,
  isento,
}

extension StatusTaxaExtension on StatusTaxa {
  String get value {
    switch (this) {
      case StatusTaxa.pendente:
        return 'pendente';
      case StatusTaxa.pago:
        return 'pago';
      case StatusTaxa.vencido:
        return 'vencido';
      case StatusTaxa.cancelado:
        return 'cancelado';
      case StatusTaxa.isento:
        return 'isento';
    }
  }

  String get displayName {
    switch (this) {
      case StatusTaxa.pendente:
        return 'Pendente';
      case StatusTaxa.pago:
        return 'Pago';
      case StatusTaxa.vencido:
        return 'Vencido';
      case StatusTaxa.cancelado:
        return 'Cancelado';
      case StatusTaxa.isento:
        return 'Isento';
    }
  }
}

// Model para resposta da API com paginação
class TaxaAdministrativaResponse {
  final List<TaxaAdministrativa> dados;
  final TaxaPagination pagination;

  TaxaAdministrativaResponse({
    required this.dados,
    required this.pagination,
  });

  factory TaxaAdministrativaResponse.fromJson(Map<String, dynamic> json) {
    return TaxaAdministrativaResponse(
      dados: (json['dados'] as List<dynamic>?)
              ?.map((item) =>
                  TaxaAdministrativa.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: TaxaPagination.fromJson(
          json['pagination'] as Map<String, dynamic>? ?? {}),
    );
  }
}

// Model para paginação
class TaxaPagination {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPrevPage;

  TaxaPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPrevPage,
  });

  factory TaxaPagination.fromJson(Map<String, dynamic> json) {
    return TaxaPagination(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      hasNextPage: json['hasNextPage'] ?? false,
      hasPrevPage: json['hasPrevPage'] ?? false,
    );
  }
}

// Validações específicas para taxa administrativa (atualizadas)
class TaxaAdministrativaValidator {
  static String? validateCompetencia(DateTime? competencia) {
    if (competencia == null) {
      return 'Competência é obrigatória';
    }

    final now = DateTime.now();
    final minDate = DateTime(now.year - 2, 1, 1);
    final maxDate = DateTime(now.year + 1, 12, 31);

    if (competencia.isBefore(minDate) || competencia.isAfter(maxDate)) {
      return 'Competência deve estar entre ${minDate.year} e ${maxDate.year}';
    }

    return null;
  }

  static String? validateValorBase(double? valor) {
    if (valor == null) {
      return 'Valor base é obrigatório';
    }

    if (valor < 0) {
      return 'Valor não pode ser negativo';
    }

    if (valor > 999999.99) {
      return 'Valor muito alto';
    }

    return null;
  }

  static String? validateValorCalculado(double? valor) {
    if (valor == null) {
      return 'Valor calculado é obrigatório';
    }

    if (valor < 0) {
      return 'Valor não pode ser negativo';
    }

    return null;
  }

  static String? validateDataInicio(DateTime? data) {
    if (data == null) {
      return 'Data de início é obrigatória';
    }

    return null;
  }

  static String? validateDataFim(DateTime? dataFim, DateTime? dataInicio) {
    if (dataFim == null) {
      return 'Data de fim é obrigatória';
    }

    if (dataInicio != null && dataFim.isBefore(dataInicio)) {
      return 'Data de fim deve ser posterior à data de início';
    }

    return null;
  }
}
