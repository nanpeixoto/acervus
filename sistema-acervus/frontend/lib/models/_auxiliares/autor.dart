class Autor {
  final int? id;
  final String nome;
  final DateTime? dataNascimento;
  final DateTime? dataFalecimento;
  final String? observacao;
  final bool ativo;

  final int? criadoPor;
  final int? alteradoPor;
  final DateTime? dataCriacao;
  final DateTime? dataAlteracao;

  Autor({
    this.id,
    required this.nome,
    this.dataNascimento,
    this.dataFalecimento,
    this.observacao,
    this.ativo = true,
    this.criadoPor,
    this.alteradoPor,
    this.dataCriacao,
    this.dataAlteracao,
  });

  factory Autor.fromJson(Map<String, dynamic> json) {
    return Autor(
      id: json['cd_autor'],
      nome: json['nome'] ?? '',
      dataNascimento: json['data_nascimento'] != null
          ? DateTime.parse(json['data_nascimento'])
          : null,
      dataFalecimento: json['data_falecimento'] != null
          ? DateTime.parse(json['data_falecimento'])
          : null,
      observacao: json['observacao'],
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

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'data_nascimento': dataNascimento?.toIso8601String(),
      'data_falecimento': dataFalecimento?.toIso8601String(),
      'observacao': observacao,
      'ativo': ativo,
    };
  }

  Autor copyWith({
    int? id,
    String? nome,
    DateTime? dataNascimento,
    DateTime? dataFalecimento,
    String? observacao,
    bool? ativo,
  }) {
    return Autor(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      dataFalecimento: dataFalecimento ?? this.dataFalecimento,
      observacao: observacao ?? this.observacao,
      ativo: ativo ?? this.ativo,
      criadoPor: criadoPor,
      alteradoPor: alteradoPor,
      dataCriacao: dataCriacao,
      dataAlteracao: dataAlteracao,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Autor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
