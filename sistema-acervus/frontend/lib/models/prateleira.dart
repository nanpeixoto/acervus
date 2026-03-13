class Prateleira {
  final int? id;
  final int? cdEstante;
  final String descricao;
  final String estante;

  Prateleira({
    this.id,
    this.cdEstante,
    required this.descricao,
    required this.estante,
  });

  // ===============================
  // FROM JSON
  // ===============================
  factory Prateleira.fromJson(Map<String, dynamic> json) {
    return Prateleira(
      id: json['cd_estante_prateleira'],
      cdEstante: json['cd_estante'],
      descricao: json['descricao_prateleira'] ?? '',
      estante: json['estante'] ?? '',
    );
  }

  // ===============================
  // TO JSON
  // ===============================
  Map<String, dynamic> toJson() {
    return {
      'descricao_prateleira': descricao,
    };
  }

  @override
  String toString() {
    return 'Prateleira{id: $id, descricao: $descricao}';
  }
}
