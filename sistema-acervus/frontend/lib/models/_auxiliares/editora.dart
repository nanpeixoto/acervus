class Editora {
  final int? id;
  final String descricao;
  final bool ativo;

  final int? paisId;
  final int? estadoId;
  final int? cidadeId;

  // Campos auxiliares (JOIN)
  final String? paisNome;
  final String? estadoNome;
  final String? estadoSigla;
  final String? cidadeNome;

  Editora({
    this.id,
    required this.descricao,
    required this.ativo,
    this.paisId,
    this.estadoId,
    this.cidadeId,
    this.paisNome,
    this.estadoNome,
    this.estadoSigla,
    this.cidadeNome,
  });

  // =============================
  // FROM JSON
  // =============================
  factory Editora.fromJson(Map<String, dynamic> json) {
    return Editora(
      id: json['cd_editora'] ?? json['id'],
      descricao: json['descricao'] ?? json['ds_editora'] ?? '',
      ativo: json['ativo'] ??
          json['sts_editora'] == 'A' || json['sts_editora'] == true,
      paisId: json['pais_id'],
      estadoId: json['estado_id'],
      cidadeId: json['cidade_id'],
      paisNome: json['pais_nome'],
      estadoNome: json['estado_nome'],
      estadoSigla: json['estado_sigla'],
      cidadeNome: json['cidade_nome'],
    );
  }

  // =============================
  // TO JSON (POST / PUT)
  // =============================
  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'ativo': ativo,
      'pais_id': paisId,
      'estado_id': estadoId,
      'cidade_id': cidadeId,
    };
  }

  // =============================
  // COPY WITH
  // =============================
  Editora copyWith({
    int? id,
    String? descricao,
    bool? ativo,
    int? paisId,
    int? estadoId,
    int? cidadeId,
    String? paisNome,
    String? estadoNome,
    String? estadoSigla,
    String? cidadeNome,
  }) {
    return Editora(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      paisId: paisId ?? this.paisId,
      estadoId: estadoId ?? this.estadoId,
      cidadeId: cidadeId ?? this.cidadeId,
      paisNome: paisNome ?? this.paisNome,
      estadoNome: estadoNome ?? this.estadoNome,
      estadoSigla: estadoSigla ?? this.estadoSigla,
      cidadeNome: cidadeNome ?? this.cidadeNome,
    );
  }
}
