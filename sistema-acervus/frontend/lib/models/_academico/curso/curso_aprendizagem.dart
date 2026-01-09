// lib/models/curso_aprendizagem.dart

class CursoAprendizagem {
  final int? id;
  final String nomeCurso;
  final String descricaoCBO;
  final int? cbo;
  final DateTime validade;
  final String nomeCursoAprendizagem;
  final List<ModuloCurso> modulos;
  final bool ativo;

  CursoAprendizagem({
    this.id,
    required this.nomeCurso,
    required this.descricaoCBO,
    required this.cbo,
    required this.validade,
    required this.nomeCursoAprendizagem,
    this.modulos = const [],
    this.ativo = true,
  });

  //criar metodo que recebe um dynamic e retornar em um int?
  static int? _asInt(dynamic value) {
    try {
      if (value is int) {
        return value;
      } else if (value is String) {
        return int.tryParse(value);
      }
    } catch (e) {
      print('Erro ao converter para int: $e');
    }
    return null;
  }

  factory CursoAprendizagem.fromJson(Map<String, dynamic> json) {
    try {
      var curso = CursoAprendizagem(
        id: _asInt(json['cd_curso']),
        nomeCurso: json['nome'] ?? '',
        descricaoCBO: json['cbo_descricao'] ?? '',
        cbo: _asInt(json['cd_cbo']),
        validade: json['validade'] != null
            ? DateTime.parse(json['validade'])
            : DateTime.now(),
        nomeCursoAprendizagem: json['nome_aprendizagem'] ?? '',
        modulos: json['modulos'] != null
            ? (json['modulos'] as List)
                .map((moduloJson) => ModuloCurso.fromJson(moduloJson))
                .toList()
            : [],
        ativo: json['ativo'] ?? true,
      );

      //imprimir objeto curso
      print('CursoAprendizagem: $curso');
      return curso;
    } catch (e) {
      print('ERRRRRRRRRRRRRRRRRRRRRRRRROO: $e');
      return CursoAprendizagem(
        id: null,
        nomeCurso: '',
        descricaoCBO: '',
        cbo: null,
        validade: DateTime.now(),
        nomeCursoAprendizagem: '',
        modulos: [],
        ativo: true,
      );
      print('ERRRRRRRRRRRRRRRRRRRRRO');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'cd_curso': id,
      'nome': nomeCurso,
      'cbo_descricao': descricaoCBO,
      'cd_cbo': cbo,
      'validade': validade.toIso8601String().split('T')[0], // Apenas a data
      'nome_aprendizagem': nomeCursoAprendizagem,
      'modulos': modulos.map((modulo) => modulo.toJson()).toList(),
      'ativo': ativo,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nome': nomeCurso,
      'cd_cbo': cbo,
      'cbo_descricao': descricaoCBO,
      'validade': validade.toIso8601String().split('T')[0],
      'nome_aprendizagem': nomeCursoAprendizagem,
      'modulos': modulos.map((modulo) => modulo.toCreateJson()).toList(),
      'ativo': ativo,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'nome': nomeCurso,
      'cd_cbo': cbo,
      'cbo_descricao': descricaoCBO,
      'validade': validade.toIso8601String().split('T')[0],
      'nome_aprendizagem': nomeCursoAprendizagem,
      'modulos': modulos.map((modulo) => modulo.toJson()).toList(),
      'ativo': ativo,
    };
  }

  CursoAprendizagem copyWith({
    int? id,
    String? nomeCurso,
    String? descricaoCBO,
    int? cbo,
    DateTime? validade,
    String? nomeCursoAprendizagem,
    List<ModuloCurso>? modulos,
    bool? ativo,
    String? createdBy,
    int? updatedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CursoAprendizagem(
      id: id ?? this.id,
      descricaoCBO: descricaoCBO ?? this.descricaoCBO,
      nomeCurso: nomeCurso ?? this.nomeCurso,
      cbo: cbo ?? this.cbo,
      validade: validade ?? this.validade,
      nomeCursoAprendizagem:
          nomeCursoAprendizagem ?? this.nomeCursoAprendizagem,
      modulos: modulos ?? this.modulos,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  String toString() {
    return 'CursoAprendizagem{id: $id, nomeCurso: $nomeCurso, cbo: $cbo, validade: $validade, nomeCursoAprendizagem: $nomeCursoAprendizagem, modulos: ${modulos.length}, ativo: $ativo}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CursoAprendizagem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Classe para os módulos do curso
class ModuloCurso {
  final int? id;
  final int? cursoAprendizagemId;
  final String nomeDisciplina;
  final bool ativo;

  ModuloCurso({
    this.id,
    this.cursoAprendizagemId,
    required this.nomeDisciplina,
    this.ativo = true,
  });

  //criar metodo que recebe um dynamic e retornar em um int?
  static int? _asInt(dynamic value) {
    try {
      if (value is int) {
        return value;
      } else if (value is String) {
        return int.tryParse(value);
      }
    } catch (e) {
      print('Erro ao converter para int: $e');
    }
    return null;
  }

  factory ModuloCurso.fromJson(Map<String, dynamic> json) {
    return ModuloCurso(
      id: _asInt(json['cd_modulo']),
      cursoAprendizagemId: _asInt(json['cd_curso']),
      nomeDisciplina: json['nome_disciplina'] ?? '',
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'cd_modulo': id,
      if (cursoAprendizagemId != null) 'cd_curso': cursoAprendizagemId,
      'nome_disciplina': nomeDisciplina,
      'ativo': ativo,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nome_disciplina': nomeDisciplina,
      'ativo': ativo,
    };
  }

  ModuloCurso copyWith({
    int? id,
    int? cursoAprendizagemId,
    String? nomeDisciplina,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ModuloCurso(
      id: id ?? this.id,
      cursoAprendizagemId: cursoAprendizagemId ?? this.cursoAprendizagemId,
      nomeDisciplina: nomeDisciplina ?? this.nomeDisciplina,
      ativo: ativo ?? this.ativo,
    );
  }

  @override
  String toString() {
    return 'ModuloCurso{id: $id, nomeDisciplina: $nomeDisciplina, ativo: $ativo}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModuloCurso &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
