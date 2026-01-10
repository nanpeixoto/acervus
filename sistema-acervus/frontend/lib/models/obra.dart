class Obra {
  final int id;

  final String? titulo;
  final String? subtitulo;
  final String? resumoObra;

  final int? cdTipoPeca;
  final int? cdSubtipoPeca;
  final int? cdAssunto;
  final int? cdMaterial;
  final int? cdAutor;
  final int? cdEditora;
  final int? cdIdioma;
  final int? cdEstadoConservacao;
  final int? cdEstantePrateleira;

  final String? origem;
  final String? medida;
  final String? conjunto;

  final String? numeroEdicao;
  final int? qtdPaginas;
  final String? volume;

  final String? dataCompra;
  final double? valor;

  Obra({
    required this.id,
    this.titulo,
    this.subtitulo,
    this.resumoObra,
    this.cdTipoPeca,
    this.cdSubtipoPeca,
    this.cdAssunto,
    this.cdMaterial,
    this.cdIdioma,
    this.cdEstadoConservacao,
    this.cdEstantePrateleira,
    this.origem,
    this.medida,
    this.cdAutor,
    this.cdEditora,
    this.conjunto,
    this.numeroEdicao,
    this.qtdPaginas,
    this.volume,
    this.dataCompra,
    this.valor,
  });

  factory Obra.fromJson(Map<String, dynamic> json) {
    return Obra(
      id: json['id'] ?? json['cd_obra'],
      titulo: json['titulo'],
      subtitulo: json['subtitulo'],
      cdTipoPeca: json['cd_tipo_peca'],
      cdSubtipoPeca: json['cd_subtipo_peca'],
      cdAssunto: json['cd_assunto'],
      cdMaterial: json['cd_material'],
      cdIdioma: json['cd_idioma'],
      cdEstadoConservacao: json['cd_estado_conservacao'],
      cdEstantePrateleira: json['cd_estante_prateleira'],
      cdAutor: json['cd_autor'],
      cdEditora: json['cd_editora'],
      origem: json['origem'],
      medida: json['medida'],
      conjunto: json['conjunto'],
      numeroEdicao: json['numero_edicao'],
      qtdPaginas: json['qtd_paginas'],
      volume: json['volume'],
      dataCompra: json['data_compra'],
      valor: json['valor'] != null
          ? double.tryParse(json['valor'].toString())
          : null,
      resumoObra: json['resumo_obra'],
    );
  }
}
