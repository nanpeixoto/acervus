// lib/models/modelo_contrato.dart
class ModeloContrato {
  final int? id;
  final String nome;
  final int idTipoModelo;
  final bool modelo;
  final bool ativo;
  final String conteudoHtml;
  final String? descricao;
  final List<String>? tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Informações do tipo de modelo (quando carregado com join)
  final String? tipoModeloNome;
  final String? tipoModeloDescricao;

  ModeloContrato({
    this.id,
    required this.nome,
    required this.idTipoModelo,
    this.modelo = true,
    this.ativo = true,
    required this.conteudoHtml,
    this.descricao,
    this.tags,
    this.createdAt,
    this.updatedAt,
    this.tipoModeloNome,
    this.tipoModeloDescricao,
  });

  factory ModeloContrato.fromJson(Map<String, dynamic> json) {
    return ModeloContrato(
      id: json['id_modelo'] as int?,
      nome: json['nome'] as String? ?? '',
      idTipoModelo: json['id_tipo_modelo'] as int? ?? json['idTipoModelo'] as int? ?? 0,
      modelo: json['modelo'] as bool? ?? true,
      ativo: json['ativo'] as bool? ?? true,
      conteudoHtml: json['conteudo_html'] as String? ?? json['conteudo_html'] as String? ?? '',
      descricao: json['descricao'] as String?,
      tags: json['tags'] != null 
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : null,
      createdAt: json['created_at'] != null || json['createdAt'] != null
          ? DateTime.parse(json['created_at'] ?? json['createdAt'])
          : null,
      updatedAt: json['updated_at'] != null || json['updatedAt'] != null
          ? DateTime.parse(json['updated_at'] ?? json['updatedAt'])
          : null,
      tipoModeloNome: json['tipo_modelo_nome'] as String? ?? 
                      json['tipoModelo']?['nome'] as String?,
      tipoModeloDescricao: json['tipo_modelo_descricao'] as String? ?? 
                          json['tipoModelo']?['descricao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'id_tipo_modelo': idTipoModelo,
      'modelo': modelo,
      'ativo': ativo,
      'conteudo_html': conteudoHtml,
      'descricao': descricao,
      'tags': tags,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nome': nome,
      'id_tipo_modelo': idTipoModelo,
      'modelo': modelo,
      'ativo': ativo,
      'conteudo_html': conteudoHtml,
      if (descricao != null) 'descricao': descricao,
      if (tags != null) 'tags': tags,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'nome': nome,
      'id_tipo_modelo': idTipoModelo,
      'modelo': modelo,
      'ativo': ativo,
      'conteudo_html': conteudoHtml,
      if (descricao != null) 'descricao': descricao,
      if (tags != null) 'tags': tags,
    };
  }

  ModeloContrato copyWith({
    int? id,
    String? nome,
    int? idTipoModelo,
    bool? modelo,
    bool? ativo,
    String? conteudoHtml,
    String? descricao,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? tipoModeloNome,
    String? tipoModeloDescricao,
  }) {
    return ModeloContrato(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      idTipoModelo: idTipoModelo ?? this.idTipoModelo,
      modelo: modelo ?? this.modelo,
      ativo: ativo ?? this.ativo,
      conteudoHtml: conteudoHtml ?? this.conteudoHtml,
      descricao: descricao ?? this.descricao,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tipoModeloNome: tipoModeloNome ?? this.tipoModeloNome,
      tipoModeloDescricao: tipoModeloDescricao ?? this.tipoModeloDescricao,
    );
  }

  @override
  String toString() {
    return 'ModeloContrato{id: $id, nome: $nome, idTipoModelo: $idTipoModelo, ativo: $ativo}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModeloContrato && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}