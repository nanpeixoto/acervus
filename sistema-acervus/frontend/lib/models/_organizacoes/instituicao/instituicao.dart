// lib/models/instituicao.dart
import '../../_core/endereco.dart';

class InstituicaoEnsino {
  final String? id;
  final int? idModelo;
  final String cnpj;
  final String razaoSocial;
  final String nomeFantasia;
  final String? campus;
  final String telefone;
  final String? celular;         // NOVO CAMPO
  final String? mantenedora;     // NOVO CAMPO
  final String? unidade;         // NOVO CAMPO
  final String? procedimento;    // NOVO CAMPO
  final String? nomeModelo;      // NOVO CAMPO
  final String? email; // NOVO CAMPO
  final Endereco endereco;
  final String? representanteLegal;
  //final ResponsavelEstagio? responsavelEstagio;
  //final ProfessorOrientador? professorOrientador;
  //final String? convenio;
  //final String? usuarioId;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Estagiario> estagiarios;
  final List<JovemAprendiz> jovensAprendizes;
  final List<Contrato> contratos;
  final List<Curso> cursos;
  final String? cpfRepresentanteLegal; // NOVO CAMPO

  InstituicaoEnsino({
    this.id,
    this.idModelo,
    required this.cnpj,
    required this.razaoSocial,
    required this.nomeFantasia,
    this.campus,
    this.telefone = '',
    this.celular,         // NOVO CAMPO
    this.mantenedora,     // NOVO CAMPO
    this.unidade,         // NOVO CAMPO
    this.procedimento,    // NOVO CAMPO
    this.nomeModelo,      // NOVO CAMPO
    this.email, // NOVO CAMPO
    required this.endereco,
    this.cpfRepresentanteLegal,
    this.representanteLegal, // NOVO CAMPO
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
    this.estagiarios = const [],
    this.jovensAprendizes = const [],
    this.contratos = const [],
    this.cursos = const [],
  });

  factory InstituicaoEnsino.fromJson(Map<String, dynamic> json) {
    try {
      return InstituicaoEnsino(
        id: (() {
          try {
            return json['cd_ie']?.toString();
          } catch (e) {
            print('Erro em id: $e');
            return null;
          }
        })(),
        idModelo: (() {
          try {
            return json['cd_template_modelo'];
          } catch (e) {
            print('Erro em idModelo: $e');
            return null;
          }
        })(),
        cnpj: (() {
          try {
            return json['cnpj']?.toString() ?? '';
          } catch (e) {
            print('Erro em cnpj: $e');
            return '';
          }
        })(),
        razaoSocial: (() {
          try {
            return json['razao_social'] ?? '';
          } catch (e) {
            print('Erro em razaoSocial: $e');
            return '';
          }
        })(),
        nomeFantasia: (() {
          try {
            return json['nome_fantasia'] ?? '';
          } catch (e) {
            print('Erro em nomeFantasia: $e');
            return '';
          }
        })(),
        //campus: json['campus'],
        telefone: (() {
          try {
            return json['telefone']?.toString() ?? '';
          } catch (e) {
            print('Erro em telefone: $e');
            return '';
          }
        })(),
        celular: json['celular']?.toString(),         // NOVO CAMPO
        mantenedora: json['mantenedora']?.toString(),
        representanteLegal: json['representante_legal']?.toString(), // NOVO CAMPO
        unidade: json['unidade']?.toString(),         // NOVO CAMPO
        procedimento: json['procedimento']?.toString(), // NOVO CAMPO
        nomeModelo: json['nome_modelo']?.toString(),    // NOVO CAMPO
        email: json['email_principal']?.toString(), // NOVO CAMPO
        endereco: (() {
          try {
            return Endereco.fromJson(json['endereco'] ?? {});
          } catch (e) {
            print('Erro em endereco: $e');
            rethrow;
          }
        })(),
        cpfRepresentanteLegal: json['cpf']?.toString(),
        ativo: !(json['bloqueado'] == true), // se 'bloqueado' == true -> ativo: false, caso contrário ativo: true
        //representanteLegal: RepresentanteLegal.fromJson(json['representanteLegal']),
        /* responsavelEstagio: json['responsavelEstagio'] != null
          ? ResponsavelEstagio.fromJson(json['responsavelEstagio'])
          : null,
      professorOrientador: json['professorOrientador'] != null
          ? ProfessorOrientador.fromJson(json['professorOrientador'])
          : null,
      convenio: json['convenio'],
      usuarioId: json['usuarioId'],
      ativo: json['ativo'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      estagiarios: json['estagiarios'] != null
          ? (json['estagiarios'] as List).map((e) => Estagiario.fromJson(e)).toList()
          : [],
      jovensAprendizes: json['jovensAprendizes'] != null
          ? (json['jovensAprendizes'] as List).map((j) => JovemAprendiz.fromJson(j)).toList()
          : [],
      contratos: json['contratos'] != null
          ? (json['contratos'] as List).map((c) => Contrato.fromJson(c)).toList()
          : [],
      cursos: json['cursos'] != null
          ? (json['cursos'] as List).map((c) => Curso.fromJson(c)).toList()
          : [], */
      );
      
    } catch (e, stack) {
      print('Erro geral em InstituicaoEnsino.fromJson: $e\n$stack');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idModelo': idModelo,
      'cnpj': cnpj,
      'razaoSocial': razaoSocial,
      'nomeFantasia': nomeFantasia,
      'campus': campus,
      'telefone': telefone,
      'celular': celular,         // NOVO CAMPO
      'mantenedora': mantenedora, // NOVO CAMPO
      'unidade': unidade,         // NOVO CAMPO
      'procedimento': procedimento, // NOVO CAMPO
      'nome_modelo': nomeModelo,    // NOVO CAMPO
      'email': email, // NOVO CAMPO
      'cep': endereco.cep,
      'logradouro': endereco.logradouro,
      'numero': endereco.numero,
      'bairro': endereco.bairro,
      'cidade': endereco.cidade,
      'estado': endereco.estado,
      'cpf': cpfRepresentanteLegal, // NOVO CAMPO
      //'complemento': endereco.complemento,
      'representanteLegal': representanteLegal, // NOVO CAMPO
      //'responsavelEstagio': responsavelEstagio?.toJson(),
      //'professorOrientador': professorOrientador?.toJson(),
      //'convenio': convenio,
      //'usuarioId': usuarioId,
      'ativo': ativo,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'cnpj': cnpj,
      'razaoSocial': razaoSocial,
      'nomeFantasia': nomeFantasia,
      'campus': campus,
      'telefone': telefone,
      'celular': celular,         // NOVO CAMPO
      'mantenedora': mantenedora, // NOVO CAMPO
      'unidade': unidade,         // NOVO CAMPO
      'procedimento': procedimento, // NOVO CAMPO
      'nome_modelo': nomeModelo,    // NOVO CAMPO
      'email': email, // NOVO CAMPO
      'endereco': endereco.toJson(),
      'cpf': cpfRepresentanteLegal, // NOVO CAMPO
      'representanteLegal': representanteLegal, // NOVO CAMPO
      //'responsavelEstagio': responsavelEstagio?.toJson(),
      //'professorOrientador': professorOrientador?.toJson(),
    };
  }

  // Métodos utilitários
  String get cnpjFormatted {
    if (cnpj.length == 14) {
      return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
    }
    return cnpj;
  }

  String get telefoneFormatted {
    final numbers = telefone.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return telefone;
  }

   String get enderecoCompleto {
     return endereco.enderecoCompleto;
   }

  String get nomeCompleto {
    if (campus != null && campus!.isNotEmpty) {
      return '$nomeFantasia - Campus $campus';
    }
    return nomeFantasia;
  }

  //bool get temResponsavelEstagio => responsavelEstagio != null;
  //bool get temProfessorOrientador => professorOrientador != null;
  //bool get temConvenio => convenio != null && convenio!.isNotEmpty;
  bool get temCampus => campus != null && campus!.isNotEmpty;

  int get totalEstagiarios => estagiarios.length;
  int get totalJovensAprendizes => jovensAprendizes.length;
  int get totalEstudantes => totalEstagiarios + totalJovensAprendizes;
  int get totalContratosAtivos =>
      contratos.where((c) => c.status == 'ATIVO').length;
  int get totalCursos => cursos.length;

  // Estatísticas por curso
  Map<String, int> get estudantesPorCurso {
    final Map<String, int> resultado = {};

    for (final estagiario in estagiarios) {
      final curso = estagiario.curso ?? 'Não informado';
      resultado[curso] = (resultado[curso] ?? 0) + 1;
    }

    for (final jovem in jovensAprendizes) {
      final curso = jovem.curso ?? 'Não informado';
      resultado[curso] = (resultado[curso] ?? 0) + 1;
    }

    return resultado;
  }

  // Métodos de cópia
  InstituicaoEnsino copyWith({
    String? id,
    String? idModelo,
    String? cnpj,
    String? razaoSocial,
    String? nomeFantasia,
    String? campus,
    String? telefone,
    String? celular,         // NOVO CAMPO
    String? mantenedora,     // NOVO CAMPO
    String? unidade,         // NOVO CAMPO
    String? procedimento,    // NOVO CAMPO
    String? nomeModelo,      // NOVO CAMPO
    String? email, // NOVO CAMPO
    Endereco? endereco,
    String? representanteLegal,
    ResponsavelEstagio? responsavelEstagio,
    ProfessorOrientador? professorOrientador,
    String? convenio,
    String? usuarioId,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Estagiario>? estagiarios,
    List<JovemAprendiz>? jovensAprendizes,
    List<Contrato>? contratos,
    List<Curso>? cursos,
  }) {
    return InstituicaoEnsino(
      id: id ?? this.id,
      idModelo: this.idModelo,
      cnpj: cnpj ?? this.cnpj,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      campus: campus ?? this.campus,
      telefone: telefone ?? this.telefone,
      celular: celular ?? this.celular,         // NOVO CAMPO
      mantenedora: mantenedora ?? this.mantenedora, // NOVO CAMPO
      unidade: unidade ?? this.unidade,         // NOVO CAMPO
      procedimento: procedimento ?? this.procedimento,    // NOVO CAMPO
      nomeModelo: nomeModelo ?? this.nomeModelo,      // NOVO CAMPO
      email: email ?? this.email, // NOVO CAMPO
      endereco: endereco ?? this.endereco,
      representanteLegal: representanteLegal ?? this.representanteLegal,
      //responsavelEstagio: responsavelEstagio ?? this.responsavelEstagio,
      //professorOrientador: professorOrientador ?? this.professorOrientador,
      //convenio: convenio ?? this.convenio,
      //usuarioId: usuarioId ?? this.usuarioId,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      estagiarios: estagiarios ?? this.estagiarios,
      jovensAprendizes: jovensAprendizes ?? this.jovensAprendizes,
      contratos: contratos ?? this.contratos,
      cursos: cursos ?? this.cursos,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InstituicaoEnsino && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'InstituicaoEnsino(id: $id, nomeFantasia: $nomeCompleto, cnpj: $cnpjFormatted)';
  }
}

class RepresentanteLegal {
  final String nome;
  final String cargo;
  final String? email;
  final String? telefone;
  final String? cpf;

  RepresentanteLegal({
    required this.nome,
    required this.cargo,
    this.email,
    this.telefone,
    this.cpf,
  });

  factory RepresentanteLegal.fromJson(Map<String, dynamic> json) {
    return RepresentanteLegal(
      nome: json['nome'],
      cargo: json['cargo'],
      email: json['email'],
      telefone: json['telefone'],
      cpf: json['cpf'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cargo': cargo,
      'email': email,
      'telefone': telefone,
      'cpf': cpf,
    };
  }

  String get telefoneFormatted {
    if (telefone == null) return '';
    final numbers = telefone!.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return telefone!;
  }

  String get cpfFormatted {
    if (cpf == null) return '';
    if (cpf!.length == 11) {
      return '${cpf!.substring(0, 3)}.${cpf!.substring(3, 6)}.${cpf!.substring(6, 9)}-${cpf!.substring(9, 11)}';
    }
    return cpf!;
  }

  RepresentanteLegal copyWith({
    String? nome,
    String? cargo,
    String? email,
    String? telefone,
    String? cpf,
  }) {
    return RepresentanteLegal(
      nome: nome ?? this.nome,
      cargo: cargo ?? this.cargo,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
    );
  }

  @override
  String toString() {
    return 'RepresentanteLegal(nome: $nome, cargo: $cargo)';
  }
}

class ResponsavelEstagio {
  final String nome;
  final String cargo;
  final String? email;
  final String? telefone;
  final String? cpf;
  final String? formacao;

  ResponsavelEstagio({
    required this.nome,
    required this.cargo,
    this.email,
    this.telefone,
    this.cpf,
    this.formacao,
  });

  factory ResponsavelEstagio.fromJson(Map<String, dynamic> json) {
    return ResponsavelEstagio(
      nome: json['nome'],
      cargo: json['cargo'],
      email: json['email'],
      telefone: json['telefone'],
      cpf: json['cpf'],
      formacao: json['formacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'cargo': cargo,
      'email': email,
      'telefone': telefone,
      'cpf': cpf,
      'formacao': formacao,
    };
  }

  String get telefoneFormatted {
    if (telefone == null) return '';
    final numbers = telefone!.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return telefone!;
  }

  String get cpfFormatted {
    if (cpf == null) return '';
    if (cpf!.length == 11) {
      return '${cpf!.substring(0, 3)}.${cpf!.substring(3, 6)}.${cpf!.substring(6, 9)}-${cpf!.substring(9, 11)}';
    }
    return cpf!;
  }

  ResponsavelEstagio copyWith({
    String? nome,
    String? cargo,
    String? email,
    String? telefone,
    String? cpf,
    String? formacao,
  }) {
    return ResponsavelEstagio(
      nome: nome ?? this.nome,
      cargo: cargo ?? this.cargo,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      formacao: formacao ?? this.formacao,
    );
  }

  @override
  String toString() {
    return 'ResponsavelEstagio(nome: $nome, cargo: $cargo)';
  }
}

class ProfessorOrientador {
  final String nome;
  final String? departamento;
  final String? titulacao;
  final String? email;
  final String? telefone;
  final String? cpf;
  final String? lattes;

  ProfessorOrientador({
    required this.nome,
    this.departamento,
    this.titulacao,
    this.email,
    this.telefone,
    this.cpf,
    this.lattes,
  });

  factory ProfessorOrientador.fromJson(Map<String, dynamic> json) {
    return ProfessorOrientador(
      nome: json['nome'],
      departamento: json['departamento'],
      titulacao: json['titulacao'],
      email: json['email'],
      telefone: json['telefone'],
      cpf: json['cpf'],
      lattes: json['lattes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'departamento': departamento,
      'titulacao': titulacao,
      'email': email,
      'telefone': telefone,
      'cpf': cpf,
      'lattes': lattes,
    };
  }

  String get nomeCompleto {
    if (titulacao != null && titulacao!.isNotEmpty) {
      return '$titulacao $nome';
    }
    return nome;
  }

  String get telefoneFormatted {
    if (telefone == null) return '';
    final numbers = telefone!.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return telefone!;
  }

  String get cpfFormatted {
    if (cpf == null) return '';
    if (cpf!.length == 11) {
      return '${cpf!.substring(0, 3)}.${cpf!.substring(3, 6)}.${cpf!.substring(6, 9)}-${cpf!.substring(9, 11)}';
    }
    return cpf!;
  }

  ProfessorOrientador copyWith({
    String? nome,
    String? departamento,
    String? titulacao,
    String? email,
    String? telefone,
    String? cpf,
    String? lattes,
  }) {
    return ProfessorOrientador(
      nome: nome ?? this.nome,
      departamento: departamento ?? this.departamento,
      titulacao: titulacao ?? this.titulacao,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      lattes: lattes ?? this.lattes,
    );
  }

  @override
  String toString() {
    return 'ProfessorOrientador(nome: $nomeCompleto, departamento: $departamento)';
  }
}

class Curso {
  final String? id;
  final String nome;
  final String nivel;
  final String modalidade;
  final String? descricao;
  final int? duracao; // em semestres
  final bool ativo;
  final String instituicaoId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Curso({
    this.id,
    required this.nome,
    required this.nivel,
    required this.modalidade,
    this.descricao,
    this.duracao,
    this.ativo = true,
    required this.instituicaoId,
    this.createdAt,
    this.updatedAt,
  });

  factory Curso.fromJson(Map<String, dynamic> json) {
    return Curso(
      id: json['id'],
      nome: json['nome'],
      nivel: json['nivel'],
      modalidade: json['modalidade'],
      descricao: json['descricao'],
      duracao: json['duracao'],
      ativo: json['ativo'] ?? true,
      instituicaoId: json['instituicaoId'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'nivel': nivel,
      'modalidade': modalidade,
      'descricao': descricao,
      'duracao': duracao,
      'ativo': ativo,
      'instituicaoId': instituicaoId,
    };
  }

  String get nomeCompleto {
    return '$nome ($nivel - $modalidade)';
  }

  String get duracaoFormatada {
    if (duracao == null) return 'Não informado';
    if (duracao == 1) return '1 semestre';
    return '$duracao semestres';
  }

  Curso copyWith({
    String? id,
    String? nome,
    String? nivel,
    String? modalidade,
    String? descricao,
    int? duracao,
    bool? ativo,
    String? instituicaoId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Curso(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      nivel: nivel ?? this.nivel,
      modalidade: modalidade ?? this.modalidade,
      descricao: descricao ?? this.descricao,
      duracao: duracao ?? this.duracao,
      ativo: ativo ?? this.ativo,
      instituicaoId: instituicaoId ?? this.instituicaoId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Curso && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Curso(id: $id, nome: $nomeCompleto)';
  }
}

// Enums relacionados
enum TipoInstituicao {
  PUBLICA,
  PRIVADA,
  FEDERAL,
  ESTADUAL,
  MUNICIPAL,
  COMUNITARIA,
}

enum NivelEnsino {
  FUNDAMENTAL,
  MEDIO,
  TECNICO,
  SUPERIOR,
  POS_GRADUACAO,
  MESTRADO,
  DOUTORADO,
}

enum ModalidadeEnsino {
  PRESENCIAL,
  SEMI_PRESENCIAL,
  EAD,
  HIBRIDO,
}

// Extensions para facilitar o uso
extension TipoInstituicaoExtension on TipoInstituicao {
  String get displayName {
    switch (this) {
      case TipoInstituicao.PUBLICA:
        return 'Pública';
      case TipoInstituicao.PRIVADA:
        return 'Privada';
      case TipoInstituicao.FEDERAL:
        return 'Federal';
      case TipoInstituicao.ESTADUAL:
        return 'Estadual';
      case TipoInstituicao.MUNICIPAL:
        return 'Municipal';
      case TipoInstituicao.COMUNITARIA:
        return 'Comunitária';
    }
  }
}

extension NivelEnsinoExtension on NivelEnsino {
  String get displayName {
    switch (this) {
      case NivelEnsino.FUNDAMENTAL:
        return 'Ensino Fundamental';
      case NivelEnsino.MEDIO:
        return 'Ensino Médio';
      case NivelEnsino.TECNICO:
        return 'Técnico';
      case NivelEnsino.SUPERIOR:
        return 'Superior';
      case NivelEnsino.POS_GRADUACAO:
        return 'Pós-Graduação';
      case NivelEnsino.MESTRADO:
        return 'Mestrado';
      case NivelEnsino.DOUTORADO:
        return 'Doutorado';
    }
  }
}

extension ModalidadeEnsinoExtension on ModalidadeEnsino {
  String get displayName {
    switch (this) {
      case ModalidadeEnsino.PRESENCIAL:
        return 'Presencial';
      case ModalidadeEnsino.SEMI_PRESENCIAL:
        return 'Semi-presencial';
      case ModalidadeEnsino.EAD:
        return 'EaD';
      case ModalidadeEnsino.HIBRIDO:
        return 'Híbrido';
    }
  }
}

// Classe para validações
class InstituicaoValidator {
  static String? validateCNPJ(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) {
      return 'CNPJ é obrigatório';
    }

    final numbers = cnpj.replaceAll(RegExp(r'\D'), '');

    if (numbers.length != 14) {
      return 'CNPJ deve ter 14 dígitos';
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(numbers)) {
      return 'CNPJ inválido';
    }

    return _validateCNPJAlgorithm(numbers) ? null : 'CNPJ inválido';
  }

  static bool _validateCNPJAlgorithm(String cnpj) {
    List<int> weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    List<int> weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * weights1[i];
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cnpj[12]) != digit1) return false;

    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * weights2[i];
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;

    return int.parse(cnpj[13]) == digit2;
  }

  static String? validateRazaoSocial(String? razaoSocial) {
    if (razaoSocial == null || razaoSocial.trim().isEmpty) {
      return 'Razão social é obrigatória';
    }
    if (razaoSocial.trim().length < 2) {
      return 'Razão social deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  static String? validateNomeFantasia(String? nomeFantasia) {
    if (nomeFantasia == null || nomeFantasia.trim().isEmpty) {
      return 'Nome fantasia é obrigatório';
    }
    if (nomeFantasia.trim().length < 2) {
      return 'Nome fantasia deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  static String? validateCampus(String? campus) {
    if (campus != null && campus.isNotEmpty && campus.trim().length < 2) {
      return 'Campus deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  static String? validateRepresentanteLegal(RepresentanteLegal? representante) {
    if (representante == null) {
      return 'Representante legal é obrigatório';
    }
    if (representante.nome.trim().isEmpty) {
      return 'Nome do representante é obrigatório';
    }
    if (representante.cargo.trim().isEmpty) {
      return 'Cargo do representante é obrigatório';
    }
    return null;
  }
}

// Classes relacionadas (importações/dependências)
class Estagiario {
  final String id;
  final String nome;
  final String? curso;

  Estagiario({required this.id, required this.nome, this.curso});

  factory Estagiario.fromJson(Map<String, dynamic> json) {
    return Estagiario(
      id: json['id'],
      nome: json['nome'],
      curso: json['curso'],
    );
  }
}

class JovemAprendiz {
  final String id;
  final String nome;
  final String? curso;

  JovemAprendiz({required this.id, required this.nome, this.curso});

  factory JovemAprendiz.fromJson(Map<String, dynamic> json) {
    return JovemAprendiz(
      id: json['id'],
      nome: json['nome'],
      curso: json['curso'],
    );
  }
}

class Contrato {
  final String id;
  final String status;

  Contrato({required this.id, required this.status});

  factory Contrato.fromJson(Map<String, dynamic> json) {
    return Contrato(
      id: json['id'],
      status: json['status'],
    );
  }
}
