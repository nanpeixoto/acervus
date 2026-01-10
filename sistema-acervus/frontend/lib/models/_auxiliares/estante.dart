import 'package:sistema_estagio/models/_auxiliares/prateleira.dart';

class Estante {
  final int? id; // 👈 agora pode ser null

  final String descricao;
  final int cdSala;
  final int paisId;
  final int estadoId;
  final int cidadeId;

  final String? pais_descricao;
  final String? estado_descricao;
  final String? cidade_descricao;
  final String? sala_descricao;

  // 👉 usado na LISTAGEM
  final int totalPrateleiras;

  // 👉 usado só no DETALHE / EDITAR
  final List<Prateleira> prateleiras;

  Estante({
    required this.id,
    required this.descricao,
    required this.cdSala,
    required this.paisId,
    required this.estadoId,
    required this.cidadeId,
    this.pais_descricao,
    this.estado_descricao,
    this.cidade_descricao,
    this.sala_descricao,
    this.totalPrateleiras = 0,
    this.prateleiras = const [],
  });

  factory Estante.fromJson(Map<String, dynamic> json) {
    return Estante(
      id: json['cd_estante'],
      descricao: json['descricao']?.trim() ?? '',
      cdSala: json['cd_sala'],
      paisId: json['pais_id'],
      estadoId: json['estado_id'],
      pais_descricao: json['pais_descricao'],
      estado_descricao: json['estado_descricao'],
      cidade_descricao: json['cidade_descricao'],
      sala_descricao: json['sala_descricao'],
      cidadeId: json['cidade_id'],
      totalPrateleiras: int.tryParse(
            json['total_prateleiras']?.toString() ?? '0',
          ) ??
          0,
      prateleiras: (json['prateleiras'] as List<dynamic>?)
              ?.map((p) => Prateleira.fromJson(p))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pais_id': paisId,
      'estado_id': estadoId,
      'cidade_id': cidadeId,
      'cd_sala': cdSala,
      'descricao': descricao,
      'prateleiras': prateleiras
          .map((p) => {
                'descricao_prateleira': p.descricao,
              })
          .toList(),
    };
  }
}
