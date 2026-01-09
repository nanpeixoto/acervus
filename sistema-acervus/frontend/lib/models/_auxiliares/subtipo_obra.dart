class SubtipoObra {
  final int? id;
  final String descricao;
  final bool ativo;

  // Relacionamento
  final int cdTipoObra;
  final String? tipoObraDescricao;

  // Auditoria
  final int? criadoPor;
  final int? alteradoPor;
  final DateTime? dataCriacao;
  final DateTime? dataAlteracao;

  SubtipoObra({
    this.id,
    required this.descricao,
    required this.cdTipoObra,
    this.tipoObraDescricao,
    this.ativo = true,
    this.criadoPor,
    this.alteradoPor,
    this.dataCriacao,
    this.dataAlteracao,
  });

  // ===============================
  // FROM JSON
  // ===============================
  factory SubtipoObra.fromJson(Map<String, dynamic> json) {
    return SubtipoObra(
      id: json['cd_subtipo_peca'] ?? json['cd_subtipo'],
      descricao: json['descricao'] ?? '',
      cdTipoObra: json['cd_tipo_peca'],
      tipoObraDescricao: json['tipo_obra_descricao'] ?? json['ds_tipo_obra'],
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
      'cd_tipo_obra': cdTipoObra,
      'ativo': ativo,
    };
  }

  // ===============================
  // COPY WITH
  // ===============================
  SubtipoObra copyWith({
    int? id,
    String? descricao,
    int? cdTipoObra,
    String? tipoObraDescricao,
    bool? ativo,
  }) {
    return SubtipoObra(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      cdTipoObra: cdTipoObra ?? this.cdTipoObra,
      tipoObraDescricao: tipoObraDescricao ?? this.tipoObraDescricao,
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
      other is SubtipoObra &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SubtipoObra{id: $id, descricao: $descricao, cdTipoObra: $cdTipoObra, ativo: $ativo}';
  }
}
