// lib/models/vaga.dart - VERSÃO ATUALIZADA PARA NOVA ESTRUTURA
import 'package:sistema_estagio/models/_organizacoes/empresa/empresa.dart';
import 'package:sistema_estagio/models/_core/endereco.dart';

class Vaga {
  // ==========================================
  // CAMPOS GERAIS
  // ==========================================

  /// Identificador da vaga (PK)
  final int? cdVaga;

  /// Status da vaga - OBRIGATÓRIO
  final String
      statusVaga; // enum: Aberta, Em Andamento, Aguardo retorno Empresa, Fechada, Cancelada
  final bool disponivelWeb; // Disponível no portal web (default true)
  final bool? exibirEmpresa;
  final bool? exibirSalario;
  final bool? exibirBeneficios;
  final String? nomeProcessoSeletivo;
  final String? nomeEmpresa;
  final String? qtdCandidatura;

  // ==========================================
  // DADOS DA VAGA
  // ==========================================

  /// Tipo do regime (enum) - OBRIGATÓRIO
  final TipoRegime tipoRegime; // JOVEM APRENDIZ ou ESTÁGIO

  /// Cidade da vaga (FK) - OBRIGATÓRIO
  final int? cidadeId;
  final String? nomeCidade;
  final String? ufCidade;

  /// Turno relacionado à vaga (FK) - OBRIGATÓRIO
  final int? turnoId;

  /// Setor da empresa
  final String? setor;

  final String? nomeSupervisor;

  /// Supervisor responsável (FK)
  final int? supervisorId;

  /// Atividades a serem desempenhadas - OBRIGATÓRIO
  final String atividades;

  /// Lista de cursos (multiselect) - OBRIGATÓRIO
  final List<int> cursosIds;
  final List<Map<String, dynamic>>? cursosDetalhes;
  final List<CursoResumo> cursos;

  /// Nível de ensino (FK) - OBRIGATÓRIO
  final int? nivelEnsinoId;

  /// Gênero preferencial
  final String? sexo; // Masculino, Feminino, Indiferente

  // Período acadêmico permitido
  final int? semestreInicio;
  final int? anoInicio;
  final int? semestreFim;
  final int? anoFim;

  // Horários dos turnos
  final String? horarioTurno1Inicio;
  final String? horarioTurno1Fim;
  final String? horarioTurno2Inicio; // opcional
  final String? horarioTurno2Fim; // opcional

  // ==========================================
  // DADOS DA ENTREVISTA
  // ==========================================

  final DateTime? dataEntrevista;
  final String? contatoEntrevista;
  final String? enderecoEntrevista;
  final String? telefoneEntrevista;

  // ==========================================
  // DADOS DO CONTRATO
  // ==========================================

  final DateTime? inicioContrato;
  final DateTime? fimContrato;
  final double? valorBolsa;
  final int? cargaHoraria; // horas semanais
  final bool transporte;
  final bool cestaBasica;
  final int? duracaoMeses;
  final String? observacaoVaga;

  // ==========================================
  // RELACIONAMENTOS
  // ==========================================

  /// Empresa vinculada (FK) - OBRIGATÓRIO
  final int cdEmpresa;

  // ==========================================
  // CAMPOS DE COMPATIBILIDADE
  // ==========================================
  final String empresaId;
  final Empresa? empresa;

  Vaga({
    // Campos Gerais
    this.cdVaga,
    this.statusVaga = 'Aberta',
    this.disponivelWeb = true,
    this.exibirEmpresa = true,
    this.exibirSalario = true,
    this.exibirBeneficios = true,
    this.nomeProcessoSeletivo,
    this.nomeEmpresa,
    this.qtdCandidatura,

    // Dados da Vaga
    this.tipoRegime = TipoRegime.ESTAGIO,
    this.cidadeId,
    this.turnoId,
    this.setor,
    this.nomeCidade,
    this.ufCidade,
    this.nomeSupervisor,
    this.supervisorId,
    required this.atividades,
    this.cursosIds = const [],
    this.cursosDetalhes,
    this.cursos = const [],

    // Dados da Entrevista
    this.dataEntrevista,
    this.contatoEntrevista,
    this.enderecoEntrevista,
    this.telefoneEntrevista,

    // Dados do Contrato
    this.inicioContrato,
    this.fimContrato,
    this.valorBolsa,
    this.cargaHoraria,
    this.transporte = false,
    this.cestaBasica = false,
    this.duracaoMeses,
    this.observacaoVaga,

    // Relacionamentos
    required this.cdEmpresa,
    String? empresaId,
    this.empresa,
    this.nivelEnsinoId,
    this.sexo = 'Indiferente',
    this.semestreInicio,
    this.anoInicio,
    this.semestreFim,
    this.anoFim,
    this.horarioTurno1Inicio,
    this.horarioTurno1Fim,
    this.horarioTurno2Inicio,
    this.horarioTurno2Fim,
  }) : empresaId = empresaId ?? cdEmpresa.toString();

  // ==========================================
  // MÉTODOS DE CONVERSÃO SEGURA
  // ==========================================

  static int? _safeParseInt(dynamic value, [int? defaultValue]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) return doubleValue.toInt();
    }
    return defaultValue;
  }

  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _safeParseBool(dynamic value, [bool defaultValue = false]) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 's' || lower == 'sim';
    }
    return defaultValue;
  }

  static DateTime? _safeParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static List<int> _safeParseIntList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => _safeParseInt(e) ?? 0)
          .where((e) => e > 0)
          .toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((e) => _safeParseInt(e.trim()))
          .where((e) => e != null && e > 0)
          .cast<int>()
          .toList();
    }
    return [];
  }

  static List<String> _safeParseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  factory Vaga.fromJson(Map<String, dynamic> json) {
    try {
      // ✅ CORREÇÃO: Processar cursosids corretamente ANTES de criar o objeto
      List<int> cursosIdsList = [];
      List<Map<String, dynamic>>? cursosDetalhesList;
      List<CursoResumo> cursosResumoList = [];

      if (json['cursos'] != null) {
        cursosResumoList = _processarCursosResumo(json['cursos']);
        if (cursosResumoList.isNotEmpty) {
          cursosIdsList = cursosResumoList
              .map((curso) => curso.cdCurso)
              .whereType<int>()
              .toList();
          cursosDetalhesList =
              cursosResumoList.map((curso) => curso.toJson()).toList();
        }
      }

      if (cursosIdsList.isEmpty) {
        cursosIdsList = _processarCursosIds(json['cursosids']);
      }

      cursosDetalhesList ??= _processarCursosDetalhes(json['cursosids']);

      final empresaJson = json['empresa'] as Map<String, dynamic>?;
      final cdEmpresaValor = _safeParseInt(json['cd_empresa']) ??
          _safeParseInt(empresaJson?['cd_empresa']) ??
          0;
      final empresaIdValor = json['cd_empresa']?.toString() ??
          empresaJson?['cd_empresa']?.toString() ??
          '';

      return Vaga(
        // Campos Gerais
        cdVaga: _safeParseInt(json['cd_vaga']),
        statusVaga: json['status']?.toString() ?? 'Aberta',
        disponivelWeb: _safeParseBool(json['disponivel_web'], true),
        exibirEmpresa: _safeParseBool(json['exibir_empresa'], true),
        exibirSalario: _safeParseBool(json['exibir_salario'], true),
        exibirBeneficios: _safeParseBool(json['exibir_beneficios'], true),
        nomeProcessoSeletivo: json['nome_processo_seletivo']?.toString(),
        nomeEmpresa: json['nome_empresa']?.toString(),
        qtdCandidatura: json['qtd_candidatura']?.toString(),
        // Dados da Vaga
        tipoRegime:
            _tipoRegimeFromString(json['id_regime_contratacao']?.toString()),
        cidadeId: _safeParseInt(json['cd_cidade']),
        turnoId: _safeParseInt(json['cd_turno']),
        setor: json['setor']?.toString(),
        nomeCidade: json['nome_cidade']?.toString(),
        ufCidade: json['uf_cidade']?.toString(),
        nomeSupervisor: json['nome_supervisor']?.toString(),
        supervisorId: _safeParseInt(json['cd_supervisor']),
        atividades: json['atividades']?.toString() ?? '',
        cursosIds: cursosIdsList,
        cursosDetalhes: cursosDetalhesList,
        cursos: cursosResumoList,

        nivelEnsinoId: _safeParseInt(json['cd_nivel_formacao']),
        sexo: json['sexo']?.toString() ?? 'Indiferente',
        semestreInicio: _safeParseInt(json['semestre_inicio']),
        anoInicio: _safeParseInt(json['ano_inicio']),
        semestreFim: _safeParseInt(json['semestre_fim']),
        anoFim: _safeParseInt(json['ano_fim']),
        horarioTurno1Inicio: json['horario_turno1_inicio']?.toString(),
        horarioTurno1Fim: json['horario_turno1_fim']?.toString(),
        horarioTurno2Inicio: json['horario_turno2_inicio']?.toString(),
        horarioTurno2Fim: json['horario_turno2_fim']?.toString(),

        // Dados da Entrevista
        dataEntrevista: _safeParseDateTime(json['data_entrevista']),
        contatoEntrevista: json['contato_entrevista']?.toString(),
        enderecoEntrevista: json['endereco_entrevista']?.toString(),
        telefoneEntrevista: json['telefone_entrevista']?.toString(),

        // Dados do Contrato
        inicioContrato: _safeParseDateTime(
            json['data_inicio_contrato'] ?? json['data_inicio_contrato']),
        fimContrato: _safeParseDateTime(
            json['data_fim_contrato'] ?? json['data_fim_contrato']),
        valorBolsa: _safeParseDouble(json['valor_bolsa']),
        cargaHoraria: _safeParseInt(json['carga_horaria']),
        transporte: _safeParseBool(json['transporte']),
        cestaBasica: _safeParseBool(json['cesta_basica']),
        duracaoMeses: _safeParseInt(json['duracao_meses']),
        observacaoVaga:
            json['observacao']?.toString() ?? json['observacao']?.toString(),

        // Relacionamentos
        cdEmpresa: cdEmpresaValor,
        empresaId: empresaIdValor,
        empresa: empresaJson != null ? Empresa.fromJson(empresaJson) : null,
      );
    } catch (e, stackTrace) {
      print('❌ Erro em Vaga.fromJson: $e');
      print('JSON recebido: $json');
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  static List<int> _processarCursosIds(dynamic cursosidsJson) {
    try {
      if (cursosidsJson == null) return [];

      print(
          '🔍 [PROCESSAR_CURSOS_IDS] Tipo recebido: ${cursosidsJson.runtimeType}');
      print('🔍 [PROCESSAR_CURSOS_IDS] Valor: $cursosidsJson');

      if (cursosidsJson is List) {
        List<int> cursosIds = [];

        for (var item in cursosidsJson) {
          print('  - Processando item: $item (${item.runtimeType})');

          // Caso 1: item é um inteiro direto (formato: [14, 15])
          if (item is int) {
            cursosIds.add(item);
            print('    ✅ Adicionado int direto: $item');
          }
          // Caso 2: item é um objeto (formato: [{"cd_curso": 14}])
          else if (item is Map<String, dynamic>) {
            final cdCurso = _safeParseInt(item['cd_curso']);
            if (cdCurso != null && cdCurso > 0) {
              cursosIds.add(cdCurso);
              print('    ✅ Adicionado do objeto: $cdCurso');
            }
          }
          // Caso 3: item é string que pode ser convertida
          else if (item is String) {
            final cursoId = int.tryParse(item);
            if (cursoId != null && cursoId > 0) {
              cursosIds.add(cursoId);
              print('    ✅ Adicionado string convertida: $cursoId');
            }
          } else {
            print('    ⚠️ Tipo não suportado: ${item.runtimeType}');
          }
        }

        print('✅ [PROCESSAR_CURSOS_IDS] Resultado final: $cursosIds');
        return cursosIds;
      }

      if (cursosidsJson is String) {
        // Se é string: "1,2,3"
        return _safeParseIntList(cursosidsJson);
      }

      print('⚠️ [PROCESSAR_CURSOS_IDS] Formato não reconhecido');
      return [];
    } catch (e, stackTrace) {
      print('⚠️ [PROCESSAR_CURSOS_IDS] Erro: $e');
      print('📍 StackTrace: $stackTrace');
      return [];
    }
  }

// ✅ MÉTODO CORRIGIDO para processar cursosDetalhes
  static List<Map<String, dynamic>>? _processarCursosDetalhes(
      dynamic cursosidsJson) {
    try {
      if (cursosidsJson == null) return null;

      print(
          '🔍 [PROCESSAR_CURSOS_DETALHES] Tipo recebido: ${cursosidsJson.runtimeType}');

      if (cursosidsJson is List) {
        List<Map<String, dynamic>> detalhes = [];

        for (var item in cursosidsJson) {
          // Caso 1: item é um objeto - salvar diretamente
          if (item is Map<String, dynamic>) {
            detalhes.add(Map<String, dynamic>.from(item));
            print('  ✅ Objeto adicionado aos detalhes');
          }
          // Caso 2: item é int - criar objeto básico
          else if (item is int) {
            detalhes.add({
              'cd_curso': item,
              'descricao': 'Curso ID $item', // Placeholder
            });
            print('  ✅ Int convertido para objeto nos detalhes: $item');
          }
        }

        return detalhes.isNotEmpty ? detalhes : null;
      }

      return null;
    } catch (e, stackTrace) {
      print('⚠️ [PROCESSAR_CURSOS_DETALHES] Erro: $e');
      print('📍 StackTrace: $stackTrace');
      return null;
    }
  }

  static List<CursoResumo> _processarCursosResumo(dynamic cursosJson) {
    if (cursosJson == null) return [];
    final List<CursoResumo> cursos = [];

    if (cursosJson is List) {
      for (final item in cursosJson) {
        if (item is Map<String, dynamic>) {
          cursos.add(CursoResumo.fromJson(item));
        } else if (item is Map) {
          cursos.add(CursoResumo.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value))));
        } else if (item is int) {
          cursos.add(CursoResumo(cdCurso: item));
        } else if (item is String) {
          final id = int.tryParse(item);
          cursos.add(CursoResumo(cdCurso: id));
        }
      }
    } else if (cursosJson is Map<String, dynamic>) {
      cursos.add(CursoResumo.fromJson(cursosJson));
    }

    return cursos;
  }

  static TipoRegime _tipoVagaFromRegime(dynamic regime) {
    print(
        '🔄 [TIPO_REGIME] Convertendo regime: $regime (${regime.runtimeType})');

    // Se já é TipoRegime, retornar diretamente
    if (regime is TipoRegime) {
      print('   - Já é TipoRegime: $regime');
      return regime;
    }

    // Se é int, converter
    if (regime is int) {
      switch (regime) {
        case 1:
          print('   - Convertido para JOVEM_APRENDIZ (1)');
          return TipoRegime.JOVEM_APRENDIZ;
        case 2:
          print('   - Convertido para ESTAGIO (2)');
          return TipoRegime.ESTAGIO;
        default:
          print(
              '⚠️ [TIPO_REGIME] ID desconhecido: $regime, usando ESTAGIO como padrão');
          return TipoRegime.ESTAGIO;
      }
    }

    // Se é String, tentar converter para int primeiro
    if (regime is String) {
      final regimeId = int.tryParse(regime);
      if (regimeId != null) {
        print('   - String convertida para int: $regimeId');
        return _tipoVagaFromRegime(regimeId); // Recursão com int
      } else {
        print(
            '⚠️ [TIPO_REGIME] String não numérica: $regime, usando ESTAGIO como padrão');
        return TipoRegime.ESTAGIO;
      }
    }

    // Se é null ou outro tipo
    print(
        '⚠️ [TIPO_REGIME] Tipo não suportado ou null: $regime (${regime.runtimeType}), usando ESTAGIO como padrão');
    return TipoRegime.ESTAGIO;
  }

  static TipoRegime _tipoRegimeFromString(String? valor) {
    if (valor == null) return TipoRegime.ESTAGIO;

    switch (valor.toLowerCase()) {
      case 'jovem aprendiz':
      case 'jovem_aprendiz':
      case 'aprendiz':
      case '1':
        return TipoRegime.JOVEM_APRENDIZ;
      case 'estagio':
      case 'estágio':
      case '2':
        return TipoRegime.ESTAGIO;
      default:
        return TipoRegime.ESTAGIO;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      // Campos Gerais
      'cd_vaga': cdVaga,
      'status': statusVaga,
      'disponivel_web': disponivelWeb,
      'exibir_empresa': exibirEmpresa,
      'exibir_salario': exibirSalario,
      'exibir_beneficios': exibirBeneficios,
      'nome_processo_seletivo': nomeProcessoSeletivo,
      'nome_empresa': nomeEmpresa,
      'qtd_candidatura': qtdCandidatura,

      // Dados da Vaga
      'id_regime_contratacao': _tipoRegimeToId(tipoRegime),
      'cd_cidade': cidadeId,
      'nome_cidade': nomeCidade,
      'uf_cidade': ufCidade,
      'cd_turno': turnoId,
      'setor': setor,
      'cd_supervisor': supervisorId,
      'atividades': atividades,
      if (cursosIds.isNotEmpty) 'cursosids': cursosIds,
      if (cursosDetalhes != null && cursosDetalhes!.isNotEmpty)
        'cursosDetalhes': cursosDetalhes,
      'cd_nivel_formacao': nivelEnsinoId,
      'sexo': sexo,
      'semestre_inicio': semestreInicio,
      'ano_inicio': anoInicio,
      'semestre_fim': semestreFim,
      'ano_fim': anoFim,
      'horario_turno1_inicio': horarioTurno1Inicio,
      'horario_turno1_fim': horarioTurno1Fim,
      'horario_turno2_inicio': horarioTurno2Inicio,
      'horario_turno2_fim': horarioTurno2Fim,

      // Dados da Entrevista
      'data_entrevista': dataEntrevista?.toIso8601String().split('T')[0],
      'contato_entrevista': contatoEntrevista,
      'endereco_entrevista': enderecoEntrevista,
      'telefone_entrevista': telefoneEntrevista,

      // Dados do Contrato
      'data_inicio_contrato': inicioContrato?.toIso8601String().split('T')[0],
      'data_fim_contrato': fimContrato?.toIso8601String().split('T')[0],
      'valor_bolsa': valorBolsa,
      'carga_horaria': cargaHoraria,
      'transporte': transporte,
      'cesta_basica': cestaBasica,
      'duracao_meses': duracaoMeses,
      'observacao': observacaoVaga,

      // Relacionamentos
      'cd_empresa': cdEmpresa,
    };
  }

  static int _tipoRegimeParaId(TipoRegime tipoRegime) {
    switch (tipoRegime) {
      case TipoRegime.JOVEM_APRENDIZ:
        return 1;
      case TipoRegime.ESTAGIO:
        return 2;
    }
  }

  int get idRegimeContratacao => _tipoRegimeParaId(tipoRegime);

  /// Nome formatado do tipo de regime
  String get tipoFormatado => tipoRegime.displayName;

  Map<String, dynamic> toCreateJson() {
    return {
      // ✅ CAMPOS PRINCIPAIS
      "status": statusVaga,
      "disponivel_web": disponivelWeb,
      "exibir_empresa": exibirEmpresa,
      "exibir_salario": exibirSalario,
      "exibir_beneficios": exibirBeneficios,
      "nome_processo_seletivo": nomeProcessoSeletivo,
      "nome_empresa": nomeEmpresa,
      "qtd_candidatura": qtdCandidatura,
      // ✅ REGIME DE CONTRATAÇÃO
      "id_regime_contratacao": _tipoRegimeToId(tipoRegime),          
      // ✅ LOCALIZAÇÃO E TURNO
      "cd_cidade": cidadeId,
      "cd_turno": turnoId,
      "nome_cidade": nomeCidade,
      "uf_cidade": ufCidade,

      // ✅ DADOS DA VAGA
      "setor": setor,
      "cd_supervisor": supervisorId,
      "atividades": atividades,
      "sexo": sexo,

      // ✅ PERÍODO ACADÊMICO
      "semestre_inicio": semestreInicio,
      "ano_inicio": anoInicio,
      "semestre_fim": semestreFim,
      "ano_fim": anoFim,

      // ✅ HORÁRIOS
      "horario_turno1_inicio": horarioTurno1Inicio,
      "horario_turno1_fim": horarioTurno1Fim,
      "horario_turno2_inicio": horarioTurno2Inicio,
      "horario_turno2_fim": horarioTurno2Fim,

      // ✅ DADOS DA ENTREVISTA
      "data_entrevista": dataEntrevista
          ?.toIso8601String()
          .split('T')[0], // Formato: YYYY-MM-DD
      "contato_entrevista": contatoEntrevista,
      "endereco_entrevista": enderecoEntrevista,
      "telefone_entrevista": telefoneEntrevista,

      // ✅ DADOS DO CONTRATO
      "data_inicio_contrato": inicioContrato
          ?.toIso8601String()
          .split('T')[0], // Formato: YYYY-MM-DD
      "data_fim_contrato":
          fimContrato?.toIso8601String().split('T')[0], // Formato: YYYY-MM-DD
      "valor_bolsa": valorBolsa,
      "carga_horaria": cargaHoraria,
      "transporte": transporte,
      "cesta_basica": cestaBasica,
      "duracao_meses": duracaoMeses,
      "observacao": observacaoVaga,

      // ✅ EMPRESA
      "cd_empresa": cdEmpresa,

      // ✅ CURSOS E NÍVEL (se necessário - verificar com a API)
      if (cursosIds.isNotEmpty) "cursosids": cursosIds,
      if (nivelEnsinoId != null) "cd_nivel_formacao": nivelEnsinoId,
    }..removeWhere((key, value) => value == null); // Remove campos null
  }

// ✅ MÉTODO AUXILIAR PARA CONVERTER TIPO DE REGIME
  int _tipoRegimeToId(TipoRegime tipoRegime) {
    switch (tipoRegime) {
      case TipoRegime.ESTAGIO:
        return 2;
      case TipoRegime.JOVEM_APRENDIZ:
        return 1;
      default:
        return 2; // Default para estágio
    }
  }

  // ==========================================
  // GETTERS E UTILIDADES
  // ==========================================

  String get tipoRegimeFormatado => tipoRegime.displayName;
  String get statusFormatado => statusVaga;
  bool get isAtiva => statusVaga.toLowerCase() == 'aberta';
  bool get isExpirada =>
      fimContrato != null && fimContrato!.isBefore(DateTime.now());
  bool get isUrgente =>
      fimContrato != null &&
      fimContrato!.difference(DateTime.now()).inDays <= 7;

  String get periodoAcademico {
    if (semestreInicio != null && anoInicio != null) {
      String inicio = '$semestreInicio/$anoInicio';
      if (semestreFim != null && anoFim != null) {
        return '$inicio - $semestreFim/$anoFim';
      }
      return 'A partir de $inicio';
    }
    return '';
  }

  Vaga atualizarCursos(List<int> novosCursosIds,
      [List<Map<String, dynamic>>? novosDetalhes]) {
    return copyWith(
      cursosIds: novosCursosIds,
      cursosDetalhes: novosDetalhes,
    );
  }

  /// Adiciona um curso à vaga
  Vaga adicionarCurso(int cursoId, [Map<String, dynamic>? detalheCurso]) {
    final novosIds = List<int>.from(cursosIds ?? []);
    if (!novosIds.contains(cursoId)) {
      novosIds.add(cursoId);
    }

    List<Map<String, dynamic>>? novosDetalhes;
    if (cursosDetalhes != null && detalheCurso != null) {
      novosDetalhes = List<Map<String, dynamic>>.from(cursosDetalhes!);
      // Remover se já existe e adicionar o novo
      novosDetalhes.removeWhere((curso) => curso['cd_curso'] == cursoId);
      novosDetalhes.add(detalheCurso);
    }

    return copyWith(cursosIds: novosIds, cursosDetalhes: novosDetalhes);
  }

  /// Remove um curso da vaga
  Vaga removerCurso(int cursoId) {
    final novosIds = List<int>.from(cursosIds ?? []);
    novosIds.remove(cursoId);

    List<Map<String, dynamic>>? novosDetalhes;
    if (cursosDetalhes != null) {
      novosDetalhes = List<Map<String, dynamic>>.from(cursosDetalhes!);
      novosDetalhes.removeWhere((curso) => curso['cd_curso'] == cursoId);
    }

    return copyWith(cursosIds: novosIds, cursosDetalhes: novosDetalhes);
  }

  String get beneficiosCompletos {
    List<String> beneficiosList = [];
    if (valorBolsa != null && valorBolsa! > 0) {
      beneficiosList.add('Bolsa: R\$ ${valorBolsa!.toStringAsFixed(2)}');
    }
    if (transporte) {
      beneficiosList.add('Auxílio Transporte');
    }
    if (cestaBasica) {
      beneficiosList.add('Cesta Básica');
    }
    return beneficiosList.isEmpty ? 'Não informado' : beneficiosList.join(', ');
  }

  Vaga copyWith({
    int? cdVaga,
    String? statusVaga,
    bool? disponivelWeb,
    bool? exibirEmpresa,
    bool? exibirSalario,
    bool? exibirBeneficios,
    String? nomeProcessoSeletivo,
    String? nomeEmpresa,
    String? qtdCandidatura,
    TipoRegime? tipoRegime,
    int? cidadeId,
    int? turnoId,
    String? setor,
    String? nomeCidade,
    String? ufCidade,
    String? nomeSupervisor,
    int? supervisorId,
    String? atividades,
    List<int>? cursosIds,
    List<Map<String, dynamic>>? cursosDetalhes,
    List<CursoResumo>? cursos,
    int? nivelEnsinoId,
    String? sexo,
    int? semestreInicio,
    int? anoInicio,
    int? semestreFim,
    int? anoFim,
    String? horarioTurno1Inicio,
    String? horarioTurno1Fim,
    String? horarioTurno2Inicio,
    String? horarioTurno2Fim,
    DateTime? dataEntrevista,
    String? contatoEntrevista,
    String? enderecoEntrevista,
    String? telefoneEntrevista,
    DateTime? inicioContrato,
    DateTime? fimContrato,
    double? valorBolsa,
    int? cargaHoraria,
    bool? transporte,
    bool? cestaBasica,
    int? duracaoMeses,
    String? observacaoVaga,
    int? cdEmpresa,
  }) {
    return Vaga(
      cdVaga: cdVaga ?? this.cdVaga,
      statusVaga: statusVaga ?? this.statusVaga,
      disponivelWeb: disponivelWeb ?? this.disponivelWeb,
      exibirEmpresa: exibirEmpresa ?? this.exibirEmpresa,
      exibirSalario: exibirSalario ?? this.exibirSalario,
      exibirBeneficios: exibirBeneficios ?? this.exibirBeneficios,
      nomeProcessoSeletivo: nomeProcessoSeletivo ?? this.nomeProcessoSeletivo,
      nomeEmpresa: nomeEmpresa ?? this.nomeEmpresa,
      qtdCandidatura: qtdCandidatura ?? this.qtdCandidatura,
      tipoRegime: tipoRegime ?? this.tipoRegime,
      cidadeId: cidadeId ?? this.cidadeId,
      turnoId: turnoId ?? this.turnoId,
      setor: setor ?? this.setor,
      nomeCidade: nomeCidade ?? this.nomeCidade,
      ufCidade: ufCidade ?? this.ufCidade,
      nomeSupervisor: nomeSupervisor ?? this.nomeSupervisor,
      supervisorId: supervisorId ?? this.supervisorId,
      atividades: atividades ?? this.atividades,
      cursosIds: cursosIds ?? this.cursosIds,
      cursosDetalhes: cursosDetalhes ?? this.cursosDetalhes,
      cursos: cursos ?? this.cursos,
      nivelEnsinoId: nivelEnsinoId ?? this.nivelEnsinoId,
      sexo: sexo ?? this.sexo,
      semestreInicio: semestreInicio ?? this.semestreInicio,
      anoInicio: anoInicio ?? this.anoInicio,
      semestreFim: semestreFim ?? this.semestreFim,
      anoFim: anoFim ?? this.anoFim,
      horarioTurno1Inicio: horarioTurno1Inicio ?? this.horarioTurno1Inicio,
      horarioTurno1Fim: horarioTurno1Fim ?? this.horarioTurno1Fim,
      horarioTurno2Inicio: horarioTurno2Inicio ?? this.horarioTurno2Inicio,
      horarioTurno2Fim: horarioTurno2Fim ?? this.horarioTurno2Fim,
      dataEntrevista: dataEntrevista ?? this.dataEntrevista,
      contatoEntrevista: contatoEntrevista ?? this.contatoEntrevista,
      enderecoEntrevista: enderecoEntrevista ?? this.enderecoEntrevista,
      telefoneEntrevista: telefoneEntrevista ?? this.telefoneEntrevista,
      inicioContrato: inicioContrato ?? this.inicioContrato,
      fimContrato: fimContrato ?? this.fimContrato,
      valorBolsa: valorBolsa ?? this.valorBolsa,
      cargaHoraria: cargaHoraria ?? this.cargaHoraria,
      transporte: transporte ?? this.transporte,
      cestaBasica: cestaBasica ?? this.cestaBasica,
      duracaoMeses: duracaoMeses ?? this.duracaoMeses,
      observacaoVaga: observacaoVaga ?? this.observacaoVaga,
      cdEmpresa: cdEmpresa ?? this.cdEmpresa,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vaga && (other.cdVaga == cdVaga);
  }

  @override
  int get hashCode => cdVaga?.hashCode ?? 0;

  @override
  String toString() {
    return 'Vaga(cdVaga: $cdVaga, atividades: ${atividades.length > 50 ? '${atividades.substring(0, 50)}...' : atividades}, empresa: $cdEmpresa, tipo: $tipoRegimeFormatado, status: $statusVaga)';
  }
}

// ==========================================
// ENUMS E CLASSES AUXILIARES
// ==========================================

enum TipoRegime {
  ESTAGIO,
  JOVEM_APRENDIZ;

  String get displayName {
    switch (this) {
      case TipoRegime.ESTAGIO:
        return 'Estágio';
      case TipoRegime.JOVEM_APRENDIZ:
        return 'Jovem Aprendiz';
    }
  }

  int get id {
    switch (this) {
      case TipoRegime.JOVEM_APRENDIZ:
        return 1;
      case TipoRegime.ESTAGIO:
        return 2;
    }
  }

  static TipoRegime fromId(int id) {
    switch (id) {
      case 1:
        return TipoRegime.JOVEM_APRENDIZ;
      case 2:
        return TipoRegime.ESTAGIO;
      default:
        return TipoRegime.ESTAGIO;
    }
  }
}

enum StatusVaga {
  ABERTA,
  EM_ANDAMENTO,
  AGUARDO_RETORNO_EMPRESA,
  FECHADA,
  CANCELADA,
}

enum SexoVaga {
  MASCULINO,
  FEMININO,
  INDIFERENTE,
}

// Extensions
extension TipoRegimeExtension on TipoRegime {
  String get displayName {
    switch (this) {
      case TipoRegime.ESTAGIO:
        return 'Estágio';
      case TipoRegime.JOVEM_APRENDIZ:
        return 'Jovem Aprendiz';
    }
  }

  String get description {
    switch (this) {
      case TipoRegime.ESTAGIO:
        return 'Vaga de estágio curricular ou extracurricular';
      case TipoRegime.JOVEM_APRENDIZ:
        return 'Programa de Jovem Aprendiz (14-24 anos)';
    }
  }
}

extension StatusVagaExtension on StatusVaga {
  String get displayName {
    switch (this) {
      case StatusVaga.ABERTA:
        return 'Aberta';
      case StatusVaga.EM_ANDAMENTO:
        return 'Em Andamento';
      case StatusVaga.AGUARDO_RETORNO_EMPRESA:
        return 'Aguardo retorno Empresa';
      case StatusVaga.FECHADA:
        return 'Fechada';
      case StatusVaga.CANCELADA:
        return 'Cancelada';
    }
  }
}

extension SexoVagaExtension on SexoVaga {
  String get displayName {
    switch (this) {
      case SexoVaga.MASCULINO:
        return 'Masculino';
      case SexoVaga.FEMININO:
        return 'Feminino';
      case SexoVaga.INDIFERENTE:
        return 'Indiferente';
    }
  }
}

// ==========================================
// CLASSES AUXILIARES PARA COMPATIBILIDADE
// ==========================================

class Candidatura {
  final String? id;
  final String vagaId;
  final String candidatoId;
  final TipoCandidato tipo;
  final StatusCandidatura status;
  final String? observacoes;
  final DateTime? dataCandidatura;
  final DateTime? dataResposta;
  final String? motivoRejeicao;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final dynamic candidato;
  final Vaga? vaga;

  Candidatura({
    this.id,
    required this.vagaId,
    required this.candidatoId,
    required this.tipo,
    this.status = StatusCandidatura.PENDENTE,
    this.observacoes,
    this.dataCandidatura,
    this.dataResposta,
    this.motivoRejeicao,
    this.createdAt,
    this.updatedAt,
    this.candidato,
    this.vaga,
  });

  factory Candidatura.fromJson(Map<String, dynamic> json) {
    return Candidatura(
      id: json['id']?.toString(),
      vagaId: json['cd_vaga']?.toString() ?? '',
      candidatoId: json['candidatoId']?.toString() ??
          json['cd_candidato']?.toString() ??
          '',
      tipo: TipoCandidato.values.firstWhere(
        (e) => e.name == json['tipo'],
        orElse: () => TipoCandidato.ESTAGIARIO,
      ),
      status: StatusCandidatura.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StatusCandidatura.PENDENTE,
      ),
      observacoes: json['observacoes'],
      dataCandidatura: Vaga._safeParseDateTime(
          json['dataCandidatura'] ?? json['data_candidatura']),
      dataResposta: Vaga._safeParseDateTime(
          json['dataResposta'] ?? json['data_resposta']),
      motivoRejeicao: json['motivoRejeicao'] ?? json['motivo_rejeicao'],
      candidato: json['candidato'],
      vaga: json['vaga'] != null ? Vaga.fromJson(json['vaga']) : null,
    );
  }

  String get statusFormatado => status.displayName;
  String get tipoFormatado => tipo.displayName;
  String get nomeCandidato =>
      candidato?['nome'] ?? candidato?['nome_completo'] ?? 'N/A';
  String get nomeVaga => vaga?.atividades ?? 'N/A';
}

enum TipoVaga {
  ESTAGIO,
  JOVEM_APRENDIZ,
}

enum StatusCandidatura {
  PENDENTE,
  APROVADA,
  REJEITADA,
  EM_PROCESSO,
}

enum TipoCandidato {
  ESTAGIARIO,
  JOVEM_APRENDIZ,
}

enum NivelEnsino {
  FUNDAMENTAL,
  MEDIO,
  TECNICO,
  SUPERIOR,
  POS_GRADUACAO,
}

extension TipoVagaExtension on TipoVaga {
  String get displayName {
    switch (this) {
      case TipoVaga.ESTAGIO:
        return 'Estágio';
      case TipoVaga.JOVEM_APRENDIZ:
        return 'Jovem Aprendiz';
    }
  }

  String get description {
    switch (this) {
      case TipoVaga.ESTAGIO:
        return 'Vaga de estágio curricular ou extracurricular';
      case TipoVaga.JOVEM_APRENDIZ:
        return 'Programa de Jovem Aprendiz (14-24 anos)';
    }
  }
}

extension StatusCandidaturaExtension on StatusCandidatura {
  String get displayName {
    switch (this) {
      case StatusCandidatura.PENDENTE:
        return 'Pendente';
      case StatusCandidatura.APROVADA:
        return 'Aprovada';
      case StatusCandidatura.REJEITADA:
        return 'Rejeitada';
      case StatusCandidatura.EM_PROCESSO:
        return 'Em Processo';
    }
  }
}

extension TipoCandidatoExtension on TipoCandidato {
  String get displayName {
    switch (this) {
      case TipoCandidato.ESTAGIARIO:
        return 'Estagiário';
      case TipoCandidato.JOVEM_APRENDIZ:
        return 'Jovem Aprendiz';
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
    }
  }
}

// ==========================================
// CLASSE PARA VALIDAÇÕES ATUALIZADA
// ==========================================
class VagaValidator {
  static Map<String, String> validateVaga(Vaga vaga) {
    Map<String, String> errors = {};

    // Campos obrigatórios
    if (vaga.atividades.trim().isEmpty) {
      errors['atividades'] = 'Atividades são obrigatórias';
    }

    if (vaga.cdEmpresa <= 0) {
      errors['cd_empresa'] = 'Empresa é obrigatória';
    }

    if (vaga.statusVaga.trim().isEmpty) {
      errors['status'] = 'Status é obrigatório';
    }

    if (vaga.cursosIds.isEmpty) {
      errors['cursosids'] = 'Pelo menos um curso deve ser selecionado';
    }

    // Validações opcionais
    if (vaga.cargaHoraria != null) {
      if (vaga.cargaHoraria! <= 0) {
        errors['carga_horaria'] = 'Carga horária deve ser maior que 0';
      }
      if (vaga.cargaHoraria! > 44) {
        errors['carga_horaria'] =
            'Carga horária não pode exceder 44 horas semanais';
      }
    }

    if (vaga.valorBolsa != null && vaga.valorBolsa! < 0) {
      errors['valor_bolsa'] = 'Valor da bolsa não pode ser negativo';
    }

    if (vaga.duracaoMeses != null) {
      if (vaga.duracaoMeses! <= 0) {
        errors['duracao_meses'] = 'Duração deve ser maior que 0';
      }
      if (vaga.duracaoMeses! > 24) {
        errors['duracao_meses'] = 'Duração não pode exceder 24 meses';
      }
    }

    // Validação de período acadêmico
    if (vaga.semestreInicio != null &&
        (vaga.semestreInicio! < 1 || vaga.semestreInicio! > 12)) {
      errors['semestre_inicio'] = 'Semestre de início deve ser entre 1 e 12';
    }

    if (vaga.semestreFim != null &&
        (vaga.semestreFim! < 1 || vaga.semestreFim! > 12)) {
      errors['semestre_fim'] = 'Semestre de fim deve ser entre 1 e 12';
    }

    // Validação de datas de contrato
    if (vaga.inicioContrato != null && vaga.fimContrato != null) {
      if (vaga.inicioContrato!.isAfter(vaga.fimContrato!)) {
        errors['data_contrato'] =
            'Data de início deve ser anterior à data de fim';
      }
    }

    // Validação de horários
    if (vaga.horarioTurno1Inicio != null &&
        !_isValidTimeFormat(vaga.horarioTurno1Inicio!)) {
      errors['horario_turno1_inicio'] =
          'Formato de horário inválido (use HH:MM)';
    }

    if (vaga.horarioTurno1Fim != null &&
        !_isValidTimeFormat(vaga.horarioTurno1Fim!)) {
      errors['horario_turno1_fim'] = 'Formato de horário inválido (use HH:MM)';
    }

    return errors;
  }

  static bool _isValidTimeFormat(String time) {
    final RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(time);
  }

  // Validações individuais por campo
  static String? validateAtividades(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Atividades são obrigatórias';
    }
    if (value.length < 10) {
      return 'Descrição das atividades deve ter pelo menos 10 caracteres';
    }
    if (value.length > 1000) {
      return 'Descrição das atividades muito longa';
    }
    return null;
  }

  static String? validateCursosIds(List<int>? cursosIds) {
    if (cursosIds == null || cursosIds.isEmpty) {
      return 'Pelo menos um curso deve ser selecionado';
    }
    return null;
  }

  static String? validateCargaHoraria(String? value) {
    if (value != null && value.isNotEmpty) {
      final int? carga = int.tryParse(value);
      if (carga == null || carga <= 0) {
        return 'Carga horária deve ser um número válido maior que 0';
      }
      if (carga > 44) {
        return 'Carga horária não pode exceder 44 horas semanais';
      }
    }
    return null;
  }

  static String? validateValorBolsa(String? value) {
    if (value != null && value.isNotEmpty) {
      final double? valor = double.tryParse(value);
      if (valor == null || valor < 0) {
        return 'Valor da bolsa deve ser um número válido';
      }
    }
    return null;
  }

  static String? validateHorario(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!_isValidTimeFormat(value)) {
        return 'Formato de horário inválido (use HH:MM)';
      }
    }
    return null;
  }
}

class CursoResumo {
  final int? cdCurso;
  final String? nome;

  const CursoResumo({this.cdCurso, this.nome});

  factory CursoResumo.fromJson(Map<String, dynamic> json) {
    return CursoResumo(
      cdCurso: Vaga._safeParseInt(json['cd_curso']),
      nome: json['nome']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cd_curso': cdCurso,
      'nome': nome,
    }..removeWhere((key, value) => value == null);
  }
}
