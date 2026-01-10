class Idioma {
  final int? id;
  final String nome;
  final String descricao;
  final bool ativo;
  final bool isDefault;
  final int? ordem;
  final String? cor;

  Idioma({
    this.id,
    required this.nome,
    required this.descricao,
    required this.ativo,
    required this.isDefault,
    this.ordem,
    this.cor,
  });

  /// =========================
  /// FROM JSON
  /// =========================
  factory Idioma.fromJson(Map<String, dynamic> json) {
    return Idioma(
      id: json['id'] ?? json['cd_idioma'] ?? json['cd_status'] ?? json['cd'],
      nome: json['nome'] ?? json['descricao'] ?? json['ds_idioma'] ?? '',
      descricao: json['descricao'] ?? json['ds_idioma'] ?? '',
      ativo: json['ativo'] == true ||
          json['ativo'] == 'true' ||
          json['sts_idioma'] == 'A',
      isDefault: json['is_default'] == true || json['isDefault'] == true,
      ordem: json['ordem'],
      cor: json['cor'],
    );
  }

  /// =========================
  /// TO JSON
  /// =========================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'is_default': isDefault,
      'ordem': ordem,
      'cor': cor,
    };
  }
}
