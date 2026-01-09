class Contrato {
  final String id;
  final String numero;
  final String tipo;
  final String status;
  final DateTime dataInicio;
  final DateTime dataFim;
  final double bolsa;
  final double transporte;
  final String modalidadeTransporte;
  final List<String> atividades;
  final String horario;
  final int cargaHoraria;
  final String seguradora;
  final double? alimentacao;
  final String? observacoes;
  final dynamic empresa;
  final dynamic estudante;
  final dynamic instituicao;
  final dynamic supervisor;

  Contrato({
    required this.id,
    required this.numero,
    required this.tipo,
    required this.status,
    required this.dataInicio,
    required this.dataFim,
    required this.bolsa,
    required this.transporte,
    required this.modalidadeTransporte,
    required this.atividades,
    required this.horario,
    required this.cargaHoraria,
    required this.seguradora,
    this.alimentacao,
    this.observacoes,
    this.empresa,
    this.estudante,
    this.instituicao,
    this.supervisor,
  });

  factory Contrato.fromJson(Map<String, dynamic> json) {
    return Contrato(
      id: json['id'],
      numero: json['numero'],
      tipo: json['tipo'],
      status: json['status'],
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: DateTime.parse(json['dataFim']),
      bolsa: double.parse(json['bolsa'].toString()),
      transporte: double.parse(json['transporte'].toString()),
      modalidadeTransporte: json['modalidadeTransporte'],
      atividades: List<String>.from(json['atividades']),
      horario: json['horario'],
      cargaHoraria: json['cargaHoraria'],
      seguradora: json['seguradora'],
      alimentacao: json['alimentacao'] != null 
          ? double.parse(json['alimentacao'].toString()) 
          : null,
      observacoes: json['observacoes'],
      empresa: json['empresa'],
      estudante: json['estagiario'] ?? json['jovemAprendiz'],
      instituicao: json['instituicao'],
      supervisor: json['supervisor'],
    );
  }
}