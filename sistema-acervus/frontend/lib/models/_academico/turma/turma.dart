// lib/models/turma.dart

class Turma {
  final int? id;
  final int? numeroTurma;
  final int cursoAprendizagemId;
  final String? cursoAprendizagemNome;
  final bool ativo;
  final String createdBy;
  final int? updatedBy;
  final String? cor; // Cor para exibição no front-end
  final int? ordem; // Ordem de exibição
  final bool isDefault; // Se é um status padrão do sistema
  final int totalUsos;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Turma({
    this.id,
    required this.numeroTurma,
    required this.cursoAprendizagemId,
    this.cursoAprendizagemNome,
    this.ativo = true,
    required this.createdBy,
    this.updatedBy,
    this.cor,
    this.ordem,
    this.isDefault = false,
    this.totalUsos = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Turma.fromJson(Map<String, dynamic> json) {
    return Turma(
      id: json['cd_turma'],
      numeroTurma: json['numero'] ?? '',
      cursoAprendizagemId: json['cd_curso'] ?? 0,
      cursoAprendizagemNome: json['curso'] ?? 
                            json['nome_curso_aprendizagem'] ?? 
                            json['curso_nome'] ?? '',
      ativo: json['ativo'] ?? true,
      cor: json['cor'],
      ordem: json['ordem'],
      isDefault: json['is_default'] ?? false,
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
      if (id != null) 'cd_turma': id,
      'numero': numeroTurma,
      'cd_curso': cursoAprendizagemId,
      'ativo': ativo,
      if (cor != null) 'cor': cor,
      if (ordem != null) 'ordem': ordem,
      'is_default': isDefault,
      'total_usos': totalUsos,
      'criado_por': createdBy,
      if (updatedBy != null) 'alterado_por': updatedBy,
      if (createdAt != null) 'criado_em': createdAt!.toIso8601String(),
      if (updatedAt != null) 'alterado_em': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'numero': numeroTurma,
      'cd_curso': cursoAprendizagemId,
      'ativo': ativo,
      if (cor != null) 'cor': cor,
      if (ordem != null) 'ordem': ordem,
      'is_default': isDefault,
      'criado_por': createdBy,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'numero': numeroTurma,
      'cd_curso': cursoAprendizagemId,
      'ativo': ativo,
      if (cor != null) 'cor': cor,
      if (ordem != null) 'ordem': ordem,
      'is_default': isDefault,
      if (updatedBy != null) 'alterado_por': updatedBy,
    };
  }

  Turma copyWith({
    int? id,
    int? numeroTurma,
    int? cursoAprendizagemId,
    String? cursoAprendizagemNome,
    bool? ativo,
    String? createdBy,
    int? updatedBy,
    String? cor,
    int? ordem,
    bool? isDefault,
    int? totalUsos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Turma(
      id: id ?? this.id,
      numeroTurma: numeroTurma ?? this.numeroTurma,
      cursoAprendizagemId: cursoAprendizagemId ?? this.cursoAprendizagemId,
      cursoAprendizagemNome: cursoAprendizagemNome ?? this.cursoAprendizagemNome,
      ativo: ativo ?? this.ativo,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      cor: cor ?? this.cor,
      ordem: ordem ?? this.ordem,
      isDefault: isDefault ?? this.isDefault,
      totalUsos: totalUsos ?? this.totalUsos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Turma{id: $id, numeroTurma: $numeroTurma, cursoAprendizagemId: $cursoAprendizagemId, cursoAprendizagemNome: $cursoAprendizagemNome, ativo: $ativo}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Turma &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  


  
  String get displayName => 'Turma $numeroTurma - ${cursoAprendizagemNome ?? 'Curso não informado'}';
  
  bool get isAtiva => ativo;
  
  // Validação do número da turma
  static String? validarNumeroTurma(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Número da turma é obrigatório';
    }
    
    final numero = valor.trim();
    
    if (numero.length > 10) {
      return 'Número da turma deve ter no máximo 10 caracteres';
    }
    
    // Permitir apenas números e letras
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(numero)) {
      return 'Número da turma deve conter apenas letras e números';
    }
    
    return null;
  }
}

// Classe auxiliar para dropdown de cursos
class CursoAprendizagemOption {
  final int id;
  final String nome;
  final String cbo;
  final bool ativo;

  CursoAprendizagemOption({
    required this.id,
    required this.nome,
    required this.cbo,
    this.ativo = true,
  });

  factory CursoAprendizagemOption.fromJson(Map<String, dynamic> json) {
    return CursoAprendizagemOption(
      id: json['cd_curso'] ?? json['id'],
      nome: json['nome_curso_aprendizagem'] ?? json['nome_curso'] ?? json['nome'],
      cbo: json['cbo'] ?? '',
      ativo: json['ativo'] ?? true,
    );
  }

  @override
  String toString() => nome;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CursoAprendizagemOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}