class Assunto {
  final int? id;
  final String sigla;
  final String descricao;
  final bool ativo;

  final int? criadoPor;
  final int? alteradoPor;
  final DateTime? dataCriacao;
  final DateTime? dataAlteracao;

  Assunto({
    this.id,
    required this.sigla,
    required this.descricao,
    this.ativo = true,
    this.criadoPor,
    this.alteradoPor,
    this.dataCriacao,
    this.dataAlteracao,
  });

  // ===============================
  // FROM JSON
  // ===============================
  factory Assunto.fromJson(Map<String, dynamic> json) {
    return Assunto(
      id: json['cd_assunto'],
      sigla: json['sigla'] ?? '',
      descricao: json['descricao'] ?? '',
      ativo: json['ativo'] ?? true,
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
      'sigla': sigla,
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  // ===============================
  // COPY WITH
  // ===============================
  Assunto copyWith({
    int? id,
    String? sigla,
    String? descricao,
    bool? ativo,
  }) {
    return Assunto(
      id: id ?? this.id,
      sigla: sigla ?? this.sigla,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      criadoPor: criadoPor,
      alteradoPor: alteradoPor,
      dataCriacao: dataCriacao,
      dataAlteracao: dataAlteracao,
    );
  }

  // ===============================
  // EQUALS / HASH
  // ===============================
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Assunto && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Assunto{id: $id, sigla: $sigla, descricao: $descricao, ativo: $ativo}';
  }
}
