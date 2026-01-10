class Pais {
  final int? id;
  final String nome;
  final String? sigla;

  Pais({
    this.id,
    required this.nome,
    this.sigla,
  });

  // =============================
  // FROM JSON
  // =============================
  factory Pais.fromJson(Map<String, dynamic> json) {
    return Pais(
      id: json['id'],
      nome: json['nome'] ?? '',
      sigla: json['sigla'],
    );
  }

  // =============================
  // TO JSON (POST / PUT)
  // =============================
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'sigla': sigla,
    };
  }

  // =============================
  // COPY WITH
  // =============================
  Pais copyWith({
    int? id,
    String? nome,
    String? sigla,
  }) {
    return Pais(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      sigla: sigla ?? this.sigla,
    );
  }
}
