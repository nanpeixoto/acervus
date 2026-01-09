class Contato {
  final int? id;
  final int? candidatoId;
  final String? nome;
  final String? email;
  final String? telefone;
  final String? celular;
  final String? whatsapp;
  final String? grauParentesco;
  bool principal = false;

  Contato({
    this.id,
    this.candidatoId,
    this.nome,
    this.email,
    this.telefone,
    this.celular,
    this.whatsapp,
    this.grauParentesco,
    this.principal = false,
  });

  factory Contato.fromJson(Map<String, dynamic> json) {
    return Contato(
      id: json['cd_contato'] as int?,
      candidatoId: json['cd_candidato'] as int?,
      nome: json['nome'] as String?,
      email: json['email'] as String?,
      telefone: json['telefone'] as String?,
      celular: json['celular'] as String?,
      whatsapp: json['whatsapp'] as String?,
      grauParentesco: json['grau_parentesco'] as String?,
      principal: json['principal'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cd_contato': id,
      'cd_candidato': candidatoId,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'celular': celular,
      'whatsapp': whatsapp,
      'grau_parentesco': grauParentesco,
      'principal': principal,
    };
  }
}