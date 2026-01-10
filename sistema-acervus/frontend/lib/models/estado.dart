class Estado {
  final int? id;
  final String nome;
  final String? sigla;
  final int paisId;

  // Campos auxiliares (JOIN)
  final String? paisNome;
  final String? paisSigla;

  Estado({
    this.id,
    required this.nome,
    this.sigla,
    required this.paisId,
    this.paisNome,
    this.paisSigla,
  });

  // =============================
  // FROM JSON
  // =============================
  factory Estado.fromJson(Map<String, dynamic> json) {
    return Estado(
      id: json['id'],
      nome: json['nome'] ?? '',
      sigla: json['sigla'],
      paisId: json['pais_id'],
      paisNome: json['pais_nome'],
      paisSigla: json['pais_sigla'],
    );
  }

  // =============================
  // TO JSON (POST / PUT)
  // =============================
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'sigla': sigla,
      'pais_id': paisId,
    };
  }

  // =============================
  // COPY WITH
  // =============================
  Estado copyWith({
    int? id,
    String? nome,
    String? sigla,
    int? paisId,
    String? paisNome,
    String? paisSigla,
  }) {
    return Estado(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      sigla: sigla ?? this.sigla,
      paisId: paisId ?? this.paisId,
      paisNome: paisNome ?? this.paisNome,
      paisSigla: paisSigla ?? this.paisSigla,
    );
  }
}
