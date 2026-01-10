class Materiais {
  final int? id;
  final String descricao;
  final bool ativo;

  final int? criadoPor;
  final int? alteradoPor;
  final DateTime? dataCriacao;
  final DateTime? dataAlteracao;

  Materiais({
    this.id,
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
  factory Materiais.fromJson(Map<String, dynamic> json) {
    return Materiais(
      id: json['cd_material'] ?? json['cd_Materiais'],
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
      'descricao': descricao,
      'ativo': ativo,
    };
  }

  // ===============================
  // COPY WITH
  // ===============================
  Materiais copyWith({
    int? id,
    String? descricao,
    bool? ativo,
  }) {
    return Materiais(
      id: id ?? this.id,
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
      other is Materiais && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'MateriaisItem{id: $id, descricao: $descricao, ativo: $ativo}';
  }
}
