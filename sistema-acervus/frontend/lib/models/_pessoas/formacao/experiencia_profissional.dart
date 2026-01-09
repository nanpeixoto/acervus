class ExperienciaProfissional {
  final int? id;
  final int candidatoId;
  final String empresa;

  //final String cargo;
  final String descricaoAtividades;
  final DateTime dataInicio;
  final DateTime? dataFim;

  ExperienciaProfissional({
    this.id,
    required this.candidatoId,
    required this.empresa,
    //required this.cargo,
    required this.descricaoAtividades,
    required this.dataInicio,
    this.dataFim,
  });

  factory ExperienciaProfissional.fromJson(Map<String, dynamic> json) {
    return ExperienciaProfissional(
      id: json['cd_experiencia_candidato'],
      candidatoId: json['cd_candidato'],
      empresa: json['empresa'],
      //cargo: json['cargo'],
      descricaoAtividades: json['descricao'],
      dataInicio: DateTime.parse(json['data_inicio']),
      dataFim:
          json['data_fim'] != null ? DateTime.parse(json['data_fim']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'candidatoId': candidatoId,
      'empresa': empresa,
      //'cargo': cargo,
      'descricao': descricaoAtividades,
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim?.toIso8601String(),
    };
  }

  ExperienciaProfissional copyWith({
    int? id,
    int? candidatoId,
    String? empresa,
    String? descricao,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) {
    return ExperienciaProfissional(
      id: id ?? this.id,
      candidatoId: candidatoId ?? this.candidatoId,
      empresa: empresa ?? this.empresa,
      descricaoAtividades: descricao ?? descricaoAtividades,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
    );
  }

  @override
  String toString() {
    return 'ExperienciaProfissional{id: $id, candidatoId: $candidatoId, empresa: $empresa, descricaoAtividades: $descricaoAtividades, dataInicio: $dataInicio, dataFim: $dataFim}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExperienciaProfissional &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
