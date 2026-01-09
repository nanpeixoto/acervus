// lib/models/jovem_aprendiz.dart
import '../../_core/endereco.dart';

class JovemAprendiz {
  final String? id;
  final String nome;
  final String? nomeSocial;
  final String rg;
  final String cpf;
  final String carteiraTrabalho;
  final TipoCarteira tipoCarteira;
  final String orgaoEmissor;
  final String uf;
  final String sexo;
  final String genero;
  final String raca;
  final String estadoCivil;
  final DateTime dataNascimento;
  final String naturalidade;
  final String email;
  final String telefone;
  final String celular;
  final Endereco endereco;
  final String? responsavel;
  final bool menorIdade;
  final String? instituicaoId;
  final String? curso;
  final List<ExperienciaProfissional> experiencias;
  final String? usuarioId;
  final bool ativo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Contrato> contratos;

  JovemAprendiz({
    this.id,
    required this.nome,
    this.nomeSocial,
    required this.rg,
    required this.cpf,
    required this.carteiraTrabalho,
    required this.tipoCarteira,
    required this.orgaoEmissor,
    required this.uf,
    required this.sexo,
    required this.genero,
    required this.raca,
    required this.estadoCivil,
    required this.dataNascimento,
    required this.naturalidade,
    required this.email,
    required this.telefone,
    required this.celular,
    required this.endereco,
    this.responsavel,
    required this.menorIdade,
    this.instituicaoId,
    this.curso,
    this.experiencias = const [],
    this.usuarioId,
    this.ativo = true,
    this.createdAt,
    this.updatedAt,
    this.contratos = const [],
  });

  factory JovemAprendiz.fromJson(Map<String, dynamic> json) {
    return JovemAprendiz(
      id: json['id'],
      nome: json['nome'],
      nomeSocial: json['nomeSocial'],
      rg: json['rg'],
      cpf: json['cpf'],
      carteiraTrabalho: json['carteiraTrabalho'],
      tipoCarteira: TipoCarteira.values.firstWhere(
        (e) => e.name == json['tipoCarteira'],
        orElse: () => TipoCarteira.FISICA,
      ),
      orgaoEmissor: json['orgaoEmissor'],
      uf: json['uf'],
      sexo: json['sexo'],
      genero: json['genero'],
      raca: json['raca'],
      estadoCivil: json['estadoCivil'],
      dataNascimento: DateTime.parse(json['dataNascimento']),
      naturalidade: json['naturalidade'],
      email: json['email'],
      telefone: json['telefone'],
      celular: json['celular'],
      endereco: Endereco.fromEstagiarioJson(json),
      responsavel: json['responsavel'],
      menorIdade: json['menorIdade'] ?? false,
      instituicaoId: json['instituicaoId'],
      curso: json['curso'],
      experiencias: json['experiencias'] != null
          ? (json['experiencias'] as List)
              .map((e) => ExperienciaProfissional.fromJson(e))
              .toList()
          : [],
      usuarioId: json['usuarioId'],
      ativo: json['ativo'] ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      contratos: json['contratos'] != null
          ? (json['contratos'] as List).map((c) => Contrato.fromJson(c)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'nomeSocial': nomeSocial,
      'rg': rg,
      'cpf': cpf,
      'carteiraTrabalho': carteiraTrabalho,
      'tipoCarteira': tipoCarteira.name,
      'orgaoEmissor': orgaoEmissor,
      'uf': uf,
      'sexo': sexo,
      'genero': genero,
      'raca': raca,
      'estadoCivil': estadoCivil,
      'dataNascimento': dataNascimento.toIso8601String(),
      'naturalidade': naturalidade,
      'email': email,
      'telefone': telefone,
      'celular': celular,
      'cep': endereco.cep,
      'logradouro': endereco.logradouro,
      'numero': endereco.numero,
      'bairro': endereco.bairro,
      'cidade': endereco.cidade,
      'estado': endereco.estado,
      //'complemento': endereco.complemento,
      'responsavel': responsavel,
      'menorIdade': menorIdade,
      'instituicaoId': instituicaoId,
      'curso': curso,
      'experiencias': experiencias.map((e) => e.toJson()).toList(),
      'usuarioId': usuarioId,
      'ativo': ativo,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nome': nome,
      'nomeSocial': nomeSocial,
      'rg': rg,
      'cpf': cpf,
      'carteiraTrabalho': carteiraTrabalho,
      'tipoCarteira': tipoCarteira.name,
      'orgaoEmissor': orgaoEmissor,
      'uf': uf,
      'sexo': sexo,
      'genero': genero,
      'raca': raca,
      'estadoCivil': estadoCivil,
      'dataNascimento': dataNascimento.toIso8601String(),
      'naturalidade': naturalidade,
      'email': email,
      'telefone': telefone,
      'celular': celular,
      'endereco': endereco.toJson(),
      'responsavel': responsavel,
      'instituicaoId': instituicaoId,
      'curso': curso,
      'experiencias': experiencias.map((e) => e.toJson()).toList(),
    };
  }

  // Métodos utilitários
  String get cpfFormatted {
    if (cpf.length == 11) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9, 11)}';
    }
    return cpf;
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

  String get celularFormatted {
    final numbers = celular.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return celular;
  }

  String get enderecoCompleto {
    return endereco.enderecoCompleto;
  }

  String get nomeCompleto {
    if (nomeSocial != null && nomeSocial!.isNotEmpty) {
      return '$nome ($nomeSocial)';
    }
    return nome;
  }

  String get identificacao {
    return '$nome - CPF: $cpfFormatted';
  }

  int get idade {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;
    if (hoje.month < dataNascimento.month || 
        (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }
    return idade;
  }

  String get idadeFormatada {
    final anos = idade;
    if (anos == 1) return '1 ano';
    return '$anos anos';
  }

  bool get temNomeSocial => nomeSocial != null && nomeSocial!.isNotEmpty;
  bool get temResponsavel => responsavel != null && responsavel!.isNotEmpty;
  bool get temInstituicao => instituicaoId != null && instituicaoId!.isNotEmpty;
  bool get temCurso => curso != null && curso!.isNotEmpty;
  bool get temExperiencias => experiencias.isNotEmpty;
  bool get carteiraDigital => tipoCarteira == TipoCarteira.DIGITAL;

  int get totalExperiencias => experiencias.length;
  int get totalContratosAtivos => contratos.where((c) => c.status == 'ATIVO').length;

  // Validações
  bool get dadosCompletos {
    return nome.isNotEmpty &&
           rg.isNotEmpty &&
           cpf.isNotEmpty &&
           carteiraTrabalho.isNotEmpty &&
           orgaoEmissor.isNotEmpty &&
           uf.isNotEmpty &&
           sexo.isNotEmpty &&
           email.isNotEmpty &&
           telefone.isNotEmpty &&
           celular.isNotEmpty &&
           endereco.isValid &&
           (!menorIdade || (responsavel != null && responsavel!.isNotEmpty));
  }

  bool get documentosCompletos {
    return rg.isNotEmpty &&
           cpf.isNotEmpty &&
           carteiraTrabalho.isNotEmpty &&
           orgaoEmissor.isNotEmpty;
  }

  // Métodos de cópia
  JovemAprendiz copyWith({
    String? id,
    String? nome,
    String? nomeSocial,
    String? rg,
    String? cpf,
    String? carteiraTrabalho,
    TipoCarteira? tipoCarteira,
    String? orgaoEmissor,
    String? uf,
    String? sexo,
    String? genero,
    String? raca,
    String? estadoCivil,
    DateTime? dataNascimento,
    String? naturalidade,
    String? email,
    String? telefone,
    String? celular,
    Endereco? endereco,
    String? responsavel,
    bool? menorIdade,
    String? instituicaoId,
    String? curso,
    List<ExperienciaProfissional>? experiencias,
    String? usuarioId,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Contrato>? contratos,
  }) {
    return JovemAprendiz(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      nomeSocial: nomeSocial ?? this.nomeSocial,
      rg: rg ?? this.rg,
      cpf: cpf ?? this.cpf,
      carteiraTrabalho: carteiraTrabalho ?? this.carteiraTrabalho,
      tipoCarteira: tipoCarteira ?? this.tipoCarteira,
      orgaoEmissor: orgaoEmissor ?? this.orgaoEmissor,
      uf: uf ?? this.uf,
      sexo: sexo ?? this.sexo,
      genero: genero ?? this.genero,
      raca: raca ?? this.raca,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      naturalidade: naturalidade ?? this.naturalidade,
      email: email ?? this.email,
      telefone: telefone ?? this.telefone,
      celular: celular ?? this.celular,
      endereco: endereco ?? this.endereco,
      responsavel: responsavel ?? this.responsavel,
      menorIdade: menorIdade ?? this.menorIdade,
      instituicaoId: instituicaoId ?? this.instituicaoId,
      curso: curso ?? this.curso,
      experiencias: experiencias ?? this.experiencias,
      usuarioId: usuarioId ?? this.usuarioId,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contratos: contratos ?? this.contratos,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JovemAprendiz && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'JovemAprendiz(id: $id, nome: $nomeCompleto, cpf: $cpfFormatted, idade: $idadeFormatada)';
  }
}

class ExperienciaProfissional {
  final String? id;
  final String empresa;
  final String cargo;
  final String periodo;
  final String? descricao;
  final bool atual;
  final DateTime? dataInicio;
  final DateTime? dataFim;

  ExperienciaProfissional({
    this.id,
    required this.empresa,
    required this.cargo,
    required this.periodo,
    this.descricao,
    this.atual = false,
    this.dataInicio,
    this.dataFim,
  });

  factory ExperienciaProfissional.fromJson(Map<String, dynamic> json) {
    return ExperienciaProfissional(
      id: json['id'],
      empresa: json['empresa'],
      cargo: json['cargo'],
      periodo: json['periodo'],
      descricao: json['descricao'],
      atual: json['atual'] ?? false,
      dataInicio: json['dataInicio'] != null ? DateTime.parse(json['dataInicio']) : null,
      dataFim: json['dataFim'] != null ? DateTime.parse(json['dataFim']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa': empresa,
      'cargo': cargo,
      'periodo': periodo,
      'descricao': descricao,
      'atual': atual,
      'dataInicio': dataInicio?.toIso8601String(),
      'dataFim': dataFim?.toIso8601String(),
    };
  }

  String get periodoFormatado {
    if (dataInicio != null) {
      final inicio = '${dataInicio!.month}/${dataInicio!.year}';
      if (atual) {
        return '$inicio - Atual';
      } else if (dataFim != null) {
        final fim = '${dataFim!.month}/${dataFim!.year}';
        return '$inicio - $fim';
      }
      return inicio;
    }
    return periodo;
  }

  String get duracaoEmprago {
    if (dataInicio == null) return 'Não informado';
    
    final fim = atual ? DateTime.now() : dataFim ?? DateTime.now();
    final diferenca = fim.difference(dataInicio!);
    final meses = diferenca.inDays ~/ 30;
    
    if (meses < 1) return 'Menos de 1 mês';
    if (meses == 1) return '1 mês';
    if (meses < 12) return '$meses meses';
    
    final anos = meses ~/ 12;
    final mesesRestantes = meses % 12;
    
    if (anos == 1 && mesesRestantes == 0) return '1 ano';
    if (anos == 1) return '1 ano e $mesesRestantes ${mesesRestantes == 1 ? 'mês' : 'meses'}';
    if (mesesRestantes == 0) return '$anos anos';
    return '$anos anos e $mesesRestantes ${mesesRestantes == 1 ? 'mês' : 'meses'}';
  }

  String get resumo {
    return '$cargo na $empresa ($periodoFormatado)';
  }

  ExperienciaProfissional copyWith({
    String? id,
    String? empresa,
    String? cargo,
    String? periodo,
    String? descricao,
    bool? atual,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) {
    return ExperienciaProfissional(
      id: id ?? this.id,
      empresa: empresa ?? this.empresa,
      cargo: cargo ?? this.cargo,
      periodo: periodo ?? this.periodo,
      descricao: descricao ?? this.descricao,
      atual: atual ?? this.atual,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
    );
  }

  @override
  String toString() {
    return 'ExperienciaProfissional(empresa: $empresa, cargo: $cargo, periodo: $periodoFormatado)';
  }
}

// Enums relacionados
enum TipoCarteira {
  FISICA,
  DIGITAL,
}

enum SexoJovemAprendiz {
  M,
  F,
}

enum EstadoCivil {
  SOLTEIRO,
  CASADO,
  DIVORCIADO,
  VIUVO,
  UNIAO_ESTAVEL,
}

enum RacaCor {
  BRANCA,
  PRETA,
  PARDA,
  AMARELA,
  INDIGENA,
  NAO_DECLARADO,
}

// Extensions para facilitar o uso
extension TipoCarteiraExtension on TipoCarteira {
  String get displayName {
    switch (this) {
      case TipoCarteira.FISICA:
        return 'Física';
      case TipoCarteira.DIGITAL:
        return 'Digital';
    }
  }

  String get description {
    switch (this) {
      case TipoCarteira.FISICA:
        return 'Carteira de Trabalho impressa';
      case TipoCarteira.DIGITAL:
        return 'Carteira de Trabalho Digital (CTPS Digital)';
    }
  }
}

extension SexoJovemAprendizExtension on SexoJovemAprendiz {
  String get displayName {
    switch (this) {
      case SexoJovemAprendiz.M:
        return 'Masculino';
      case SexoJovemAprendiz.F:
        return 'Feminino';
    }
  }
}

extension EstadoCivilExtension on EstadoCivil {
  String get displayName {
    switch (this) {
      case EstadoCivil.SOLTEIRO:
        return 'Solteiro(a)';
      case EstadoCivil.CASADO:
        return 'Casado(a)';
      case EstadoCivil.DIVORCIADO:
        return 'Divorciado(a)';
      case EstadoCivil.VIUVO:
        return 'Viúvo(a)';
      case EstadoCivil.UNIAO_ESTAVEL:
        return 'União Estável';
    }
  }
}

extension RacaCorExtension on RacaCor {
  String get displayName {
    switch (this) {
      case RacaCor.BRANCA:
        return 'Branca';
      case RacaCor.PRETA:
        return 'Preta';
      case RacaCor.PARDA:
        return 'Parda';
      case RacaCor.AMARELA:
        return 'Amarela';
      case RacaCor.INDIGENA:
        return 'Indígena';
      case RacaCor.NAO_DECLARADO:
        return 'Não Declarado';
    }
  }
}

// Classe para validações
class JovemAprendizValidator {
  static String? validateNome(String? nome) {
    if (nome == null || nome.trim().isEmpty) {
      return 'Nome é obrigatório';
    }
    if (nome.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  static String? validateCPF(String? cpf) {
    if (cpf == null || cpf.isEmpty) {
      return 'CPF é obrigatório';
    }
    
    cpf = cpf.replaceAll(RegExp(r'\D'), '');
    
    if (cpf.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(cpf)) {
      return 'CPF inválido';
    }

    // Validação básica do algoritmo do CPF
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int firstDigit = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cpf[9]) != firstDigit) {
      return 'CPF inválido';
    }

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int secondDigit = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cpf[10]) != secondDigit) {
      return 'CPF inválido';
    }

    return null;
  }

  static String? validateRG(String? rg) {
    if (rg == null || rg.trim().isEmpty) {
      return 'RG é obrigatório';
    }
    if (rg.trim().length < 5) {
      return 'RG deve ter pelo menos 5 caracteres';
    }
    return null;
  }

  static String? validateCarteiraTrabalho(String? carteira) {
    if (carteira == null || carteira.trim().isEmpty) {
      return 'Carteira de trabalho é obrigatória';
    }
    if (carteira.trim().length < 5) {
      return 'Carteira de trabalho deve ter pelo menos 5 caracteres';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email é obrigatório';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Email inválido';
    }
    return null;
  }

  static String? validateTelefone(String? telefone) {
    if (telefone == null || telefone.isEmpty) {
      return 'Telefone é obrigatório';
    }
    
    telefone = telefone.replaceAll(RegExp(r'\D'), '');
    
    if (telefone.length < 10 || telefone.length > 11) {
      return 'Telefone inválido';
    }
    
    return null;
  }

  static String? validateDataNascimento(DateTime? data) {
    if (data == null) {
      return 'Data de nascimento é obrigatória';
    }
    
    final hoje = DateTime.now();
    final idade = hoje.year - data.year;
    
    if (idade < 14) {
      return 'Jovem aprendiz deve ter pelo menos 14 anos';
    }
    
    if (idade > 24) {
      return 'Jovem aprendiz deve ter no máximo 24 anos';
    }
    
    return null;
  }

  static String? validateResponsavel(String? responsavel, bool menorIdade) {
    if (menorIdade && (responsavel == null || responsavel.trim().isEmpty)) {
      return 'Responsável é obrigatório para menores de idade';
    }
    return null;
  }

  // Validação completa
  static Map<String, String> validateJovemAprendiz(JovemAprendiz jovemAprendiz) {
    Map<String, String> errors = {};

    final nomeError = validateNome(jovemAprendiz.nome);
    if (nomeError != null) errors['nome'] = nomeError;

    final cpfError = validateCPF(jovemAprendiz.cpf);
    if (cpfError != null) errors['cpf'] = cpfError;

    final rgError = validateRG(jovemAprendiz.rg);
    if (rgError != null) errors['rg'] = rgError;

    final carteiraError = validateCarteiraTrabalho(jovemAprendiz.carteiraTrabalho);
    if (carteiraError != null) errors['carteiraTrabalho'] = carteiraError;

    final emailError = validateEmail(jovemAprendiz.email);
    if (emailError != null) errors['email'] = emailError;

    final telefoneError = validateTelefone(jovemAprendiz.telefone);
    if (telefoneError != null) errors['telefone'] = telefoneError;

    final celularError = validateTelefone(jovemAprendiz.celular);
    if (celularError != null) errors['celular'] = celularError;

    final dataError = validateDataNascimento(jovemAprendiz.dataNascimento);
    if (dataError != null) errors['dataNascimento'] = dataError;

    final responsavelError = validateResponsavel(jovemAprendiz.responsavel, jovemAprendiz.menorIdade);
    if (responsavelError != null) errors['responsavel'] = responsavelError;

    return errors;
  }
}

// Classe para utilitários
class JovemAprendizUtils {
  // Calcular se é menor de idade baseado na data de nascimento
  static bool isMenorIdade(DateTime dataNascimento) {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;
    if (hoje.month < dataNascimento.month || 
        (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }
    return idade < 18;
  }

  // Calcular idade em anos
  static int calcularIdade(DateTime dataNascimento) {
    final hoje = DateTime.now();
    int idade = hoje.year - dataNascimento.year;
    if (hoje.month < dataNascimento.month || 
        (hoje.month == dataNascimento.month && hoje.day < dataNascimento.day)) {
      idade--;
    }
    return idade;
  }

  // Verificar se está na faixa etária permitida para jovem aprendiz (14-24 anos)
  static bool isIdadeValida(DateTime dataNascimento) {
    final idade = calcularIdade(dataNascimento);
    return idade >= 14 && idade <= 24;
  }

  // Formatar CPF
  static String formatCPF(String cpf) {
    final numbers = cpf.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '${numbers.substring(0, 3)}.${numbers.substring(3, 6)}.${numbers.substring(6, 9)}-${numbers.substring(9, 11)}';
    }
    return cpf;
  }

  // Formatar telefone
  static String formatTelefone(String telefone) {
    final numbers = telefone.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return telefone;
  }

  // Calcular tempo total de experiência profissional
  static String calcularTempoTotalExperiencia(List<ExperienciaProfissional> experiencias) {
    int totalMeses = 0;
    
    for (final exp in experiencias) {
      if (exp.dataInicio != null) {
        final fim = exp.atual ? DateTime.now() : exp.dataFim ?? DateTime.now();
        final diferenca = fim.difference(exp.dataInicio!);
        totalMeses += diferenca.inDays ~/ 30;
      }
    }
    
    if (totalMeses < 1) return 'Menos de 1 mês';
    if (totalMeses == 1) return '1 mês';
    if (totalMeses < 12) return '$totalMeses meses';
    
    final anos = totalMeses ~/ 12;
    final mesesRestantes = totalMeses % 12;
    
    if (anos == 1 && mesesRestantes == 0) return '1 ano';
    if (anos == 1) return '1 ano e $mesesRestantes ${mesesRestantes == 1 ? 'mês' : 'meses'}';
    if (mesesRestantes == 0) return '$anos anos';
    return '$anos anos e $mesesRestantes ${mesesRestantes == 1 ? 'mês' : 'meses'}';
  }
}

// Classes relacionadas (importações/dependências)
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