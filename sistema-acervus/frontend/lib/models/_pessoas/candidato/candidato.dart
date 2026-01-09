// lib/models/candidato.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class Candidato {
  final int? id;
  final String? numeroMatricula;
  final String nomeCompleto;
  final String? pis;
  final String? numeroMembros;
  final String? rendaDomiciliar;
  final bool? recebeAuxilio;
  final String? qualAuxilio;
  final String? nomeSocial;
  final String? cursoAtual;
  final DateTime? dataNascimento;
  final String? paisOrigem;
  final String? nacionalidade;
  final String email;
  final String cpf;
  final String? rg;
  final String? orgaoEmissor;
  final String? ufEmissor;
  final String? cep;
  final String? logradouro; // era endereco (String)
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? uf;
  final String? complemento;
  final String? celular;
  final String? telefone;
  final String? resumoProfissional;
  final String? sexo;
  final String? genero;
  final String? tipoCurso;
  final String? estadoCivil;
  final bool? estrangeiro;
  final String? cor;
  final String? raca;
  final String? tipoCadastroCandidato;
  final String? nomePai;
  final String? nomeMae;
  final bool? pcd;
  final String? tipoPcd;
  final String? nivelPcd;
  final DateTime? dataCriacao;
  final DateTime? dataAtualizacao;
  final int? idRegimeContratacao;
  final String? senha;
  final bool? ativo;
  final String? observacao;

  // Novos campos para dados do candidato CARTEIRA TRABALHO E RESPONSAVEL
  final String? carteiraTrabalhoNumero;
  final String? carteiraTrabalhoNumeroSerie;
  final bool? carteiraTrabalhoDigital;
  final String? nomeResponsavel;

  // Campos relacionados
  final List<FormacaoAcademica>? formacoesAcademicas;
  final List<CursoComplementar>? cursosComplementares;
  final List<ExperienciaProfissional>? experienciasProfissionais;
  final List<Idioma>? idiomas;
  final List<AreaInteresse>? areasInteresse;

  // Novos campos do JSON
  final String? raMatricula;
  final String? comprovantePath;
  final String? comprovanteUrl;
  final bool? aceiteLgpd;
  final DateTime? dataAceiteLgpd;
  final EnderecoCandidato? endereco;
  final FormacaoAcademica? formacao;
  final ContatoCandidato? contato;

  // Dados bancários
  final int? cdBanco;
  final String? agencia;
  final String? conta;
  final String? tipoConta;

  Candidato({
    this.id,
    this.carteiraTrabalhoNumero,
    this.carteiraTrabalhoNumeroSerie,
    this.carteiraTrabalhoDigital,
    this.pis,
    this.numeroMembros,
    this.rendaDomiciliar,
    this.recebeAuxilio,
    this.qualAuxilio,
    this.nomeResponsavel,
    this.numeroMatricula,
    required this.nomeCompleto,
    this.nomeSocial,
    this.cursoAtual,
    this.dataNascimento,
    this.paisOrigem,
    this.nacionalidade,
    required this.email,
    required this.cpf,
    this.rg,
    this.orgaoEmissor,
    this.ufEmissor,
    this.cep,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.uf,
    this.complemento,
    this.celular,
    this.telefone,
    this.resumoProfissional,
    this.sexo,
    this.genero,
    this.estadoCivil,
    this.estrangeiro,
    this.cor,
    this.raca,
    this.tipoCadastroCandidato,
    this.tipoCurso,
    this.nomePai,
    this.nomeMae,
    this.pcd,
    this.tipoPcd,
    this.nivelPcd,
    this.dataCriacao,
    this.dataAtualizacao,
    this.idRegimeContratacao,
    this.senha,
    this.ativo,
    this.observacao,
    this.formacoesAcademicas,
    this.cursosComplementares,
    this.experienciasProfissionais,
    this.idiomas,
    this.areasInteresse,
    this.raMatricula,
    this.comprovantePath,
    this.comprovanteUrl,
    this.aceiteLgpd,
    this.dataAceiteLgpd,
    this.endereco,
    this.formacao,
    this.contato,
    this.cdBanco,
    this.agencia,
    this.conta,
    this.tipoConta,
  });

  factory Candidato.fromJson(Map<String, dynamic> json) {
    try {
      //print('🏗️ Criando Candidato.fromJson:');
      //print('   JSON keys: ${json.keys.toList()}');

      return Candidato(
        // IDs e identificadores
        id: _parseInt(
            json['id'] ?? json['cd_candidato'] ?? json['CodigoCandidato']),
        numeroMatricula:
            _parseString(json['numero_matricula'] ?? json['Numero_Matricula']),
        // 4 argumentos posicionais obrigatórios
        carteiraTrabalhoNumero: _parseString(json['numero_carteira_trabalho']),
        carteiraTrabalhoNumeroSerie:
            _parseString(json['numero_serie_carteira_trabalho']),
        carteiraTrabalhoDigital: _parseBool(json['possui_carteira_fisica']),
        nomeResponsavel: _parseString(json['nome_responsavel']),

        pis: _parseString(json['pis']),
        numeroMembros: _parseString(json['qtd_membros_domicilio']),
        rendaDomiciliar: _parseString(json['renda_domiciliar_mensal']),
        recebeAuxilio: _parseBool(json['recebe_auxilio_governo']),
        qualAuxilio: _parseString(json['qual_auxilio_governo']),

        //Curso Atual
        cursoAtual: _parseString(json['curso'] ?? ''),
        tipoCurso: _parseString(json['tipo_curso'] ?? ''),

        // Dados pessoais básicos
        nomeCompleto: _parseString(json['nome_completo'] ?? json['Nome']) ?? '',
        nomeSocial: _parseString(json['nome_social'] ?? json['NomeSocial']),
        dataNascimento:
            _parseDateTime(json['data_nascimento'] ?? json['DataNascimento']),
        paisOrigem:
            _parseString(json['pais_origem'] ?? json['PaisOrigem']) ?? 'Brasil',
        nacionalidade:
            _parseString(json['nacionalidade'] ?? json['Nacionalidade']) ??
                'Brasileira',

        // Contato
        email: _parseString(json['email'] ?? json['Email']) ?? '',
        cpf: _parseString(json['cpf'] ?? json['CPF']) ?? '',
        rg: _parseString(json['rg'] ?? json['RG']),
        orgaoEmissor: _parseString(json['orgao_emissor'] ??
            json['org_emissor'] ??
            json['OrgaoEmissor']),
        ufEmissor:
            _parseString(json['uf_rg'] ?? json['uf_rg'] ?? json['uf_rg']),
        celular: _parseString(json['celular'] ?? json['Celular']),
        telefone: _parseString(json['telefone'] ?? json['Telefone']),

        // Endereço
        cep: _parseString(json['cep'] ?? json['CEP']),
        logradouro: _parseString(json['endereco'] ?? json['logradouro']),
        numero: _parseString(json['numero'] ?? json['Numero']),
        bairro: _parseString(json['bairro'] ?? json['Bairro']),
        cidade: _parseString(json['cidade'] ?? json['Cidade']),
        uf: _parseString(json['uf'] ?? json['UF']),
        complemento: _parseString(json['complemento'] ?? json['Complemento']),

        // Informações demográficas
        sexo: _parseString(json['sexo'] ?? json['Sexo']),
        genero: _parseString(json['genero'] ?? json['Genero']),
        estadoCivil: _parseString(json['estado_civil'] ?? json['EstadoCivil']),
        estrangeiro: _parseBool(json['estrangeiro'] ?? json['Estrangeiro']),
        cor: _parseString(json['cor'] ?? json['Cor']),
        raca: _parseString(json['raca'] ?? json['Raca']),

        // Informações familiares
        nomePai: _parseString(json['nome_pai'] ?? json['NomePai']),
        nomeMae: _parseString(json['nome_mae'] ?? json['NomeMae']),

        // PCD
        pcd: _parseBool(json['pcd'] ?? json['PCD']),
        tipoPcd: _parseString(json['tipo_pcd'] ?? json['TipoPCD']),
        nivelPcd: _parseString(json['nivel_pcd'] ?? json['NivelPCD']),

        // Outros campos
        resumoProfissional: _parseString(
            json['resumo_profissional'] ?? json['ResumoProfissional']),
        tipoCadastroCandidato: _parseString(
            json['tipo_cadastro_candidato'] ?? json['TipoCadastroCandidato']),
        observacao: _parseString(json['observacao'] ?? json['Observacao']),

        // Campos de sistema
        dataCriacao: _parseDateTime(json['data_criacao'] ?? json['created_at']),
        dataAtualizacao:
            _parseDateTime(json['data_atualizacao'] ?? json['updated_at']),
        idRegimeContratacao: _parseInt(
            json['id_regime_contratacao'] ?? json['IdRegimeContratacao']),
        senha: _parseString(json['senha']),
        ativo: _parseBool(json['ativo']) ?? true,

        // Novos campos do JSON
        raMatricula: _parseString(json['ra_matricula']),
        comprovantePath: _parseString(json['comprovante_path']),
        comprovanteUrl: _parseString(json['comprovante_url']),
        aceiteLgpd: _parseBool(json['aceite_lgpd']),
        dataAceiteLgpd: _parseDateTime(json['data_aceite_lgpd']),
        endereco:
            json['endereco'] != null && json['endereco'] is Map<String, dynamic>
                ? EnderecoCandidato.fromJson(json['endereco'])
                : null,
        formacao: json['formacao'] != null
            ? FormacaoAcademica.fromJson(json['formacao'])
            : null,
        contato: json['contato'] != null
            ? ContatoCandidato.fromJson(json['contato'])
            : null,

        // Dados bancários
        cdBanco: _parseInt(json['cd_banco']),
        agencia: _parseString(json['agencia']),
        conta: _parseString(json['conta']),
        tipoConta: _parseString(json['tipo_conta']),

        // Relacionamentos (se presentes)
        formacoesAcademicas: json['formacoes_academicas'] != null
            ? (json['formacoes_academicas'] as List)
                .map((e) => FormacaoAcademica.fromJson(e))
                .toList()
            : null,
        cursosComplementares: json['cursos_complementares'] != null
            ? (json['cursos_complementares'] as List)
                .map((e) => CursoComplementar.fromJson(e))
                .toList()
            : null,
        experienciasProfissionais: json['experiencias_profissionais'] != null
            ? (json['experiencias_profissionais'] as List)
                .map((e) => ExperienciaProfissional.fromJson(e))
                .toList()
            : null,
        idiomas: json['idiomas'] != null
            ? (json['idiomas'] as List).map((e) => Idioma.fromJson(e)).toList()
            : null,
        areasInteresse: json['areas_interesse'] != null
            ? (json['areas_interesse'] as List)
                .map((e) => AreaInteresse.fromJson(e))
                .toList()
            : null,
      );
    } catch (e, stackTrace) {
      print('💥 Erro detalhado ao processar candidato:');
      print('   JSON: $json');
      print('   Erro: $e');
      print(
          '   Stack: ${stackTrace.toString().split('\n').take(5).join('\n')}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome_completo': nomeCompleto,
      'nome_social': nomeSocial,
      'data_nascimento': dataNascimento?.toIso8601String(),
      'pais_origem': paisOrigem,
      'nacionalidade': nacionalidade,
      'email': email,
      'cpf': cpf,
      'rg': rg,
      'orgao_emissor': orgaoEmissor,
      'uf_rg': ufEmissor,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'uf': uf,
      'complemento': complemento,
      'celular': celular,
      'telefone': telefone,
      'resumo_profissional': resumoProfissional,
      'sexo': sexo,
      'genero': genero,
      'estado_civil': estadoCivil,
      'estrangeiro': estrangeiro,
      'cor': cor,
      'raca': raca,
      'tipo_cadastro_candidato': tipoCadastroCandidato,
      'nome_pai': nomePai,
      'nome_mae': nomeMae,
      'pcd': pcd,
      'tipo_pcd': tipoPcd,
      'nivel_pcd': nivelPcd,
      'data_criacao': dataCriacao?.toIso8601String(),
      'data_atualizacao': dataAtualizacao?.toIso8601String(),
      'id_regime_contratacao': idRegimeContratacao,
      'ativo': ativo,
      'observacao': observacao,
      'ra_matricula': raMatricula,
      'comprovante_path': comprovantePath,
      'comprovante_url': comprovanteUrl,
      'aceite_lgpd': aceiteLgpd,
      'data_aceite_lgpd': dataAceiteLgpd?.toIso8601String(),
      'endereco': endereco?.toJson(),
      'formacao': formacao?.toJson(),
      'contato': contato?.toJson(),
      'tipo_curso': tipoCurso,
      'cd_banco': cdBanco,
      'agencia': agencia,
      'conta': conta,
      'tipo_conta': tipoConta,
      'nome_responsavel': nomeResponsavel,
      'numero_carteira_trabalho': carteiraTrabalhoNumero,
      'numero_serie_carteira_trabalho': carteiraTrabalhoNumeroSerie,
      'possui_carteira_fisica': carteiraTrabalhoDigital,
      'pis': pis,
      'qtd_membros_domicilio': numeroMembros,
      'renda_domiciliar_mensal': rendaDomiciliar,
      'recebe_auxilio_governo': recebeAuxilio,
      'qual_auxilio_governo': qualAuxilio,
    };
  }

  // Métodos auxiliares para parsing seguro
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) {
      return value.toInt();
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        // Tenta diferentes formatos de data
        if (value.contains('/')) {
          // Formato DD/MM/YYYY
          final parts = value.split('/');
          if (parts.length == 3) {
            return DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            );
          }
        }
        return DateTime.parse(value);
      } catch (e) {
        print('Erro ao fazer parse da data: $value - $e');
        return null;
      }
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 's' || lower == 'sim') {
        return true;
      }
      if (lower == 'false' ||
          lower == '0' ||
          lower == 'n' ||
          lower == 'não' ||
          lower == 'nao') {
        return false;
      }
    }
    if (value is int) {
      return value == 1;
    }
    return null;
  }

  // Getters úteis
  String get nomeExibicao =>
      nomeSocial?.isNotEmpty == true ? nomeSocial! : nomeCompleto;

  String get enderecoCompleto {
    if (endereco != null) {
      final partes = <String>[];
      if (endereco!.logradouro?.isNotEmpty == true) {
        partes.add(endereco!.logradouro!);
      }
      if (endereco!.numero?.isNotEmpty == true) partes.add(endereco!.numero!);
      if (endereco!.bairro?.isNotEmpty == true) partes.add(endereco!.bairro!);
      if (endereco!.cidade?.isNotEmpty == true) partes.add(endereco!.cidade!);
      if (endereco!.uf?.isNotEmpty == true) partes.add(endereco!.uf!);
      return partes.join(', ');
    }
    return '';
  }

  bool get isDadosCompletos {
    return nomeCompleto.isNotEmpty &&
        email.isNotEmpty &&
        cpf.isNotEmpty &&
        dataNascimento != null &&
        celular?.isNotEmpty == true;
  }

  bool get isMenorIdade {
    if (dataNascimento == null) return false;
    final hoje = DateTime.now();
    final idade = hoje.year - dataNascimento!.year;
    if (hoje.month < dataNascimento!.month ||
        (hoje.month == dataNascimento!.month &&
            hoje.day < dataNascimento!.day)) {
      return idade - 1 < 18;
    }
    return idade < 18;
  }

  @override
  String toString() {
    return 'Candidato(id: $id, nome: $nomeCompleto, email: $email, cpf: $cpf, curso: $cursoAtual, cursoAtual: $cursoAtual)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Candidato && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ============================================================================
// CLASSE FORMAÇÃO ACADÊMICA COMPLETA E CORRIGIDA
// ============================================================================

class FormacaoAcademica {
  final int? id;
  final String? nivel;
  final String? curso;
  final String? cursoNaoListado;
  final String? instituicao;
  final String? instituicaoNaoListada;
  final String? statusCurso;
  final String? semestreAnoInicial;
  final String? semestreAnoConclusao;
  final String? turno;
  final String? modalidade;
  final String? raMatricula;
  final bool ativo;
  final DateTime? dataInicio;
  final DateTime? dataInicioCurso;
  final DateTime? dataFimCurso;
  final DateTime? dataFim;
  final DateTime? dataCriacao;
  final DateTime? dataAtualizacao;
  final File comprovanteMatricula;

  // Campos de relacionamento (IDs para o backend)
  final int? candidatoId;
  final int? nivelFormacaoId;
  final int? cursoId;
  final int? instituicaoId;
  final int? statusCursoId;
  final int? turnoId;
  final int? modalidadeId;

  FormacaoAcademica({
    this.id,
    this.nivel,
    this.curso,
    this.cursoNaoListado,
    this.instituicao,
    this.instituicaoNaoListada,
    this.statusCurso,
    this.semestreAnoInicial,
    this.semestreAnoConclusao,
    this.turno,
    this.modalidade,
    this.raMatricula,
    this.ativo = true,
    this.dataInicio,
    this.dataFim,
    this.dataInicioCurso,
    this.dataFimCurso,
    this.dataCriacao,
    this.dataAtualizacao,
    this.candidatoId,
    this.nivelFormacaoId,
    this.cursoId,
    this.instituicaoId,
    this.statusCursoId,
    this.turnoId,
    this.modalidadeId,
    required this.comprovanteMatricula,
    Uint8List? comprovanteMatriculaBytes,
  });

  factory FormacaoAcademica.fromJson(Map<String, dynamic> json) {
    try {
      print('🎓 Criando FormacaoAcademica.fromJson:');
      print('   JSON keys: ${json.keys.toList()}');

      return FormacaoAcademica(
        id: Candidato._parseInt(json['id'] ?? json['cd_nivel_formacao']),
        nivel: Candidato._parseString(
            json['nivel'] ?? json['nivel_formacao'] ?? json['descricao_nivel']),
        //nivelFormacaoId: Candidato._parseInt(json['nivel'] ?? json['cd_nivel_formacao'] ?? json['descricao_nivel']),
        curso: Candidato._parseString(json['curso']),
        //cursoId: Candidato._parseInt(json['curso'] ?? json['cd_curso'] ?? json['descricao_curso']),
        cursoNaoListado: Candidato._parseString(json['cd_curso_nao_listado']),
        instituicao: Candidato._parseString(json['razao_social_instituicao']),
        instituicaoNaoListada:
            Candidato._parseString(json['cd_instituicao_nao_listada']),
        //instituicaoId: Candidato._parseInt(json['instituicao'] ?? json['cd_instituicao_ensino'] ?? json['nome_instituicao']),
        statusCurso: Candidato._parseString(json['status_curso'] ??
            json['situacao'] ??
            json['descricao_status']),
        semestreAnoInicial: Candidato._parseString(
            json['semestre_ano_inicial'] ?? json['semestre_ano']),
        semestreAnoConclusao: Candidato._parseString(
            json['semestre_ano_conclusao'] ?? json['periodo_final']),
        turno: Candidato._parseString(json['turno'] ?? json['descricao_turno']),
        //turnoId: Candidato._parseInt(json['turno'] ?? json['cd_turno'] ?? json['descricao_turno']),
        modalidade: Candidato._parseString(json['modalidade'] ??
            json['modalidade_ensino'] ??
            json['descricao_modalidade']),
        //modalidadeId: Candidato._parseInt(json['modalidade'] ?? json['cd_modalidade_ensino'] ?? json['descricao_modalidade']),
        raMatricula: Candidato._parseString(
            json['ra_matricula'] ?? json['numero_matricula']),
        ativo: Candidato._parseBool(json['ativo']) ?? true,
        dataInicio: Candidato._parseDateTime(json['data_inicio']),
        dataFim: Candidato._parseDateTime(json['data_fim']),
        dataInicioCurso: Candidato._parseDateTime(json['data_inicio_curso']),
        dataFimCurso: Candidato._parseDateTime(json['data_fim_curso']),
        dataCriacao: Candidato._parseDateTime(
            json['data_criacao'] ?? json['created_at']),
        dataAtualizacao: Candidato._parseDateTime(
            json['data_atualizacao'] ?? json['updated_at']),

        // IDs de relacionamento
        candidatoId:
            Candidato._parseInt(json['cd_candidato'] ?? json['candidato_id']),
        nivelFormacaoId: Candidato._parseInt(
            json['cd_nivel_formacao'] ?? json['nivel_formacao_id']),
        cursoId: Candidato._parseInt(json['cd_curso'] ?? json['curso_id']),
        instituicaoId: Candidato._parseInt(
            json['cd_instituicao_ensino'] ?? json['instituicao_id']),
        statusCursoId: Candidato._parseInt(
            json['cd_status_curso'] ?? json['status_curso_id']),
        turnoId: Candidato._parseInt(json['cd_turno'] ?? json['turno_id']),
        modalidadeId: Candidato._parseInt(
            json['cd_modalidade'] ?? json['cd_modalidade_ensino']),
        comprovanteMatriculaBytes: kIsWeb && json['comprovante_path'] != null
            ? base64Decode(json['comprovante_path'])
            : null,
        comprovanteMatricula: File(json['comprovante_path'] ?? ''),
      );
    } catch (e, stackTrace) {
      print('💥 Erro ao processar FormacaoAcademica:');
      print('   JSON: $json');
      print('   Erro: $e');
      print(
          '   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nivel': nivel,
      'curso': curso,
      'curso_nao_listado': cursoNaoListado,
      'instituicao': instituicao,
      'instituicao_nao_listada': instituicaoNaoListada,
      'status_curso': statusCurso,
      'semestre_ano_inicial': semestreAnoInicial,
      'semestre_ano_conclusao': semestreAnoConclusao,
      'turno': turno,
      'modalidade': modalidade,
      'ra_matricula': raMatricula,
      'ativo': ativo,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'data_inicio_curso': dataInicioCurso?.toIso8601String(),
      'data_fim_curso': dataFimCurso?.toIso8601String(),
      'data_criacao': dataCriacao?.toIso8601String(),
      'data_atualizacao': dataAtualizacao?.toIso8601String(),
      'cd_candidato': candidatoId,
      'cd_nivel_formacao': nivelFormacaoId,
      'cd_curso': cursoId,
      'cd_instituicao': instituicaoId,
      'cd_status_curso': statusCursoId,
      'cd_turno': turnoId,
      'cd_modalidade': modalidadeId,
    };
  }

  FormacaoAcademica copyWith({
    int? id,
    String? nivel,
    String? curso,
    String? cursoNaoListado,
    String? instituicao,
    String? instituicaoNaoListada,
    String? statusCurso,
    String? semestreAnoInicial,
    String? semestreAnoConclusao,
    String? turno,
    String? modalidade,
    String? raMatricula,
    bool? ativo,
    DateTime? dataInicio,
    DateTime? dataFim,
    DateTime? dataCriacao,
    DateTime? dataInicioCurso,
    DateTime? dataFimCurso,
    DateTime? dataAtualizacao,
    int? candidatoId,
    int? nivelFormacaoId,
    int? cursoId,
    int? instituicaoId,
    int? statusCursoId,
    int? turnoId,
    int? modalidadeId,
  }) {
    return FormacaoAcademica(
      id: id ?? this.id,
      nivel: nivel ?? this.nivel,
      curso: curso ?? this.curso,
      cursoNaoListado: cursoNaoListado ?? this.cursoNaoListado,
      instituicao: instituicao ?? this.instituicao,
      instituicaoNaoListada:
          instituicaoNaoListada ?? this.instituicaoNaoListada,
      statusCurso: statusCurso ?? this.statusCurso,
      semestreAnoInicial: semestreAnoInicial ?? this.semestreAnoInicial,
      semestreAnoConclusao: semestreAnoConclusao ?? this.semestreAnoConclusao,
      turno: turno ?? this.turno,
      modalidade: modalidade ?? this.modalidade,
      raMatricula: raMatricula ?? this.raMatricula,
      ativo: ativo ?? this.ativo,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      dataInicioCurso: dataInicioCurso ?? this.dataInicioCurso,
      dataFimCurso: dataFimCurso ?? this.dataFimCurso,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataAtualizacao: dataAtualizacao ?? this.dataAtualizacao,
      candidatoId: candidatoId ?? this.candidatoId,
      nivelFormacaoId: nivelFormacaoId ?? this.nivelFormacaoId,
      cursoId: cursoId ?? this.cursoId,
      instituicaoId: instituicaoId ?? this.instituicaoId,
      statusCursoId: statusCursoId ?? this.statusCursoId,
      turnoId: turnoId ?? this.turnoId,
      modalidadeId: modalidadeId ?? this.modalidadeId,
      comprovanteMatricula:
          comprovanteMatricula, // File não é copiado, deve ser gerenciado externamente
    );
  }

  // Getters úteis
  String get cursoExibicao => curso ?? cursoNaoListado ?? 'Curso não informado';
  String get instituicaoExibicao =>
      instituicao ?? instituicaoNaoListada ?? 'Instituição não informada';

  bool get isCompleto {
    return nivel != null &&
        (curso != null || cursoNaoListado != null) &&
        (instituicao != null || instituicaoNaoListada != null) &&
        statusCurso != null;
  }

  bool get isCursando => statusCurso == 'Cursando';
  bool get isConcluido => statusCurso == 'Concluído';

  @override
  String toString() {
    return 'FormacaoAcademica(id: $id, curso: $cursoExibicao, instituicao: $instituicaoExibicao, nivel: $nivel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FormacaoAcademica && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// ============================================================================
// OUTRAS CLASSES RELACIONADAS MELHORADAS
// ============================================================================

class CursoComplementar {
  final int? id;
  final String? nome;
  final String? instituicao;
  final int? cargaHoraria;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final String? certificado;
  final bool ativo;

  CursoComplementar({
    this.id,
    this.nome,
    this.instituicao,
    this.cargaHoraria,
    this.dataInicio,
    this.dataFim,
    this.certificado,
    this.ativo = true,
  });

  factory CursoComplementar.fromJson(Map<String, dynamic> json) {
    return CursoComplementar(
      id: Candidato._parseInt(json['id']),
      nome: Candidato._parseString(json['nome']),
      instituicao: Candidato._parseString(json['instituicao']),
      cargaHoraria: Candidato._parseInt(json['carga_horaria']),
      dataInicio: Candidato._parseDateTime(json['data_inicio']),
      dataFim: Candidato._parseDateTime(json['data_fim']),
      certificado: Candidato._parseString(json['certificado']),
      ativo: Candidato._parseBool(json['ativo']) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'instituicao': instituicao,
      'carga_horaria': cargaHoraria,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'certificado': certificado,
      'ativo': ativo,
    };
  }
}

class ExperienciaProfissional {
  final int? id;
  final String? empresa;
  final String? cargo;
  final String? atividades;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final double? salario;
  final String? motivoSaida;
  final bool empregoAtual;
  final bool ativa;

  ExperienciaProfissional({
    this.id,
    this.empresa,
    this.cargo,
    this.atividades,
    this.dataInicio,
    this.dataFim,
    this.salario,
    this.motivoSaida,
    this.empregoAtual = false,
    this.ativa = true,
  });

  factory ExperienciaProfissional.fromJson(Map<String, dynamic> json) {
    return ExperienciaProfissional(
      id: Candidato._parseInt(json['id']),
      empresa: Candidato._parseString(json['empresa']),
      cargo: Candidato._parseString(json['cargo']),
      atividades: Candidato._parseString(json['atividades']),
      dataInicio: Candidato._parseDateTime(json['data_inicio']),
      dataFim: Candidato._parseDateTime(json['data_fim']),
      salario: json['salario']?.toDouble(),
      motivoSaida: Candidato._parseString(json['motivo_saida']),
      empregoAtual: Candidato._parseBool(json['emprego_atual']) ?? false,
      ativa: Candidato._parseBool(json['ativa']) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empresa': empresa,
      'cargo': cargo,
      'atividades': atividades,
      'data_inicio': dataInicio?.toIso8601String(),
      'data_fim': dataFim?.toIso8601String(),
      'salario': salario,
      'motivo_saida': motivoSaida,
      'emprego_atual': empregoAtual,
      'ativa': ativa,
    };
  }
}

class Idioma {
  final int? id;
  final String? nome;
  final String? nivel;
  //final String? certificacao;
  //final bool ativo;

  Idioma({
    this.id,
    this.nome,
    this.nivel,
    //this.certificacao,
    //this.ativo = true,
  });

  factory Idioma.fromJson(Map<String, dynamic> json) {
    return Idioma(
      id: Candidato._parseInt(json['id']),
      nome: Candidato._parseString(json['nome']),
      nivel: Candidato._parseString(json['nivel']),
      //certificacao: Candidato._parseString(json['certificacao']),
      //ativo: Candidato._parseBool(json['ativo']) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'nivel': nivel,
      //'certificacao': certificacao,
      //'ativo': ativo,
    };
  }
}

class AreaInteresse {
  final int? id;
  final String? nome;
  final String? descricao;
  final bool ativo;

  AreaInteresse({
    this.id,
    this.nome,
    this.descricao,
    this.ativo = true,
  });

  factory AreaInteresse.fromJson(Map<String, dynamic> json) {
    return AreaInteresse(
      id: Candidato._parseInt(json['id']),
      nome: Candidato._parseString(json['nome']),
      descricao: Candidato._parseString(json['descricao']),
      ativo: Candidato._parseBool(json['ativo']) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      //'ativo': ativo,
    };
  }
}

class EnderecoCandidato {
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? complemento;
  final String? telefone;
  final String? codigoIbge;
  final String? uf;
  final bool? ativo;
  final bool? principal;
  int id;

  EnderecoCandidato({
    required this.id,
    this.cep,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.complemento,
    this.telefone,
    this.codigoIbge,
    this.uf,
    this.ativo,
    this.principal,
  });

  factory EnderecoCandidato.fromJson(Map<String, dynamic> json) {
    return EnderecoCandidato(
      id: json['id_endereco'] ?? 0,
      cep: json['cep'],
      logradouro: json['logradouro'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      complemento: json['complemento'],
      telefone: json['telefone'],
      codigoIbge: json['codigo_ibge']?.toString(),
      uf: json['uf'],
      ativo: json['ativo'],
      principal: json['principal'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id_endereco': id,
        'cep': cep,
        'logradouro': logradouro,
        'numero': numero,
        'bairro': bairro,
        'cidade': cidade,
        'complemento': complemento,
        'telefone': telefone,
        'codigo_ibge': codigoIbge,
        'uf': uf,
        'ativo': ativo,
        'principal': principal,
      };
}

class ContatoCandidato {
  final String? nome;
  final String? grauParentesco;
  final String? telefone;
  final String? celular;
  final String? whatsapp;
  final bool? principal;
  final int? idContato;

  ContatoCandidato({
    this.idContato,
    this.nome,
    this.grauParentesco,
    this.telefone,
    this.celular,
    this.whatsapp,
    this.principal,
  });

  factory ContatoCandidato.fromJson(Map<String, dynamic> json) {
    return ContatoCandidato(
      idContato: json['id_contato'] ?? 0,
      nome: json['nome'],
      grauParentesco: json['grau_parentesco'],
      telefone: json['telefone'],
      celular: json['celular'],
      whatsapp: json['whatsapp'],
      principal: json['principal'],
    );
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'grau_parentesco': grauParentesco,
        'telefone': telefone,
        'celular': celular,
        'whatsapp': whatsapp,
        'principal': principal,
      };
}
