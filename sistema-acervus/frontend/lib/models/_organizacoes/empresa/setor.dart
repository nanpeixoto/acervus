// lib/models/setor.dart
class Setor {
  final String? id;
  final String descricao;
  final bool ativo;
  final String criadoPor;
  final String? alteradoPor;
  final DateTime? dataCriacao;
  final DateTime? dataAlteracao;
  final String? cor; // Cor para exibição no front-end
  final int? ordem; // Ordem de exibição
  final bool isDefault; // Se é um setor padrão do sistema
  final int totalUsos;

  Setor({
    this.id,
    required this.descricao,
    this.ativo = true,
    required this.criadoPor,
    this.alteradoPor,
    this.dataCriacao,
    this.dataAlteracao,
    this.cor,
    this.ordem,
    this.isDefault = false,
    this.totalUsos = 0,
  });

  // Nome como getter para compatibilidade com outras partes do sistema
  String get nome => descricao;

  factory Setor.fromJson(Map<String, dynamic> json) {
    return Setor(
      id: json['cd_setor']?.toString(),
      descricao: json['descricao'] ?? '',
      ativo: json['ativo'] ?? true,
      criadoPor: json['criado_por']?.toString() ?? 'unknown',
      alteradoPor: json['alterado_por']?.toString(),
      dataCriacao: json['data_criacao'] != null
          ? DateTime.parse(json['data_criacao'])
          : null,
      dataAlteracao: json['data_alteracao'] != null
          ? DateTime.parse(json['data_alteracao'])
          : null,
      cor: json['cor'],
      ordem: json['ordem'],
      isDefault: json['is_default'] ?? false,
      totalUsos: json['total_usos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cd_setor': id,
      'descricao': descricao,
      'ativo': ativo,
      'criado_por': criadoPor,
      'alterado_por': alteradoPor,
      'data_criacao': dataCriacao?.toIso8601String(),
      'data_alteracao': dataAlteracao?.toIso8601String(),
      'cor': cor,
      'ordem': ordem,
      'is_default': isDefault,
      'total_usos': totalUsos,
    };
  }

  // Para compatibilidade com formulários que esperam formato interno
  Map<String, dynamic> toFormJson() {
    return {
      'id': id,
      'nome': descricao,
      'descricao': descricao,
      'ativo': ativo,
      'cor': cor,
      'ordem': ordem,
      'is_default': isDefault,
      'total_usos': totalUsos,
    };
  }

  Setor copyWith({
    String? id,
    String? descricao,
    bool? ativo,
    String? criadoPor,
    String? alteradoPor,
    DateTime? dataCriacao,
    DateTime? dataAlteracao,
    String? cor,
    int? ordem,
    bool? isDefault,
    int? totalUsos,
  }) {
    return Setor(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      criadoPor: criadoPor ?? this.criadoPor,
      alteradoPor: alteradoPor ?? this.alteradoPor,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAlteracao: dataAlteracao ?? this.dataAlteracao,
      cor: cor ?? this.cor,
      ordem: ordem ?? this.ordem,
      isDefault: isDefault ?? this.isDefault,
      totalUsos: totalUsos ?? this.totalUsos,
    );
  }

  @override
  String toString() {
    return 'Setor{id: $id, descricao: $descricao, ativo: $ativo, '
        'criadoPor: $criadoPor, alteradoPor: $alteradoPor, '
        'dataCriacao: $dataCriacao, dataAlteracao: $dataAlteracao}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Setor &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Setores padrão para o sistema de estágios
  static List<Setor> getSetoresPadrao() {
    return [
      Setor(
        id: '1',
        descricao: 'Recursos Humanos',
        cor: '#4CAF50',
        ordem: 1,
        isDefault: true,
        ativo: true,
        criadoPor: 'system',
      ),
      Setor(
        id: '2',
        descricao: 'Tecnologia da Informação',
        cor: '#2196F3',
        ordem: 2,
        isDefault: true,
        ativo: true,
        criadoPor: 'system',
      ),
      Setor(
        id: '3',
        descricao: 'Administrativo',
        cor: '#FF9800',
        ordem: 3,
        isDefault: true,
        ativo: true,
        criadoPor: 'system',
      ),
      Setor(
        id: '4',
        descricao: 'Financeiro',
        cor: '#9C27B0',
        ordem: 4,
        isDefault: true,
        ativo: true,
        criadoPor: 'system',
      ),
      Setor(
        id: '5',
        descricao: 'Marketing',
        cor: '#E91E63',
        ordem: 5,
        isDefault: true,
        ativo: true,
        criadoPor: 'system',
      ),
      Setor(
        id: '6',
        descricao: 'Jurídico',
        cor: '#795548',
        ordem: 6,
        isDefault: true,
        ativo: true,
        criadoPor: 'system',
      ),
    ];
  }

  // Método para validar se o setor pode ser excluído
  bool podeSerExcluido() {
    return !isDefault && totalUsos == 0;
  }

  // Método para obter cor com fallback
  String getCorOuPadrao() {
    return cor ?? '#607D8B';
  }

  // Método para formatar nome para exibição
  String getDisplayName() {
    return descricao.isEmpty ? 'Setor sem nome' : descricao;
  }
}