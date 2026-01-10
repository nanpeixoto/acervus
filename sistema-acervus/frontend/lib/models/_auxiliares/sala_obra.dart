class Sala {
  final int? id;
  final String descricao;
  final String? observacao;
  final bool ativo;

  // Auditoria (opcional – já deixei pronto)
  final int? criadoPor;
  final int? alteradoPor;
  final DateTime? dataCriacao;
  final DateTime? dataAlteracao;

  Sala({
    this.id,
    required this.descricao,
    this.observacao,
    this.ativo = true,
    this.criadoPor,
    this.alteradoPor,
    this.dataCriacao,
    this.dataAlteracao,
  });

  // ===============================
  // FROM JSON
  // ===============================
  factory Sala.fromJson(Map<String, dynamic> json) {
    return Sala(
      id: json['cd_sala'],
      descricao: json['ds_sala'] ?? json['descricao'] ?? '',
      observacao: json['observacao'],
      ativo: json['ativo'] ??
          (json['sts_sala'] != null ? json['sts_sala'] == 'A' : true),
      criadoPor: json['criado_por'],
      alteradoPor: json['alterado_por'],
      dataCriacao: json['data_criacao'] != null
          ? DateTime.parse(json['data_criacao'])
          : null,
      dataAlteracao: json['data_alteracao'] != null
          ? DateTime.parse(json['data_alteracao'])
          : null,
    );
  }

  // ===============================
  // TO JSON (POST / PUT)
  // ===============================
  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'observacao': observacao,
      'ativo': ativo,
    };
  }

  // ===============================
  // COPY WITH
  // ===============================
  Sala copyWith({
    int? id,
    String? descricao,
    String? observacao,
    bool? ativo,
  }) {
    return Sala(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      observacao: observacao ?? this.observacao,
      ativo: ativo ?? this.ativo,
      criadoPor: criadoPor,
      alteradoPor: alteradoPor,
      dataCriacao: dataCriacao,
      dataAlteracao: dataAlteracao,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sala && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Sala{id: $id, descricao: $descricao, ativo: $ativo}';
  }
}
