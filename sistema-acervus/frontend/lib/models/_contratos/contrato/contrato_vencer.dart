// lib/models/contrato_vencer.dart
class ContratoVencer {
  final int cdContrato;
  final int cdEmpresa;
  final String nomeFantasia;
  final String unidadeGestora;
  final String estudante;
  final String dataTermino; // DD/MM/YYYY
  final String? emailEmpresa;
  final String? emailSupervisor;
  final String? nomeSupervisor;

  ContratoVencer({
    required this.cdContrato,
    required this.cdEmpresa,
    required this.nomeFantasia,
    required this.unidadeGestora,
    required this.estudante,
    required this.dataTermino,
    this.emailEmpresa,
    this.emailSupervisor,
    this.nomeSupervisor,
  });

  factory ContratoVencer.fromJson(Map<String, dynamic> j) {
    return ContratoVencer(
      cdContrato: j['cd_contrato'],
      cdEmpresa: j['cd_empresa'],
      nomeFantasia: j['nome_fantasia'] ?? '',
      unidadeGestora: j['unidade_gestora'] ?? '',
      estudante: j['estudante'] ?? '',
      dataTermino: j['data_termino'] ?? '',
      emailEmpresa: j['email_empresa'],
      emailSupervisor: j['email_supervisor'],
      nomeSupervisor: j['nome_supervisor'],
    );
  }
}
