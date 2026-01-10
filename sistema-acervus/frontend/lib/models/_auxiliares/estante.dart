class Estante {
  final int? id;
  final int paisId;
  final int estadoId;
  final int cidadeId;
  final int cdSala;
  final String descricao;
  final List<Prateleira> prateleiras;

  Estante({
    this.id,
    required this.paisId,
    required this.estadoId,
    required this.cidadeId,
    required this.cdSala,
    required this.descricao,
    required this.prateleiras,
  });

  Map<String, dynamic> toJson() {
    return {
      'pais_id': paisId,
      'estado_id': estadoId,
      'cidade_id': cidadeId,
      'cd_sala': cdSala,
      'descricao': descricao,
      'prateleiras': prateleiras.map((p) => p.toJson()).toList(),
    };
  }

  factory Estante.fromJson(Map<String, dynamic> json) {
    return Estante(
      id: json['cd_estante'],
      paisId: json['pais_id'],
      estadoId: json['estado_id'],
      cidadeId: json['cidade_id'],
      cdSala: json['cd_sala'],
      descricao: json['descricao'],
      prateleiras: (json['prateleiras'] as List? ?? [])
          .map((e) => Prateleira.fromJson(e))
          .toList(),
    );
  }
}

class Prateleira {
  final int? id;
  final String descricao;

  Prateleira({this.id, required this.descricao});

  Map<String, dynamic> toJson() => {
        'descricao_prateleira': descricao,
      };

  factory Prateleira.fromJson(Map<String, dynamic> json) {
    return Prateleira(
      id: json['cd_estante_prateleira'],
      descricao: json['descricao_prateleira'],
    );
  }
}
