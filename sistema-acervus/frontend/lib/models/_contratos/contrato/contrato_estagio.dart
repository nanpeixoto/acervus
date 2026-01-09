// lib/models/contrato_estagio.dart
class ContratoEstagio {
  final String? id;
  final String? numero;
  final String tipo;
  final String status;
  final String descricaoStatus;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final DateTime? dataDesligamento; // Novo campo para data de desligamento
  final DateTime? dataEmissao;

  // Dados da Empresa
  final String empresaId;
  final dynamic empresa;

  // Dados do Estudante
  final String estudanteId;
  final dynamic estudante;

  // Dados da Instituição
  final String instituicaoEnsinoId;
  final dynamic instituicaoEnsino;

  // Dados do Supervisor
  final String supervisorId;
  final dynamic supervisor;

  // Informações do Contrato
  final String setor;
  final double bolsa;
  final double transporte;
  final double valorAlimentacao;
  final String modalidadeTransporte; // 'diario' ou 'mensal'
  final String atividades;

  // Horários
  /// Tipo de horário: 'sem_escala' ou 'com_escala'
  final String? horarioTipo;

  /// Se possui intervalo (para horário sem escala)
  final bool? possuiIntervalo;

  /// Total de horas da semana (calculado automaticamente)
  final int? totalHorasSemana;

  /// Dados da escala de horários (JSON) - para horário com escala
  final Map<String, dynamic>? escalaHorarios;

  // Campos de horário existentes (mantidos para compatibilidade)
  final String horarioInicio;
  final String horarioInicioIntervalo;
  final String horarioFimIntervalo;
  final String horarioFim;
  final int cargaHoraria;
  // Dados Financeiros
  final String taxaFinanceira;
  final double? valorTaxa;

  // Modelo e Seguradora
  final String modeloContratoId;
  final dynamic modeloContrato;
  final String? seguradora;
  final double? alimentacao;

  // Observações e Metadados
  final String? observacoes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool ativo;
  final List<Map<String, dynamic>>? aditivos;

  ContratoEstagio({
    this.horarioTipo,
    this.possuiIntervalo,
    this.totalHorasSemana,
    this.escalaHorarios,
    this.id,
    this.numero,
    required this.tipo,
    required this.status,
    required this.descricaoStatus,
    this.dataInicio,
    this.dataFim,
    this.dataDesligamento, // Novo campo para data de desligamento
    this.dataEmissao,
    required this.empresaId,
    this.empresa,
    required this.estudanteId,
    this.estudante,
    required this.instituicaoEnsinoId,
    this.instituicaoEnsino,
    required this.supervisorId,
    this.supervisor,
    required this.setor,
    required this.bolsa,
    required this.transporte,
    this.valorAlimentacao = 0.0,
    required this.modalidadeTransporte,
    required this.atividades,
    required this.horarioInicio,
    required this.horarioInicioIntervalo,
    required this.horarioFimIntervalo,
    required this.horarioFim,
    required this.cargaHoraria,
    required this.taxaFinanceira,
    this.valorTaxa,
    required this.modeloContratoId,
    this.modeloContrato,
    this.seguradora,
    this.alimentacao,
    this.observacoes,
    this.createdAt,
    this.updatedAt,
    this.ativo = true,
    this.aditivos,
  });

  factory ContratoEstagio.fromJson(Map<String, dynamic> json) {
    return ContratoEstagio(
      id: json['cd_contrato']?.toString(),
      numero: json['numero'],
      tipo: json['tipo'] ?? 'estagio',
      status: json['status'] ?? '',
      descricaoStatus: json['descricao_status'] ?? '',
      dataInicio: json['data_inicio'] != null
          ? DateTime.parse(json['data_inicio'])
          : null,
      dataFim:
          json['data_fim'] != null ? DateTime.parse(json['data_fim']) : null,
      dataDesligamento: json['data_desligamento'] != null
          ? DateTime.parse(json['data_desligamento'])
          : null,
      dataEmissao: json['data_emissao'] != null
          ? DateTime.parse(json['data_emissao'])
          : null,

      // IDs - manter como estavam para compatibilidade
      empresaId: json['empresa_id']?.toString() ??
          json['cd_empresa']?.toString() ??
          '',
      empresa: _extrairNomeEmpresa(json), // Nome da empresa vem diretamente

      estudanteId: json['estudante_id']?.toString() ??
          json['cd_candidato']?.toString() ??
          '',
      estudante:
          _extrairNomeEstudante(json), // Nome do estudante vem diretamente

      instituicaoEnsinoId: json['instituicao_ensino_id']?.toString() ??
          json['cd_instituicao_ensino']?.toString() ??
          '',
      instituicaoEnsino:
          json['instituicao_ensino'], // Nome da instituição vem diretamente

      supervisorId: json['supervisor_id']?.toString() ??
          json['cd_supervisor']?.toString() ??
          '',
      supervisor: json['supervisor'], // Nome do supervisor vem diretamente

      // Dados básicos do contrato
      setor: json['setor'] ?? '',
      bolsa: double.tryParse(json['bolsa']?.toString() ?? '0') ?? 0.0,
      transporte: double.tryParse(json['transporte']?.toString() ?? '0') ?? 0.0,
      valorAlimentacao:
          double.tryParse(json['alimentacao']?.toString() ?? '0') ?? 0.0,
      modalidadeTransporte: json['modalidade_transporte'] ??
          (json['transporte']?.toString().toLowerCase() == 'mensal'
              ? 'mensal'
              : 'diario'),
      atividades: json['atividades'] ?? '',

      // NOVOS CAMPOS DE HORÁRIO
      horarioTipo: json['horario_tipo'] as String?,
      possuiIntervalo: json['possui_intervalo'] as bool?,
      totalHorasSemana: json['total_horas_semana'] as int?,
      escalaHorarios: json['escala_horarios'] != null &&
              json['escala_horarios'] is Map &&
              (json['escala_horarios'] as Map).isNotEmpty
          ? json['escala_horarios'] as Map<String, dynamic>
          : null,

      // Campos de horário existentes (mantidos para compatibilidade)
      horarioInicio: json['horario_inicio'] != null
          ? json['horario_inicio']
              .toString()
              .substring(0, 5) // Remove segundos se houver
          : '',
      horarioInicioIntervalo: json['horario_inicio_intervalo'] != null
          ? json['horario_inicio_intervalo'].toString().substring(0, 5)
          : '',
      horarioFimIntervalo: json['horario_fim_intervalo'] != null
          ? json['horario_fim_intervalo'].toString().substring(0, 5)
          : '',
      horarioFim: json['horario_fim'] != null
          ? json['horario_fim'].toString().substring(0, 5)
          : '',
      cargaHoraria: json['carga_horaria'] as int? ??
          json['total_horas_semana'] as int? ??
          0,

      // Outros campos
      taxaFinanceira: json['taxa_financeira'] ?? json['plano_pagamento'] ?? '',
      valorTaxa: double.tryParse(json['valor_taxa']?.toString() ?? '0'),

      modeloContratoId: json['cd_template_modelo']?.toString() ??
          json['cd_modelo']?.toString() ??
          '',
      modeloContrato: json['modelo_contrato'],

      seguradora: json['seguradora'],
      alimentacao: double.tryParse(json['alimentacao']?.toString() ?? '0'),
      observacoes: json['observacoes'],

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['data_criacao'] != null
              ? DateTime.parse(json['data_criacao'])
              : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      ativo:
          json['ativo'] == true || json['ativo'] == 1 || json['ativo'] == '1',
      aditivos: json['aditivos'] != null
          ? List<Map<String, dynamic>>.from(json['aditivos'])
          : null,
    );
  }
  static String _extrairNomeEmpresa(Map<String, dynamic> json) {
    // Se empresa é um Map (objeto), extrair o nome
    if (json['empresa'] is Map<String, dynamic>) {
      final empresaMap = json['empresa'] as Map<String, dynamic>;
      return empresaMap['nome']?.toString() ??
          empresaMap['razao_social']?.toString() ??
          empresaMap['nome_fantasia']?.toString() ??
          '';
    }
    // Se empresa é uma String direta, usar ela
    else if (json['empresa'] is String) {
      return json['empresa'] as String;
    }
    // Fallback para outros casos
    return '';
  }

  static String _extrairNomeEstudante(Map<String, dynamic> json) {
    // Se estudante é um Map (objeto), extrair o nome
    if (json['estudante'] is Map<String, dynamic>) {
      final estudanteMap = json['estudante'] as Map<String, dynamic>;
      return estudanteMap['nome']?.toString() ?? '';
    }
    // Se estudante é uma String direta, usar ela
    else if (json['estudante'] is String) {
      return json['estudante'] as String;
    }
    // Fallback para outros casos
    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'cd_empresa': int.tryParse(empresaId) ?? empresaId,
      'cd_estudante': int.tryParse(estudanteId) ?? estudanteId,
      'cd_instituicao_ensino':
          int.tryParse(instituicaoEnsinoId) ?? instituicaoEnsinoId,
      'setor': setor,
      'bolsa': bolsa,
      'transporte': modalidadeTransporte,
      'alimentacao': valorAlimentacao,
      'modalidade_transporte': modalidadeTransporte,
      'atividades': atividades,
      'cd_supervisor': int.tryParse(supervisorId) ?? supervisorId,
      'horario_inicio': horarioInicio,
      'horario_inicio_intervalo': horarioInicioIntervalo,
      'horario_fim_intervalo': horarioFimIntervalo,
      'horario_fim': horarioFim,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'data_desligamento': dataDesligamento?.toIso8601String(),
      'carga_horaria': cargaHoraria,
      'horario_tipo': horarioTipo,
      'possui_intervalo': possuiIntervalo,
      'total_horas_semana': totalHorasSemana,
      'escala_horarios': escalaHorarios,
      'cd_plano_pagamento': taxaFinanceira,
      'cd_template_modelo': int.tryParse(modeloContratoId) ?? modeloContratoId,
      'aditivos': aditivos,
    };
  }

  ContratoEstagio copyWith({
    String? id,
    String? numero,
    String? tipo,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataDesligamento, // Novo campo para data de desligamento
    String? descricaoStatus,
    DateTime? dataEmissao,
    String? empresaId,
    dynamic empresa,
    String? estudanteId,
    dynamic estudante,
    String? instituicaoEnsinoId,
    dynamic instituicaoEnsino,
    String? supervisorId,
    dynamic supervisor,
    String? setor,
    double? bolsa,
    double? transporte,
    double? valorAlimentacao,
    String? modalidadeTransporte,
    String? atividades,
    String? horarioTipo,
    bool? possuiIntervalo,
    int? totalHorasSemana,
    Map<String, dynamic>? escalaHorarios,
    String? horarioInicio,
    String? horarioInicioIntervalo,
    String? horarioFimIntervalo,
    String? horarioFim,
    int? cargaHoraria,
    String? taxaFinanceira,
    double? valorTaxa,
    String? modeloContratoId,
    dynamic modeloContrato,
    String? seguradora,
    double? alimentacao,
    String? observacoes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? ativo,
  }) {
    return ContratoEstagio(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      tipo: tipo ?? this.tipo,
      status: status ?? this.status,
      descricaoStatus: descricaoStatus ?? '',
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      dataDesligamento: dataDesligamento ?? this.dataDesligamento,
      dataEmissao: dataEmissao ?? this.dataEmissao,
      empresaId: empresaId ?? this.empresaId,
      empresa: empresa ?? this.empresa,
      estudanteId: estudanteId ?? this.estudanteId,
      estudante: estudante ?? this.estudante,
      instituicaoEnsinoId: instituicaoEnsinoId ?? this.instituicaoEnsinoId,
      instituicaoEnsino: instituicaoEnsino ?? this.instituicaoEnsino,
      supervisorId: supervisorId ?? this.supervisorId,
      supervisor: supervisor ?? this.supervisor,
      setor: setor ?? this.setor,
      bolsa: bolsa ?? this.bolsa,
      transporte: transporte ?? this.transporte,
      valorAlimentacao: valorAlimentacao ?? this.valorAlimentacao,
      modalidadeTransporte: modalidadeTransporte ?? this.modalidadeTransporte,
      atividades: atividades ?? this.atividades,
      horarioTipo: horarioTipo ?? this.horarioTipo,
      possuiIntervalo: possuiIntervalo ?? this.possuiIntervalo,
      totalHorasSemana: totalHorasSemana ?? this.totalHorasSemana,
      escalaHorarios: escalaHorarios ?? this.escalaHorarios,
      horarioInicio: horarioInicio ?? this.horarioInicio,
      horarioInicioIntervalo:
          horarioInicioIntervalo ?? this.horarioInicioIntervalo,
      horarioFimIntervalo: horarioFimIntervalo ?? this.horarioFimIntervalo,
      horarioFim: horarioFim ?? this.horarioFim,
      cargaHoraria: cargaHoraria ?? this.cargaHoraria,
      taxaFinanceira: taxaFinanceira ?? this.taxaFinanceira,
      valorTaxa: valorTaxa ?? this.valorTaxa,
      modeloContratoId: modeloContratoId ?? this.modeloContratoId,
      modeloContrato: modeloContrato ?? this.modeloContrato,
      seguradora: seguradora ?? this.seguradora,
      alimentacao: alimentacao ?? this.alimentacao,
      observacoes: observacoes ?? this.observacoes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ativo: ativo ?? this.ativo,
    );
  }

  String get descricaoHorario {
    if (horarioTipo == 'com_escala') {
      return _formatarHorarioEscala();
    } else {
      return _formatarHorarioFixo();
    }
  }

  String _formatarHorarioFixo() {
    if (possuiIntervalo == true) {
      return '$horarioInicio às $horarioInicioIntervalo e $horarioFimIntervalo às $horarioFim';
    } else {
      return '$horarioInicio às $horarioFim';
    }
  }

  String _formatarHorarioEscala() {
    if (escalaHorarios == null) return 'Escala não configurada';

    List<String> diasConfigrados = [];

    final diasSemana = {
      'segunda': 'Segunda',
      'terca': 'Terça',
      'quarta': 'Quarta',
      'quinta': 'Quinta',
      'sexta': 'Sexta',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    escalaHorarios!.forEach((dia, dados) {
      if (dados['ativo'] == 'true') {
        String diaFormatado = diasSemana[dia] ?? dia;
        String horarioFormatado;

        if (dados['possui_intervalo'] == 'true') {
          horarioFormatado =
              '${dados['horario_inicio']} às ${dados['horario_inicio_intervalo']} e ${dados['horario_fim_intervalo']} às ${dados['horario_fim']}';
        } else {
          horarioFormatado =
              '${dados['horario_inicio']} às ${dados['horario_fim']}';
        }

        diasConfigrados.add('$diaFormatado: $horarioFormatado');
      }
    });

    return diasConfigrados.join('\n');
  }

  /// Verifica se o horário está configurado corretamente
  bool get isHorarioValido {
    if (horarioTipo == null) return false;

    if (horarioTipo == 'sem_escala') {
      return horarioInicio.isNotEmpty && horarioFim.isNotEmpty;
    } else {
      // Para escala, verificar se pelo menos um dia está configurado
      if (escalaHorarios == null) return false;

      return escalaHorarios!.values.any((dados) =>
          dados['ativo'] == 'true' &&
          dados['horario_inicio']?.isNotEmpty == true &&
          dados['horario_fim']?.isNotEmpty == true);
    }
  }

  /// Retorna os dias da semana configurados (para escala)
  List<String> get diasConfigrados {
    if (horarioTipo != 'com_escala' || escalaHorarios == null) {
      return [];
    }

    final diasSemana = {
      'segunda': 'Segunda-feira',
      'terca': 'Terça-feira',
      'quarta': 'Quarta-feira',
      'quinta': 'Quinta-feira',
      'sexta': 'Sexta-feira',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    return escalaHorarios!.entries
        .where((entry) => entry.value['ativo'] == 'true')
        .map((entry) => diasSemana[entry.key] ?? entry.key)
        .toList();
  }

  @override
  String toString() {
    return 'ContratoEstagio{id: $id, numero: $numero, empresa: ${empresa ?? empresaId}, estudante: ${estudante ?? estudanteId}, status: $status}';
  }
}
