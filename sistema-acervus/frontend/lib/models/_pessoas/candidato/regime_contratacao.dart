class RegimeContratacao {
  final int id;
  final String descricao;

  RegimeContratacao({
    required this.id,
    required this.descricao,
  });

  factory RegimeContratacao.fromJson(Map<String, dynamic> json) {
    return RegimeContratacao(
      id: json['id_regime_contratacao'] ?? json['id_regime_contratacao'] ?? 0,
      descricao: json['descricao'] ?? '',
    );
  }

  // Para facilitar o debug
  @override
  String toString() => 'RegimeContratacao(id: $id, descricao: $descricao)';
}