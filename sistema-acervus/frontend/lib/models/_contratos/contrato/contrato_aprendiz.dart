// lib/models/contrato_aprendiz.dart
class ContratoAprendiz {
  final String? id;
  final String? numero;
  final String? jovemAprendiz;
  final String empresaId;
  final dynamic empresa;
  final String instituicaoEnsinoId;
  final dynamic instituicaoEnsino;
  final String setor;
  final String supervisor;
  final int? modeloContratoId;
  final String status;
  final String descricaoStatus;
  final double bolsa;
  final String modalidadeTransporte;
  final int? cargaHoraria;
  final int? totalHorasSemana;
  final String horarioTipo;
  final String horarioInicio;
  final String horarioFim;
  final bool? possuiIntervalo;
  final String horarioInicioIntervalo;
  final String horarioFimIntervalo;

  /// Dados da escala de horários (JSON) - para horário com escala
  final Map<String, dynamic>? escalaHorarios;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final DateTime? dataDesligamento;
  final List<Map<String, dynamic>>? aditivos;

  ContratoAprendiz({
    this.id,
    this.numero,
    this.jovemAprendiz,
    required this.empresaId,
    this.empresa,
    this.modeloContratoId,
    required this.instituicaoEnsinoId,
    this.instituicaoEnsino,
    this.setor = '',
    this.supervisor = '',
    this.status = '',
    this.descricaoStatus = '',
    this.bolsa = 0.0,
    this.modalidadeTransporte = '',
    this.cargaHoraria,
    this.totalHorasSemana,
    this.horarioTipo = '',
    this.horarioInicio = '',
    this.horarioFim = '',
    this.possuiIntervalo,
    this.horarioInicioIntervalo = '',
    this.horarioFimIntervalo = '',
    this.escalaHorarios,
    this.dataInicio,
    this.dataFim,
    this.dataDesligamento,
    this.aditivos,
  });

  factory ContratoAprendiz.fromJson(Map<String, dynamic> json) {
    return ContratoAprendiz(
      id: json['id']?.toString() ?? json['cd_contrato']?.toString(),
      numero: json['numero']?.toString() ?? json['numero_contrato']?.toString(),
      jovemAprendiz: json['estudante']?.toString() ?? '',
      // IDs - manter como estavam para compatibilidade
      empresaId: json['empresa_id']?.toString() ??
          json['cd_empresa']?.toString() ??
          '',
      empresa: _extrairNomeEmpresa(json), // Nome da empresa vem diretamente
      modeloContratoId: _parseInt(json['cd_template_modelo'] ?? ''),

      instituicaoEnsinoId: json['instituicao_ensino_id']?.toString() ??
          json['cd_instituicao_ensino']?.toString() ??
          '',
      instituicaoEnsino:
          json['instituicao_ensino'], // Nome da instituição vem diretamente
      setor: json['setor']?.toString() ?? '',
      supervisor: json['supervisor']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      descricaoStatus: json['descricao_status']?.toString() ??
          json['status_descricao']?.toString() ??
          _getDescricaoStatus(json['status']?.toString()),
      bolsa: double.tryParse(json['bolsa']?.toString() ?? '0') ?? 0.0,
      modalidadeTransporte: json['modalidade_transporte']?.toString() ??
          json['modalidadeTransporte']?.toString() ??
          '',
      cargaHoraria: _parseInt(json['carga_horaria'] ?? json['cargaHoraria']),
      totalHorasSemana:
          _parseInt(json['total_horas_semana'] ?? json['totalHorasSemana']),
      horarioTipo: json['horario_tipo']?.toString() ??
          json['horarioTipo']?.toString() ??
          '',
      horarioInicio: json['horario_inicio']?.toString() ??
          json['horarioInicio']?.toString() ??
          '',
      horarioFim: json['horario_fim']?.toString() ??
          json['horarioFim']?.toString() ??
          '',
      possuiIntervalo: json['possui_intervalo'] ?? json['possuiIntervalo'],
      horarioInicioIntervalo: json['horario_inicio_intervalo']?.toString() ??
          json['horarioInicioIntervalo']?.toString() ??
          '',
      horarioFimIntervalo: json['horario_fim_intervalo']?.toString() ??
          json['horarioFimIntervalo']?.toString() ??
          '',
      dataInicio: _parseDate(json['data_inicio'] ?? json['dataInicio']),
      dataFim: _parseDate(json['data_fim'] ?? json['dataFim']),
      dataDesligamento:
          _parseDate(json['data_desligamento'] ?? json['dataDesligamento']),
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
      'id': id,
      'numero': numero,
      'estudante': jovemAprendiz,
      'empresa': empresa,
      'instituicao_ensino': instituicaoEnsino,
      'modeloContratoId': modeloContratoId,
      'setor': setor,
      'supervisor': supervisor,
      'status': status,
      'descricao_status': descricaoStatus,
      'bolsa': bolsa,
      'modalidade_transporte': modalidadeTransporte,
      'carga_horaria': cargaHoraria,
      'total_horas_semana': totalHorasSemana,
      'horario_tipo': horarioTipo,
      'horario_inicio': horarioInicio,
      'horario_fim': horarioFim,
      'possui_intervalo': possuiIntervalo,
      'horario_inicio_intervalo': horarioInicioIntervalo,
      'horario_fim_intervalo': horarioFimIntervalo,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'data_desligamento': dataDesligamento?.toIso8601String(),
      'aditivos': aditivos,
    };
  }

  // Métodos auxiliares para parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
    }
    return 0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static String _getDescricaoStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'A':
        return 'Ativo';
      case 'C':
        return 'Cancelado';
      case 'D':
        return 'Desligado';
      case 'R':
        return 'Revisão';
      case 'G':
        return 'Gerado';
      default:
        return status ?? '';
    }
  }

  ContratoAprendiz copyWith({
    String? id,
    String? numero,
    String? jovemAprendiz,
    String? empresa,
    String? instituicaoEnsino,
    String? setor,
    String? supervisor,
    String? status,
    String? descricaoStatus,
    double? bolsa,
    String? modalidadeTransporte,
    int? cargaHoraria,
    int? totalHorasSemana,
    String? horarioTipo,
    String? horarioInicio,
    String? horarioFim,
    bool? possuiIntervalo,
    String? horarioInicioIntervalo,
    String? horarioFimIntervalo,
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataDesligamento,
    List<Map<String, dynamic>>? aditivos,
  }) {
    return ContratoAprendiz(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      jovemAprendiz: jovemAprendiz ?? this.jovemAprendiz,
      empresaId: empresaId ?? empresaId,
      modeloContratoId: modeloContratoId ?? modeloContratoId,
      empresa: empresa ?? this.empresa,
      instituicaoEnsinoId: instituicaoEnsinoId ?? instituicaoEnsinoId,
      instituicaoEnsino: instituicaoEnsino ?? this.instituicaoEnsino,
      setor: setor ?? this.setor,
      supervisor: supervisor ?? this.supervisor,
      status: status ?? this.status,
      descricaoStatus: descricaoStatus ?? this.descricaoStatus,
      bolsa: bolsa ?? this.bolsa,
      modalidadeTransporte: modalidadeTransporte ?? this.modalidadeTransporte,
      cargaHoraria: cargaHoraria ?? this.cargaHoraria,
      totalHorasSemana: totalHorasSemana ?? this.totalHorasSemana,
      horarioTipo: horarioTipo ?? this.horarioTipo,
      horarioInicio: horarioInicio ?? this.horarioInicio,
      horarioFim: horarioFim ?? this.horarioFim,
      possuiIntervalo: possuiIntervalo ?? this.possuiIntervalo,
      horarioInicioIntervalo:
          horarioInicioIntervalo ?? this.horarioInicioIntervalo,
      horarioFimIntervalo: horarioFimIntervalo ?? this.horarioFimIntervalo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      dataDesligamento: dataDesligamento ?? this.dataDesligamento,
      aditivos: aditivos ?? this.aditivos,
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
    return 'ContratoAprendiz(id: $id, numero: $numero, jovemAprendiz: $jovemAprendiz, empresa: $empresa, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContratoAprendiz && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
