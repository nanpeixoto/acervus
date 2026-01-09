// lib/models/cbo.dart
class CBO {
  final int? id;
  final String codigo;
  final String descricao;
  final bool ativo;
  final DateTime? dataCriacao;
  final DateTime? dataAlteracao;
  final String? criadoPor;
  final String? alteradoPor;

  CBO({
    this.id,
    required this.codigo,
    required this.descricao,
    this.ativo = true,
    this.dataCriacao,
    this.dataAlteracao,
    this.criadoPor,
    this.alteradoPor,
  });

  // Para compatibilidade com formulários que esperam o nome
  String get nome => descricao;

  factory CBO.fromJson(Map<String, dynamic> json) {
    return CBO(
      id: json['cd_cbo'] is String
          ? int.tryParse(json['cd_cbo'])
          : json['cd_cbo'],
      codigo: json['codigo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      ativo: _parseBool(json['ativo']), // Corrigir: remover o asterisco
      dataCriacao: json['data_criacao'] != null // Corrigir: remover o asterisco
          ? DateTime.tryParse(json['data_criacao'].toString())
          : null,
      dataAlteracao: json['data_alteracao'] != null
          ? DateTime.tryParse(json['data_alteracao'].toString())
          : null,
      criadoPor: json['criado_por']?.toString(),
      alteradoPor: json['alterado_por']?.toString(),
    );
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1' || value == 'ativo';
    }
    if (value is int) return value == 1;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'cd_cbo': id,
      'codigo': codigo,
      'descricao': descricao,
      'ativo': ativo,
      'data_criacao': dataCriacao?.toIso8601String(),
      'data_alteracao': dataAlteracao?.toIso8601String(),
      'criado_por': criadoPor,
      'alterado_por': alteradoPor,
    };
  }

  CBO copyWith({
    int? id,
    String? codigo,
    String? descricao,
    bool? ativo,
    DateTime? dataCriacao,
    DateTime? dataAlteracao,
    String? criadoPor,
    String? alteradoPor,
  }) {
    return CBO(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAlteracao: dataAlteracao ?? this.dataAlteracao,
      criadoPor: criadoPor ?? this.criadoPor,
      alteradoPor: alteradoPor ?? this.alteradoPor,
    );
  }

  @override
  String toString() {
    return 'CBO{id: $id, codigo: $codigo, descricao: $descricao, ativo: $ativo}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CBO &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          codigo == other.codigo;

  @override
  int get hashCode => id.hashCode ^ codigo.hashCode;
}
