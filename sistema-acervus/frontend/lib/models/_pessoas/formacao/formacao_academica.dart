class FormacaoAcademica {
  final int? id;
  final String? nivel;
  final String? curso;
  final String? cursoNaoListado;
  final String? instituicao;
  final String? instituicaoNaoListada;
  final String statusCurso;
  final String semestreAnoInicial;
  final String semestreAnoConclusao;
  final String turno;
  final String modalidade;
  final String raMatricula;
  final String? dataInicioCurso;
  final String? dataFimCurso;
  final bool ativo;
  late List<int> comprovanteMatriculaBytes;

  FormacaoAcademica({
    this.id,
    this.nivel,
    this.curso,
    this.dataInicioCurso,
    this.dataFimCurso,
    this.cursoNaoListado,
    this.instituicao,
    this.instituicaoNaoListada,
    required this.statusCurso,
    required this.semestreAnoInicial,
    required this.semestreAnoConclusao,
    required this.turno,
    required this.modalidade,
    required this.raMatricula,
    this.ativo = true,
    List<int>? comprovanteMatriculaBytes,
  })  : assert(nivel != null && nivel.isNotEmpty, 'Nivel cannot be null or empty'),
        comprovanteMatriculaBytes = comprovanteMatriculaBytes ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nivel': nivel,
      'curso': curso ?? cursoNaoListado,
      'cursoNaoListado': cursoNaoListado,
      'instituicao': instituicao ?? instituicaoNaoListada,
      'instituicaoNaoListada': instituicaoNaoListada,
      'statusCurso': statusCurso,
      'semestreAnoInicial': semestreAnoInicial,
      'semestreAnoConclusao': semestreAnoConclusao,
      'turno': turno,
      'modalidade': modalidade,
      'raMatricula': raMatricula,
      'dataInicioCurso': dataInicioCurso,
      'dataFimCurso': dataFimCurso,
      'ativo': ativo,
      'comprovanteMatriculaBytes': null, // Placeholder for file bytes
    };
  }

  factory FormacaoAcademica.fromJson(Map<String, dynamic> json) {
    return FormacaoAcademica(
      id: json['id'],
      nivel: json['nivel'],
      curso: json['curso'],
      cursoNaoListado: json['cursoNaoListado'],
      instituicao: json['instituicao'],
      instituicaoNaoListada: json['instituicaoNaoListada'],
      statusCurso: json['statusCurso'],
      semestreAnoInicial: json['semestreAnoInicial'],
      semestreAnoConclusao: json['semestreAnoConclusao'],
      turno: json['turno'],
      modalidade: json['modalidade'],
      raMatricula: json['raMatricula'],
      dataInicioCurso: json['dataInicioCurso'],
      dataFimCurso: json['dataFimCurso'],
      ativo: json['ativo'] ?? true,
      comprovanteMatriculaBytes: json['comprovanteMatriculaBytes'] as List<int>?,
    );
  }
}
