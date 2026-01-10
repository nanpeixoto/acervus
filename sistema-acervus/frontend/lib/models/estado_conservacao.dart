class EstadoConservacao {
  final int? id;
  final String descricao;
  final bool ativo;

  EstadoConservacao({
    this.id,
    required this.descricao,
    this.ativo = true,
  });

  factory EstadoConservacao.fromJson(Map<String, dynamic> json) {
    return EstadoConservacao(
      id: json['cd_estado_conservacao'],
      descricao: json['descricao'] ?? '',
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'descricao': descricao,
      'ativo': ativo,
    };
  }
}
