class Prateleira {
  final int? id;
  final int? cdEstante;
  final String descricao;
  final String estante;
  final String? sala;

  Prateleira({
    this.id,
    this.cdEstante,
    required this.descricao,
    required this.estante,
    this.sala,
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
      sala: json['sala'] ?? '',
    );
  }

  // ===============================
  // TO JSON
  // ===============================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cd_estante': cdEstante,
      'descricao_prateleira': descricao,
      'sala': sala,
    };
  }

  @override
  String toString() {
    return 'Prateleira{id: $id, descricao: $descricao, sala: $sala}';
  }
}
