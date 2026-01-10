// lib/models/cidade.dart
class Cidade {
  final int? id;
  final String nome;
  final String uf;
  final String regiao;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Cidade({
    this.id,
    required this.nome,
    required this.uf,
    required this.regiao,
    this.createdAt,
    this.updatedAt,
  });

  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      id: json['id'] as int?,
      nome: json['nome'] ?? '',
      uf: json['uf'] ?? '',
      regiao: json['regiao'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'uf': uf,
      'regiao': regiao,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Cidade copyWith({
    int? id,
    String? nome,
    String? uf,
    String? regiao,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cidade(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      uf: uf ?? this.uf,
      regiao: regiao ?? this.regiao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Cidade(id: $id, nome: $nome, uf: $uf, regiao: $regiao)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cidade &&
        other.id == id &&
        other.nome == nome &&
        other.uf == uf &&
        other.regiao == regiao;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nome.hashCode ^ uf.hashCode ^ regiao.hashCode;
  }
}
