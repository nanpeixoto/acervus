// TODO Implement this library.// TODO Implement this library.// lib/models/turnos.dart
class Modalidade {
  final int? id;
  final String nome;
  final String descricao;
  final bool ativo;
  final String createdBy;
  final int? updatedBy;
  final String? cor; // Cor para exibição no front-end
  final int? ordem; // Ordem de exibição
  final bool isDefault; // Se é um status padrão do sistema
  final int totalUsos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Modalidade({
    required this.createdBy,
    this.updatedBy,
    this.id,
    required this.nome,
    required this.descricao,
    this.cor,
    this.ordem,
    this.isDefault = false,
    this.ativo = true,
    this.totalUsos = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Modalidade.fromJson(Map<String, dynamic> json) {
    return Modalidade(
      id: json['cd_modalidade_ensino'],
      nome: json['descricao'] ?? '',
      descricao: json[''] ?? '',
      cor: json['cor'],
      ordem: json['ordem'],
      isDefault: json['is_default'] ?? false,
      ativo: json['ativo'] ?? true,
      totalUsos: json['total_usos'] ?? 0,
      createdAt: json['criado_em'] != null
          ? DateTime.parse(json['criado_em'])
          : null,
      updatedAt: json['alterado_em'] != null
          ? DateTime.parse(json['alterado_em'])
          : null,
      createdBy: '${json['criado_por'] ?? 'unknown'}',
      updatedBy: json['alterado_por'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'cor': cor,
      'ordem': ordem,
      'is_default': isDefault,
      'ativo': ativo,
      'total_usos': totalUsos,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Modalidade copyWith({
    int? id,
    String? nome,
    String? descricao,
    String? cor,
    int? ordem,
    bool? isDefault,
    bool? ativo,
    int? totalUsos,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? updatedBy,
  }) {
    return Modalidade(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      cor: cor ?? this.cor,
      ordem: ordem ?? this.ordem,
      isDefault: isDefault ?? this.isDefault,
      ativo: ativo ?? this.ativo,
      totalUsos: totalUsos ?? this.totalUsos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  String toString() {
    return 'Modalidade{id: $id, nome: $nome, ativo: $ativo, descricao: $descricao, createdBy: $createdBy, updatedBy: $updatedBy, createdAt: $createdAt, updatedAt: $updatedAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Modalidade &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Status padrão do sistema
  static List<Modalidade> getStatusPadrao() {
    return [
      Modalidade(
        id: 1,
        nome: 'Ativo',
        descricao: 'Curso ativo e disponível para matrícula',
        cor: '#4CAF50',
        ordem: 1,
        isDefault: true,
        ativo: true,
        createdBy: 'system',
      ),
      Modalidade(
        id: 2,
        nome: 'Inativo',
        descricao: 'Curso temporariamente inativo',
        cor: '#FF9800',
        ordem: 2,
        isDefault: true,
        ativo: true,
        createdBy: 'system',
      ),
      Modalidade(
        id: 3,
        nome: 'Suspenso',
        descricao: 'Curso suspenso por determinação administrativa',
        cor: '#F44336',
        ordem: 3,
        isDefault: true,
        ativo: true,
        createdBy: 'system',
      ),
      Modalidade(
        id: 4,
        nome: 'Em Análise',
        descricao: 'Curso em processo de análise/aprovação',
        cor: '#2196F3',
        ordem: 4,
        isDefault: true,
        ativo: true,
        createdBy: 'system',
      ),
      Modalidade(
        id: 5,
        nome: 'Encerrado',
        descricao: 'Curso encerrado definitivamente',
        cor: '#9E9E9E',
        ordem: 5,
        isDefault: true,
        ativo: true,
        createdBy: 'system',
      ),
    ];
  }
}