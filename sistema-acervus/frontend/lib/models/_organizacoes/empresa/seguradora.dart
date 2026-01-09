class Seguradora {
  final int? id;
  final int? idEndereco;
  final String razaoSocial;
  final String nomeFantasia;
  final String cnpj;
  final String telefone;
  final String? celular;
  final String cep;
  final String logradouro;
  final String? numero;
  final String? complemento;
  final String bairro;
  final String cidade;
  final String uf;
  final String apolice;
  final double valorApolice;
  final double porcentagemDhmo;
  final bool ativo;
  final String? observacao;
  final bool isDefault;

  Seguradora({
    this.id,
    this.idEndereco,
    this.isDefault = false,
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.cnpj,
    required this.telefone,
    this.celular,
    required this.cep,
    required this.logradouro,
    this.numero,
    this.complemento,
    required this.bairro,
    required this.cidade,
    required this.uf,
    required this.apolice,
    required this.valorApolice,
    required this.porcentagemDhmo,
    this.ativo = true,
    this.observacao,
  });

  factory Seguradora.fromJson(Map<String, dynamic> json) {
    final endereco = json['endereco'] ?? {};

    return Seguradora(
      id: json['cd_seguradora'] != null
          ? int.tryParse(json['cd_seguradora'].toString())
          : null,
      razaoSocial: json['razao_social'] ?? '',
      nomeFantasia: json['nome_fantasia'] ?? '',
      cnpj: json['cnpj'] ?? '',
      telefone: json['telefone'] ?? '',
      celular: json['celular'] ?? '',
      apolice: json['numero_apolice'] ?? '',
      valorApolice: (json['valor_apolice'] is String)
          ? double.tryParse(json['valor_apolice']
                  .replaceAll(RegExp(r'[^\d,\.]'), '')
                  .replaceAll(',', '.')) ??
              0.0
          : (json['valor_apolice'] ?? 0.0).toDouble(),
      porcentagemDhmo: (json['porcentagem_dhmo'] is String)
          ? double.tryParse(json['porcentagem_dhmo'].replaceAll(',', '.')) ??
              0.0
          : (json['porcentagem_dhmo'] ?? 0.0).toDouble(),
      observacao: json['observacao'] ?? '',
      ativo: json['ativo'] ?? true,

      // Endereço (aninhado)
      idEndereco: endereco['id_endereco'] != null
          ? int.tryParse(endereco['id_endereco'].toString())
          : null,
      cep: endereco['cep'] ?? '',
      logradouro: endereco['logradouro'] ?? '',
      numero: endereco['numero'] ?? '',
      complemento: endereco['complemento'] ?? '',
      bairro: endereco['bairro'] ?? '',
      cidade: endereco['cidade'] ?? '',
      uf: endereco['uf'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cd_seguradora': id,
      'id_endereco': idEndereco,
      'razao_social': razaoSocial,
      'nome_fantasia': nomeFantasia,
      'cnpj': cnpj,
      'telefone': telefone,
      'celular': celular,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'uf': uf,
      'apolice': apolice,
      'valor_apolice': valorApolice,
      'porcentagem_dhmo': porcentagemDhmo,
      'ativo': ativo,
      'observacao': observacao,
    };
  }
}
