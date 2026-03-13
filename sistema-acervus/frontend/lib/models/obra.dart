class Obra {
  final int id;
  final String? titulo;
  final String? subtitulo;
  final String? resumoObra;
  final int? cdTipoPeca;
  final int? cdSubtipoPeca;
  final int? cdAssunto;
  final String? dsAssunto;
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
  final String? dataHistorica;
  final double? valor;
  final String? carimbo;
  final String? autorNome;
  final String? numeroApolice; // ✅ ADICIONADO
  final String? observacao; // ✅ ADICIONADO
  final String? dsIdioma;
  final String? dsEstadoConservacao;
  final String? dsTipoPeca;
  final String? dsSubtipoPeca;
  final String? dsAutor;

  Obra(
      {required this.id,
      this.titulo,
      this.subtitulo,
      this.resumoObra,
      this.cdTipoPeca,
      this.cdSubtipoPeca,
      this.cdAssunto,
      this.dsAssunto,
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
      this.carimbo,
      this.autorNome,
      this.numeroApolice, // ✅ ADICIONADO
      this.observacao, // ✅ ADICIONADO
      this.dataHistorica,
      this.dsIdioma,
      this.dsEstadoConservacao,
      this.dsTipoPeca,
      this.dsSubtipoPeca,
      this.dsAutor});

  factory Obra.fromJson(Map<String, dynamic> json) {
    return Obra(
      id: json['id'] ?? json['cd_obra'] ?? 0,
      titulo: json['titulo'] as String?,
      subtitulo: json['subtitulo'] as String?,
      resumoObra: json['resumo'] as String?,
      cdTipoPeca: json['cd_tipo_peca'] as int?,
      cdSubtipoPeca: json['cd_subtipo_peca'] as int?,
      cdAssunto: json['cd_assunto'] as int?,
      dsAssunto: json['dsassunto'] as String?,
      dsIdioma: json['dsidioma'] as String?,
      dsEstadoConservacao: json['dsEstadoConservacao'] as String?,
      dsTipoPeca: json['dstipopeca'] as String?,
      dsSubtipoPeca: json['dssubtipopeca'] as String?,
      dsAutor: json['dsautor'] as String?,
      cdMaterial: json['cd_material'] as int?,
      cdIdioma: json['cd_idioma'] as int?,
      cdEstadoConservacao: json['cd_estado_conservacao'] as int?,
      cdEstantePrateleira: json['cd_estante_prateleira'] as int?,
      cdAutor: json['cd_autor'] as int?,
      cdEditora: json['cd_editora'] as int?,
      origem: json['origem'] as String?,
      medida: json['medida'] as String?,
      conjunto: json['conjunto'] as String?,
      numeroEdicao: json['numero_edicao'] as String?,
      volume: json['volume'] as String?,
      dataCompra: json['data_compra'] as String?,
      dataHistorica: json['data_historica'] as String?,
      carimbo: json['carimbo'] as String?,
      autorNome: json['autor_nome'] as String?,
      qtdPaginas: json['qtd_paginas'] != null
          ? int.tryParse(json['qtd_paginas'].toString())
          : null,
      valor: json['valor'] != null
          ? double.tryParse(json['valor'].toString())
          : null,
      numeroApolice: json['numero_apolice'] as String?, // ✅ ADICIONADO
      observacao: json['observacao'] as String?, // ✅ ADICIONADO
    );
  }
}
