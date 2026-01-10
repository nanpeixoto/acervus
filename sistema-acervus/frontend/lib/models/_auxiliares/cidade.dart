class Cidade {
  final int? id;
  final String nome;
  final int estadoId;

  final int? codigoIbge;
  final int? populacao2010;
  final double? densidadeDemo;
  final String? gentilico;
  final double? area;

  // Campos auxiliares (JOIN)
  final String? estadoNome;
  final String? estadoSigla;
  final int? paisId;
  final String? paisNome;
  final String? paisSigla;

  Cidade({
    this.id,
    required this.nome,
    required this.estadoId,
    this.codigoIbge,
    this.populacao2010,
    this.densidadeDemo,
    this.gentilico,
    this.area,
    this.estadoNome,
    this.estadoSigla,
    this.paisId,
    this.paisNome,
    this.paisSigla,
  });

  // =============================
  // FROM JSON
  // =============================
  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      id: json['id'],
      nome: json['nome'] ?? '',
      estadoId: json['estado_id'],
      codigoIbge: json['codigo_ibge'],
      populacao2010: json['populacao_2010'],
      densidadeDemo: json['densidade_demo'] != null
          ? double.tryParse(json['densidade_demo'].toString())
          : null,
      gentilico: json['gentilico'],
      area: json['area'] != null
          ? double.tryParse(json['area'].toString())
          : null,
      estadoNome: json['estado_nome'],
      estadoSigla: json['estado_sigla'],
      paisId: json['pais_id'],
      paisNome: json['pais_nome'],
      paisSigla: json['pais_sigla'],
    );
  }

  // =============================
  // TO JSON (POST / PUT)
  // =============================
  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'estado_id': estadoId,
      'codigo_ibge': codigoIbge,
      'populacao_2010': populacao2010,
      'densidade_demo': densidadeDemo,
      'gentilico': gentilico,
      'area': area,
    };
  }

  // =============================
  // COPY WITH
  // =============================
  Cidade copyWith({
    int? id,
    String? nome,
    int? estadoId,
    int? codigoIbge,
    int? populacao2010,
    double? densidadeDemo,
    String? gentilico,
    double? area,
    String? estadoNome,
    String? estadoSigla,
    int? paisId,
    String? paisNome,
    String? paisSigla,
  }) {
    return Cidade(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      estadoId: estadoId ?? this.estadoId,
      codigoIbge: codigoIbge ?? this.codigoIbge,
      populacao2010: populacao2010 ?? this.populacao2010,
      densidadeDemo: densidadeDemo ?? this.densidadeDemo,
      gentilico: gentilico ?? this.gentilico,
      area: area ?? this.area,
      estadoNome: estadoNome ?? this.estadoNome,
      estadoSigla: estadoSigla ?? this.estadoSigla,
      paisId: paisId ?? this.paisId,
      paisNome: paisNome ?? this.paisNome,
      paisSigla: paisSigla ?? this.paisSigla,
    );
  }
}
