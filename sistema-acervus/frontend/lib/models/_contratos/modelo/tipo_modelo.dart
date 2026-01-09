// lib/models/tipo_modelo.dart
class TipoModelo {
  final int? id;
  final String nome;
  final String descricao;
  final bool ativo;
  final bool complementar;
  final String createdBy;
  //final String categoria;
  final int? updatedBy;
  //final String tipo;
  //final String formato;
  //final String conteudo;
  //final List<String> tags;

  final int totalUsos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? tipoModelo; // Novo campo

  TipoModelo({
    required this.createdBy,
    this.updatedBy,
    this.id,
    required this.nome,
    required this.descricao,
    //this.categoria,
    //this.tipo,
    //this.formato,
    //this.conteudo,
    //this.tags,
    this.ativo = true,
    this.totalUsos = 0,
    this.createdAt,
    this.updatedAt,
    this.tipoModelo,
    this.complementar = false, // Novo campo
  });

  factory TipoModelo.fromJson(Map<String, dynamic> json) {
    return TipoModelo(
      id: json['id_tipo_modelo'],
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      ativo: json['ativo'] ?? true,
      complementar: json['complementar'] ?? false,
      createdAt:
          json['criado_em'] != null ? DateTime.parse(json['criado_em']) : null,
      updatedAt: json['alterado_em'] != null
          ? DateTime.parse(json['alterado_em'])
          : null,
      createdBy: '${json['criado_por'] ?? 'unknown'}',
      updatedBy: json['alterado_por'],
      tipoModelo: json['tipo_modelo'],
      // totalUsos: json['totalUsos'] ?? 0, // só habilite se backend mandar
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tipo_modelo': id,
      'nome': nome,
      'descricao': descricao,
      'ativo': ativo,
      'complementar': complementar,
      'total_usos': totalUsos,
      'criado_em': createdAt?.toIso8601String(),
      'alterado_em': updatedAt?.toIso8601String(),
      'tipo_modelo': tipoModelo,
      'criado_por': createdBy,
      'alterado_por': updatedBy,
    };
  }

  TipoModelo copyWith({
    int? id,
    String? nome,
    String? descricao,
    bool? ativo,
    bool? complementar,
    int? totalUsos,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tipoModelo,
    String? createdBy,
    int? updatedBy,
  }) {
    return TipoModelo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      complementar: complementar ?? this.complementar,
      totalUsos: totalUsos ?? this.totalUsos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      tipoModelo: tipoModelo ?? this.tipoModelo,
    );
  }

  @override
  String toString() {
    return 'TipoModelo{id: $id, nome: $nome, ativo: $ativo, complementar: $complementar}, descricao: $descricao, createdBy: $createdBy, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipoModelo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
