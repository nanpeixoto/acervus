import 'dart:io';
import 'dart:html' as html;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:sistema_estagio/models/_pessoas/candidato/candidato.dart';
import 'package:sistema_estagio/models/_academico/curso/curso.dart'
    as modelCurso;
import 'package:sistema_estagio/models/_organizacoes/instituicao/instituicao.dart';
import 'package:sistema_estagio/models/_academico/modalidade/modalidade_ensino.dart';
import 'package:sistema_estagio/models/_pessoas/formacao/nivel_conhecimento.dart';
import 'package:sistema_estagio/models/_academico/modalidade/nivel_formacao.dart';

import 'package:sistema_estagio/models/_academico/curso/status_curso.dart';
import 'package:sistema_estagio/models/_pessoas/formacao/turno.dart';
import 'package:sistema_estagio/services/_pessoas/candidato/candidato_service.dart';
import 'package:sistema_estagio/services/_academico/curso/curso_service.dart';
import 'package:sistema_estagio/models/_pessoas/formacao/idioma.dart'
    as modelIdioma;
import 'package:sistema_estagio/services/_pessoas/formacao/idioma_service.dart';
import 'package:sistema_estagio/services/_organizacoes/instituicao/instituicao_service.dart';
import 'package:sistema_estagio/services/_pessoas/formacao/nivel_conhecimento_service.dart';
import 'package:sistema_estagio/services/_pessoas/formacao/nivel_formacao_service.dart';
import 'package:sistema_estagio/services/_academico/modalidade/modalidade_ensino_service.dart'
    as ModalidadeService;
import 'package:sistema_estagio/services/_academico/curso/status_curso_service.dart';
import 'package:sistema_estagio/services/_core/storage_service.dart';
import 'package:sistema_estagio/services/_academico/curso/turno_service.dart';
import 'package:sistema_estagio/services/_pessoas/formacao/conhecimento_service.dart';
import 'package:sistema_estagio/models/_pessoas/formacao/conhecimento.dart'
    as modelConhecimento;
import 'package:sistema_estagio/services/_financeiro/banco_service.dart';
import 'package:sistema_estagio/models/_core/banco.dart' as modelBanco;

import '../../../providers/auth_provider.dart';
import '../../../utils/validators.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/loading_overlay.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '/utils/app_config.dart' as config;

// Classe para FormacaoAcademica
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
  final String? dataInicioCurso;
  final String? dataFimCurso;
  final bool ativo;

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
    this.dataInicioCurso,
    this.dataFimCurso,
    this.ativo = true,
  });

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
    );
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
    String? dataInicioCurso,
    String? dataFimCurso,
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
      dataInicioCurso: dataInicioCurso ?? this.dataInicioCurso,
      dataFimCurso: dataFimCurso ?? this.dataFimCurso,
    );
  }
}

class CadastroCandidatoScreen extends StatefulWidget {
  final String? candidatoId;
  final bool modoEdicao;
  final String? regimeId;

  const CadastroCandidatoScreen({
    super.key,
    this.candidatoId,
    required this.modoEdicao,
    this.regimeId,
  });

  @override
  State<CadastroCandidatoScreen> createState() =>
      _CadastroCandidatoScreenState();
}

class _CadastroCandidatoScreenState extends State<CadastroCandidatoScreen> {
  static const Color _primaryColor = Color(0xFF82265C); // Roxo principal

  bool _isEdicaoMode = false;
  int? _candidatoIdEdicao;

  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  int _currentPage = 0;

  final List<Map<String, dynamic>> _cursos = [];
  bool _showFormCurso = false;
  Map<String, dynamic>? _cursoEditando;
  final _nomeCursoController = TextEditingController();
  final _instituicaoCursoController = TextEditingController();
  final _cargaHorariaCursoController = TextEditingController();
  final _dataInicioCursoController = TextEditingController();
  final _dataFimCursoController = TextEditingController();
  final _certificacaoCursoController = TextEditingController();
  bool _cursoAtivo = true;

  // ==============================================================
// 2. VARIÁVEIS DE ESTADO (Adicionar/Alterar na classe)
// ==============================================================

// ADICIONAR estas variáveis para conhecimentos:
  Map<String, int> _conhecimentosMap = {};
  String? _conhecimentoSelecionado;
  int? _conhecimentoSelecionadoId;
  int? _nivelConhecimentoId;
  String? _nivelConhecimento;
  Map<String, int> _niveisConhecimentoMap = {};
  final TextEditingController _nomeConhecimentoController =
      TextEditingController();
  final TextEditingController _descricaoConhecimentoController =
      TextEditingController();
  Map<String, dynamic>? _conhecimentoEditando;
  bool _conhecimentosNeedRefresh = false;

  //Variaveis para comprovantes de matricula do Estagiario
  // Adicione estas variáveis na classe State:
  File? _comprovanteMatricula;
  Uint8List? _comprovanteMatriculaBytes; // Para web
  String? _nomeComprovanteMatricula;
  String? _comprovanteMatriculaUrl; // URL do comprovante, se existir
  bool _exibirComprovanteObrigatorio = false;

  //Variaveis para nivel de idioma
  int? _idiomaSelecionadoId;
  int? _nivelIdiomaId;
  bool _idiomasNeedRefresh = false;
  bool _experienciasNeedRefresh = false;
  Map<String, int> _idiomasMap = {};
  Map<String, int> _niveisIdiomaMap = {};

  // Formatters
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##');
  final _cepFormatter = MaskTextInputFormatter(mask: '#####-###');
  final _telefoneFormatter = MaskTextInputFormatter(mask: '(##) #####-####');
  final _telefoneFixoFormatter = MaskTextInputFormatter(mask: '(##) ####-####');

  // Controllers - Dados Pessoais
  //Adicionar controllers e variaveis para: Carteira de trabalho, RadioGroup se é Fisica ou Digital, Nome do Responsável
  final _carteiraTrabalhoNumeroController = TextEditingController();
  final _carteiraTrabalhoNumeroSerieController =
      TextEditingController(); // Para número de série
  final _carteiraTrabalhoDigital =
      false; // RadioGroup para carteira de trabalho
  final _pisController = TextEditingController();
  final _nomeResponsavelController = TextEditingController();
  final _nomeController = TextEditingController();
  final _nomeSocialController = TextEditingController();
  final _rgController = TextEditingController();
  final _ufRgController = TextEditingController();
  final _cpfController = TextEditingController();
  final _orgaoEmissorController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _confirmarEmailController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _celularController = TextEditingController();
  int? _regimeContratacaoId;

  final _numeroMembrosController = TextEditingController();
  final _rendaDomiciliarController = TextEditingController();
  final _qualAuxilioController = TextEditingController();
  // Torne não-nulo
  String _recebeAuxilio = 'Não';

  // Controllers - Endereço
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _complementoController = TextEditingController();

  // Controllers - Contatos para Recados
  final _nomeContatoRecadoController = TextEditingController();
  final _emailContatoRecadoController = TextEditingController();
  final _telefoneRecadoController = TextEditingController();
  final _celularRecadoController = TextEditingController();
  final _whatsappRecadoController = TextEditingController();
  final _grauParentescoRecadoController = TextEditingController();

  // Endereço ID para edição
  int? _enderecoId;

  // Contato ID para edição
  int? _contatoId;
  String? _carteiraTrabalhoNumero;
  String? _carteiraTrabalhoNumeroSerie;
  bool _isCarteiraTrabalhoFisica =
      false; // RadioGroup para carteira de trabalho

  // Dropdowns
  String? _uf;
  String? _ufRg;
  String? _sexo;
  String? _genero;
  String? _tipoCurso;
  String? _raca;
  String? _estadoCivil;
  String? _estado;
  String? _paisOrigem = 'Brasil';
  String? _nacionalidade = 'Brasileira';
  DateTime? _dataNascimento;
  DateTime? _dataInicioCurso;
  DateTime? _dataFimCurso;
  bool _isLoading = false;

  // Loading states para prevenir múltiplos cliques
  bool _isLoadingExperiencia = false;
  bool _isLoadingIdioma = false;
  bool _isLoadingConhecimento = false;
  bool _menorIdade = false;
  bool _aceiteLGPD = false;
  bool _isEstrangeiro = false;
  bool _isPCD = false;

  // ID do candidato
  String? _candidatoId;

  // Controllers Formação Academica
  late TextEditingController _cursoNaoListadoController;
  late TextEditingController _instituicaoNaoListadaController;
  late TextEditingController _semestreAnoInicialController;
  late TextEditingController _semestreAnoConclusaoController;
  late TextEditingController _raMatriculaController;

  // Valores selecionados
  String? _nivelFormacao;
  String? _cursoSelecionado;
  String? _instituicaoSelecionada;
  String? _statusCurso;
  String? _turno;
  String? _modalidadeFormacao;

  // Mapas para controlar ID e descrição dos dropdowns
  Map<String, int> _niveisFormacaoMap = {};
  Map<String, int> _statusCursosMap = {};
  Map<String, int> _turnosMap = {};
  Map<String, int> _modalidadesMap = {};

  // Listas para controle de dados filtrados
  final List<modelCurso.Curso> _cursosFiltrados = [];
  final List<InstituicaoEnsino> _instituicoesFiltradas = [];

  // Variáveis para armazenar IDs selecionados
  int? _nivelFormacaoId;
  int? _cursoId;
  int? _instituicaoId;
  int? _statusCursoId;
  int? _turnoId;
  int? _modalidadeId;

  // Lista de formações acadêmicas
  final List<FormacaoAcademica> _formacoesAcademicas = [];
  bool _showFormFormacao = false;
  FormacaoAcademica? _formacaoEditando;

  // Idiomas
  final List<Map<String, dynamic>> _idiomas = [];
  bool _showFormIdioma = false;
  Map<String, dynamic>? _idiomaEditando;
  final _nomeIdiomaController = TextEditingController();
  String? _nivelIdioma;
  final _certificacaoIdiomaController = TextEditingController();

  // Experiência Profissional
  final List<Map<String, dynamic>> _experiencias = [];
  bool _showFormExperiencia = false;
  Map<String, dynamic>? _experienciaEditando;
  final _empresaController = TextEditingController();
  final _atividadesController = TextEditingController();
  final _dataInicioExpController = TextEditingController();
  final _dataFimExpController = TextEditingController();

  // Conhecimentos de Informática
  final List<Map<String, dynamic>> _conhecimentos = [];
  bool _showFormConhecimento = false;
  final _softwareController = TextEditingController();
  final _versaoController = TextEditingController();
  final bool _conhecimentoAtivo = true;

  //lista dropdown grau parentesco
  final List<String> _grauParentesco = [
    'Pai',
    'Mãe',
    'Irmão(ã)',
    'Cônjuge',
    'Filho(a)',
    'Tios(as)',
    'Madrasta',
    'Padrasto',
    'Avôs(ós)',
    'Outros',
  ];

  final List<String> _ufs = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO'
  ];

  // Cache de dados para dropdowns
  Map<String, dynamic>? _niveisFormacaoCache;
  Map<String, dynamic>? _statusCursosCache;
  Map<String, dynamic>? _turnosCache;
  Map<String, dynamic>? _modalidadesCache;
  Map<String, dynamic>? _idiomasCache;
  Map<String, dynamic>? _niveisIdiomaCache;
  Map<String, dynamic>? _conhecimentosCache;
  Map<String, dynamic>? _niveisConhecimentoCache;
  bool _dadosCarregados = false;

  // Cache para listas de idiomas e conhecimentos carregados
  List<Map<String, dynamic>>? _idiomasCarregados;
  List<Map<String, dynamic>>? _experienciasCarregadas;
  List<Map<String, dynamic>>? _conhecimentosCarregados;
  bool _listasCarregadas = false;
  bool _carregandoListas =
      false; // ✅ NOVA FLAG para evitar carregamentos múltiplos
  bool _carregamentoIniciado =
      false; // ✅ NOVA FLAG para evitar múltiplos inícios de carregamento

  // Dados Bancários
  final _agenciaController = TextEditingController();
  final _contaController = TextEditingController();
  String? _bancoSelecionado;
  int? _bancoId;
  String? _tipoContaSelecionado;
  Map<String, int> _bancosMap = {};
  List<modelBanco.Banco> _bancos = [];

  // Tipos de conta bancária
  final List<Map<String, String>> _tiposConta = [
    {'codigo': 'S', 'descricao': 'Conta Salário'},
    {'codigo': 'C', 'descricao': 'Conta Corrente'},
    {'codigo': 'P', 'descricao': 'Conta Poupança'},
  ];

  @override
  void initState() {
    super.initState();

    // Inicializar modo de edição baseado nos parâmetros
    _isEdicaoMode = widget.modoEdicao;
    if (widget.candidatoId != null) {
      _candidatoIdEdicao = int.tryParse(widget.candidatoId!);
    }

    _cursoNaoListadoController = TextEditingController();
    _instituicaoNaoListadaController = TextEditingController();
    _semestreAnoInicialController = TextEditingController();
    _semestreAnoConclusaoController = TextEditingController();
    _raMatriculaController = TextEditingController();

    // Carregar dados dos dropdowns uma única vez
    _carregarDadosDropdowns();

    // Verificar se está em modo edição
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarModoEdicao();
    });
  }

// Helper pra garantir que o value sempre exista nos items
  String _safeRecebeAuxilio(String? v) {
    return (v == 'Sim' || v == 'Não') ? v! : 'Não';
  }

  Object? _safeDropdownValue<T>(T? value, List<DropdownMenuItem<T>> items) {
    if (value == null) return null;
    final matches = items.where((e) => e.value == value).length;
    return matches == 1
        ? value
        : null; // se não houver (ou houver duplicado), zera
  }

  // Helper: normaliza data para ISO String
  String _asIsoString(dynamic v) {
    if (v == null) return '';
    if (v is DateTime) return v.toIso8601String();
    return v.toString();
  }

  Future<void> _carregarDadosDropdowns() async {
    setState(() => _isLoading = true);

    try {
      // Carregar todos os dados dos dropdowns em paralelo
      final futures = await Future.wait([
        NivelFormacaoService.listarNiveisFormacao(ativo: true, limit: 100),
        StatusCursoService.listarStatusCursos(ativo: true, limit: 100),
        TurnoService.listarTurnos(ativo: true, limit: 100),
        ModalidadeService.ModalidadeService.listarModalidades(
            ativo: true, limit: 100),
        IdiomaService.listarIdiomas(ativo: true, limit: 100),
        NivelConhecimentoService.listarNiveisConhecimento(
            ativo: true, limit: 100),
        ConhecimentoService.listarConhecimentos(ativo: true, limit: 100),
        BancoService.listarBancos(ativo: true, limit: 100),
      ]);

      setState(() {
        _niveisFormacaoCache = futures[0];
        _statusCursosCache = futures[1];
        _turnosCache = futures[2];
        _modalidadesCache = futures[3];
        _idiomasCache = futures[4];
        _niveisConhecimentoCache = futures[5];
        _niveisIdiomaCache = futures[5]; // Mesmo serviço para idiomas
        _conhecimentosCache = futures[6];

        // Processar dados dos bancos
        final bancoResult = futures[7];
        _bancos = bancoResult['bancos'] as List<modelBanco.Banco>;
        _bancosMap = {for (var banco in _bancos) banco.nome: banco.id!};

        _dadosCarregados = true;
      });

      print('✅ Dados dos dropdowns carregados com sucesso');
    } catch (e) {
      print('❌ Erro ao carregar dados dos dropdowns: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Adicionar este método para verificar modo edição:
  void _verificarModoEdicao() {
    // Capturar ID da URL usando GoRouter
    final location =
        GoRouter.of(context).routeInformationProvider.value.location;
    print('🔍 [MODO_EDICAO] Location atual: $location');

    // ✅ CORREÇÃO: Adicionar regex para rota de candidato também
    final editRegexAdmin = RegExp(r'/admin/candidatos/editar/(\d+)');
    final editRegexCandidato =
        RegExp(r'/candidato/perfil/editar/(\d+)/(\d+)'); // NOVA REGEX

    Match? match = editRegexAdmin.firstMatch(location);

    // ✅ Se não encontrou no padrão admin, tenta o padrão candidato
    match ??= editRegexCandidato.firstMatch(location);

    if (match != null) {
      final candidatoIdStr = match.group(1);
      final candidatoIdInt = int.tryParse(candidatoIdStr ?? '');

      if (candidatoIdInt != null) {
        print('🎯 [MODO_EDICAO] Modo edição detectado - ID: $candidatoIdInt');

        setState(() {
          _isEdicaoMode = true;
          _candidatoIdEdicao = candidatoIdInt;
          _candidatoId = candidatoIdStr; // Definir o ID string também
        });

        // Carregar dados do candidato
        _carregarDadosCandidato(candidatoIdInt);
      } else {
        print('❌ [MODO_EDICAO] ID inválido na URL: $candidatoIdStr');
      }
    } else {
      print('ℹ️ [MODO_EDICAO] Modo criação detectado');

      // ✅ NOVA LÓGICA: Verificar se é rota de estagiário
      bool isRotaEstagiario = location.contains('/estagiario') ||
          location.contains('/estagi') ||
          location.contains('regime=2');

      setState(() {
        _isEdicaoMode = false;
        _candidatoIdEdicao = null;

        // Se for rota de estagiário, definir regime como 2
        if (isRotaEstagiario) {
          _regimeContratacaoId = 2;
          print(
              '🎯 [REGIME_CONTRATACAO] Rota de estagiário detectada - Regime ID: 2');
        }
      });
    }
  }

  Future<void> _carregarDadosCandidato(int candidatoId) async {
    // ✅ VALIDAÇÃO 1: Verificar se o widget está montado ANTES de setState
    if (!mounted) {
      print(
          '⚠️ [CARREGAR_CANDIDATO] Widget não montado, abortando carregamento');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print(
          '🔄 [CARREGAR_CANDIDATO] Iniciando carregamento do candidato ID: $candidatoId');

      // Aguardar o carregamento dos dados dos dropdowns antes de preencher o formulário
      if (!_dadosCarregados) {
        print('📥 [CARREGAR_CANDIDATO] Carregando dados dos dropdowns...');
        await _carregarDadosDropdowns();
      }

      // ✅ VALIDAÇÃO 2: Verificar novamente após operação assíncrona
      if (!mounted) {
        print('⚠️ [CARREGAR_CANDIDATO] Widget desmontado durante carregamento');
        return;
      }

      // Buscar candidato
      print('🔍 [CARREGAR_CANDIDATO] Buscando candidato...');
      final candidato =
          await CandidatoService.buscarCandidatoPorId(candidatoId);

      // ✅ VALIDAÇÃO 3: Verificar novamente após busca
      if (!mounted) {
        print('⚠️ [CARREGAR_CANDIDATO] Widget desmontado após busca');
        return;
      }

      if (candidato != null) {
        print(
            '✅ [CARREGAR_CANDIDATO] Candidato encontrado: ${candidato.nomeCompleto}');

        // Preencher formulário
        _preencherFormularioComDados(candidato);

        // ✅ VALIDAÇÃO 4: Verificar antes de carregar listas
        if (!mounted) {
          print(
              '⚠️ [CARREGAR_CANDIDATO] Widget desmontado antes de carregar listas');
          return;
        }

        // Carregar listas de idiomas, experiências e conhecimentos
        print('📋 [CARREGAR_CANDIDATO] Carregando listas de edição...');
        await _carregarListasEdicao();

        print('🎉 [CARREGAR_CANDIDATO] Candidato carregado com sucesso!');
      } else {
        print(
            '❌ [CARREGAR_CANDIDATO] Candidato não encontrado (retornou null)');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Candidato não encontrado'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );

          // ✅ NAVEGAÇÃO SEGURA
          _navegacaoSegura();
        }
      }
    } catch (e, stackTrace) {
      print('💥 [CARREGAR_CANDIDATO] ERRO ao carregar candidato: $e');
      print('📍 [CARREGAR_CANDIDATO] Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar candidato: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        // ✅ NAVEGAÇÃO SEGURA
        _navegacaoSegura();
      }
    } finally {
      // ✅ VALIDAÇÃO FINAL: Apenas alterar estado se widget ainda montado
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return int.tryParse(v.toString());
  }

  Future<void> _sincronizarInstituicaoSelecionada({
    int? instituicaoId,
    String? instituicaoNome,
  }) async {
    if (!mounted) return;

    if (instituicaoId == null) {
      if (instituicaoNome != null && instituicaoNome.isNotEmpty) {
        setState(() {
          _instituicaoSelecionada = instituicaoNome;
          _instituicaoNaoListadaController.text = '';
        });
      }
      return;
    }

    final instituicao =
        await InstituicaoService.obterInstituicaoPorId(instituicaoId);

    if (!mounted) return;

    if (instituicao != null) {
      setState(() {
        // FIX: id pode vir como String no modelo; converter com segurança
        _instituicaoId = _asInt(instituicao.id);
        final descricao = [
          instituicao.nomeFantasia,
          instituicao.razaoSocial,
        ].whereType<String>().firstWhere(
              (value) => value.trim().isNotEmpty,
              orElse: () => instituicaoNome ?? '',
            );
        _instituicaoSelecionada = descricao;
        _instituicaoNaoListadaController.text = '';
        if (!_instituicoesFiltradas.any((item) => item.id == instituicao.id)) {
          _instituicoesFiltradas.add(instituicao);
        }
      });
    } else if (instituicaoNome != null && instituicaoNome.isNotEmpty) {
      setState(() {
        _instituicaoSelecionada = instituicaoNome;
        _instituicaoNaoListadaController.text = '';
      });
    }
  }

  void _preencherFormularioComDados(Candidato candidato) {
    print('📝 [PREENCHER_DADOS] Iniciando preenchimento do formulário');
    print('   - Candidato ID: ${candidato.id}');
    print('   - Nome: ${candidato.nomeCompleto}');
    print('   - Dados carregados: $_dadosCarregados');
    print(
        '   - Cache nível formação disponível: ${_niveisFormacaoCache != null}');

    // ✅ VALIDAÇÃO CRÍTICA: Verificar se widget está montado
    if (!mounted) {
      print('⚠️ [PREENCHER_DADOS] Widget não montado, abortando preenchimento');
      return;
    }

    try {
      // ===== DADOS PESSOAIS =====
      print('👤 [PREENCHER_DADOS] Preenchendo dados pessoais...');
      _nomeController.text = candidato.nomeCompleto ?? '';
      _nomeSocialController.text = candidato.nomeSocial ?? '';
      _rgController.text = candidato.rg ?? '';
      _ufRgController.text = candidato.ufEmissor ?? '';
      _cpfController.text = candidato.cpf ?? '';
      _orgaoEmissorController.text = candidato.orgaoEmissor ?? '';
      _emailController.text = candidato.email ?? '';
      _confirmarEmailController.text = candidato.email ?? '';
      _telefoneController.text = candidato.telefone ?? '';
      _celularController.text = candidato.celular ?? '';
      _observacaoController.text = candidato.observacao ?? '';

      // Dropdowns
      _uf = candidato.uf;
      _ufRg = candidato.ufEmissor ?? '';
      _sexo = candidato.sexo;
      _genero = candidato.genero;
      _tipoCurso = candidato.tipoCurso;
      _raca = candidato.raca;
      _estadoCivil = candidato.estadoCivil;
      _dataNascimento = candidato.dataNascimento;
      _paisOrigem = candidato.paisOrigem ?? 'Brasil';
      _nacionalidade = candidato.nacionalidade ?? 'Brasileira';

      // Flags
      _isPCD = candidato.pcd ?? false;
      _isEstrangeiro = candidato.estrangeiro ?? false;
      _menorIdade = candidato.isMenorIdade ?? false;
      _aceiteLGPD = candidato.aceiteLgpd ?? false;

      // Dados da carteira de trabalho
      _carteiraTrabalhoNumeroController.text =
          candidato.carteiraTrabalhoNumero ?? '';
      _carteiraTrabalhoNumeroSerieController.text =
          candidato.carteiraTrabalhoNumeroSerie ?? '';
      _isCarteiraTrabalhoFisica = candidato.carteiraTrabalhoDigital ?? false;
      _pisController.text = candidato.pis ?? '';

      // Dados do questionário social
      _numeroMembrosController.text = candidato.numeroMembros?.toString() ?? '';
      _rendaDomiciliarController.text =
          candidato.rendaDomiciliar?.toString() ?? '';
      _recebeAuxilio = (candidato.recebeAuxilio == true) ? 'Sim' : 'Não';
      _qualAuxilioController.text = candidato.qualAuxilio ?? '';

      // Dados do Responsável
      _nomeResponsavelController.text = candidato.nomeResponsavel ?? '';

      // ===== REGIME DE CONTRATAÇÃO =====
      _regimeContratacaoId = candidato.idRegimeContratacao;
      print('🎯 [REGIME_CONTRATACAO] ID: $_regimeContratacaoId');

      // ===== ENDEREÇO =====
      if (candidato.endereco != null) {
        print('📍 [PREENCHER_DADOS] Preenchendo endereço');
        final endereco = candidato.endereco!;

        _enderecoId = endereco.id;
        print('📍 [ENDERECO] ID do endereço: $_enderecoId');

        _cepController.text = endereco.cep?.toString() ?? '';
        _logradouroController.text = endereco.logradouro?.toString() ?? '';
        _numeroController.text = endereco.numero?.toString() ?? '';
        _bairroController.text = endereco.bairro?.toString() ?? '';
        _cidadeController.text = endereco.cidade?.toString() ?? '';
        _complementoController.text = endereco.complemento?.toString() ?? '';
        _estado = endereco.uf?.toString();
      } else {
        print('ℹ️ [ENDERECO] Candidato sem endereço cadastrado');
      }

      // ===== FORMAÇÃO ACADÊMICA - TRATAMENTO SEGURO DE NULL =====
      if (candidato.formacao != null) {
        print('🎓 [PREENCHER_DADOS] Preenchendo formação acadêmica');
        final formacao = candidato.formacao!;
        print('   - cd_nivel_formacao: ${formacao.nivelFormacaoId}');
        print('   - Nível atual string: ${formacao.nivel}');

        // ✅ NÍVEL DE FORMAÇÃO - COM TRATAMENTO SEGURO
        _nivelFormacaoId = formacao.nivelFormacaoId;

        if (_nivelFormacaoId != null && _niveisFormacaoCache != null) {
          try {
            final niveisFormacao = _niveisFormacaoCache!['niveisFormacao']
                    as List<NivelFormacao>? ??
                [];

            if (niveisFormacao.isNotEmpty) {
              final nivelEncontrado = niveisFormacao.firstWhere(
                (nivel) => nivel.id == _nivelFormacaoId,
                orElse: () => NivelFormacao(
                    id: null,
                    nome: '',
                    descricao: '',
                    ativo: false,
                    createdBy: ''),
              );

              if (nivelEncontrado.nome.isNotEmpty) {
                _nivelFormacao = nivelEncontrado.nome;
                print(
                    '✅ [NIVEL_FORMACAO] ID: $_nivelFormacaoId -> Nome: $_nivelFormacao');
              } else {
                _nivelFormacao = formacao.nivel?.toString();
                print(
                    '⚠️ [NIVEL_FORMACAO] Nível ID $_nivelFormacaoId não encontrado no cache');
                print('   Usando valor direto: $_nivelFormacao');
              }
            } else {
              _nivelFormacao = formacao.nivel?.toString();
              print(
                  '⚠️ [NIVEL_FORMACAO] Cache de níveis vazio, usando valor direto');
            }
          } catch (e) {
            print('⚠️ [NIVEL_FORMACAO] Erro ao buscar nível no cache: $e');
            _nivelFormacao = formacao.nivel?.toString();
          }
        } else {
          _nivelFormacao = formacao.nivel?.toString();
          print('🎯 [NIVEL_FORMACAO] Usando valor direto: $_nivelFormacao');

          if (_nivelFormacaoId == null) {
            print(
                'ℹ️ [NIVEL_FORMACAO] Candidato sem nível de formação definido');
          }
          if (_niveisFormacaoCache == null) {
            print('⚠️ [NIVEL_FORMACAO] Cache de níveis não disponível');
          }
        }

        // ✅ CURSO - TRATAMENTO COMPLETO
        if (formacao.cursoId != null) {
          _cursoId = formacao.cursoId;
          _cursoSelecionado = formacao.curso?.toString();
          _cursoNaoListadoController.text = '';
          print('✅ [CURSO] Curso por ID: $_cursoSelecionado (ID: $_cursoId)');
        } else if (formacao.curso != null && formacao.curso!.isNotEmpty) {
          _cursoSelecionado = formacao.curso!.toString();
          _cursoId = null;
          _cursoNaoListadoController.text = '';
          print('✅ [CURSO] Curso por nome: $_cursoSelecionado');
        } else if (formacao.cursoNaoListado != null &&
            formacao.cursoNaoListado!.isNotEmpty) {
          _cursoSelecionado = null;
          _cursoId = null;
          _cursoNaoListadoController.text = formacao.cursoNaoListado!;
          print('✅ [CURSO] Curso não listado: ${formacao.cursoNaoListado}');
        } else {
          _cursoSelecionado = null;
          _cursoId = null;
          _cursoNaoListadoController.text = '';
          print('ℹ️ [CURSO] Nenhum curso definido para este candidato');
        }

        // ✅ INSTITUIÇÃO - TRATAMENTO COMPLETO
        if (formacao.instituicaoId != null) {
          _instituicaoId = formacao.instituicaoId;
          _instituicaoSelecionada = formacao.instituicao;
          _instituicaoNaoListadaController.text =
              formacao.instituicaoNaoListada ?? '';
          _sincronizarInstituicaoSelecionada(
            instituicaoId: _instituicaoId,
            instituicaoNome: _instituicaoSelecionada,
          );
          print(
              '✅ [IE] Instituicao por ID: $_instituicaoSelecionada (ID: $_instituicaoId)');
        } else if (formacao.instituicao != null &&
            formacao.instituicao!.isNotEmpty) {
          _instituicaoSelecionada = formacao.instituicao!.toString();
          _instituicaoId = null;
          _instituicaoNaoListadaController.text = '';
          print('✅ [IE] Instituicao por nome: $_instituicaoSelecionada');
        } else if (formacao.instituicaoNaoListada != null &&
            formacao.instituicaoNaoListada!.isNotEmpty) {
          _instituicaoSelecionada = null;
          _instituicaoId = null;
          _instituicaoNaoListadaController.text =
              formacao.instituicaoNaoListada!;
          print(
              '✅ [IE] Instituicao não listada: ${formacao.instituicaoNaoListada}');
        } else {
          _instituicaoSelecionada = null;
          _instituicaoId = null;
          _instituicaoNaoListadaController.text = '';
          print('ℹ️ [IE] Nenhuma instituição definida para este candidato');
        }

        // Outros campos da formação
        _statusCurso = formacao.statusCurso?.toString();
        _turno = formacao.turno?.toString();
        _modalidadeFormacao = formacao.modalidade?.toString();
        _semestreAnoInicialController.text =
            formacao.semestreAnoInicial?.toString() ?? '';
        _raMatriculaController.text = candidato.raMatricula ?? '';

        // Datas do curso (corrigido: aceita DateTime ou String)
        if (formacao.dataInicioCurso != null) {
          _dataInicioCurso = formacao.dataInicioCurso is DateTime
              ? formacao.dataInicioCurso as DateTime
              : null;
          _dataInicioCursoController.text =
              _formatarDataParaExibicao(_asIsoString(formacao.dataInicioCurso));
        } else {
          _dataInicioCurso = null;
          _dataInicioCursoController.clear();
        }

        if (formacao.dataFimCurso != null) {
          _dataFimCurso = formacao.dataFimCurso is DateTime
              ? formacao.dataFimCurso as DateTime
              : null;
          _dataFimCursoController.text =
              _formatarDataParaExibicao(_asIsoString(formacao.dataFimCurso));
        } else {
          _dataFimCurso = null;
          _dataFimCursoController.clear();
        }

        // IDs para backend (manter para envio)
        _statusCursoId = formacao.statusCursoId;
        _turnoId = formacao.turnoId;
        _modalidadeId = formacao.modalidadeId;

        // Comprovante de matrícula
        if (_statusCurso == 'Cursando') {
          _exibirComprovanteObrigatorio = true;

          if (candidato.comprovanteUrl != null &&
              candidato.comprovanteUrl!.isNotEmpty) {
            _comprovanteMatriculaUrl = candidato.comprovanteUrl!;
            _nomeComprovanteMatricula =
                _extrairNomeArquivoDeUrl(candidato.comprovanteUrl!);
            print('✅ [COMPROVANTE] URL existente: $_comprovanteMatriculaUrl');
            print(
                '✅ [COMPROVANTE] Nome do arquivo: $_nomeComprovanteMatricula');
          } else {
            _comprovanteMatriculaUrl = null;
            _nomeComprovanteMatricula = null;
            print('ℹ️ [COMPROVANTE] Nenhum comprovante anexado');
          }
        }

        print('✅ [FORMACAO] Dados preenchidos:');
        print('   - Nível: $_nivelFormacao (ID: $_nivelFormacaoId)');
        print('   - Curso: $_cursoSelecionado (ID: $_cursoId)');
        print('   - Curso Não Listado: ${_cursoNaoListadoController.text}');
        print(
            '   - Instituição: $_instituicaoSelecionada (ID: $_instituicaoId)');
        print('   - Status: $_statusCurso (ID: $_statusCursoId)');
        print('   - Comprovante URL: $_comprovanteMatriculaUrl');
      } else {
        print('ℹ️ [FORMACAO] Candidato sem formação acadêmica cadastrada');

        // Limpar campos de formação
        _nivelFormacao = null;
        _nivelFormacaoId = null;
        _cursoSelecionado = null;
        _cursoId = null;
        _cursoNaoListadoController.text = '';
        _instituicaoSelecionada = null;
        _instituicaoId = null;
        _instituicaoNaoListadaController.text = '';
      }

      // ===== DADOS BANCÁRIOS =====
      if (candidato.cdBanco != null) {
        print('🏦 [PREENCHER_DADOS] Preenchendo dados bancários');
        print('   - cd_banco: ${candidato.cdBanco}');
        print('   - agencia: ${candidato.agencia}');
        print('   - conta: ${candidato.conta}');
        print('   - tipo_conta: ${candidato.tipoConta}');
        print('   - Lista de bancos carregada: ${_bancos.length} bancos');

        _agenciaController.text = candidato.agencia?.toString() ?? '';
        _contaController.text = candidato.conta?.toString() ?? '';
        _bancoId = candidato.cdBanco;

        // Tipo de conta
        _tipoContaSelecionado = candidato.tipoConta;
        print('🏦 [TIPO_CONTA] Valor recebido: "${candidato.tipoConta}"');

        // Validar se o código existe na lista de tipos
        final tipoEncontrado = _tiposConta
            .where((t) => t['codigo'] == candidato.tipoConta)
            .toList();
        if (tipoEncontrado.isNotEmpty) {
          print(
              '✅ [TIPO_CONTA] Tipo válido encontrado: ${tipoEncontrado.first['descricao']}');
        } else {
          print(
              '⚠️ [TIPO_CONTA] Código "${candidato.tipoConta}" não encontrado na lista');
          print(
              '   Códigos válidos: ${_tiposConta.map((t) => t['codigo']).join(', ')}');
          _tipoContaSelecionado = null;
        }

        // Buscar nome do banco
        if (_bancos.isEmpty && _dadosCarregados) {
          print('⚠️ [BANCO] Lista de bancos vazia mesmo com dados carregados');
        } else if (_bancos.isNotEmpty) {
          final bancoEncontrado =
              _bancos.where((b) => b.id == _bancoId).toList();
          if (bancoEncontrado.isNotEmpty) {
            _bancoSelecionado = bancoEncontrado.first.nome;
            print(
                '✅ [BANCO] Nome do banco selecionado: $_bancoSelecionado (ID: $_bancoId)');
          } else {
            print('⚠️ [BANCO] Banco com ID $_bancoId não encontrado na lista');
            print(
                '   Bancos disponíveis: ${_bancos.map((b) => '${b.id}:${b.nome}').join(', ')}');
          }
        } else {
          print(
              'ℹ️ [BANCO] Lista de bancos ainda não carregada, tentaremos novamente');

          // ✅ Agendar retry COM validação de mounted
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _bancos.isNotEmpty && _bancoId != null) {
              final bancoEncontrado =
                  _bancos.where((b) => b.id == _bancoId).toList();
              if (bancoEncontrado.isNotEmpty) {
                setState(() {
                  _bancoSelecionado = bancoEncontrado.first.nome;
                });
                print(
                    '✅ [BANCO] Nome do banco selecionado (retry): $_bancoSelecionado');
              }
            }
          });
        }

        print(
            '✅ [DADOS_BANCARIOS] Preenchidos: Banco($_bancoSelecionado), Agência(${_agenciaController.text}), Conta(${_contaController.text}), Tipo($_tipoContaSelecionado)');
      } else {
        print(
            'ℹ️ [DADOS_BANCARIOS] Nenhum dado bancário encontrado no candidato');
      }

      // ===== CONTATOS =====
      if (candidato.contato != null) {
        print('📞 [PREENCHER_DADOS] Preenchendo contatos');
        final contato = candidato.contato!;
        _contatoId = contato.idContato;
        print('📍 [CONTATO] ID do contato: $_contatoId');

        _nomeContatoRecadoController.text = contato.nome?.toString() ?? '';
        _telefoneRecadoController.text = contato.telefone?.toString() ?? '';
        _celularRecadoController.text = contato.celular?.toString() ?? '';
        _whatsappRecadoController.text = contato.whatsapp?.toString() ?? '';
        _grauParentescoRecadoController.text =
            contato.grauParentesco?.toString() ?? '';
      } else {
        print('ℹ️ [CONTATOS] Nenhum contato de recado encontrado');
      }

      print('✅ [PREENCHER_DADOS] Formulário preenchido com sucesso');

      // ✅ VALIDAR ANTES DE setState
      if (mounted) {
        setState(() {});
      }
    } catch (e, stackTrace) {
      print('💥 [PREENCHER_DADOS] ERRO ao preencher formulário: $e');
      print('📍 [PREENCHER_DADOS] Stack trace: $stackTrace');

      // ✅ MOSTRAR ERRO AO USUÁRIO SE WIDGET MONTADO
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

// ==========================================
// MÉTODO AUXILIAR: NAVEGAÇÃO SEGURA
// ==========================================

  void _navegacaoSegura() {
    if (!mounted) {
      print('⚠️ [NAVEGACAO_SEGURA] Widget não montado');
      return;
    }

    try {
      if (Navigator.canPop(context)) {
        print('↩️ [NAVEGACAO_SEGURA] Fazendo pop');
        Navigator.of(context).pop();
      } else {
        print('↩️ [NAVEGACAO_SEGURA] Redirecionando para /candidatos');
        context.go('/candidatos');
      }
    } catch (e) {
      print('⚠️ [NAVEGACAO_SEGURA] Erro na navegação: $e');
      // Fallback: tentar forçar navegação
      try {
        context.go('/candidatos');
      } catch (e2) {
        print('💥 [NAVEGACAO_SEGURA] Falha total na navegação: $e2');
      }
    }
  }

// ✅ MÉTODO AUXILIAR: Extrair nome do arquivo da URL
  String _extrairNomeArquivoDeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return 'Comprovante existente';
    } catch (e) {
      print('Erro ao extrair nome do arquivo da URL: $e');
      return 'Comprovante existente';
    }
  }

  Widget _buildSecaoComprovanteMatricula() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF9C27B0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_file, color: Color(0xFF9C27B0), size: 20),
              SizedBox(width: 8),
              Text(
                'Comprovante de Matrícula',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ✅ VERIFICA SE TEM COMPROVANTE EXISTENTE OU NOVO ARQUIVO
          if (_temComprovanteExistente || _temComprovanteNovo) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _temComprovanteExistente
                            ? Icons.cloud_done
                            : Icons.attach_file,
                        color: const Color(0xFF4CAF50),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _temComprovanteExistente
                                  ? 'Comprovante já enviado'
                                  : 'Novo arquivo selecionado',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nomeComprovanteMatricula ?? 'Arquivo sem nome',
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                            if (_temComprovanteExistente &&
                                _comprovanteMatriculaUrl != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'URL: ${_comprovanteMatriculaUrl!.length > 50 ? "${_comprovanteMatriculaUrl!.substring(0, 50)}..." : _comprovanteMatriculaUrl!}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ✅ BOTÕES DE AÇÃO
                  Row(
                    children: [
                      // Botão Visualizar (apenas para comprovante existente)
                      if (_temComprovanteExistente &&
                          _comprovanteMatriculaUrl != null) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _visualizarComprovanteExistente,
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('Visualizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Botão Trocar Arquivo
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selecionarComprovanteMatricula,
                          icon: const Icon(Icons.swap_horiz, size: 16),
                          label: const Text('Trocar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Botão Remover
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _removerComprovanteMatricula,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Remover'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // ✅ ÁREA PARA SELECIONAR ARQUIVO (quando não tem nenhum)
            InkWell(
              onTap: _selecionarComprovanteMatricula,
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF9C27B0), width: 2),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined,
                        size: 32, color: Color(0xFF9C27B0)),
                    SizedBox(height: 8),
                    Text('Clique para selecionar o arquivo',
                        style: TextStyle(
                            color: Color(0xFF9C27B0),
                            fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text('PDF, JPG, PNG (máx. 10MB)',
                        style:
                            TextStyle(color: Color(0xFF9C27B0), fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],

          // ✅ DEBUG INFO (apenas em modo debug)
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Info:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  Text(
                    'Tem existente: $_temComprovanteExistente',
                    style: TextStyle(fontSize: 10, color: Colors.blue[600]),
                  ),
                  Text(
                    'Tem novo: $_temComprovanteNovo',
                    style: TextStyle(fontSize: 10, color: Colors.blue[600]),
                  ),
                  Text(
                    'URL: ${_comprovanteMatriculaUrl ?? "N/A"}',
                    style: TextStyle(fontSize: 10, color: Colors.blue[600]),
                  ),
                  Text(
                    'Nome: ${_nomeComprovanteMatricula ?? "N/A"}',
                    style: TextStyle(fontSize: 10, color: Colors.blue[600]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

// 3. MÉTODOS AUXILIARES PARA COMPROVANTE

  /// Verifica se tem comprovante existente (URL do servidor)
  bool get _temComprovanteExistente {
    return _comprovanteMatriculaUrl != null &&
        _comprovanteMatriculaUrl!.isNotEmpty &&
        _comprovanteMatricula == null &&
        _comprovanteMatriculaBytes == null;
  }

  /// Verifica se tem novo comprovante selecionado
  bool get _temComprovanteNovo {
    return (kIsWeb && _comprovanteMatriculaBytes != null) ||
        (!kIsWeb && _comprovanteMatricula != null);
  }

  /// Getter combinado para verificar se tem algum tipo de comprovante
  bool get _temComprovanteMatricula {
    return _temComprovanteExistente || _temComprovanteNovo;
  }

  /// Visualizar comprovante existente
  void _visualizarComprovanteExistente() {
    if (_comprovanteMatriculaUrl != null &&
        _comprovanteMatriculaUrl!.isNotEmpty) {
      final url = _comprovanteMatriculaUrl!.startsWith('http')
          ? _comprovanteMatriculaUrl!
          : 'https://cideestagio.com.br/${_comprovanteMatriculaUrl!}'; // 👈 força caminho absoluto

      if (kIsWeb) {
        html.window
            .open(url, '_blank'); // 🔹 abre em nova aba real, fora da SPA
      } else {
        // Aqui segue sua lógica mobile (ex: abrir com url_launcher)
        // launchUrl(Uri.parse(url));
      }
    }
  }

  /// Método melhorado para remover comprovante
  void _removerComprovanteMatricula() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Comprovante'),
        content: const Text(
          'Tem certeza que deseja remover o comprovante de matrícula?\n\n'
          'Esta ação não pode ser desfeita e você precisará selecionar um novo arquivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                // Limpar todos os dados do comprovante
                _comprovanteMatricula = null;
                _comprovanteMatriculaBytes = null;
                _nomeComprovanteMatricula = null;
                _comprovanteMatriculaUrl = null;
              });

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comprovante removido com sucesso!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
      String titulo = 'Candidato';
      if (widget.regimeId == '1') titulo = 'Aprendiz';
      if (widget.regimeId == '2') titulo = 'Estudante';
      return Scaffold(
        appBar: AppBar(
            title: Text(
              _isEdicaoMode ? 'Editar $titulo' : 'Cadastro de $titulo',
              style: const TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/admin/candidatos'),
            )),
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Progress Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildStepIndicator(0, 'Cadastro Principal'),
                          _buildStepConnector(),
                          _buildStepIndicator(1, 'Informações Complementares'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (_currentPage + 1) / 2,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2E7D32)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Etapa ${_currentPage + 1} de 2',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Page Content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _buildEtapa1Page(), // Dados pessoais + Endereço + Formação
                      _buildEtapa2Page(), // Contatos + Idiomas + Experiência + Informática + LGPD
                    ],
                  ),
                ),

                // Navigation Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryColor,
                              side: const BorderSide(color: Color(0xFF2E7D32)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Anterior'),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_currentPage == 1 ? _submitForm : _nextPage),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text(_currentPage == 1
                                  ? 'Finalizar Cadastro'
                                  : 'Próximo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return Scaffold(
        body: Center(
          child: Text(
            'Erro ao construir a tela: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildStepIndicator(int step, String title) {
    final isActive = step <= _currentPage;
    final isCurrent = step == _currentPage;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? _primaryColor : Colors.grey[300],
              border:
                  isCurrent ? Border.all(color: _primaryColor, width: 3) : null,
            ),
            child: Center(
              child: isActive
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? _primaryColor : Colors.grey[600],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector() {
    return Container(
      height: 2,
      width: 20,
      color: Colors.grey[300],
      margin: const EdgeInsets.only(bottom: 20),
    );
  }

  // ==================== HELPER PARA DROPDOWNS COM TRATAMENTO DE ERRO ====================

  /// Wrapper para dropdowns que pode tratar erros de assertion
  Widget _buildSafeDropdown(
      String debugName, Widget Function() dropdownBuilder) {
    try {
      return dropdownBuilder();
    } catch (e) {
      print('❌ [DROPDOWN_ERROR] Erro no dropdown $debugName: $e');

      // Em caso de erro, retornar um dropdown básico ou mensagem de erro
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Erro no campo $debugName',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Problema detectado nos dados. Entre em contato com o suporte.',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 12,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                'Debug: $e',
                style: TextStyle(
                  color: Colors.red.shade500,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      );
    }
  }

  // ==================== DROPDOWNS COM CACHE ====================

  Widget _buildDropdownIdioma() {
    if (_idiomasCache == null) {
      return const Text('Erro ao carregar idiomas');
    }

    final idiomas =
        _idiomasCache!['idiomas'] as List<modelIdioma.Idioma>? ?? [];

    _idiomasMap = {for (var idioma in idiomas) idioma.nome: idioma.id!};

    // ✅ CORREÇÃO: Validar se o value existe nos items
    String? valueSeguro = _nomeIdiomaController.text.isNotEmpty &&
            _idiomasMap.containsKey(_nomeIdiomaController.text)
        ? _nomeIdiomaController.text
        : null;

    return CustomDropdown<String>(
      value: valueSeguro,
      label: 'Idioma *',
      items: idiomas
          .map((idioma) => DropdownMenuItem<String>(
                value: idioma.nome,
                child: Text(idioma.nome),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _nomeIdiomaController.text = value ?? '';
          _idiomaSelecionadoId = value != null ? _idiomasMap[value] : null;
        });
      },
      validator: (value) =>
          value == null || value.isEmpty ? 'Idioma é obrigatório' : null,
    );
  }

  Widget _buildDropdownNivelIdioma() {
    if (_niveisIdiomaCache == null) {
      return const Text('Erro ao carregar níveis');
    }

    final niveis =
        _niveisIdiomaCache!['niveisConhecimento'] as List<NivelConhecimento>? ??
            [];

    _niveisIdiomaMap = {};
    for (var nivel in niveis) {
      final chave = nivel.nome.isNotEmpty
          ? nivel.nome
          : (nivel.descricao.isNotEmpty
              ? nivel.descricao
              : 'Nível ${nivel.id}');
      _niveisIdiomaMap[chave] = nivel.id!;
    }
    // Se regimeId == '1', campo não é obrigatório
    final regimeId = widget.regimeId;
    final campoObrigatorio = regimeId != '1';

    return CustomDropdown<String>(
      value: _nivelIdioma != null && _niveisIdiomaMap.containsKey(_nivelIdioma!)
          ? _nivelIdioma
          : null,
      label: 'Nível *',
      items: _niveisIdiomaMap.keys
          .map((chave) => DropdownMenuItem<String>(
                value: chave,
                child: Text(chave),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _nivelIdioma = value;
          _nivelIdiomaId = value != null ? _niveisIdiomaMap[value] : null;
        });
      },
      validator: (value) =>
          campoObrigatorio && value == null ? 'Nível é obrigatório' : null,
    );
  }

  Widget _buildDropdownConhecimento() {
    if (_conhecimentosCache == null) {
      return const Text('Erro ao carregar conhecimentos');
    }

    // ✅ CORREÇÃO: Só construir o mapa se estiver vazio
    if (_conhecimentosMap.isEmpty) {
      final conhecimentos = _conhecimentosCache!['conhecimentos']
              as List<modelConhecimento.Conhecimento>? ??
          [];

      _conhecimentosMap = {};
      for (var conhecimento in conhecimentos) {
        // Usar o nome como prioridade, depois descrição como fallback
        final chave = conhecimento.nome.isNotEmpty
            ? conhecimento.nome
            : (conhecimento.descricao.isNotEmpty
                ? conhecimento.descricao
                : 'Conhecimento ${conhecimento.id}');
        _conhecimentosMap[chave] = conhecimento.id!;
      }
    }

    return CustomDropdown<String>(
      value: _conhecimentoSelecionado != null &&
              _conhecimentosMap.containsKey(_conhecimentoSelecionado!)
          ? _conhecimentoSelecionado
          : null,
      label: 'Conhecimento *',
      items: _conhecimentosMap.keys
          .map((chave) => DropdownMenuItem<String>(
                value: chave,
                child: Text(chave),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _conhecimentoSelecionado = value;
          _conhecimentoSelecionadoId =
              value != null ? _conhecimentosMap[value] : null;
        });
      },
      validator: (value) => value == null ? 'Conhecimento é obrigatório' : null,
    );
  }

  Widget _buildDropdownNivelConhecimento() {
    if (_niveisConhecimentoCache == null) {
      return const Text('Erro ao carregar níveis');
    }

    // ✅ CORREÇÃO: Só construir o mapa se estiver vazio
    if (_niveisConhecimentoMap.isEmpty) {
      final niveis = _niveisConhecimentoCache!['niveisConhecimento']
              as List<NivelConhecimento>? ??
          [];

      _niveisConhecimentoMap = {};
      for (var nivel in niveis) {
        final chave = nivel.nome.isNotEmpty
            ? nivel.nome
            : (nivel.descricao.isNotEmpty
                ? nivel.descricao
                : 'Nível ${nivel.id}');
        _niveisConhecimentoMap[chave] = nivel.id!;
      }
    }

    return CustomDropdown<String>(
      value: _nivelConhecimento != null &&
              _niveisConhecimentoMap.containsKey(_nivelConhecimento!)
          ? _nivelConhecimento
          : null,
      label: 'Nível *',
      items: _niveisConhecimentoMap.keys
          .map((chave) => DropdownMenuItem<String>(
                value: chave,
                child: Text(chave),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _nivelConhecimento = value;
          _nivelConhecimentoId =
              value != null ? _niveisConhecimentoMap[value] : null;
        });
      },
      validator: (value) => value == null ? 'Nível é obrigatório' : null,
    );
  }

  Widget _buildDropdownNivelFormacao() {
    if (_niveisFormacaoCache == null) {
      return const Text('Erro ao carregar níveis de formação');
    }

    List<NivelFormacao> niveisFormacao =
        (_niveisFormacaoCache!['niveisFormacao'] as List<NivelFormacao>? ?? [])
            .toList();

    // Buscar valor pelo ID no modo edição
    String? valorNivelSelecionado = _nivelFormacao;

    if (_isEdicaoMode &&
        _nivelFormacaoId != null &&
        valorNivelSelecionado == null) {
      // Tentar encontrar o nível na lista atual (ativos)
      final nivelEncontrado = niveisFormacao
          .where((nivel) => nivel.id == _nivelFormacaoId)
          .firstOrNull;

      if (nivelEncontrado != null) {
        // Nível encontrado na lista de ativos
        valorNivelSelecionado = nivelEncontrado.nome;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _nivelFormacao != valorNivelSelecionado) {
            setState(() {
              _nivelFormacao = valorNivelSelecionado;
            });
          }
        });
      } else {
        // ✅ NOVA LÓGICA: Se nível inativo, deixar campo vazio e forçar nova seleção
        print(
            '⚠️ [NIVEL_FORMACAO] Nível ID $_nivelFormacaoId está inativo. Campo será limpo para nova seleção.');
        valorNivelSelecionado = null;

        // Limpar os valores antigos para forçar nova seleção
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _nivelFormacao = null;
              _nivelFormacaoId = null;
            });
          }
        });
      }
    }

    // Construir o mapa com todos os níveis (apenas ativos)
    _niveisFormacaoMap = {
      for (var nivel in niveisFormacao) nivel.nome: nivel.id!
    };

    // ✅ VALIDAÇÃO EXTRA: Garantir que o valor selecionado existe na lista
    if (valorNivelSelecionado != null &&
        !_niveisFormacaoMap.containsKey(valorNivelSelecionado)) {
      print(
          '⚠️ [DROPDOWN_NIVEL] Valor selecionado "$valorNivelSelecionado" não encontrado na lista. Limpando...');
      valorNivelSelecionado = null;
    }

    // ✅ VALIDAÇÃO: Remover duplicatas (caso existam) baseado no nome
    final niveisUnicos = <String, NivelFormacao>{};
    for (var nivel in niveisFormacao) {
      if (!niveisUnicos.containsKey(nivel.nome)) {
        niveisUnicos[nivel.nome] = nivel;
      }
    }
    final niveisLista = niveisUnicos.values.toList();

    // Se regimeId == '1', campo não é obrigatório
    final regimeId = widget.regimeId;
    final campoObrigatorio = regimeId != '1';

    return CustomDropdown<String>(
      value: valorNivelSelecionado,
      label: 'Nível de Formação *',
      items: niveisLista
          .map((nivel) => DropdownMenuItem(
                value: nivel.nome,
                child: Text(nivel.nome),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _nivelFormacao = value;
          _nivelFormacaoId = _niveisFormacaoMap[value];
        });
      },
      validator: (value) =>
          campoObrigatorio && value == null ? 'Nível é obrigatório' : null,
    );
  }

  Widget _buildDropdownStatusCurso() {
    if (_statusCursosCache == null) {
      return const Text('Erro ao carregar status do curso');
    }

    List<StatusCurso> statusCursos =
        (_statusCursosCache!['statusCursos'] as List<StatusCurso>? ?? [])
            .toList();

    // ✅ NOVA LÓGICA: Se regime de contratação = 2, sempre "Cursando" e readonly
    bool isRegimeContratacao2 = _regimeContratacaoId == 2;
    bool isRegimeContratacao1 = _regimeContratacaoId == 1;
    String? valorStatusSelecionado;

    if (isRegimeContratacao2 || isRegimeContratacao1) {
      // Regime 2: Forçar "Cursando" sempre
      valorStatusSelecionado = 'Cursando';

      // Garantir que as variáveis estejam sincronizadas
      if (_statusCurso != 'Cursando' || _statusCursoId != 2) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _statusCurso = 'Cursando';
              _statusCursoId = 2; // Sempre ID 2 para "Cursando"
              _exibirComprovanteObrigatorio = true;
            });
          }
        });
      }

      print('🎯 [STATUS_CURSO] Regime 2 detectado - Forçando Cursando');
    } else {
      // Buscar valor pelo ID no modo edição
      valorStatusSelecionado = _statusCurso;

      if (_isEdicaoMode &&
          _statusCursoId != null &&
          valorStatusSelecionado == null) {
        // Tentar encontrar o status na lista atual (ativos)
        final statusEncontrado = statusCursos
            .where((status) => status.id == _statusCursoId)
            .firstOrNull;

        if (statusEncontrado != null) {
          // Status encontrado na lista de ativos
          valorStatusSelecionado = statusEncontrado.nome;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _statusCurso != valorStatusSelecionado) {
              setState(() {
                _statusCurso = valorStatusSelecionado;
              });
            }
          });
        } else {
          // ✅ NOVA LÓGICA: Se status inativo, deixar campo vazio e forçar nova seleção
          print(
              '⚠️ [STATUS_CURSO] Status ID $_statusCursoId está inativo. Campo será limpo para nova seleção.');
          valorStatusSelecionado = null;

          // Limpar os valores antigos para forçar nova seleção
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _statusCurso = null;
                _statusCursoId = null;
              });
            }
          });
        }
      } else if (!_isEdicaoMode) {
        // Modo criação: forçar "Cursando" apenas se não for regime 2
        valorStatusSelecionado = 'Cursando';
        if (_statusCurso != 'Cursando') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_statusCurso != 'Cursando') {
              setState(() {
                _statusCurso = 'Cursando';
                _statusCursoId = _statusCursosMap['Cursando'];
                _exibirComprovanteObrigatorio = true;
              });
            }
          });
        }
      }

      // Verificar se precisa exibir comprovante (apenas para outros regimes)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (valorStatusSelecionado == 'Cursando' &&
            !_exibirComprovanteObrigatorio) {
          setState(() {
            _exibirComprovanteObrigatorio = true;
          });
        } else if (valorStatusSelecionado != 'Cursando' &&
            _exibirComprovanteObrigatorio) {
          setState(() {
            _exibirComprovanteObrigatorio = false;
          });
        }
      });
    }

    // Construir o mapa com todos os status (apenas ativos)
    _statusCursosMap = {
      for (var status in statusCursos) status.nome: status.id!
    };

    // ✅ VALIDAÇÃO EXTRA: Garantir que o valor selecionado existe na lista
    if (valorStatusSelecionado != null &&
        !_statusCursosMap.containsKey(valorStatusSelecionado)) {
      print(
          '⚠️ [DROPDOWN_STATUS] Valor selecionado "$valorStatusSelecionado" não encontrado na lista. Limpando...');
      valorStatusSelecionado = null;
    }

    // ✅ VALIDAÇÃO: Remover duplicatas (caso existam) baseado no nome
    final statusUnicos = <String, StatusCurso>{};
    for (var status in statusCursos) {
      if (!statusUnicos.containsKey(status.nome)) {
        statusUnicos[status.nome] = status;
      }
    }
    final statusLista = statusUnicos.values.toList();
    // Se regimeId == '1' ou '2', desabilita seleção do status do curso
    final regimeId = widget.regimeId;
    final habilitarSelecaoStatus = (regimeId == "1");
    // Exibir no console o status do regime e se a seleção está habilitada
    print(
        '🎯 [STATUS_CURSO] $habilitarSelecaoStatus - $isRegimeContratacao1 Regime ID: $regimeId, Habilitar Seleção: $habilitarSelecaoStatus');

    print(
        '🎯 [STATUS_CURSO] $habilitarSelecaoStatus -  $isRegimeContratacao1 Regime ID: $regimeId, Habilitar Seleção: $habilitarSelecaoStatus');

    // Se regimeId == '1', campo não é obrigatório
    final campoObrigatorio = regimeId != '1';
    return CustomDropdown<String>(
      value: valorStatusSelecionado,
      label: 'Status do Curso *',
      items: isRegimeContratacao2 && regimeId != '1'
          ? [
              // Regime 2 (exceto regimeId == '1'): Apenas "Cursando" disponível
              const DropdownMenuItem(
                value: 'Cursando',
                child: Text('Cursando'),
              ),
            ]
          : statusLista
              .map((status) => DropdownMenuItem(
                    value: status.nome,
                    child: Text(status.nome),
                  ))
              .toList(),
      onChanged: habilitarSelecaoStatus
          ? (value) {
              setState(() {
                _statusCurso = value;
                _statusCursoId = _statusCursosMap[value];

                // Atualizar exibição do comprovante
                _exibirComprovanteObrigatorio = (value == 'Cursando');

                // Se não for mais "Cursando", limpar comprovante
                if (value != 'Cursando') {
                  _comprovanteMatricula = null;
                  _comprovanteMatriculaBytes = null;
                  _nomeComprovanteMatricula = null;
                  // Manter URL existente para não perder dados já salvos
                }
              });
            }
          : null, // Desabilita seleção se não permitido
      validator: (value) =>
          campoObrigatorio && value == null ? 'Status é obrigatório' : null,
    );
  }

  Widget _buildDropdownTurno() {
    if (_turnosCache == null) {
      return const Text('Erro ao carregar turnos');
    }

    List<Turno> turnos =
        (_turnosCache!['turnos'] as List<Turno>? ?? []).toList();

    // Buscar valor pelo ID no modo edição
    String? valorTurnoSelecionado = _turno;

    if (_isEdicaoMode && _turnoId != null && valorTurnoSelecionado == null) {
      // Tentar encontrar o turno na lista atual (ativos)
      final turnoEncontrado =
          turnos.where((turno) => turno.id == _turnoId).firstOrNull;

      if (turnoEncontrado != null) {
        // Turno encontrado na lista de ativos
        valorTurnoSelecionado = turnoEncontrado.nome;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _turno != valorTurnoSelecionado) {
            setState(() {
              _turno = valorTurnoSelecionado;
            });
          }
        });
      } else {
        // ✅ NOVA LÓGICA: Se turno inativo, deixar campo vazio e forçar nova seleção
        print(
            '⚠️ [TURNO] Turno ID $_turnoId está inativo. Campo será limpo para nova seleção.');
        valorTurnoSelecionado = null;

        // Limpar os valores antigos para forçar nova seleção
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _turno = null;
              _turnoId = null;
            });
          }
        });
      }
    }

    // Construir o mapa com todos os turnos (apenas ativos)
    _turnosMap = {for (var turno in turnos) turno.nome: turno.id!};

    // ✅ VALIDAÇÃO EXTRA: Garantir que o valor selecionado existe na lista
    if (valorTurnoSelecionado != null &&
        !_turnosMap.containsKey(valorTurnoSelecionado)) {
      print(
          '⚠️ [DROPDOWN_TURNO] Valor selecionado "$valorTurnoSelecionado" não encontrado na lista. Limpando...');
      valorTurnoSelecionado = null;
    }

    // ✅ VALIDAÇÃO: Remover duplicatas (caso existam) baseado no nome
    final turnosUnicos = <String, Turno>{};
    for (var turno in turnos) {
      if (!turnosUnicos.containsKey(turno.nome)) {
        turnosUnicos[turno.nome] = turno;
      }
    }
    final turnosLista = turnosUnicos.values.toList();

    final regimeId = widget.regimeId;
    final campoObrigatorio = regimeId != '1';

    return CustomDropdown<String>(
      value: valorTurnoSelecionado,
      label: 'Turno',
      items: turnosLista
          .map((turno) => DropdownMenuItem(
                value: turno.nome,
                child: Text(turno.nome),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _turno = value;
          _turnoId = _turnosMap[value];
        });
      },
      validator: (value) =>
          campoObrigatorio && value == null ? 'Turno é obrigatório' : null,
    );
  }

  Widget _buildDropdownModalidade() {
    if (_modalidadesCache == null) {
      return const Text('Erro ao carregar modalidades');
    }

    List<Modalidade> modalidades =
        (_modalidadesCache!['modalidades'] as List<Modalidade>? ?? []).toList();

    // Buscar valor pelo ID no modo edição
    String? valorModalidadeSelecionada = _modalidadeFormacao;

    if (_isEdicaoMode &&
        _modalidadeId != null &&
        valorModalidadeSelecionada == null) {
      // Tentar encontrar a modalidade na lista atual (ativos)
      final modalidadeEncontrada = modalidades
          .where((modalidade) => modalidade.id == _modalidadeId)
          .firstOrNull;

      if (modalidadeEncontrada != null) {
        // Modalidade encontrada na lista de ativos
        valorModalidadeSelecionada = modalidadeEncontrada.nome;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _modalidadeFormacao != valorModalidadeSelecionada) {
            setState(() {
              _modalidadeFormacao = valorModalidadeSelecionada;
            });
          }
        });
      } else {
        // ✅ NOVA LÓGICA: Se modalidade inativa, deixar campo vazio e forçar nova seleção
        print(
            '⚠️ [MODALIDADE] Modalidade ID $_modalidadeId está inativa. Campo será limpo para nova seleção.');
        valorModalidadeSelecionada = null;

        // Limpar os valores antigos para forçar nova seleção
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _modalidadeFormacao = null;
              _modalidadeId = null;
            });
          }
        });
      }
    }

    // Construir o mapa com todas as modalidades (apenas ativas)
    _modalidadesMap = {
      for (var modalidade in modalidades) modalidade.nome: modalidade.id!
    };

    // ✅ VALIDAÇÃO EXTRA: Garantir que o valor selecionado existe na lista
    if (valorModalidadeSelecionada != null &&
        !_modalidadesMap.containsKey(valorModalidadeSelecionada)) {
      print(
          '⚠️ [DROPDOWN_MODALIDADE] Valor selecionado "$valorModalidadeSelecionada" não encontrado na lista. Limpando...');
      valorModalidadeSelecionada = null;
    }

    // ✅ VALIDAÇÃO: Remover duplicatas (caso existam) baseado no nome
    final modalidadesUnicas = <String, Modalidade>{};
    for (var modalidade in modalidades) {
      if (!modalidadesUnicas.containsKey(modalidade.nome)) {
        modalidadesUnicas[modalidade.nome] = modalidade;
      }
    }
    final modalidadesLista = modalidadesUnicas.values.toList();

    final regimeId = widget.regimeId;
    final campoObrigatorio = regimeId != '1';
    return CustomDropdown<String>(
      value: valorModalidadeSelecionada,
      label: 'Modalidade *',
      items: modalidadesLista
          .map((modalidade) => DropdownMenuItem(
                value: modalidade.nome,
                child: Text(modalidade.nome),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _modalidadeFormacao = value;
          _modalidadeId = _modalidadesMap[value];
        });
      },
      validator: (value) =>
          campoObrigatorio && value == null ? 'Modalidade é obrigatória' : null,
    );
  }

  // ==================== NOVAS ETAPAS ====================

  Widget _buildEtapa1Page() {
    try {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEÇÃO DADOS PESSOAIS
                _buildSecaoDadosPessoais(),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                if (widget.regimeId == '1') ...[
                  // SEÇÃO CARTEIRA DE TRABALHO (já existente)
                  _buildSecaoCarteiraTrabalho(),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),

                  // NOVA SEÇÃO: QUESTIONÁRIO SOCIAL
                  _buildSecaoQuestionarioSocial(),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),
                ],
                // SEÇÃO ENDEREÇO
                _buildSecaoEndereco(),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),

                // SEÇÃO DADOS BANCÁRIOS
                _buildSecaoDadosBancarios(),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),

                // SEÇÃO FORMAÇÃO ACADÊMICA (simplificada - apenas 1)
                _buildSecaoFormacaoUnica(),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),

                // NOVA: SEÇÃO CONTATOS (mover da etapa 2)
                _buildSecaoContatos(),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),

                // NOVA: SEÇÃO LGPD (mover da etapa 2)
                _buildSecaoLGPD(),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Text(
          'Erro ao construir a etapa 1: $e',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildSecaoQuestionarioSocial() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Questionário Social - Domicílio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),

          // Número de membros da família
          CustomTextField(
            controller: _numeroMembrosController,
            label:
                'Número de membros da família que moram no mesmo domicílio *',
            keyboardType: TextInputType.number,
            validator: (value) => Validators.validateRequired(
                value, 'Número de membros da família'),
          ),
          const SizedBox(height: 16),

          // Renda domiciliar
          CustomTextField(
            controller: _rendaDomiciliarController,
            label: 'Renda domiciliar mensal: R\$',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
          const SizedBox(height: 16),

          // Recebe auxílio do governo
          Row(
            children: [
              const Expanded(
                flex: 2,
                child: Text(
                  'Alguém da família recebe alguma auxílio do Governo?',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: CustomDropdown<String>(
                  value: _safeRecebeAuxilio(_recebeAuxilio),
                  label: '',
                  items: const [
                    DropdownMenuItem(value: 'Não', child: Text('Não')),
                    DropdownMenuItem(value: 'Sim', child: Text('Sim')),
                  ],
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() {
                      _recebeAuxilio = (value == 'Sim') ? 'Sim' : 'Não';
                      if (_recebeAuxilio == 'Não') {
                        _qualAuxilioController.clear();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Qual auxílio (condicional)
          if (_recebeAuxilio == 'Sim') ...[
            CustomTextField(
              controller: _qualAuxilioController,
              label: 'Qual?',
              hintText: 'Ex: Bolsa Família, Auxílio Brasil, etc.',
            ),
            const SizedBox(height: 16),
          ],
        ],
      );
    } catch (e) {
      return Text('Erro ao construir seção questionário social: $e',
          style: const TextStyle(color: Colors.red));
    }
  }

  Widget _buildEtapa2Page() {
    print(
        '🔄 [BUILD_ETAPA2] Construindo etapa 2 - _isEdicaoMode: $_isEdicaoMode, _listasCarregadas: $_listasCarregadas, _carregandoListas: $_carregandoListas, _carregamentoIniciado: $_carregamentoIniciado');

    // ✅ VERIFICAÇÃO: Se é modo edição e ainda não iniciou carregamento das listas
    if (_isEdicaoMode &&
        _candidatoId != null &&
        !_listasCarregadas &&
        !_carregandoListas &&
        !_carregamentoIniciado) {
      print('🚀 [BUILD_ETAPA2] Iniciando carregamento das listas...');
      _carregamentoIniciado = true; // Marcar como iniciado imediatamente
      // Usar WidgetsBinding para evitar setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _carregarListasEdicao();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSecaoExperiencia(),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),
              // SEÇÃO IDIOMAS
              _buildSecaoIdiomas(),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),

              // SEÇÃO CURSOS (nova seção - vamos criar depois)
              _buildSecaoCursos(),
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),

              // // SEÇÃO CONHECIMENTOS DE INFORMÁTICA
              // _buildSecaoConhecimentos(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecaoFormacaoUnica() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Formação Acadêmica',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),

          // Formulário direto (sem botões incluir/lista)
          _buildFormularioFormacaoUnica(),
        ],
      );
    } catch (e) {
      return Text(
        'Erro ao construir seção de formação acadêmica: $e',
        style: const TextStyle(color: Colors.red),
      );
    }
  }

  Widget _buildFormularioFormacaoUnica() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. NÍVEL DE FORMAÇÃO - USANDO CACHE
          if (!_dadosCarregados)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else
            _buildSafeDropdown(
                'Nível Formação', () => _buildDropdownNivelFormacao()),
          const SizedBox(height: 16),

          // 2. BUSCA DE CURSO
          _buildCampoBuscaCursoCorrigido(),
          const SizedBox(height: 16),

          // Curso Não Listado
          CustomTextField(
            controller: _cursoNaoListadoController,
            label: 'Curso Não Listado',
            hintText: 'Caso não encontre o curso acima',
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _cursoSelecionado = null;
                  _cursoId = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // 3. BUSCA DE INSTITUIÇÃO
          _buildCampoBuscaInstituicaoCorrigido(),
          const SizedBox(height: 16),

          // Instituição Não Listada
          CustomTextField(
            controller: _instituicaoNaoListadaController,
            label: 'Instituição Não Listada',
            hintText: 'Caso não encontre a instituição acima',
            onChanged: (value) {
              if (value.isNotEmpty) {
                setState(() {
                  _instituicaoSelecionada = null;
                  _instituicaoId = null;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // 4. STATUS DO CURSO - USANDO CACHE
          if (!_dadosCarregados)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else
            _buildSafeDropdown(
                'Status Curso', () => _buildDropdownStatusCurso()),
          const SizedBox(height: 16),

          // ✅ NOVO: Comprovante de matrícula (se necessário)
          if (_exibirComprovanteObrigatorio) ...[
            _buildSecaoComprovanteMatricula(),
            const SizedBox(height: 16),
          ],

          // ✅ REORGANIZADO: Data de Início do Curso e Tipo de Curso na mesma linha
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _dataInicioCurso ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 3650)), // 10 anos no futuro
                      locale: const Locale('pt', 'BR'),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: _primaryColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dataInicioCurso = pickedDate;
                        _dataInicioCursoController.text =
                            _formatarDataParaExibicao(
                                pickedDate.toIso8601String());
                      });
                    }
                  },
                  child: IgnorePointer(
                    child: CustomTextField(
                      controller: _dataInicioCursoController,
                      label: _statusCurso == 'Cursando'
                          ? 'Data de Início *'
                          : 'Data de Início',
                      hintText: 'DD/MM/AAAA',
                      validator: (value) {
                        final regimeId = widget.regimeId;
                        final campoObrigatorio =
                            regimeId != '1' && _statusCurso == 'Cursando';
                        return campoObrigatorio &&
                                (value == null || value.isEmpty)
                            ? 'Data de início é obrigatória para cursos em andamento'
                            : null;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomDropdown<String>(
                  value: _tipoCurso,
                  label: _statusCurso == 'Cursando'
                      ? 'Tipo de Curso *'
                      : 'Tipo de Curso',
                  items: const [
                    DropdownMenuItem(value: 'Periodo', child: Text('Período')),
                    DropdownMenuItem(value: 'Ano', child: Text('Ano')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoCurso = value;
                    });
                  },
                  validator: (value) {
                    final regimeId = widget.regimeId;
                    final campoObrigatorio =
                        regimeId != '1' && _statusCurso == 'Cursando';
                    return campoObrigatorio && (value == null || value.isEmpty)
                        ? 'Tipo de Curso é obrigatório para cursos em andamento'
                        : null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _semestreAnoInicialController,
                  label: _statusCurso == 'Cursando'
                      ? 'Semestre ou Ano *'
                      : 'Semestre ou Ano',
                  validator: (value) {
                    final regimeId = widget.regimeId;
                    final campoObrigatorio =
                        regimeId != '1' && _statusCurso == 'Cursando';
                    return campoObrigatorio && (value == null || value.isEmpty)
                        ? 'Semestre ou Ano é obrigatório para cursos em andamento'
                        : null;
                  },
                  hintText: 'Ex: 1, 2, 3...',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // TURNO E MODALIDADE
          Row(
            children: [
              Expanded(
                child: !_dadosCarregados
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : _buildSafeDropdown('Turno', () => _buildDropdownTurno()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: !_dadosCarregados
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : _buildSafeDropdown(
                        'Modalidade', () => _buildDropdownModalidade()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _raMatriculaController,
                  label: 'RA / Matrícula',
                ),
              ),
            ],
          ),
        ],
      );
    } catch (e) {
      return Text(
        'Erro ao construir formulário de formação acadêmica: $e',
        style: const TextStyle(color: Colors.red),
      );
    }
  }

  Widget _buildCampoBuscaCursoCorrigido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curso *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Autocomplete<modelCurso.Curso>(
          displayStringForOption: (curso) => curso.nome,
          // ✅ CORREÇÃO: Definir valor inicial se existe curso selecionado
          initialValue:
              _cursoSelecionado != null && _cursoSelecionado!.isNotEmpty
                  ? TextEditingValue(
                      text: _cursoId != null ? _cursoId!.toString() : '')
                  : const TextEditingValue(),
          optionsBuilder: (textEditingValue) async {
            final query = textEditingValue.text.trim();
            //final query = _cursoId!.toString();

            if (query.length < 3) {
              return const Iterable<modelCurso.Curso>.empty();
            }

            try {
              final result = await CursoService.buscarCurso(query);
              return result ?? [];
            } catch (e) {
              print('Erro ao buscar cursos: $e');
              return const Iterable<modelCurso.Curso>.empty();
            }
          },
          onSelected: (curso) {
            setState(() {
              _cursoSelecionado = curso.nome;
              _cursoId = curso.id;
              print('Curso selecionado: ${curso.nome} (ID: ${curso.id})');
              _cursoNaoListadoController.clear();
            });
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            // ✅ CORREÇÃO MELHORADA: Verificar e preencher o controller
            if (_cursoSelecionado != null &&
                _cursoSelecionado!.isNotEmpty &&
                controller.text != _cursoSelecionado) {
              // Use Future.microtask para evitar problemas de timing
              Future.microtask(() {
                if (mounted && controller.text != _cursoSelecionado) {
                  controller.text = _cursoSelecionado!;
                  // Mover cursor para o final
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                }
              });
            }
            final regimeId = widget.regimeId;
            final campoObrigatorio = regimeId != '1';

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                hintText:
                    'Digite o nome do curso (informe pelo menos 3 caracteres)',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          setState(() {
                            _cursoSelecionado = null;
                            _cursoId = null;
                          });
                        },
                      )
                    : null,
              ),
              // ✅ CORREÇÃO: Listener para mudanças no texto
              onChanged: (value) {
                // Se o usuário mudou o texto, limpar a seleção se não corresponder
                if (value != _cursoSelecionado) {
                  // Não limpar imediatamente para permitir edição
                  // Só limpar se o campo for totalmente limpo
                  if (value.isEmpty) {
                    setState(() {
                      _cursoSelecionado = null;
                      _cursoId = null;
                    });
                  }
                }
              },
              validator: (value) {
                if ((_cursoSelecionado == null || _cursoSelecionado!.isEmpty) &&
                    campoObrigatorio &&
                    _cursoNaoListadoController.text.trim().isEmpty) {
                  return 'Selecione um curso ou preencha "Curso Não Listado"';
                }
                return null;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _buildOptionsView(options, onSelected, Icons.school);
          },
        ),
      ],
    );
  }

  Widget _buildCampoBuscaCursoSimplificado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curso *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // ✅ SOLUÇÃO ALTERNATIVA: Campo simples que sempre mostra o valor
        TextFormField(
          // ✅ Usar valor inicial diretamente
          initialValue: _cursoSelecionado ?? '',
          decoration: InputDecoration(
            hintText: _cursoSelecionado?.isEmpty ?? true
                ? 'Digite o nome do curso (informe pelo menos 3 caracteres)'
                : null,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _cursoSelecionado?.isNotEmpty == true
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _cursoSelecionado = null;
                            _cursoId = null;
                          });
                        },
                      ),
                    ],
                  )
                : null,
          ),
          // Campo somente leitura se já tem curso selecionado
          readOnly: _cursoSelecionado?.isNotEmpty == true,
          onTap: _cursoSelecionado?.isNotEmpty == true
              ? () {
                  // Mostrar dialog para trocar curso
                  _mostrarDialogTrocarCurso();
                }
              : null,
          onChanged: (value) async {
            // Só fazer busca se não tem curso selecionado
            if (_cursoSelecionado?.isEmpty ?? true) {
              if (value.length >= 3) {
                _realizarBuscaCurso(value);
              }
            }
          },
          validator: (value) {
            if ((_cursoSelecionado == null || _cursoSelecionado!.isEmpty) &&
                _cursoNaoListadoController.text.trim().isEmpty) {
              return 'Selecione um curso ou preencha "Curso Não Listado"';
            }
            return null;
          },
        ),

        // Mostrar resultado da busca se necessário
        if (_cursosBuscaResultado.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _cursosBuscaResultado.length,
              itemBuilder: (context, index) {
                final curso = _cursosBuscaResultado[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.school, size: 16),
                  title: Text(curso.nome, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    setState(() {
                      _cursoSelecionado = curso.nome;
                      _cursoId = curso.id;
                      _cursosBuscaResultado.clear();
                      _cursoNaoListadoController.clear();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

// ========================================================================
// MÉTODOS AUXILIARES PARA A VERSÃO SIMPLIFICADA
// ========================================================================

// Adicionar estas variáveis na classe State:
  List<modelCurso.Curso> _cursosBuscaResultado = [];

  void _mostrarDialogTrocarCurso() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trocar Curso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Curso atual: $_cursoSelecionado'),
            const SizedBox(height: 16),
            const Text('Deseja buscar um novo curso?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _cursoSelecionado = null;
                _cursoId = null;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Trocar Curso',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _realizarBuscaCurso(String query) async {
    try {
      final result = await CursoService.buscarCurso(query);
      if (mounted) {
        setState(() {
          _cursosBuscaResultado = result ?? [];
        });
      }
    } catch (e) {
      print('Erro ao buscar cursos: $e');
      if (mounted) {
        setState(() {
          _cursosBuscaResultado = [];
        });
      }
    }
  }

  Widget _buildCampoBuscaInstituicaoCorrigido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Instituição *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Autocomplete<InstituicaoEnsino>(
          displayStringForOption: (instituicao) => instituicao.razaoSocial,
          optionsBuilder: (textEditingValue) async {
            final query = textEditingValue.text.trim();

            if (query.length < 3) {
              return const Iterable<InstituicaoEnsino>.empty();
            }

            try {
              final result = await InstituicaoService.buscarInstituicao(query);
              return result;
            } catch (e) {
              print('Erro ao buscar instituições: $e');
              return const Iterable<InstituicaoEnsino>.empty();
            }
          },
          onSelected: (instituicao) {
            setState(() {
              _instituicaoSelecionada = instituicao.razaoSocial;
              _instituicaoId = int.tryParse(instituicao.id ?? '');
              _instituicaoNaoListadaController.clear();
            });
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            // ✅ CORREÇÃO: Preencher o campo no modo edição
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _instituicaoSelecionada != null &&
                  _instituicaoSelecionada!.isNotEmpty &&
                  controller.text.isEmpty) {
                controller.text = _instituicaoSelecionada!;
              }
            });

            final regimeId = widget.regimeId;
            final campoObrigatorio = regimeId != '1';

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                hintText:
                    'Digite o nome da instituição (informe pelo menos 3 caracteres)',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          setState(() {
                            _instituicaoSelecionada = null;
                            _instituicaoId = null;
                          });
                        },
                      )
                    : null,
              ),
              validator: (value) {
                if ((_instituicaoSelecionada == null ||
                        _instituicaoSelecionada!.isEmpty) &&
                    campoObrigatorio &&
                    _instituicaoNaoListadaController.text.trim().isEmpty) {
                  return 'Selecione uma instituição ou preencha "Instituição Não Listada"';
                }
                return null;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _buildOptionsView(
                options, onSelected, Icons.account_balance);
          },
        ),
      ],
    );
  }

  Widget _buildSecaoCursos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cursos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            ElevatedButton.icon(
              onPressed:
                  _adicionarNovoConhecimento, // Método correto para conhecimentos/cursos
              icon: const Icon(Icons.add),
              label: const Text('Incluir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Formulário de conhecimento (corrigido para usar a variável certa)
        if (_showFormConhecimento) ...[
          _buildFormularioCurso(),
          const SizedBox(height: 24),
        ],

        // Lista de conhecimentos
        _buildListaConhecimentos(),
      ],
    );
  }

  Widget _buildSecaoCursos2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cursos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _adicionarNovoCurso,
              icon: const Icon(Icons.add),
              label: const Text('Incluir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Formulário de curso
        if (_showFormCurso) ...[
          _buildFormularioCurso(),
          const SizedBox(height: 24),
        ],

        // Lista de cursos
        _buildListaCursos(),
      ],
    );
  }

  void _adicionarNovoCurso() {
    _limparFormularioCurso();
    setState(() {
      _showFormCurso = true;
      _cursoEditando = null;
    });
  }

  void _editarCurso(Map<String, dynamic> curso) {
    _preencherFormularioCurso(curso);
    setState(() {
      _showFormCurso = true;
      _cursoEditando = curso;
    });
  }

  void _cancelarFormularioCurso() {
    _limparFormularioCurso();
    setState(() {
      _showFormCurso = false;
      _cursoEditando = null;
    });
  }

  void _limparFormularioCurso() {
    _nomeCursoController.clear();
    _instituicaoCursoController.clear();
    _cargaHorariaCursoController.clear();
    _dataInicioCursoController.clear();
    _dataFimCursoController.clear();
    _certificacaoCursoController.clear();
    _cursoAtivo = true;
  }

  void _preencherFormularioCurso(Map<String, dynamic> curso) {
    _nomeCursoController.text = curso['nome'] ?? '';
    _instituicaoCursoController.text = curso['instituicao'] ?? '';
    _cargaHorariaCursoController.text =
        curso['carga_horaria']?.toString() ?? '';
    _dataInicioCursoController.text = curso['data_inicio'] ?? '';
    _dataFimCursoController.text = curso['data_fim'] ?? '';
    _certificacaoCursoController.text = curso['certificacao'] ?? '';
    _cursoAtivo = curso['ativo'] == true;
  }

  void _salvarCurso() {
    if (_nomeCursoController.text.isEmpty) {
      _mostrarErroObrigatorio('Nome do Curso');
      return;
    }

    final novoCurso = {
      "nome": _nomeCursoController.text,
      "instituicao": _instituicaoCursoController.text.isEmpty
          ? null
          : _instituicaoCursoController.text,
      "carga_horaria": _cargaHorariaCursoController.text.isEmpty
          ? null
          : int.tryParse(_cargaHorariaCursoController.text),
      "data_inicio": _dataInicioCursoController.text.isEmpty
          ? null
          : _dataInicioCursoController.text,
      "data_fim": _dataFimCursoController.text.isEmpty
          ? null
          : _dataFimCursoController.text,
      "certificacao": _certificacaoCursoController.text.isEmpty
          ? null
          : _certificacaoCursoController.text,
      "ativo": _cursoAtivo,
      "cd_candidato": _candidatoId != null ? int.parse(_candidatoId!) : null,
    };

    setState(() {
      if (_cursoEditando != null) {
        final idx = _cursos.indexOf(_cursoEditando!);
        if (idx != -1) _cursos[idx] = novoCurso;
      } else {
        _cursos.add(novoCurso);
      }
      _showFormCurso = false;
      _cursoEditando = null;
    });

    _limparFormularioCurso();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cursoEditando != null
              ? 'Curso atualizado com sucesso!'
              : 'Curso adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildListaCursos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_cursos.isNotEmpty) ...[
          Text(
            'Cursos Cadastrados (${_cursos.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_cursos.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Nenhum curso cadastrado ainda.\nClique em "Incluir" para adicionar o primeiro curso.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._cursos.map((curso) => _buildItemCurso(curso)),
      ],
    );
  }

  Widget _buildItemCurso(Map<String, dynamic> curso) {
    final isAtivo = curso['ativo'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isAtivo ? Colors.white : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso['nome'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (curso['instituicao'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Instituição: ${curso['instituicao']}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                    if (curso['carga_horaria'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Carga Horária: ${curso['carga_horaria']}h',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                    if (curso['data_inicio'] != null ||
                        curso['data_fim'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${curso['data_inicio'] ?? ''} - ${curso['data_fim'] ?? ''}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editarCurso(curso),
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SEÇÕES EXTRAÍDAS ====================

  Widget _buildSecaoDadosPessoais() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Dados Pessoais',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // CPF, RG, Órgão Emissor e UF - RG
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cpfController,
                  label: 'CPF *',
                  inputFormatters: [_cpfFormatter],
                  keyboardType: TextInputType.number,
                  validator: Validators.validateCPF,
                  onChanged: (value) async {
                    final cpf =
                        _cpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
                    if (cpf.length == 11) {
                      setState(() => _isLoading = true);
                      try {
                        final response = await http.get(
                          Uri.parse(
                              '${config.AppConfig.apiURLPRD}/candidato/cpf/$cpf'),
                          headers: await _getHeaders(),
                        );
                        if (response.statusCode == 200) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('CPF já cadastrado!'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                          _cpfController.clear();
                        }
                      } catch (e) {
                        // Erro na consulta, pode ignorar para cadastro novo
                      } finally {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _rgController,
                  label: 'RG *',
                  hintText: 'Informe seu RG',
                  validator: (value) =>
                      Validators.validateRequired(value, 'RG'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _orgaoEmissorController,
                  label: 'Org.Emissor *',
                  hintText: 'Informe o órgão emissor do seu RG',
                  validator: (value) =>
                      Validators.validateRequired(value, 'Órgão Emissor'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: CustomDropdown<String>(
                  value: _ufRg != null && _ufs.contains(_ufRg) ? _ufRg : null,
                  label: 'UF - RG *',
                  hintText: 'UF Emissor',
                  items: _ufs
                      .map((uf) => DropdownMenuItem(
                            value: uf,
                            child: Text(uf),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _ufRg = value),
                  validator: (value) =>
                      value == null ? 'UF é obrigatória' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nome Completo, Nome Social e Data de Nascimento
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _nomeController,
                  label: 'Nome Completo *',
                  hintText: 'Informe seu Nome',
                  validator: (value) =>
                      Validators.validateRequired(value, 'Nome'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _nomeSocialController,
                  label: 'Nome Social',
                  hintText: 'Informe seu Nome Social',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: TextEditingController(
                              text: _dataNascimento != null
                                  ? '${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}'
                                  : '',
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Informe sua data de nascimento',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              color: _dataNascimento != null
                                  ? Colors.black
                                  : Colors.grey,
                              fontSize: 14,
                            ),
                            keyboardType: TextInputType.datetime,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9/]')),
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Data de nascimento é obrigatória';
                              }
                              final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
                              if (!regex.hasMatch(value)) {
                                return 'Formato inválido (DD/MM/AAAA)';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final regex =
                                  RegExp(r'^(\d{2})/(\d{2})/(\d{4})$');
                              if (regex.hasMatch(value)) {
                                final match = regex.firstMatch(value);
                                final day = int.tryParse(match?.group(1) ?? '');
                                final month =
                                    int.tryParse(match?.group(2) ?? '');
                                final year =
                                    int.tryParse(match?.group(3) ?? '');
                                if (day != null &&
                                    month != null &&
                                    year != null) {
                                  final date = DateTime.tryParse(
                                      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}');
                                  if (date != null) {
                                    setState(() {
                                      _dataNascimento = date;
                                    });
                                    _verificarIdade();
                                  }
                                }
                              }
                            },
                          ),
                        ),
                        if (_dataNascimento == null)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Text(
                              '*',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nacionalidade e Estrangeiro
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomDropdown<String>(
                  value: _nacionalidade ?? 'Brasileira',
                  label: 'Nacionalidade *',
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Selecione')),
                    DropdownMenuItem(
                        value: 'Brasileira', child: Text('Brasileira')),
                    DropdownMenuItem(
                        value: 'Argentina', child: Text('Argentina')),
                    DropdownMenuItem(value: 'Chilena', child: Text('Chilena')),
                    DropdownMenuItem(
                        value: 'Uruguaia', child: Text('Uruguaia')),
                    DropdownMenuItem(
                        value: 'Paraguaia', child: Text('Paraguaia')),
                    DropdownMenuItem(
                        value: 'Boliviana', child: Text('Boliviana')),
                    DropdownMenuItem(value: 'Peruana', child: Text('Peruana')),
                    DropdownMenuItem(
                        value: 'Equatoriana', child: Text('Equatoriana')),
                    DropdownMenuItem(
                        value: 'Colombiana', child: Text('Colombiana')),
                    DropdownMenuItem(
                        value: 'Venezuelana', child: Text('Venezuelana')),
                    DropdownMenuItem(
                        value: 'Americana', child: Text('Americana')),
                    DropdownMenuItem(
                        value: 'Canadense', child: Text('Canadense')),
                    DropdownMenuItem(
                        value: 'Mexicana', child: Text('Mexicana')),
                    DropdownMenuItem(
                        value: 'Francesa', child: Text('Francesa')),
                    DropdownMenuItem(value: 'Alemã', child: Text('Alemã')),
                    DropdownMenuItem(
                        value: 'Italiana', child: Text('Italiana')),
                    DropdownMenuItem(
                        value: 'Espanhola', child: Text('Espanhola')),
                    DropdownMenuItem(
                        value: 'Portuguesa', child: Text('Portuguesa')),
                    DropdownMenuItem(
                        value: 'Britânica', child: Text('Britânica')),
                    DropdownMenuItem(
                        value: 'Japonesa', child: Text('Japonesa')),
                    DropdownMenuItem(value: 'Chinesa', child: Text('Chinesa')),
                    DropdownMenuItem(
                        value: 'Sul-coreana', child: Text('Sul-coreana')),
                    DropdownMenuItem(value: 'Outra', child: Text('Outra')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _nacionalidade =
                          value != null && value.isNotEmpty ? value : null;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Nacionalidade é obrigatória'
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estrangeiro',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _isEstrangeiro,
                          onChanged: (value) {
                            setState(() {
                              _isEstrangeiro = value!;
                            });
                          },
                          activeColor: _primaryColor,
                        ),
                        const Text('Sim'),
                        const SizedBox(width: 16),
                        Radio<bool>(
                          value: false,
                          groupValue: _isEstrangeiro,
                          onChanged: (value) {
                            setState(() {
                              _isEstrangeiro = value!;
                            });
                          },
                          activeColor: _primaryColor,
                        ),
                        const Text('Não'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sexo, Raça, Gênero e Estado Civil (tudo na mesma linha)
          Row(
            children: [
              Expanded(
                child: CustomDropdown<String>(
                  value: _sexo != null && ['M', 'F'].contains(_sexo)
                      ? _sexo
                      : null,
                  label: 'Sexo *',
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Masculino')),
                    DropdownMenuItem(value: 'F', child: Text('Feminino')),
                    DropdownMenuItem(value: 'N', child: Text('Não Informado')),
                    DropdownMenuItem(
                        value: 'MT', child: Text('Mulher Transgênero')),
                    DropdownMenuItem(
                        value: 'HT', child: Text('Homem Transgênero')),
                  ],
                  onChanged: (value) => setState(() => _sexo = value),
                  validator: (value) =>
                      value == null ? 'Sexo é obrigatório' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomDropdown<String>(
                  value: _raca != null &&
                          [
                            'Branca',
                            'Preta',
                            'Parda',
                            'Amarela',
                            'Indígena',
                            'Prefiro não informar'
                          ].contains(_raca)
                      ? _raca
                      : null,
                  label: 'Raça *',
                  items: const [
                    DropdownMenuItem(value: 'Branca', child: Text('Branca')),
                    DropdownMenuItem(value: 'Preta', child: Text('Preta')),
                    DropdownMenuItem(value: 'Parda', child: Text('Parda')),
                    DropdownMenuItem(value: 'Amarela', child: Text('Amarela')),
                    DropdownMenuItem(
                        value: 'Indígena', child: Text('Indígena')),
                    DropdownMenuItem(
                        value: 'Prefiro não informar',
                        child: Text('Prefiro não informar')),
                  ],
                  onChanged: (value) => setState(() => _raca = value),
                  validator: (value) =>
                      value == null ? 'Raça é obrigatória' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomDropdown<String>(
                  value: _genero != null &&
                          [
                            'Nao_informar',
                            'Transgenero_Masculino',
                            'Transgenero_Feminino',
                            'Travesti_Transgenero',
                            'Genero_Neutro',
                            'Nao_Binario',
                            'Agenero',
                            'Pangenero',
                            'Genderqueer',
                            'Two_Spirit',
                            'Terceiro_Genero',
                            'Cisgenero',
                            'Todos',
                            'Nenhum'
                          ].contains(_genero)
                      ? _genero
                      : null,
                  label: 'Gênero',
                  hintText: 'Selecionar',
                  validator: (value) =>
                      value == null ? 'Gênero é obrigatório' : null,
                  items: const [
                    DropdownMenuItem(
                        value: 'Nao_informar',
                        child: Text('Prefiro não informar')),
                    DropdownMenuItem(
                        value: 'Transgenero_Masculino',
                        child: Text('Transgênero Masculino')),
                    DropdownMenuItem(
                        value: 'Transgenero_Feminino',
                        child: Text('Transgênero Feminino')),
                    DropdownMenuItem(
                        value: 'Travesti_Transgenero',
                        child: Text('Travesti/Transgênero')),
                    DropdownMenuItem(
                        value: 'Genero_Neutro', child: Text('Gênero Neutro')),
                    DropdownMenuItem(
                        value: 'Nao_Binario', child: Text('Não Binário')),
                    DropdownMenuItem(value: 'Agenero', child: Text('Agênero')),
                    DropdownMenuItem(
                        value: 'Pangenero', child: Text('Pangênero')),
                    DropdownMenuItem(
                        value: 'Genderqueer', child: Text('Genderqueer')),
                    DropdownMenuItem(
                        value: 'Two_Spirit', child: Text('Two-Spirit')),
                    DropdownMenuItem(
                        value: 'Terceiro_Genero',
                        child: Text('Terceiro Gênero')),
                    DropdownMenuItem(
                        value: 'Cisgenero', child: Text('Cisgênero')),
                    DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                    DropdownMenuItem(value: 'Nenhum', child: Text('Nenhum')),
                  ],
                  onChanged: (value) => setState(() => _genero = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomDropdown<String>(
                  value: _estadoCivil != null &&
                          [
                            'Solteiro(a)',
                            'Casado(a)',
                            'Divorciado(a)',
                            'Separado(a)',
                            'Viúvo(a)',
                            'União Estável'
                          ].contains(_estadoCivil)
                      ? _estadoCivil
                      : null,
                  label: 'Estado Civil *',
                  items: const [
                    DropdownMenuItem(
                        value: 'Solteiro(a)', child: Text('Solteiro(a)')),
                    DropdownMenuItem(
                        value: 'Casado(a)', child: Text('Casado(a)')),
                    DropdownMenuItem(
                        value: 'Divorciado(a)', child: Text('Divorciado(a)')),
                    DropdownMenuItem(
                        value: 'Viúvo(a)', child: Text('Viúvo(a)')),
                    DropdownMenuItem(
                        value: 'União Estável', child: Text('União Estável')),
                    DropdownMenuItem(
                        value: 'Separado(a)', child: Text('Separado(a)')),
                  ],
                  onChanged: (value) => setState(() => _estadoCivil = value),
                  validator: (value) =>
                      value == null ? 'Estado civil é obrigatório' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Telefone e Celular
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _telefoneController,
                  label: 'Telefone',
                  hintText: '(99) 9999-9999',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_telefoneFixoFormatter],
                  validator: Validators.validatePhone,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _celularController,
                  label: 'Celular *',
                  hintText: '(99) 99999-9999',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_telefoneFormatter],
                  validator: Validators.validatePhone,
                ),
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PCD (Pessoa com Deficiência)?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Radio<bool>(
                        value: true,
                        groupValue: _isPCD,
                        onChanged: (value) {
                          setState(() {
                            _isPCD = value!;
                          });
                        },
                        activeColor: _primaryColor,
                      ),
                      const Text('Sim'),
                      const SizedBox(width: 16),
                      Radio<bool>(
                        value: false,
                        groupValue: _isPCD,
                        onChanged: (value) {
                          setState(() {
                            _isPCD = value!;
                          });
                        },
                        activeColor: _primaryColor,
                      ),
                      const Text('Não'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // E-mail e Confirmar E-mail
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _emailController,
                  label: 'E-mail *',
                  hintText: 'Informe seu e-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _confirmarEmailController,
                  label: 'Confirmar E-mail *',
                  hintText: 'Confirme seu e-mail',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != _emailController.text) {
                      return 'E-mails não conferem';
                    }
                    return Validators.validateEmail(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Senha e Confirmar Senha
          if (_isEdicaoMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Caso deseje alterar sua senha, apenas digite uma nova senha e confirmar senha, do contrário ela será mantida',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _senhaController,
                  label: 'Senha *',
                  hintText: 'Informe a senha',
                  obscureText: true,
                  validator: (value) {
                    // Se está em modo edição e o campo está vazio, não é obrigatório
                    if (_isEdicaoMode && (value == null || value.isEmpty)) {
                      return null;
                    }
                    // Fora do modo edição, ou se digitou algo, valida normalmente
                    return Validators.validatePassword(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _confirmarSenhaController,
                  label: 'Confirmar Senha *',
                  hintText: 'Informe a confirmação da senha',
                  obscureText: true,
                  validator: (value) {
                    // Se está em modo edição e o campo está vazio, não é obrigatório
                    if (_isEdicaoMode && (value == null || value.isEmpty)) {
                      return null;
                    }
                    if (value != _senhaController.text) {
                      return 'Senhas não conferem';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Observação
          CustomTextField(
            controller: _observacaoController,
            label: 'Observação',
            hintText: 'Informações adicionais sobre o candidato',
            maxLines: 3,
          ),

          // Indicador de menor de idade
          if (_menorIdade)
            Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menor de Idade Identificado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                            Text(
                              'Será necessário o consentimento do responsável legal.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Campo para nome do responsável legal
                            if (widget.regimeId == '1') ...[
                              CustomTextField(
                                controller: _nomeResponsavelController,
                                label: 'Nome do Responsável',
                                hintText: 'Informe o nome do responsável',
                                validator: (value) =>
                                    Validators.validateRequired(
                                        value, 'Nome do Responsável'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      );
    } catch (e) {
      return Text('Erro ao construir seção de dados pessoais: $e',
          style: const TextStyle(color: Colors.red));
    }
  }

  Widget _buildSecaoEndereco() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Endereço Residencial',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),

          // CEP, Logradouro e Número na mesma linha
          Row(
            children: [
              Expanded(
                flex: 1,
                child: CustomTextField(
                  controller: _cepController,
                  label: 'CEP *',
                  inputFormatters: [_cepFormatter],
                  keyboardType: TextInputType.number,
                  validator: Validators.validateCEP,
                  onChanged: _buscarCEP,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () => _buscarCEP(_cepController.text),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _logradouroController,
                  label: 'Logradouro *',
                  validator: (value) =>
                      Validators.validateRequired(value, 'Logradouro'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: CustomTextField(
                  controller: _numeroController,
                  label: 'Número *',
                  hintText: 'S/N',
                  validator: (value) =>
                      Validators.validateRequired(value, 'Número'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bairro e Complemento
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _bairroController,
                  label: 'Bairro *',
                  validator: (value) =>
                      Validators.validateRequired(value, 'Bairro'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _complementoController,
                  label: 'Complemento',
                  hintText: 'Apto, sala, etc.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cidade e Estado
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cidadeController,
                  label: 'Cidade *',
                  validator: (value) =>
                      Validators.validateRequired(value, 'Cidade'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomDropdown<String>(
                  value: _estado,
                  label: 'Estado *',
                  items: _ufs
                      .map((uf) => DropdownMenuItem(
                            value: uf,
                            child: Text(uf),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _estado = value),
                  validator: (value) =>
                      value == null ? 'Estado é obrigatório' : null,
                ),
              ),
            ],
          ),
        ],
      );
    } catch (e) {
      return Text('Erro ao construir seção de endereço: $e',
          style: const TextStyle(color: Colors.red));
    }
  }

  //Implementar a seção de Carteira de Trabalho
  Widget _buildSecaoCarteiraTrabalho() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carteira de Trabalho',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),

          // PIS - NOVO CAMPO
          CustomTextField(
            controller: _pisController,
            label: 'PIS *',
            keyboardType: TextInputType.number,
            validator: (value) => Validators.validateRequired(value, 'PIS'),
          ),
          const SizedBox(height: 16),

          // Tipo de carteira
          Row(
            children: [
              Expanded(
                flex: 1,
                child: CustomDropdown<String>(
                  value: _isCarteiraTrabalhoFisica ? 'Física' : 'Digital',
                  label: 'Tipo de Carteira?',
                  items: const [
                    DropdownMenuItem(value: 'Física', child: Text('Física')),
                    DropdownMenuItem(value: 'Digital', child: Text('Digital')),
                  ],
                  onChanged: (value) => setState(
                      () => _isCarteiraTrabalhoFisica = value == 'Física'),
                ),
              ),
              const SizedBox(width: 16),

              // Campos condicionais baseados no tipo
              if (_isCarteiraTrabalhoFisica) ...[
                Expanded(
                  flex: 2,
                  child: CustomTextField(
                    controller: _carteiraTrabalhoNumeroController,
                    label: 'Número da Carteira *',
                    keyboardType: TextInputType.number,
                    validator: (value) => Validators.validateRequired(
                        value, 'Número da Carteira'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: CustomTextField(
                    controller: _carteiraTrabalhoNumeroSerieController,
                    label: 'Série *',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        Validators.validateRequired(value, 'Série'),
                  ),
                ),
              ] else ...[
                // Para carteira digital, mostrar CPF (somente leitura)
                Expanded(
                  flex: 3,
                  child: CustomTextField(
                    controller:
                        TextEditingController(text: _cpfController.text),
                    label: 'CPF (Carteira Digital)',
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    } catch (e) {
      return Text('Erro ao construir seção de carteira de trabalho: $e',
          style: const TextStyle(color: Colors.red));
    }
  }

  Widget _buildSecaoDadosBancarios() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dados Bancários',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),
          // Banco e Tipo de Conta na mesma linha
          Row(
            children: [
              Expanded(
                child: _buildDropdownBanco(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomDropdown<String>(
                  value: _tipoContaSelecionado,
                  label: 'Tipo de Conta',
                  items: _tiposConta
                      .map((tipo) => DropdownMenuItem(
                            value: tipo['codigo'],
                            child: Text(tipo['descricao']!),
                          ))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _tipoContaSelecionado = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Agência e Conta
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _agenciaController,
                  label: 'Agência',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _contaController,
                  label: 'Conta',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      );
    } catch (e) {
      return Text('Erro ao construir seção de dados bancários: $e',
          style: const TextStyle(color: Colors.red));
    }
  }

  Widget _buildDropdownBanco() {
    if (_bancos.isEmpty) {
      // Se ainda não carregou os bancos, mostra loading
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Banco',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Carregando bancos...'),
              ],
            ),
          ),
        ],
      );
    }

    // lista de itens com truncamento
    final items = _bancos
        .map((banco) => DropdownMenuItem<String>(
              value: banco.nome,
              child: Tooltip(
                message: banco.nome,
                waitDuration: const Duration(milliseconds: 400),
                child: Text(
                  banco.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ))
        .toList();

    // garante que o value exista nos items (evita asserts)
    final nomes = _bancos.map((b) => b.nome).toSet();
    final valueSeguro =
        (_bancoSelecionado != null && nomes.contains(_bancoSelecionado!))
            ? _bancoSelecionado
            : null;

    return CustomDropdown<String>(
      value: valueSeguro,
      label: 'Banco',
      items: items,
      isExpanded: true, // evita overflow
      // exibição do item selecionado com ellipsis
      selectedItemBuilder: (context) => _bancos
          .map(
            (b) => Align(
              alignment: Alignment.centerLeft,
              child: Tooltip(
                message: b.nome,
                waitDuration: const Duration(milliseconds: 400),
                child: Text(
                  b.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _bancoSelecionado = value;
          _bancoId = value != null ? _bancosMap[value] : null;
        });
      },
    );
  }

  Widget _buildSecaoContatos() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contatos para Recados',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),

          // Nome e Grau de Parentesco na mesma linha
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _nomeContatoRecadoController,
                  label: 'Nome',
                  //validator: (value) => Validators.validateRequired(value, 'Nome'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: CustomDropdown<String>(
                  value: _grauParentescoRecadoController.text.isNotEmpty
                      ? _grauParentescoRecadoController.text
                      : null,
                  label: 'Grau de Parentesco',
                  items: _grauParentesco
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _grauParentescoRecadoController.text = value ?? '';
                    });
                  },
                  // validator: (value) => value == null || value.isEmpty
                  //     ? 'Selecione o grau de parentesco'
                  //     : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Telefone, Celular e Whatsapp na mesma linha
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _telefoneRecadoController,
                  label: 'Telefone',
                  hintText: '(99) 9999-9999',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_telefoneFixoFormatter],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _celularRecadoController,
                  label: 'Celular',
                  hintText: '(99) 99999-9999',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_telefoneFormatter],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _whatsappRecadoController,
                  label: 'WhatsApp',
                  hintText: '(99) 99999-9999',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_telefoneFormatter],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      );
    } catch (e) {
      return Text(
        'Erro ao construir seção de contatos: $e',
        style: const TextStyle(color: Colors.red),
      );
    }
  }

  Widget _buildSecaoIdiomas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Idiomas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _adicionarNovoIdioma,
              icon: const Icon(Icons.add),
              label: const Text('Incluir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Formulário de idioma
        if (_showFormIdioma) ...[
          _buildFormularioIdioma(),
          const SizedBox(height: 24),
        ],

        // Lista de idiomas
        _buildListaIdiomas(),
      ],
    );
  }

  Widget _buildSecaoExperiencia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Experiência Profissional',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _adicionarNovaExperiencia,
              icon: const Icon(Icons.add),
              label: const Text('Incluir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Formulário de experiência
        if (_showFormExperiencia) ...[
          _buildFormularioExperiencia(),
          const SizedBox(height: 24),
        ],

        // Lista de experiências
        _buildListaExperiencias(),
      ],
    );
  }

  // Widget _buildSecaoConhecimentos() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Cabeçalho
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //         children: [
  //           const Text(
  //             'Conhecimentos de Informática',
  //             style: TextStyle(
  //               fontSize: 24,
  //               fontWeight: FontWeight.bold,
  //               color: Color(0xFF2E7D32),
  //             ),
  //           ),
  //           ElevatedButton.icon(
  //             onPressed: _adicionarNovoConhecimento,
  //             icon: const Icon(Icons.add),
  //             label: const Text('Incluir'),
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.blue,
  //               foregroundColor: Colors.white,
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 24),

  //       // Formulário de conhecimento
  //       if (_showFormConhecimento) ...[
  //         _buildFormularioConhecimento(),
  //         const SizedBox(height: 24),
  //       ],

  //       // Lista de conhecimentos
  //       _buildListaConhecimentos(),
  //     ],
  //   );
  // }

  Widget _buildSecaoLGPD() {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Termo de Aceite LGPD',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 24),

          // Container com o texto LGPD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.privacy_tip, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Lei Geral de Proteção de Dados',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const SingleChildScrollView(
                    child: Text(
                      '''
            Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), autorizo a empresa CIDE RH, a coletar, armazenar, tratar e utilizar os dados pessoais e profissionais por mim informados nesta plataforma.

            As finalidades incluem:
            • Realização de processos seletivos;
            • Divulgação de vagas de emprego;
            • Acesso e consulta à base de currículos por empresas contratantes;
            • Compartilhamento de dados com parceiros e clientes da CIDE RH para fins de recrutamento e seleção;
            • Utilização da plataforma em formato SAAS (Software as a Service), com uso de ferramentas automatizadas de triagem e análise de perfis.

            Declaro estar ciente de que:
            • Os dados serão armazenados pelo tempo necessário para cumprir as finalidades descritas;
            • Poderei, a qualquer momento, solicitar acesso, correção ou exclusão dos meus dados pessoais, conforme previsto na LGPD;
            • O CIDE RH se compromete a adotar as medidas de segurança adequadas para proteger meus dados.

            Ao prosseguir, declaro que li, compreendi e concordo com os termos acima.
            ''',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Botão Visualizar e Checkbox de Aceite
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _visualizarTermoLGPD,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Visualizar Termo Completo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Checkbox(
                          value: _aceiteLGPD,
                          onChanged: (value) {
                            setState(() {
                              _aceiteLGPD = value!;
                            });
                          },
                          activeColor: _primaryColor,
                        ),
                        const Text(
                          'Li e aceito os termos da LGPD *',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (!_aceiteLGPD)
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      'Você deve aceitar os termos da LGPD para continuar',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Texto explicativo
                const SizedBox(height: 16),
                Text(
                  'Ao marcar esta opção, você confirma que leu e compreendeu todos os termos relacionados ao tratamento de seus dados pessoais conforme a Lei Geral de Proteção de Dados (LGPD).',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      );
    } catch (e) {
      return Text(
        'Erro ao construir seção LGPD: $e',
        style: const TextStyle(color: Colors.red),
      );
    }
  }

  // ==================== MÉTODOS DE NAVEGAÇÃO ====================

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() async {
    print('[NEXT_PAGE] Iniciando _nextPage. Página atual: $_currentPage');

    if (_currentPage == 0) {
      print('[NEXT_PAGE] Salvando etapa 1 completa...');

      if (_validarEtapa1()) {
        final sucesso = await _salvarEtapa1Completa();
        print('[NEXT_PAGE] Resultado salvar etapa 1: $sucesso');

        if (!sucesso) {
          print(
              '[NEXT_PAGE] Falha ao salvar etapa 1. Abortando avanço de página.');
          return;
        }

        // ✅ CORREÇÃO: Verificar se ainda está montado após operação assíncrona
        if (!mounted) {
          print(
              '[NEXT_PAGE] Widget desmontado após salvar etapa 1. Abortando.');
          return;
        }

        // ✅ NOVA VALIDAÇÃO: Verificar se o candidato realmente existe no banco
        // ✅ IMPORTANTE: Apenas no modo de CRIAÇÃO, não na EDIÇÃO
        if (!_isEdicaoMode && _candidatoId != null) {
          final candidatoIdInt = int.tryParse(_candidatoId!);

          if (candidatoIdInt != null) {
            print('[NEXT_PAGE] ========================================');
            print('[NEXT_PAGE] MODO CRIAÇÃO - Verificando existência');
            print('[NEXT_PAGE] ID: $candidatoIdInt');
            print('[NEXT_PAGE] ========================================');

            try {
              final candidatoExiste =
                  await CandidatoService.verificarCandidatoExiste(
                      candidatoIdInt);

              print('[NEXT_PAGE] ========================================');
              print('[NEXT_PAGE] RESULTADO DA VERIFICAÇÃO');
              print('[NEXT_PAGE] candidatoExiste: $candidatoExiste');
              print('[NEXT_PAGE] Tipo: ${candidatoExiste.runtimeType}');
              print('[NEXT_PAGE] ========================================');

              // ✅ Verificar novamente se ainda está montado
              if (!mounted) {
                print(
                    '[NEXT_PAGE] Widget desmontado após verificação. Abortando.');
                return;
              }

              if (!candidatoExiste) {
                print(
                    '[NEXT_PAGE] ❌ ERRO: Candidato não existe no banco. Abortando.');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Erro: Candidato não foi salvo corretamente. Tente novamente.',
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
                return;
              }

              print(
                  '[NEXT_PAGE] ✅ Candidato confirmado no banco. ID: $candidatoIdInt');
            } catch (e) {
              print('[NEXT_PAGE] 💥 ERRO na verificação: $e');
              print('[NEXT_PAGE] Tipo do erro: ${e.runtimeType}');

              // ✅ Em caso de erro na verificação, perguntar ao usuário
              if (mounted) {
                final continuar = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange[700], size: 28),
                        const SizedBox(width: 12),
                        const Text('Erro na Verificação'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Não foi possível verificar se o candidato foi salvo corretamente.',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue[700], size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Informações:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• ID do candidato: $candidatoIdInt',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.blue[900]),
                              ),
                              Text(
                                '• O cadastro foi concluído',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.blue[900]),
                              ),
                              Text(
                                '• Erro: Timeout na verificação',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.blue[900]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Deseja continuar para a próxima etapa?',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Sim, Continuar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (!mounted) {
                  print(
                      '[NEXT_PAGE] Widget desmontado após dialog. Abortando.');
                  return;
                }

                if (continuar != true) {
                  print('[NEXT_PAGE] Usuário optou por não continuar');
                  return;
                }

                print(
                    '[NEXT_PAGE] ✅ Usuário optou por continuar mesmo com erro na verificação');
              }
            }
          } else {
            print(
                '[NEXT_PAGE] ❌ ERRO: ID do candidato inválido: $_candidatoId');

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro: ID do candidato inválido.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else if (!_isEdicaoMode && _candidatoId == null) {
          print('[NEXT_PAGE] ❌ ERRO: ID do candidato não definido');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Erro: Candidato não foi salvo. Tente novamente.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        } else if (_isEdicaoMode) {
          print(
              '[NEXT_PAGE] ℹ️ MODO EDIÇÃO - Pulando verificação de existência');
        }

        print('[NEXT_PAGE] ========================================');
        print('[NEXT_PAGE] ✅ Validação OK. Avançando para próxima página.');
        print('[NEXT_PAGE] ========================================');

        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        print('[NEXT_PAGE] ❌ Validação FALHOU. Não avança.');
      }
    }

    print('[NEXT_PAGE] Finalizando _nextPage.');
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
    );
  }

  bool _validarEtapa1() {
    print('🔍 Iniciando validação da Etapa 1...');

    print('✅ Todas as validações passaram!');
    return true;
  }

  void _mostrarErroValidacaoComFoco(
      String mensagem, TextEditingController controller) {
    // Mostrar mensagem de erro
    _mostrarErroValidacao(mensagem);

    // Selecionar todo o texto do campo para destacá-lo
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && controller.text.isNotEmpty) {
          controller.selection = TextSelection(
              baseOffset: 0, extentOffset: controller.text.length);
        }
      });
    }
  }

  void _mostrarErroValidacao(String mensagem) {
    // ✅ CORREÇÃO: Verificar se o widget ainda está montado
    if (!mounted) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensagem),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _mostrarErroObrigatorio(String campo) {
    // ✅ CORREÇÃO: Verificar se o widget ainda está montado
    if (!mounted) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$campo é obrigatório'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ==================== NOVO MÉTODO PARA SALVAR ETAPA 1 COMPLETA ====================

  Future<bool> _salvarEtapa1Completa() async {
    if (!_formKey.currentState!.validate()) return false;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      bool sucesso = false;

      if (_isEdicaoMode && _candidatoIdEdicao != null) {
        print(
            '🔄 [SALVAR_ETAPA1] Modo EDIÇÃO - Atualizando candidato ID: $_candidatoIdEdicao');
        sucesso = await _salvarEdicaoPrincipal();
      } else {
        print('➕ [SALVAR_ETAPA1] Modo CRIAÇÃO - Criando novo candidato');
        sucesso = await _salvarCadastroPrincipal();
        if (sucesso) {
          _isEdicaoMode = true;
          _candidatoIdEdicao = int.tryParse(_candidatoId!);
          print(
              '_candidatoIdEdicao: $_candidatoIdEdicao'); // Atualiza o ID para
          if (_candidatoIdEdicao != null) {
            _carregarDadosCandidato(_candidatoIdEdicao!);
          }
        }
      }

      if (!sucesso) {
        print('❌ [SALVAR_ETAPA1] Falha ao salvar candidato');
        return false;
      }

      print(
          '✅ [SALVAR_ETAPA1] Candidato salvo com sucesso - ID: $_candidatoId');
      return true;
    } catch (e) {
      print('💥 [SALVAR_ETAPA1] Erro: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar dados: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _salvarEdicaoPrincipal() async {
    if (_candidatoIdEdicao == null) {
      throw Exception('ID do candidato para edição não está definido');
    }

    try {
      // Verificar se há novo comprovante para enviar
      final temNovoComprovante =
          (kIsWeb && _comprovanteMatriculaBytes != null) ||
              (!kIsWeb && _comprovanteMatricula != null);

      print('🔍 [EDICAO] Verificando comprovantes:');
      print('   kIsWeb: $kIsWeb');
      print(
          '   _comprovanteMatriculaBytes != null: ${_comprovanteMatriculaBytes != null}');
      print(
          '   _comprovanteMatricula != null: ${_comprovanteMatricula != null}');
      print('   _comprovanteMatriculaUrl: $_comprovanteMatriculaUrl');
      print('   _nomeComprovanteMatricula: $_nomeComprovanteMatricula');
      print('   temNovoComprovante: $temNovoComprovante');

      if (temNovoComprovante) {
        // Se há novo comprovante, usar MultipartRequest
        print(
            '📂 [EDICAO] Novo comprovante detectado, usando MultipartRequest');

        final uri = Uri.parse(
            'https://cideestagio.com.br/api/candidato/alterar/$_candidatoIdEdicao');
        var request = http.MultipartRequest('PUT', uri);

        // Adicionar headers
        final headers = await _getHeaders();
        request.headers.addAll(headers);

        // Preparar dados como campos do formulário multipart
        final dadosFormulario = {
          "cpf": _cpfController.text,
          "rg": _rgController.text,
          "org_emissor": _orgaoEmissorController.text,
          "uf_rg": _ufRg ?? '',
          "pais_origem": _paisOrigem ?? '',
          "uf": _estado ?? '',
          "nome_completo": _nomeController.text,
          "nome_social": _nomeSocialController.text.isEmpty
              ? ''
              : _nomeSocialController.text,
          "data_nascimento": _dataNascimento?.toIso8601String() ?? '',
          "nacionalidade": _nacionalidade ?? '',
          "estrangeiro": _isEstrangeiro.toString(),
          "sexo": _sexo ?? '',
          "raca": _raca ?? '',
          "genero": _genero ?? '',
          "estado_civil": _estadoCivil ?? '',
          "telefone":
              _telefoneController.text.isEmpty ? '' : _telefoneController.text,
          "celular": _celularController.text,
          "email": _emailController.text,
          if (_senhaController.text.isNotEmpty) "senha": _senhaController.text,
          if (_senhaController.text.isNotEmpty &&
              _confirmarSenhaController.text.isNotEmpty)
            "confirmar_senha": _confirmarSenhaController.text,
          "pcd": _isPCD.toString(),
          "observacao": _observacaoController.text.isEmpty
              ? ''
              : _observacaoController.text,
          "id_regime_contratacao": widget.regimeId.toString(),
          "tipo_curso": _tipoCurso ?? '',
          "aceite_lgpd": _aceiteLGPD.toString(),

          //Campo Reponsavel Legal (flatten)
          "nome_responsavel": _nomeResponsavelController.text.isEmpty
              ? ''
              : _nomeResponsavelController.text,

          //Campos da Carteira de Trabalho (flatten)
          "numero_carteira_trabalho":
              _carteiraTrabalhoNumeroController.text.isEmpty
                  ? ''
                  : _carteiraTrabalhoNumeroController.text,
          "numero_serie_carteira_trabalho":
              _carteiraTrabalhoNumeroSerieController.text.isEmpty
                  ? ''
                  : _carteiraTrabalhoNumeroSerieController.text,
          "possui_carteira_fisica": _isCarteiraTrabalhoFisica.toString(),

          // Campos de endereço (flatten)
          "endereco[id_endereco]": (_enderecoId ?? '').toString(),
          "endereco[cep]": _cepController.text,
          "endereco[logradouro]": _logradouroController.text,
          "endereco[numero]": _numeroController.text,
          "endereco[bairro]": _bairroController.text,
          "endereco[cidade]": _cidadeController.text,
          "endereco[complemento]": _complementoController.text.isEmpty
              ? ''
              : _complementoController.text,
          "endereco[telefone]":
              _telefoneController.text.isEmpty ? '' : _telefoneController.text,
          "endereco[uf]": _estado ?? '',
          "endereco[ativo]": "true",
          "endereco[principal]": "true",
          "endereco[cd_candidato]": _candidatoIdEdicao.toString(),

          // Campos de formação (flatten)
          "formacao[cd_nivel_formacao]": (_nivelFormacaoId ?? '').toString(),
          "formacao[cd_curso]": (_cursoId ?? '').toString(),
          "formacao[ds_curso]": _cursoNaoListadoController.text.isNotEmpty
              ? _cursoNaoListadoController.text
              : '',
          "formacao[cd_instituicao_ensino]": (_instituicaoId ?? '').toString(),
          "formacao[ds_instituicao]":
              _instituicaoNaoListadaController.text.isNotEmpty
                  ? _instituicaoNaoListadaController.text
                  : '',
          "formacao[cd_status_curso]": (_statusCursoId ?? '').toString(),
          "formacao[semestre_ano]": _semestreAnoInicialController.text,
          "formacao[cd_turno]": (_turnoId ?? '').toString(),
          "formacao[cd_modalidade_ensino]": (_modalidadeId ?? '').toString(),
          "formacao[ra_matricula]": _raMatriculaController.text.isNotEmpty
              ? _raMatriculaController.text
              : '',
          "formacao[data_inicio_curso]": _dataInicioCurso != null // ✅ NOVO
              ? _formatarDataParaBackend(_dataInicioCursoController.text)
              : '',

          // Campos de contato (flatten)
          "contato[id_contato]": (_contatoId ?? '').toString(),
          "contato[nome]": _nomeContatoRecadoController.text,
          "contato[grau_parentesco]": _grauParentescoRecadoController.text,
          "contato[telefone]": _telefoneRecadoController.text.isEmpty
              ? ''
              : _telefoneRecadoController.text,
          "contato[celular]": _celularRecadoController.text.isEmpty
              ? ''
              : _celularRecadoController.text,
          "contato[whatsapp]":
              _whatsappRecadoController.text.isNotEmpty.toString(),
          "contato[email]": _emailContatoRecadoController.text.isEmpty
              ? ''
              : _emailContatoRecadoController.text,
          "contato[principal]": "true",
          "contato[cd_candidato]": _candidatoIdEdicao.toString(),

          // Dados bancários (campos no nível raiz, conforme payload do backend)
          "cd_banco": (_bancoId ?? '').toString(),
          "tipo_conta": _tipoContaSelecionado ?? '',
          "agencia": _agenciaController.text,
          "conta": _contaController.text,
        };

        // Adicionar campos ao request
        dadosFormulario.forEach((key, value) {
          print('📄 [EDICAO] Adicionando campo: $key = $value');
          if (value.isNotEmpty) {
            request.fields[key] = value.toString();
          }
        });

        // ✅ ADICIONAR NOVO ARQUIVO COMPROVANTE
        if (kIsWeb && _comprovanteMatriculaBytes != null) {
          print('📂 [EDICAO] Enviando novo comprovante de matrícula WEB');
          request.files.add(
            http.MultipartFile.fromBytes(
              'comprovante',
              _comprovanteMatriculaBytes as Uint8List,
              filename:
                  _nomeComprovanteMatricula ?? 'comprovante_matricula.pdf',
            ),
          );
        } else if (_comprovanteMatricula != null) {
          print('📂 [EDICAO] Enviando novo comprovante de matrícula MOBILE');
          request.files.add(
            await http.MultipartFile.fromPath(
              'comprovante',
              (_comprovanteMatricula as File).path,
              filename: _nomeComprovanteMatricula,
            ),
          );
        }

        print('📤 [EDICAO] Enviando dados de edição com comprovante...');
        print('   Campos: ${request.fields.keys}');
        print('   Arquivos: ${request.files.length}');

        // Enviar requisição
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        print('📨 [EDICAO] Resposta da edição:');
        print('   Status: ${response.statusCode}');
        print('   Body: ${response.body}');

        if (response.statusCode == 200) {
          print(
              '✅ [EDICAO] Candidato atualizado com sucesso (com comprovante)');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Candidato atualizado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }

          return true;
        } else {
          final data = jsonDecode(response.body);
          final msg = data['erro'] ?? 'Erro ao atualizar candidato';
          throw Exception(msg);
        }
      } else {
        // Se não há novo comprovante, usar requisição JSON normal
        print('📄 [EDICAO] Sem novo comprovante, usando requisição JSON');

        final dadosEdicao = {
          "cpf": _cpfController.text,
          "rg": _rgController.text,
          "org_emissor": _orgaoEmissorController.text,
          "uf_rg": _ufRg ?? '',
          "pais_origem": _paisOrigem ?? '',
          "uf": _estado ?? '',
          "nome_completo": _nomeController.text,
          "nome_social": _nomeSocialController.text.isEmpty
              ? ''
              : _nomeSocialController.text,
          "data_nascimento": _dataNascimento?.toIso8601String() ?? '',
          "nacionalidade": _nacionalidade ?? '',
          "estrangeiro": _isEstrangeiro.toString(),
          "sexo": _sexo ?? '',
          "raca": _raca ?? '',
          "genero": _genero ?? '',
          "estado_civil": _estadoCivil ?? '',
          "telefone":
              _telefoneController.text.isEmpty ? '' : _telefoneController.text,
          "celular": _celularController.text,
          "email": _emailController.text,
          if (_senhaController.text.isNotEmpty) "senha": _senhaController.text,
          if (_senhaController.text.isNotEmpty &&
              _confirmarSenhaController.text.isNotEmpty)
            "confirmar_senha": _confirmarSenhaController.text,
          "pcd": _isPCD.toString(),
          "observacao": _observacaoController.text.isEmpty
              ? ''
              : _observacaoController.text,
          "id_regime_contratacao": widget.regimeId.toString(),
          "aceite_lgpd": _aceiteLGPD.toString(),
          "tipo_curso": _tipoCurso ?? '',

          //Campo Reponsavel Legal (flatten)
          "nome_responsavel": _nomeResponsavelController.text.isEmpty
              ? ''
              : _nomeResponsavelController.text,

          //Campos da Carteira de Trabalho (flatten)
          "numero_carteira_trabalho":
              _carteiraTrabalhoNumeroController.text.isEmpty
                  ? ''
                  : _carteiraTrabalhoNumeroController.text,
          "numero_serie_carteira_trabalho":
              _carteiraTrabalhoNumeroSerieController.text.isEmpty
                  ? ''
                  : _carteiraTrabalhoNumeroSerieController.text,
          "possui_carteira_fisica": _isCarteiraTrabalhoFisica.toString(),

          "pis": _pisController.text.isEmpty ? '' : _pisController.text,

          // Campos do questionário social
          "qtd_membros_domicilio": _numeroMembrosController.text.isEmpty
              ? null
              : int.tryParse(_numeroMembrosController.text),
          "renda_domiciliar_mensal": _rendaDomiciliarController.text.isEmpty
              ? null
              : double.tryParse(
                  _rendaDomiciliarController.text.replaceAll(',', '.')),
          "recebe_auxilio_governo": _recebeAuxilio == 'Sim' ? true : false,
          "qual_auxilio_governo": _qualAuxilioController.text.isEmpty
              ? null
              : _qualAuxilioController.text,

          // Dados de endereço
          "endereco": {
            "id_endereco": _enderecoId,
            "cep": _cepController.text,
            "logradouro": _logradouroController.text,
            "numero": _numeroController.text,
            "bairro": _bairroController.text,
            "cidade": _cidadeController.text,
            "complemento": _complementoController.text.isEmpty
                ? ''
                : _complementoController.text,
            "telefone": _telefoneController.text.isEmpty
                ? ''
                : _telefoneController.text,
            "uf": _estado ?? '',
            "ativo": true,
            "principal": true,
            'cd_candidato': _candidatoIdEdicao,
          },

          // Dados de formação
          "formacao": {
            "cd_nivel_formacao": _nivelFormacaoId ?? '',
            "cd_curso": _cursoId ?? '',
            "ds_curso": _cursoNaoListadoController.text.isNotEmpty
                ? _cursoNaoListadoController.text
                : '',
            "cd_instituicao_ensino": _instituicaoId ?? '',
            "ds_instituicao": _instituicaoNaoListadaController.text.isNotEmpty
                ? _instituicaoNaoListadaController.text
                : '',
            "cd_status_curso": _statusCursoId ?? '',
            "semestre_ano": _semestreAnoInicialController.text,
            "cd_turno": _turnoId ?? '',
            "cd_modalidade_ensino": _modalidadeId ?? '',
            "ra_matricula": _raMatriculaController.text.isNotEmpty
                ? _raMatriculaController.text
                : '',
            "data_inicio_curso": _dataInicioCurso != null // ✅ NOVO
                ? _formatarDataParaBackend(_dataInicioCursoController.text)
                : '',
          },
          // Dados de contato
          if (_nomeContatoRecadoController.text.isNotEmpty &&
              _grauParentescoRecadoController.text.isNotEmpty)
            "contato": {
              "id_contato": _contatoId,
              "nome": _nomeContatoRecadoController.text,
              "grau_parentesco": _grauParentescoRecadoController.text,
              "telefone": _telefoneRecadoController.text.isEmpty
                  ? ''
                  : _telefoneRecadoController.text,
              "celular": _celularRecadoController.text.isEmpty
                  ? ''
                  : _celularRecadoController.text,
              "whatsapp": _whatsappRecadoController.text.isNotEmpty
                  ? _whatsappRecadoController.text
                  : '',
              "email": _emailContatoRecadoController.text.isEmpty
                  ? ''
                  : _emailContatoRecadoController.text,
              "principal": true,
              "cd_candidato": _candidatoIdEdicao,
            },

          // Dados bancários (campos no nível raiz, conforme payload do backend)
          "cd_banco": _bancoId,
          "tipo_conta": _tipoContaSelecionado,
          "agencia": _agenciaController.text,
          "conta": _contaController.text,
        };

        print(
            '📤 [EDICAO] Enviando dados para edição do candidato $_candidatoIdEdicao');
        print('📄 Dados de edição: $dadosEdicao');

        final candidatoAtualizado = await CandidatoService.editarCandidato(
            _candidatoIdEdicao!, dadosEdicao);

        if (candidatoAtualizado != null) {
          print('✅ [EDICAO] Candidato atualizado com sucesso');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Candidato atualizado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }

          return true;
        } else {
          throw Exception('Resposta vazia do servidor');
        }
      }
    } catch (e) {
      print('💥 [EDICAO] Erro ao editar candidato: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar candidato: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }

  Future<void> _salvarFormacaoUnica() async {
    if (_candidatoId == null) return;

    // Validar se os campos obrigatórios estão preenchidos
    if (_nivelFormacao == null ||
        ((_cursoSelecionado == null || _cursoSelecionado!.isEmpty) &&
            _cursoNaoListadoController.text.trim().isEmpty) ||
        ((_instituicaoSelecionada == null ||
                _instituicaoSelecionada!.isEmpty) &&
            _instituicaoNaoListadaController.text.trim().isEmpty) ||
        _statusCurso == null) {
      throw Exception(
          'Campos obrigatórios da formação acadêmica não preenchidos');
    }

    final dadosFormacao = {
      'cd_candidato': _candidatoId != null ? int.parse(_candidatoId!) : null,
      'id_nivel_formacao': _nivelFormacaoId,
      'id_curso': _cursoId,
      'curso_nao_listado': _cursoNaoListadoController.text.trim().isNotEmpty
          ? _cursoNaoListadoController.text.trim()
          : null,
      'id_instituicao': _instituicaoId,
      'instituicao_nao_listada':
          _instituicaoNaoListadaController.text.trim().isNotEmpty
              ? _instituicaoNaoListadaController.text.trim()
              : null,
      'id_status_curso': _statusCursoId,
      'semestre_ano_inicial':
          _semestreAnoInicialController.text.trim().isNotEmpty
              ? _semestreAnoInicialController.text.trim()
              : null,
      'semestre_ano_conclusao':
          _semestreAnoConclusaoController.text.trim().isNotEmpty
              ? _semestreAnoConclusaoController.text.trim()
              : null,
      'id_turno': _turnoId,
      'id_modalidade': _modalidadeId,
      'ra_matricula': _raMatriculaController.text.trim().isNotEmpty
          ? _raMatriculaController.text.trim()
          : null,
      'ativo': true,
    };

    final response = await http.post(
      Uri.parse('https://cideestagio.com.br/api/candidato/formacao/cadastrar'),
      headers: await _getHeaders(),
      body: jsonEncode(dadosFormacao),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao salvar formação acadêmica');
    }
  }

  // ==================== NOVO MÉTODO PARA SALVAR FORMAÇÕES ====================

  Future<void> _salvarFormacoesAcademicas() async {
    if (_candidatoId == null || _formacoesAcademicas.isEmpty) return;

    for (var formacao in _formacoesAcademicas) {
      final dadosFormacao = _prepararDadosFormacaoParaBackend(formacao);

      final response = await http.post(
        Uri.parse(
            'https://cideestagio.com.br/api/candidato/formacao/cadastrar'),
        headers: await _getHeaders(),
        body: jsonEncode(dadosFormacao),
      );

      if (response.statusCode != 201) {
        throw Exception('Erro ao salvar formação: ${formacao.curso}');
      }
    }
  }

  // ==================== MÉTODOS DE DATA ====================

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 6570)), // 18 anos
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _dataNascimento = date;
      });
      _verificarIdade();
    }
  }

  void _verificarIdade() {
    if (_dataNascimento != null) {
      final hoje = DateTime.now();
      final idade = hoje.year - _dataNascimento!.year;
      final fezAniversario = hoje.month > _dataNascimento!.month ||
          (hoje.month == _dataNascimento!.month &&
              hoje.day >= _dataNascimento!.day);

      setState(() {
        _menorIdade = fezAniversario ? idade < 18 : idade - 1 < 18;
      });
    }
  }

  // ==================== MÉTODOS DE CEP ====================

  void _buscarCEP(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length == 8) {
      setState(() => _isLoading = true);

      try {
        final response = await http.get(
          Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          if (data['erro'] == true) {
            throw Exception('CEP não encontrado');
          }

          setState(() {
            _logradouroController.text = data['logradouro'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _cidadeController.text = data['localidade'] ?? '';
            _estado = data['uf'];
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CEP encontrado!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CEP não encontrado. Verifique e tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== MÉTODOS LGPD ====================

  void _visualizarTermoLGPD() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Termo LGPD - Completo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              const Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    '''Em conformidade com a Lei Geral de Proteção de Dados (Lei nº 13.709/2018), autorizo a empresa CIDE RH, a coletar, armazenar, tratar e utilizar os dados pessoais e profissionais por mim informados nesta plataforma.

            As finalidades incluem:
            • Realização de processos seletivos;
            • Divulgação de vagas de emprego;
            • Acesso e consulta à base de currículos por empresas contratantes;
            • Compartilhamento de dados com parceiros e clientes da CIDE RH para fins de recrutamento e seleção;
            • Utilização da plataforma em formato SAAS (Software as a Service), com uso de ferramentas automatizadas de triagem e análise de perfis.

            Declaro estar ciente de que:
            • Os dados serão armazenados pelo tempo necessário para cumprir as finalidades descritas;
            • Poderei, a qualquer momento, solicitar acesso, correção ou exclusão dos meus dados pessoais, conforme previsto na LGPD;
            • O CIDE RH se compromete a adotar as medidas de segurança adequadas para proteger meus dados.

            Ao prosseguir, declaro que li, compreendi e concordo com os termos acima.
            ''',
                    style: TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MÉTODOS DE API ====================

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<bool> _salvarCadastroPrincipal() async {
    if (!_formKey.currentState!.validate()) return false;

    if (_dataNascimento == null) {
      _mostrarErroObrigatorio('Data de nascimento');
      return false;
    }

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Criar MultipartRequest em vez de POST comum
      final uri =
          Uri.parse('https://cideestagio.com.br/api/candidato/cadastrar');
      var request = http.MultipartRequest('POST', uri);

      // Adicionar headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Preparar dados como campos do formulário multipart
      final dadosFormulario = {
        "cpf": _cpfController.text,
        "rg": _rgController.text,
        "org_emissor": _orgaoEmissorController.text,
        "uf_rg": _ufRg ?? '',
        "pais_origem": _paisOrigem ?? '',
        "uf": _estado ?? '',
        "nome_completo": _nomeController.text,
        "nome_social": _nomeSocialController.text.isEmpty
            ? ''
            : _nomeSocialController.text,
        "data_nascimento": _dataNascimento?.toIso8601String() ?? '',
        "nacionalidade": _nacionalidade ?? '',
        "estrangeiro": _isEstrangeiro.toString(),
        "sexo": _sexo ?? '',
        "raca": _raca ?? '',
        "genero": _genero ?? '',
        "estado_civil": _estadoCivil ?? '',
        "telefone":
            _telefoneController.text.isEmpty ? '' : _telefoneController.text,
        "celular": _celularController.text,
        "email": _emailController.text,
        "senha": _senhaController.text,
        "pcd": _isPCD.toString(),
        "observacao": _observacaoController.text.isEmpty
            ? ''
            : _observacaoController.text,
        "id_regime_contratacao": widget.regimeId.toString(),
        "aceite_lgpd": _aceiteLGPD.toString(),
        "data_aceite_lgpd": DateTime.now().toIso8601String(),
        "tipo_curso": _tipoCurso ?? '',

        //Campo Reponsavel Legal (flatten)
        "nome_responsavel": _nomeResponsavelController.text.isEmpty
            ? ''
            : _nomeResponsavelController.text,

        //Campos da Carteira de Trabalho (flatten)
        "numero_carteira_trabalho":
            _carteiraTrabalhoNumeroController.text.isEmpty
                ? ''
                : _carteiraTrabalhoNumeroController.text,
        "numero_serie_carteira_trabalho":
            _carteiraTrabalhoNumeroSerieController.text.isEmpty
                ? ''
                : _carteiraTrabalhoNumeroSerieController.text,
        "possui_carteira_fisica": _isCarteiraTrabalhoFisica.toString(),

        "pis": _pisController.text.isEmpty ? '' : _pisController.text,

        // Campos do questionário social
        "qtd_membros_domicilio": _numeroMembrosController.text.isEmpty
            ? null
            : int.tryParse(_numeroMembrosController.text),
        "renda_domiciliar_mensal": _rendaDomiciliarController.text.isEmpty
            ? null
            : double.tryParse(
                _rendaDomiciliarController.text.replaceAll(',', '.')),
        "recebe_auxilio_governo": _recebeAuxilio == 'Sim' ? true : false,
        "qual_auxilio_governo": _qualAuxilioController.text.isEmpty
            ? null
            : _qualAuxilioController.text,

        // Campos de endereço (flatten)
        "endereco[cep]": _cepController.text,
        "endereco[logradouro]": _logradouroController.text,
        "endereco[numero]": _numeroController.text,
        "endereco[bairro]": _bairroController.text,
        "endereco[cidade]": _cidadeController.text,
        "endereco[complemento]": _complementoController.text.isEmpty
            ? ''
            : _complementoController.text,
        "endereco[telefone]":
            _telefoneController.text.isEmpty ? '' : _telefoneController.text,
        "endereco[uf]": _estado ?? '',
        "endereco[ativo]": "true",
        "endereco[principal]": "true",

        // Campos de formação (flatten)
        "formacao[cd_nivel_formacao]": (_nivelFormacaoId ?? '').toString(),
        "formacao[cd_curso]": (_cursoId ?? '').toString(),
        "formacao[ds_curso]": _cursoNaoListadoController.text.isNotEmpty
            ? _cursoNaoListadoController.text
            : '',
        "formacao[cd_instituicao_ensino]": (_instituicaoId ?? '').toString(),
        "formacao[ds_instituicao]":
            _instituicaoNaoListadaController.text.isNotEmpty
                ? _instituicaoNaoListadaController.text
                : '',
        "formacao[cd_status_curso]": (_statusCursoId ?? '').toString(),
        "formacao[semestre_ano]": _semestreAnoInicialController.text,
        "formacao[cd_turno]": (_turnoId ?? '').toString(),
        "formacao[cd_modalidade_ensino]": (_modalidadeId ?? '').toString(),
        "formacao[ra_matricula]": _raMatriculaController.text.isNotEmpty
            ? _raMatriculaController.text
            : '',
        "formacao[data_inicio_curso]": _dataInicioCurso != null // ✅ NOVO
            ? _formatarDataParaBackend(_dataInicioCursoController.text)
            : '',

        // Campos de contato (flatten)
        "contato[nome]": _nomeContatoRecadoController.text,
        "contato[grau_parentesco]": _grauParentescoRecadoController.text,
        "contato[telefone]": _telefoneRecadoController.text.isEmpty
            ? ''
            : _telefoneRecadoController.text,
        "contato[celular]": _celularRecadoController.text.isEmpty
            ? ''
            : _celularRecadoController.text,
        "contato[whatsapp]": _whatsappRecadoController.text.isEmpty
            ? ''
            : _whatsappRecadoController.text,
        "contato[email]": _emailContatoRecadoController.text.isEmpty
            ? ''
            : _emailContatoRecadoController.text,
        "contato[principal]": "true",

        // Dados bancários (campos no nível raiz, conforme payload do backend)
        "cd_banco": (_bancoId ?? '').toString(),
        "tipo_conta": _tipoContaSelecionado ?? '',
        "agencia": _agenciaController.text,
        "conta": _contaController.text,
      };

      // Adicionar campos ao request
      dadosFormulario.forEach((key, value) {
        if (value != null && (value is String ? value.isNotEmpty : true)) {
          request.fields[key] = value.toString();
        }
      });

      // ✅ ADICIONAR ARQUIVO COMPROVANTE (se existe)
      print('KisWeb: $kIsWeb');
      print('Comprovante: $_comprovanteMatricula');

      if (kIsWeb && _comprovanteMatriculaBytes != null) {
        print('📂 Enviando comprovante de matrícula WEB');
        request.files.add(
          http.MultipartFile.fromBytes(
            'comprovante',
            _comprovanteMatriculaBytes as Uint8List,
            filename: _nomeComprovanteMatricula ?? 'comprovante_matricula.pdf',
          ),
        );
      } else if (_comprovanteMatricula != null) {
        print('📂 Enviando comprovante de matrícula MOBILE');
        request.files.add(
          await http.MultipartFile.fromPath(
            'comprovante',
            (_comprovanteMatricula as File).path,
            filename: _nomeComprovanteMatricula,
          ),
        );
      }

      print('📤 Enviando cadastro de candidato...');
      print('   Campos: ${request.fields.keys}');
      print('   Arquivos: ${request.files.length}');

      // Enviar requisição
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📨 Resposta do cadastro:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 201) {
        // 🔥 CORREÇÃO: Parse correto do JSON para extrair apenas o cd_candidato
        final responseData = jsonDecode(response.body);
        final candidatoId = responseData['cd_candidato'];

        if (candidatoId != null) {
          _candidatoId = candidatoId.toString();
          print('✅ Candidato ID definido: $_candidatoId');
        } else {
          print('❌ ERRO: cd_candidato não retornado na resposta');
          throw Exception('ID do candidato não foi retornado pelo servidor');
        }

        // 🔥 CORREÇÃO: Verificar se ainda está montado antes de usar ScaffoldMessenger
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Candidato cadastrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else if (response.statusCode == 409) {
        final data = jsonDecode(response.body);
        final msg = data['erro'] ?? 'Estudante já cadastrado';

        // 🔥 CORREÇÃO: Verificar se ainda está montado
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
        return false;
      } else {
        final data = jsonDecode(response.body);
        final msg = data['erro'] ?? 'Erro ao cadastrar estudante';

        // 🔥 CORREÇÃO: Verificar se ainda está montado
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
        return false;
      }
    } catch (e) {
      print('💥 Erro no cadastro: $e');

      // 🔥 CORREÇÃO: Verificar se ainda está montado
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    } finally {
      // 🔥 CORREÇÃO: Verificar se ainda está montado antes de setState
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ========================================================================
// MÉTODOS AUXILIARES PARA VALIDAÇÃO DE ARQUIVO
// ========================================================================

  /// Valida o arquivo antes do upload
  Map<String, dynamic> _validarArquivoComprovante() {
    final resultado = {
      'valido': false,
      'erro': '',
    };

    // Se não tem arquivo e não é obrigatório, ok
    if (!_temComprovanteMatricula || _comprovanteMatricula == null) {
      resultado['valido'] = true;
      return resultado;
    }

    // Validar tipo do arquivo
    if (!_validarTipoArquivo(_nomeComprovanteMatricula)) {
      resultado['erro'] =
          'Tipo de arquivo não permitido. Use: PDF, JPG, JPEG ou PNG';
      return resultado;
    }

    // Validar tamanho
    if (!_validarTamanhoArquivo(_comprovanteMatricula)) {
      resultado['erro'] = 'Arquivo muito grande (máximo 10MB) ou vazio';
      return resultado;
    }

    resultado['valido'] = true;
    return resultado;
  }

  /// Valida o tipo de arquivo baseado na extensão
  bool _validarTipoArquivo(String? nomeArquivo) {
    if (nomeArquivo == null) return false;

    final extensao = _obterExtensaoDoNome(nomeArquivo);
    final extensoesPermitidas = ['pdf', 'jpg', 'jpeg', 'png'];

    return extensoesPermitidas.contains(extensao);
  }

  /// Obtém a extensão do arquivo
  String _obterExtensaoDoNome(String? nomeArquivo) {
    if (nomeArquivo == null || !nomeArquivo.contains('.')) {
      return 'pdf'; // Extensão padrão
    }
    return nomeArquivo.split('.').last.toLowerCase();
  }

  /// Valida o tamanho do arquivo (máximo 10MB)
  bool _validarTamanhoArquivo(dynamic arquivo) {
    const int maxSizeBytes = 10 * 1024 * 1024; // 10MB
    int tamanho = 0;

    if (arquivo is File) {
      tamanho = arquivo.lengthSync();
    } else if (arquivo is Uint8List) {
      tamanho = arquivo.length;
    }

    return tamanho <= maxSizeBytes && tamanho > 0;
  }

  // ========================================================================
  // MÉTODOS AUXILIARES PARA FORMATAÇÃO DE DATA
  // ========================================================================

  /// Converte data do formato ISO (YYYY-MM-DD) para DD/MM/YYYY para exibição
  String _formatarDataParaExibicao(String? dataISO) {
    if (dataISO == null || dataISO.isEmpty) return '';

    try {
      // Se já está no formato DD/MM/YYYY, retorna como está
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dataISO)) {
        return dataISO;
      }

      // Se está no formato ISO (YYYY-MM-DD ou YYYY-MM-DDTHH:mm:ss)
      DateTime data = DateTime.parse(dataISO);
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    } catch (e) {
      print('❌ Erro ao formatar data: $dataISO - $e');
      return dataISO; // Retorna o valor original se houver erro
    }
  }

  /// Converte data do formato DD/MM/YYYY para ISO (YYYY-MM-DD) para envio ao backend
  String _formatarDataParaBackend(String? dataBR) {
    if (dataBR == null || dataBR.isEmpty) return '';

    try {
      // Se já está no formato ISO, retorna como está
      if (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(dataBR)) {
        return dataBR;
      }

      // Se está no formato DD/MM/YYYY
      if (RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(dataBR)) {
        List<String> partes = dataBR.split('/');
        if (partes.length == 3) {
          String dia = partes[0];
          String mes = partes[1];
          String ano = partes[2];
          return '$ano-$mes-$dia';
        }
      }

      return dataBR; // Retorna o valor original se não conseguir converter
    } catch (e) {
      print('❌ Erro ao formatar data para backend: $dataBR - $e');
      return dataBR;
    }
  }

  Future<void> _submitForm() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Na etapa 2, não há campos obrigatórios específicos
      // Os dados principais já foram salvos na etapa 1

      if (mounted) {
        setState(() => _isLoading = false);

        final mensagem = _isEdicaoMode
            ? 'Candidato atualizado com sucesso!'
            : 'Cadastro realizado com sucesso!';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagem),
            backgroundColor: Colors.green,
          ),
        );

        if (mounted) {
          // Voltar para a lista de candidatos após sucesso
          context.go('/admin/candidatos/${widget.regimeId}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao finalizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _salvarEndereco() async {
    if (_candidatoId == null) return;

    final dadosEndereco = {
      "cd_candidato": _candidatoId != null ? int.tryParse(_candidatoId!) : null,
      "cep": _cepController.text,
      "logradouro": _logradouroController.text,
      "numero": _numeroController.text,
      "bairro": _bairroController.text,
      "cidade": _cidadeController.text,
      "uf": _estado,
      "complemento": _complementoController.text.isEmpty
          ? null
          : _complementoController.text,
      "ativo": true,
      "principal": true,
    };

    final response = await http.post(
      Uri.parse('https://cideestagio.com.br/api/endereco/cadastrar'),
      headers: await _getHeaders(),
      body: jsonEncode(dadosEndereco),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao salvar endereço');
    }
  }

  Future<void> _salvarContatos() async {
    if (_candidatoId == null) return;

    final dadosContatos = {
      "cd_candidato": _candidatoId != null ? int.tryParse(_candidatoId!) : null,
      "nome": _nomeContatoRecadoController.text,
      "email": _emailContatoRecadoController.text.isEmpty
          ? null
          : _emailContatoRecadoController.text,
      "celular": _celularRecadoController.text.isEmpty
          ? null
          : _celularRecadoController.text,
      "telefone": _telefoneRecadoController.text.isEmpty
          ? null
          : _telefoneRecadoController.text,
      "whatsapp": _whatsappRecadoController.text.isEmpty
          ? null
          : _whatsappRecadoController.text,
      "grau_parentesco": _grauParentescoRecadoController.text.isEmpty
          ? null
          : _grauParentescoRecadoController.text,
    };

    final response = await http.post(
      Uri.parse('https://cideestagio.com.br/api/contato/cadastrar'),
      headers: await _getHeaders(),
      body: jsonEncode(dadosContatos),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao salvar contatos');
    }
  }

  Future<void> _atualizarAceiteLGPD() async {
    if (_candidatoId == null) return;

    final dadosLGPD = {
      "aceite_lgpd": _aceiteLGPD,
      "data_aceite_lgpd": DateTime.now().toIso8601String(),
    };

    final response = await http.put(
      Uri.parse('https://cideestagio.com.br/api/candidato/lgpd/$_candidatoId'),
      headers: await _getHeaders(),
      body: jsonEncode(dadosLGPD),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar aceite LGPD');
    }
  }

  //Implementar método mock somente para etapa de dados pessoas, com todos campos já preenchidos criar um novo candidato
  // Método mock preenchimento dados pessoais
  Future<void> _mockDadosPessoaisCandidato() async {
    setState(() {
      _nomeController.text = 'João da Silva';
      _nomeSocialController.text = 'Joãozinho';
      _rgController.text = '123456789';
      _cpfController.text = '';
      _orgaoEmissorController.text = 'SSP';
      _uf = 'PR';
      _paisOrigem = 'Brasil';
      _estado = 'PR';
      _nacionalidade = 'Brasileira';
      _dataNascimento = DateTime(2000, 5, 20);
      _sexo = 'M';
      _raca = 'Branca';
      _genero = 'Cisgênero';
      _estadoCivil = 'Solteiro(a)';
      _telefoneController.text = '(41) 3333-4444';
      _celularController.text = '(41) 98888-7777';
      _isPCD = false;
      _emailController.text = 'joao.silva@email.com';
      _confirmarEmailController.text = 'joao.silva@email.com';
      _senhaController.text = 'Senha@123';
      _confirmarSenhaController.text = 'Senha@123';
      _observacaoController.text = 'Candidato mock para testes.';
      _isEstrangeiro = false;
    });
  }

  // ==================== FORMAÇÃO ACADÊMICA ====================

  void _adicionarNovaFormacao() {
    _limparFormularioFormacao();
    setState(() {
      _showFormFormacao = true;
      _formacaoEditando = null;
    });
  }

  void _editarFormacao(FormacaoAcademica formacao) {
    _preencherFormularioFormacao(formacao);
    setState(() {
      _showFormFormacao = true;
      _formacaoEditando = formacao;
    });
  }

  void _cancelarFormularioFormacao() {
    _limparFormularioFormacao();
    setState(() {
      _showFormFormacao = false;
      _formacaoEditando = null;
    });
  }

  void _salvarFormacao() {
    // Validações existentes...
    if (_nivelFormacao == null) {
      _mostrarErroObrigatorio('Nível');
      return;
    }

    if (_statusCurso == null) {
      _mostrarErroObrigatorio('Status do curso');

      return;
    }

    // ✅ NOVA VALIDAÇÃO: Comprovante obrigatório
    if (_exibirComprovanteObrigatorio && _comprovanteMatricula == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Comprovante de matrícula é obrigatório para cursos em andamento'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validar se curso foi selecionado ou preenchido
    if ((_cursoSelecionado == null || _cursoSelecionado!.isEmpty) &&
        _cursoNaoListadoController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Selecione um curso ou preencha "Cursos Não Listado"'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validar se instituição foi selecionada ou preenchida
    if ((_instituicaoSelecionada == null || _instituicaoSelecionada!.isEmpty) &&
        _instituicaoNaoListadaController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Selecione uma instituição ou preencha "Instituição Não Listada"'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Criar objeto FormacaoAcademica com IDs para backend
    final formacao = FormacaoAcademica(
      id: _formacaoEditando?.id,
      nivel: _nivelFormacao, // Descrição para exibição
      curso: _cursoSelecionado, // Descrição para exibição
      cursoNaoListado: _cursoNaoListadoController.text.trim().isNotEmpty
          ? _cursoNaoListadoController.text.trim()
          : null,
      instituicao: _instituicaoSelecionada, // Descrição para exibição
      instituicaoNaoListada:
          _instituicaoNaoListadaController.text.trim().isNotEmpty
              ? _instituicaoNaoListadaController.text.trim()
              : null,
      statusCurso: _statusCurso, // Descrição para exibição
      semestreAnoInicial: _semestreAnoInicialController.text.trim().isNotEmpty
          ? _semestreAnoInicialController.text.trim()
          : null,
      semestreAnoConclusao:
          _semestreAnoConclusaoController.text.trim().isNotEmpty
              ? _semestreAnoConclusaoController.text.trim()
              : null,
      turno: _turno, // Descrição para exibição
      modalidade: _modalidadeFormacao, // Descrição para exibição
      raMatricula: _raMatriculaController.text.trim().isNotEmpty
          ? _raMatriculaController.text.trim()
          : null,
    );

    setState(() {
      if (_formacaoEditando != null) {
        // Editar formação existente
        final index = _formacoesAcademicas
            .indexWhere((f) => f.id == _formacaoEditando!.id);
        if (index != -1) {
          _formacoesAcademicas[index] = formacao;
        }
      } else {
        // Adicionar nova formação
        _formacoesAcademicas.add(formacao.copyWith(
          id: DateTime.now().millisecondsSinceEpoch, // ID temporário
        ));
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_formacaoEditando != null
              ? 'Formação atualizada com sucesso!'
              : 'Formação adicionada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    _cancelarFormularioFormacao();
  }

  void _excluirFormacao(FormacaoAcademica formacao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
            'Tem certeza que deseja excluir esta formação acadêmica?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _formacoesAcademicas.removeWhere((f) => f.id == formacao.id);
              });
              Navigator.of(context).pop();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formação excluída com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _prepararDadosFormacaoParaBackend(
      FormacaoAcademica formacao) {
    return {
      'cd_candidato': _candidatoId != null ? int.parse(_candidatoId!) : null,
      'id_nivel_formacao': _nivelFormacaoId, // ID para o backend
      'id_curso':
          _cursoId, // ID do curso selecionado ou null se for "não listado"
      'curso_nao_listado': formacao.cursoNaoListado,
      'id_instituicao':
          _instituicaoId, // ID da instituição ou null se for "não listada"
      'instituicao_nao_listada': formacao.instituicaoNaoListada,
      'id_status_curso': _statusCursoId, // ID para o backend
      'semestre_ano_inicial': formacao.semestreAnoInicial,
      'semestre_ano_conclusao': formacao.semestreAnoConclusao,
      'id_turno': _turnoId, // ID para o backend
      'id_modalidade': _modalidadeId, // ID para o backend
      'ra_matricula': formacao.raMatricula,
      'ativo': formacao.ativo,
    };
  }

  void _limparFormularioFormacao() {
    _nivelFormacao = null;
    _nivelFormacaoId = null;
    _cursoSelecionado = null;
    _cursoId = null;
    _instituicaoSelecionada = null;
    _instituicaoId = null;
    _statusCurso = null;
    _statusCursoId = null;
    _turno = null;
    _turnoId = null;
    _modalidadeFormacao = null;
    _modalidadeId = null;

    _cursoNaoListadoController.clear();
    _instituicaoNaoListadaController.clear();
    _semestreAnoInicialController.clear();
    _semestreAnoConclusaoController.clear();
    _raMatriculaController.clear();
    _dataInicioCursoController.clear();
    _dataInicioCurso = null;

    // Limpar listas filtradas
    _cursosFiltrados.clear();
    _instituicoesFiltradas.clear();

    // ATUALIZADO: Usar método centralizado para limpar comprovante
    _limparDadosComprovante();
  }

  void _preencherFormularioFormacao(FormacaoAcademica formacao) {
    _nivelFormacao = formacao.nivel;
    _cursoSelecionado = formacao.curso;
    _cursoNaoListadoController.text = formacao.cursoNaoListado ?? '';
    _instituicaoSelecionada = formacao.instituicao;
    _instituicaoNaoListadaController.text =
        formacao.instituicaoNaoListada ?? '';
    _statusCurso = formacao.statusCurso;
    _semestreAnoInicialController.text = formacao.semestreAnoInicial ?? '';
    _semestreAnoConclusaoController.text = formacao.semestreAnoConclusao ?? '';
    _turno = formacao.turno;
    _modalidadeFormacao = formacao.modalidade;
    _raMatriculaController.text = formacao.raMatricula ?? '';

    // Definir IDs baseados nos valores selecionados
    _nivelFormacaoId = _niveisFormacaoMap[formacao.nivel];
    _statusCursoId = _statusCursosMap[formacao.statusCurso];
    _turnoId = _turnosMap[formacao.turno];
    _modalidadeId = _modalidadesMap[formacao.modalidade];
  }

  // ==================== IDIOMAS ====================

  void _adicionarNovoIdioma() {
    _limparFormularioIdioma();
    setState(() {
      _showFormIdioma = true;
      _idiomaEditando = null;
    });
  }

  void _editarIdioma(Map<String, dynamic> idioma) {
    _preencherFormularioIdioma(idioma);
    setState(() {
      _showFormIdioma = true;
      _idiomaEditando = Map<String, dynamic>.from(idioma);
    });
  }

  void _excluirIdioma(Map<String, dynamic> idioma) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Idioma'),
        content: const Text('Tem certeza que deseja excluir este idioma?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              final id = idioma['cd_idioma_candidato'];
              if (id == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID do idioma não encontrado.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              setState(() => _isLoadingIdioma = true);
              try {
                final response = await http.delete(
                  Uri.parse(
                      'https://cideestagio.com.br/api/candidato/idioma/$id'),
                  headers: await _getHeaders(),
                );
                if (response.statusCode == 200 || response.statusCode == 204) {
                  setState(() {
                    _idiomas.removeWhere((i) => i['cd_idioma_candidato'] == id);
                    _idiomasNeedRefresh = !_idiomasNeedRefresh;

                    // Remover do cache também, se existir
                    if (_idiomasCarregados != null) {
                      _idiomasCarregados!
                          .removeWhere((i) => i['cd_idioma_candidato'] == id);
                    }
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Idioma excluído com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Erro ao excluir idioma: ${response.body}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir idioma: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() => _isLoadingIdioma = false);
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _cancelarFormularioIdioma() {
    _limparFormularioIdioma();
    setState(() {
      _showFormIdioma = false;
      _idiomaEditando = null;
    });
  }

  void _limparFormularioIdioma() {
    _nomeIdiomaController.clear();
    _certificacaoIdiomaController.clear();
    _nivelIdioma = null;
  }

  void _preencherFormularioIdioma(Map<String, dynamic> idioma) {
    _nomeIdiomaController.text = idioma['nome'] ?? '';
    _nivelIdioma = idioma['nivel'];
    _certificacaoIdiomaController.text = idioma['certificacao'] ?? '';

    _idiomaSelecionadoId = idioma['cd_idioma'];
    _nivelIdiomaId = idioma['cd_nivel_conhecimento'];
  }

  Future<void> _salvarIdioma() async {
    // ✅ Prevenir múltiplos cliques
    if (_isLoadingIdioma) return;

    print('🏁 [SALVAR_IDIOMA] Iniciando salvamento de idioma...');

    if (_nomeIdiomaController.text.isEmpty) {
      print('❌ [SALVAR_IDIOMA] Validação falhou: Nome do idioma está vazio');
      _mostrarErroObrigatorio('Nome do idioma');
      return;
    }

    if (_nivelIdioma == null) {
      print(
          '❌ [SALVAR_IDIOMA] Validação falhou: Nível do idioma não selecionado');
      _mostrarErroObrigatorio('Nível do idioma');
      return;
    }

    // 🔥 CAPTURE O ID DO USUÁRIO NO INÍCIO, ANTES DE OPERAÇÕES ASSÍNCRONAS
    final usuarioId = mounted
        ? Provider.of<AuthProvider>(context, listen: false).usuario?.id
        : null;

    // ✅ Ativar loading específico do idioma
    if (mounted) {
      setState(() => _isLoadingIdioma = true);
    }

    print('📋 [SALVAR_IDIOMA] Dados coletados:');
    print('   - Nome do idioma: ${_nomeIdiomaController.text}');
    print('   - Nível: $_nivelIdioma');
    print('   - ID do idioma selecionado: $_idiomaSelecionadoId');
    print('   - ID do nível: $_nivelIdiomaId');
    print('   - ID do candidato: $_candidatoId');
    print('   - ID do usuário: $usuarioId');
    print(
        '   - Editando: ${_idiomaEditando != null ? "SIM (ID: ${_idiomaEditando!['cd_idioma_candidato']})" : "NÃO"}');

    try {
      final dadosIdioma = {
        "cd_idioma": _idiomaSelecionadoId,
        "cd_nivel_conhecimento": _nivelIdiomaId,
        "cd_candidato":
            _candidatoId != null ? int.tryParse(_candidatoId!) : null,
        "criado_por": usuarioId,
      };

      print('📤 [SALVAR_IDIOMA] Dados preparados para envio:');
      print('   - JSON: ${jsonEncode(dadosIdioma)}');

      bool sucesso = false;
      int? idIdiomaCandidato;
      String operacao = '';

      if (_idiomaEditando != null &&
          _idiomaEditando!['cd_idioma_candidato'] != null) {
        operacao = 'ATUALIZAÇÃO';
        final idIdiomaCandidatoExistente =
            _idiomaEditando!['cd_idioma_candidato'] as int;

        print('🔄 [SALVAR_IDIOMA] Iniciando $operacao do idioma...');
        print('   - ID do idioma candidato: $idIdiomaCandidatoExistente');

        try {
          sucesso = await IdiomaService.atualizarIdiomaCandidato(
            dadosIdioma,
            idIdiomaCandidato: idIdiomaCandidatoExistente,
          );

          idIdiomaCandidato = idIdiomaCandidatoExistente;

          print('📨 [SALVAR_IDIOMA] Resposta da $operacao:');
          print('   - Sucesso: $sucesso');
          print('   - ID mantido: $idIdiomaCandidato');
        } catch (serviceError) {
          print('💥 [SALVAR_IDIOMA] Erro no service de $operacao:');
          print('   - Erro: $serviceError');
          print('   - Tipo: ${serviceError.runtimeType}');
          rethrow;
        }
      } else {
        operacao = 'CRIAÇÃO';

        print('➕ [SALVAR_IDIOMA] Iniciando $operacao do idioma...');

        try {
          idIdiomaCandidato =
              await IdiomaService.criarIdiomaCandidato(dadosIdioma);
          sucesso = idIdiomaCandidato != null;

          print('📨 [SALVAR_IDIOMA] Resposta da $operacao:');
          print('   - ID retornado: $idIdiomaCandidato');
          print('   - Sucesso: $sucesso');
        } catch (serviceError) {
          print('💥 [SALVAR_IDIOMA] Erro no service de $operacao:');
          print('   - Erro: $serviceError');
          print('   - Tipo: ${serviceError.runtimeType}');
          rethrow;
        }
      }

      print('🎯 [SALVAR_IDIOMA] Resultado final da operação:');
      print('   - Operação: $operacao');
      print('   - Sucesso: $sucesso');
      print('   - ID final: $idIdiomaCandidato');

      if (sucesso) {
        print('✅ [SALVAR_IDIOMA] $operacao realizada com sucesso!');

        final novoIdiomaExibicao = {
          "cd_idioma_candidato": idIdiomaCandidato,
          "cd_idioma": _idiomaSelecionadoId,
          "nome": _nomeIdiomaController.text,
          "cd_nivel_conhecimento": _nivelIdiomaId,
          "nivel": _nivelIdioma,
          "cd_candidato":
              _candidatoId != null ? int.parse(_candidatoId!) : null,
        };

        print('🔄 [SALVAR_IDIOMA] Atualizando estado da interface...');
        print('   - Objeto para exibição: ${jsonEncode(novoIdiomaExibicao)}');

        // 🔥 CORREÇÃO: Verificar se ainda está montado antes de setState
        if (mounted) {
          setState(() {
            if (_idiomaEditando != null) {
              // Atualizar lista local para novo cadastro
              final idx = _idiomas.indexWhere((idioma) =>
                  idioma['cd_idioma_candidato'] ==
                  _idiomaEditando!['cd_idioma_candidato']);

              print('   - Atualizando idioma existente no índice: $idx');

              if (idx != -1) {
                _idiomas[idx] = novoIdiomaExibicao;
                print('   - Idioma atualizado na lista local');
              } else {
                print('   - ⚠️ Índice não encontrado, adicionando como novo');
                _idiomas.add(novoIdiomaExibicao);
              }

              // Atualizar cache do modo edição também
              if (_idiomasCarregados != null) {
                final idxCache = _idiomasCarregados!.indexWhere((idioma) =>
                    idioma['cd_idioma_candidato'] ==
                    _idiomaEditando!['cd_idioma_candidato']);

                if (idxCache != -1) {
                  _idiomasCarregados![idxCache] = novoIdiomaExibicao;
                  print('   - Idioma atualizado no cache');
                } else {
                  _idiomasCarregados!.add(novoIdiomaExibicao);
                  print('   - Idioma adicionado ao cache');
                }
              }
            } else {
              print('   - Adicionando novo idioma à lista');
              _idiomas.add(novoIdiomaExibicao);

              // Adicionar ao cache também, se existir
              if (_idiomasCarregados != null) {
                _idiomasCarregados!.add(novoIdiomaExibicao);
                print('   - Novo idioma adicionado ao cache');
              }
            }

            _showFormIdioma = false;
            _idiomaEditando = null;
            _idiomasNeedRefresh = !_idiomasNeedRefresh;

            print('   - Estado da interface atualizado');
            print('   - Total de idiomas na lista: ${_idiomas.length}');
            print(
                '   - Total de idiomas no cache: ${_idiomasCarregados?.length}');
          });
        } else {
          print(
              '⚠️ [SALVAR_IDIOMA] Widget desmontado, não foi possível atualizar o estado');
        }

        _limparFormularioIdioma();
        print('🧹 [SALVAR_IDIOMA] Formulário limpo');

        // 🔥 CORREÇÃO: Verificar se ainda está montado
        if (mounted) {
          final mensagemSucesso = _idiomaEditando != null
              ? 'Idioma atualizado com sucesso!'
              : 'Idioma adicionado com sucesso!';

          print(
              '🎉 [SALVAR_IDIOMA] Exibindo mensagem de sucesso: $mensagemSucesso');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagemSucesso),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print(
              '⚠️ [SALVAR_IDIOMA] Widget desmontado, não foi possível exibir mensagem de sucesso');
        }
      } else {
        print('❌ [SALVAR_IDIOMA] $operacao falhou!');
        print('   - Sucesso: $sucesso');
        print('   - ID retornado: $idIdiomaCandidato');

        if (mounted) {
          final mensagemErro = _idiomaEditando != null
              ? 'Erro ao atualizar idioma'
              : 'Erro ao adicionar idioma';

          print('📢 [SALVAR_IDIOMA] Exibindo mensagem de erro: $mensagemErro');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagemErro),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('💥 [SALVAR_IDIOMA] Erro inesperado capturado:');
      print('   - Erro: $e');
      print('   - Tipo: ${e.runtimeType}');
      print('   - Stack trace: $stackTrace');

      // 🔥 CORREÇÃO: Verificar se ainda está montado
      if (mounted) {
        final mensagemErroCompleta = 'Erro inesperado: ${e.toString()}';
        print(
            '📢 [SALVAR_IDIOMA] Exibindo mensagem de erro inesperado: $mensagemErroCompleta');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErroCompleta),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print(
            '⚠️ [SALVAR_IDIOMA] Widget desmontado, não foi possível exibir mensagem de erro');
      }
    } finally {
      print('🏁 [SALVAR_IDIOMA] Finalizando operação...');

      // ✅ Desativar loading específico do idioma
      if (mounted) {
        setState(() => _isLoadingIdioma = false);
        print('   - Loading state do idioma removido');
      } else {
        print(
            '   - ⚠️ Widget desmontado, não foi possível remover loading state');
      }

      print('🏁 [SALVAR_IDIOMA] Operação finalizada');
    }
  }

  Widget _buildFormularioIdioma() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _idiomaEditando != null ? 'Editar Idioma' : 'Novo Idioma',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              IconButton(
                onPressed: _cancelarFormularioIdioma,
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: !_dadosCarregados
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : _buildDropdownIdioma(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: !_dadosCarregados
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : _buildDropdownNivelIdioma(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelarFormularioIdioma,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoadingIdioma ? null : _salvarIdioma,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoadingIdioma
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_idiomaEditando != null ? 'Atualizar' : 'Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaIdiomas() {
    print(
        '🔄 [BUILD_LISTA_IDIOMAS] Sendo chamado - _candidatoId: $_candidatoId, _isEdicaoMode: $_isEdicaoMode, _listasCarregadas: $_listasCarregadas, _idiomasCarregados: ${_idiomasCarregados?.length}, _idiomas: ${_idiomas.length}');

    // ✅ CORREÇÃO: Sempre usar cache se disponível, senão usar lista local
    List<Map<String, dynamic>> listaParaExibir;

    if (_idiomasCarregados != null) {
      // Modo edição: usar cache carregado
      listaParaExibir = _idiomasCarregados!;
      print(
          '📋 [BUILD_LISTA_IDIOMAS] Usando cache carregado: ${listaParaExibir.length} itens');
    } else {
      // Modo novo cadastro ou quando cache não existe: usar lista local
      listaParaExibir = _idiomas;
      print(
          '📋 [BUILD_LISTA_IDIOMAS] Usando lista local: ${listaParaExibir.length} itens');
    }

    return Column(
      key: ValueKey('idiomas_${listaParaExibir.length}_$_idiomasNeedRefresh'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (listaParaExibir.isNotEmpty) ...[
          Text(
            'Idiomas Cadastrados (${listaParaExibir.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...listaParaExibir.map((idioma) => _buildItemIdioma(idioma)),
        ] else ...[
          // ✅ CORREÇÃO: Só mostrar loading se estiver carregando no modo edição
          if (_carregandoListas && _isEdicaoMode) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Nenhum idioma cadastrado ainda.\nClique em "Incluir" para adicionar o primeiro idioma.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _buscarIdiomasCandidato() async {
    try {
      if (_candidatoId == null || _candidatoId!.isEmpty) {
        throw Exception('ID do candidato não está definido');
      }

      final candidatoIdInt = int.tryParse(_candidatoId!);
      if (candidatoIdInt == null) {
        throw Exception(
            'ID do candidato não é um número válido: $_candidatoId');
      }

      final response = await http.get(
        Uri.parse(
            'https://cideestagio.com.br/api/candidato/idioma/listar/$candidatoIdInt'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data['dados'] is List) {
          final idiomasRaw = data['dados'] as List;
          final List<Map<String, dynamic>> idiomasConvertidos = [];

          for (var item in idiomasRaw) {
            if (item is Map<String, dynamic>) {
              final idioma = {
                'cd_idioma_candidato': item['id'],
                'cd_idioma': item['cd_idioma'],
                'nome': item['idioma']?.toString() ?? '',
                'cd_nivel_conhecimento': item['cd_nivel_conhecimento'],
                'nivel': item['nivel_conhecimento']?.toString() ?? '',
                'certificacao': item['certificacao']?.toString(),
                'ativo': item['ativo'] == true || item['ativo'] == 1,
                'cd_candidato': candidatoIdInt,
              };

              idiomasConvertidos.add(idioma);
            }
          }

          return idiomasConvertidos;
        } else {
          return [];
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildItemIdioma(Map<String, dynamic> idioma) {
    final isAtivo = idioma['ativo'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isAtivo ? Colors.white : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idioma['nome'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nível: ${idioma['nivel'] ?? ''}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editarIdioma(idioma),
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
                color: Colors.blue,
              ),
              IconButton(
                onPressed: () => _excluirIdioma(idioma),
                icon: const Icon(Icons.delete),
                tooltip: 'Excluir',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==================== EXPERIÊNCIA PROFISSIONAL ====================

  /// Carrega listas de idiomas, experiências e conhecimentos apenas uma vez no modo edição
  Future<void> _carregarListasEdicao() async {
    print('🔍 [CARREGAR_LISTAS] Verificando condições:');
    print('   - _isEdicaoMode: $_isEdicaoMode');
    print('   - _candidatoId: $_candidatoId');
    print('   - _listasCarregadas: $_listasCarregadas');
    print('   - _carregandoListas: $_carregandoListas');
    print('   - mounted: $mounted');

    // ✅ PRIMEIRA VERIFICAÇÃO: Se não é modo edição ou não tem candidato ID
    if (!_isEdicaoMode || _candidatoId == null) {
      print(
          '🚫 [CARREGAR_LISTAS] Cancelado - não é modo edição ou sem candidato ID');
      return;
    }

    // ✅ SEGUNDA VERIFICAÇÃO: Se já carregou ou está carregando
    if (_listasCarregadas) {
      print('🚫 [CARREGAR_LISTAS] Cancelado - listas já carregadas');
      return;
    }

    if (_carregandoListas) {
      print('🚫 [CARREGAR_LISTAS] Cancelado - carregamento já em andamento');
      return;
    }

    // ✅ VERIFICAÇÃO ADICIONAL: Se widget não está montado
    if (!mounted) {
      print('🚫 [CARREGAR_LISTAS] Cancelado - widget não está montado');
      return;
    }

    // ✅ Marcar como carregando IMEDIATAMENTE para evitar múltiplas chamadas
    _carregandoListas = true;
    print('🔄 [CARREGAR_LISTAS] Iniciando carregamento das listas...');

    try {
      // Carregar todas as listas em paralelo
      final resultados = await Future.wait([
        _buscarIdiomasCandidato(),
        _buscarExperienciasCandidato(),
        _buscarConhecimentosCandidato(),
      ]);

      // ✅ Verificar novamente se ainda está montado após operação assíncrona
      if (!mounted) {
        print('🚫 [CARREGAR_LISTAS] Widget desmontado durante carregamento');
        return;
      }

      _idiomasCarregados = resultados[0].cast<Map<String, dynamic>>();
      _experienciasCarregadas = resultados[1].cast<Map<String, dynamic>>();
      _conhecimentosCarregados = resultados[2].cast<Map<String, dynamic>>();

      // ✅ Marcar como carregadas ANTES do setState
      _listasCarregadas = true;

      print('✅ [CARREGAR_LISTAS] Listas carregadas com sucesso:');
      print('   - Idiomas: ${_idiomasCarregados?.length}');
      print('   - Experiências: ${_experienciasCarregadas?.length}');
      print('   - Conhecimentos: ${_conhecimentosCarregados?.length}');

      // ✅ Forçar rebuild da UI apenas se ainda montado
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ [CARREGAR_LISTAS] Erro ao carregar listas: $e');
      // ✅ Em caso de erro, resetar flag para permitir nova tentativa
      _listasCarregadas = false;
    } finally {
      // ✅ Sempre resetar flag de carregamento
      _carregandoListas = false;
    }
  }

  void _adicionarNovaExperiencia() {
    _limparFormularioExperiencia();
    setState(() {
      _showFormExperiencia = true;
      _experienciaEditando = null;
    });
  }

  void _editarExperiencia(Map<String, dynamic> experiencia) {
    _preencherFormularioExperiencia(experiencia);
    setState(() {
      _showFormExperiencia = true;
      _experienciaEditando = Map<String, dynamic>.from(experiencia);
    });
  }

  void _cancelarFormularioExperiencia() {
    _limparFormularioExperiencia();
    setState(() {
      _showFormExperiencia = false;
      _experienciaEditando = null;
    });
  }

  void _limparFormularioExperiencia() {
    _empresaController.clear();
    _atividadesController.clear();
    _dataInicioExpController.clear();
    _dataFimExpController.clear();
  }

  void _preencherFormularioExperiencia(Map<String, dynamic> experiencia) {
    // ✅ CORREÇÃO: Usar o campo correto 'nome_empresa' em vez de 'empresa'
    _empresaController.text =
        experiencia['nome_empresa'] ?? experiencia['empresa'] ?? '';
    _atividadesController.text = experiencia['atividades'] ?? '';

    // ✅ CORREÇÃO: Formatar datas para DD/MM/YYYY
    String dataInicio = experiencia['data_inicio'] ?? '';
    String dataFim = experiencia['data_fim'] ?? '';

    // Converter formato ISO para DD/MM/YYYY se necessário
    _dataInicioExpController.text = _formatarDataParaExibicao(dataInicio);
    _dataFimExpController.text = _formatarDataParaExibicao(dataFim);
  }

  Future<void> _salvarExperiencia() async {
    // ✅ Prevenir múltiplos cliques
    if (_isLoadingExperiencia) return;

    if (_empresaController.text.isEmpty) {
      _mostrarErroObrigatorio('Empresa');
      return;
    }

    if (_dataInicioExpController.text.isEmpty) {
      _mostrarErroObrigatorio('Data de início');
      return;
    }

    // 🔥 CAPTURE O ID DO USUÁRIO NO INÍCIO
    final usuarioId = mounted
        ? Provider.of<AuthProvider>(context, listen: false).usuario?.id
        : null;

    // ✅ Ativar loading específico da experiência
    if (mounted) {
      setState(() => _isLoadingExperiencia = true);
    }

    try {
      final dadosExperiencia = {
        "cd_candidato":
            _candidatoId != null ? int.tryParse(_candidatoId!) : null,
        "nome_empresa": _empresaController.text.trim(),
        "atividades": _atividadesController.text.trim().isEmpty
            ? null
            : _atividadesController.text.trim(),
        // ✅ CORREÇÃO: Usar método de formatação para backend
        "data_inicio": _formatarDataParaBackend(
                    _dataInicioExpController.text.trim())
                .isEmpty
            ? null
            : _formatarDataParaBackend(_dataInicioExpController.text.trim()),
        "data_fim":
            _formatarDataParaBackend(_dataFimExpController.text.trim()).isEmpty
                ? null
                : _formatarDataParaBackend(_dataFimExpController.text.trim()),
        "criado_por": usuarioId,
      };

      bool sucesso = false;
      int? idExperiencia;

      if (_experienciaEditando != null &&
          _experienciaEditando!['cd_experiencia_candidato'] != null) {
        final idExp = _experienciaEditando!['cd_experiencia_candidato'] as int;

        final dadosExperienciaEdicao =
            Map<String, dynamic>.from(dadosExperiencia);
        dadosExperienciaEdicao.remove('criado_por');
        dadosExperienciaEdicao['atualizado_por'] = usuarioId;

        final response = await http.put(
          Uri.parse(
              'https://cideestagio.com.br/api/candidato/experiencia/alterar/$idExp'),
          headers: await _getHeaders(),
          body: jsonEncode(dadosExperienciaEdicao),
        );

        sucesso = response.statusCode == 200;
        idExperiencia = idExp;
      } else {
        final response = await http.post(
          Uri.parse(
              'https://cideestagio.com.br/api/candidato/experiencia/cadastrar'),
          headers: await _getHeaders(),
          body: jsonEncode(dadosExperiencia),
        );

        if (response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          idExperiencia = responseData['cd_experiencia_candidato'];
          sucesso = true;
        }
      }

      if (sucesso) {
        final novaExperienciaExibicao = {
          "cd_experiencia_candidato": idExperiencia,
          "nome_empresa": _empresaController.text.trim(),
          "atividades": _atividadesController.text.trim().isEmpty
              ? null
              : _atividadesController.text.trim(),
          "data_inicio": _dataInicioExpController.text.trim(),
          "data_fim": _dataFimExpController.text.trim(),
          "cd_candidato":
              _candidatoId != null ? int.parse(_candidatoId!) : null,
        };

        if (mounted) {
          setState(() {
            if (_experienciaEditando != null) {
              // Atualizar lista local
              final idx = _experiencias.indexWhere((exp) =>
                  exp['cd_experiencia_candidato'] ==
                  _experienciaEditando!['cd_experiencia_candidato']);
              if (idx != -1) {
                _experiencias[idx] = novaExperienciaExibicao;
              }

              // Atualizar cache do modo edição também
              if (_experienciasCarregadas != null) {
                final idxCache = _experienciasCarregadas!.indexWhere((exp) =>
                    exp['cd_experiencia_candidato'] ==
                    _experienciaEditando!['cd_experiencia_candidato']);

                if (idxCache != -1) {
                  _experienciasCarregadas![idxCache] = novaExperienciaExibicao;
                } else {
                  _experienciasCarregadas!.add(novaExperienciaExibicao);
                }
              }
            } else {
              _experiencias.add(novaExperienciaExibicao);

              // Adicionar ao cache também, se existir
              if (_experienciasCarregadas != null) {
                _experienciasCarregadas!.add(novaExperienciaExibicao);
              }
            }

            _showFormExperiencia = false;
            _experienciaEditando = null;
            _experienciasNeedRefresh = !_experienciasNeedRefresh;
          });
        }

        _limparFormularioExperiencia();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_experienciaEditando != null
                  ? 'Experiência atualizada com sucesso!'
                  : 'Experiência adicionada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // ✅ Desativar loading específico da experiência
      if (mounted) {
        setState(() => _isLoadingExperiencia = false);
      }
    }
  }

  Widget _buildFormularioExperiencia() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _experienciaEditando != null
                    ? 'Editar Experiência'
                    : 'Nova Experiência',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              IconButton(
                onPressed: _cancelarFormularioExperiencia,
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar',
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _empresaController,
            label: 'Empresa *',
            hintText: 'Nome da empresa',
            validator: (value) => Validators.validateRequired(value, 'Empresa'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _atividadesController,
            label: 'Atividades Desenvolvidas',
            hintText: 'Descreva as principais atividades e responsabilidades',
            maxLines: 3,
            validator: (value) =>
                Validators.validateRequired(value, 'Atividades Desenvolvidas'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      locale: const Locale('pt', 'BR'),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: _primaryColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dataInicioExpController.text =
                            '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                      });
                    }
                  },
                  child: IgnorePointer(
                    child: CustomTextField(
                      controller: _dataInicioExpController,
                      label: 'Data de Início *',
                      hintText: 'DD/MM/YYYY',
                      validator: (value) =>
                          Validators.validateRequired(value, 'Data de Início'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                      locale: const Locale('pt', 'BR'),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: _primaryColor,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dataFimExpController.text =
                            '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';
                      });
                    }
                  },
                  child: IgnorePointer(
                    child: CustomTextField(
                      controller: _dataFimExpController,
                      label: 'Data de Fim',
                      hintText: 'DD/MM/YYYY',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelarFormularioExperiencia,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoadingExperiencia ? null : _salvarExperiencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoadingExperiencia
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(_experienciaEditando != null
                          ? 'Atualizar'
                          : 'Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaExperiencias() {
    print(
        '🔄 [BUILD_LISTA_EXPERIENCIAS] Sendo chamado - _candidatoId: $_candidatoId, _isEdicaoMode: $_isEdicaoMode, _listasCarregadas: $_listasCarregadas, _experienciasCarregadas: ${_experienciasCarregadas?.length}, _experiencias: ${_experiencias.length}');

    // ✅ CORREÇÃO: Sempre usar cache se disponível, senão usar lista local
    List<Map<String, dynamic>> listaParaExibir;

    if (_experienciasCarregadas != null) {
      // Modo edição: usar cache carregado
      listaParaExibir = _experienciasCarregadas!;
      print(
          '📋 [BUILD_LISTA_EXPERIENCIAS] Usando cache carregado: ${listaParaExibir.length} itens');
    } else {
      // Modo novo cadastro ou quando cache não existe: usar lista local
      listaParaExibir = _experiencias;
      print(
          '📋 [BUILD_LISTA_EXPERIENCIAS] Usando lista local: ${listaParaExibir.length} itens');
    }

    return Column(
      key: ValueKey(
          'experiencias_${listaParaExibir.length}_$_experienciasNeedRefresh'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (listaParaExibir.isNotEmpty) ...[
          Text(
            'Experiências Cadastradas (${listaParaExibir.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...listaParaExibir.map((exp) => _buildItemExperiencia(exp)),
        ] else ...[
          // ✅ CORREÇÃO: Só mostrar loading se estiver carregando no modo edição
          if (_carregandoListas && _isEdicaoMode) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Nenhuma experiência cadastrada ainda.\nClique em "Incluir" para adicionar a primeira experiência.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _buscarExperienciasCandidato() async {
    try {
      if (_candidatoId == null || _candidatoId!.isEmpty) {
        throw Exception('ID do candidato não está definido');
      }

      final candidatoIdInt = int.tryParse(_candidatoId!);
      if (candidatoIdInt == null) {
        throw Exception(
            'ID do candidato não é um número válido: $_candidatoId');
      }

      final response = await http.get(
        Uri.parse(
            'https://cideestagio.com.br/api/candidato/experiencia/listar/$candidatoIdInt'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data['dados'] is List) {
          final experienciasRaw = data['dados'] as List;
          final List<Map<String, dynamic>> experienciasConvertidas = [];

          for (var item in experienciasRaw) {
            if (item is Map<String, dynamic>) {
              final experiencia = {
                'cd_experiencia_candidato': item['id'],
                'nome_empresa': item['nome_empresa']?.toString() ?? '',
                'atividades': item['atividades']?.toString(),
                'data_inicio': item['data_inicio']?.toString() ?? '',
                'data_fim': item['data_fim']?.toString() ?? '',
                'cd_candidato': candidatoIdInt,
              };
              experienciasConvertidas.add(experiencia);
            }
          }

          return experienciasConvertidas;
        } else {
          return [];
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildItemExperiencia(Map<String, dynamic> experiencia) {
    final isAtiva = experiencia['ativo'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isAtiva ? Colors.white : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experiencia['nome_empresa'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Exibe o ID da experiência
                    if (experiencia['cd_experiencia_candidato'] != null) ...[
                      Text(
                        'ID: ${experiencia['cd_experiencia_candidato']}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    // Text(
                    //   '${experiencia['data_inicio'] ?? ''} - ${experiencia['data_fim'] ?? ''}',
                    //   style: TextStyle(
                    //     color: Colors.grey[600],
                    //     fontSize: 12,
                    //   ),
                    // ),
                    // if (experiencia['atividades'] != null &&
                    //   experiencia['atividades'].toString().isNotEmpty) ...[
                    //   const SizedBox(height: 2),
                    //   Text(
                    //   experiencia['atividades'].toString().length > 100
                    //     ? '${experiencia['atividades'].toString().substring(0, 100)}...'
                    //     : experiencia['atividades'].toString(),
                    //   style: TextStyle(
                    //     color: Colors.grey[600],
                    //     fontSize: 12,
                    //   ),
                    //   maxLines: 2,
                    //   overflow: TextOverflow.ellipsis,
                    //   ),
                    // ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editarExperiencia(experiencia),
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
                color: Colors.blue,
              ),
              IconButton(
                onPressed: () => _excluirExperiencia(experiencia),
                icon: const Icon(Icons.delete),
                tooltip: 'Excluir',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _excluirExperiencia(Map<String, dynamic> experiencia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Experiência'),
        content: const Text('Tem certeza que deseja excluir esta experiência?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              final id = experiencia['cd_experiencia_candidato'];
              if (id == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID da experiência não encontrado.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              setState(() => _isLoadingExperiencia = true);
              try {
                final response = await http.delete(
                  Uri.parse(
                      'https://cideestagio.com.br/api/candidato/experiencia/$id'),
                  headers: await _getHeaders(),
                );
                if (response.statusCode == 200 || response.statusCode == 204) {
                  setState(() {
                    _experiencias.removeWhere(
                        (exp) => exp['cd_experiencia_candidato'] == id);
                    _experienciasNeedRefresh = !_experienciasNeedRefresh;

                    // Remover do cache também, se existir
                    if (_experienciasCarregadas != null) {
                      _experienciasCarregadas!.removeWhere(
                          (exp) => exp['cd_experiencia_candidato'] == id);
                    }
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Experiência excluída com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Erro ao excluir experiência: ${response.body}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir experiência: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() => _isLoadingExperiencia = false);
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== CONHECIMENTOS DE INFORMÁTICA ====================

  void _adicionarNovoConhecimento() {
    _limparFormularioConhecimento();
    setState(() {
      _showFormConhecimento = true; // Corrigido: era _showFormCurso
      _conhecimentoEditando = null;
    });
  }

  void _editarConhecimento(Map<String, dynamic> conhecimento) {
    print('🔧 [EDITAR_CONHECIMENTO] Iniciando edição do conhecimento...');
    print('   - Dados recebidos: ${jsonEncode(conhecimento)}');

    setState(() {
      _conhecimentoEditando = conhecimento;
      _showFormConhecimento = true;

      // ✅ CORREÇÃO: Primeiro garantir que os mapas estão construídos
      _construirMapasConhecimento();

      // ✅ CORREÇÃO: Salvar IDs antes de qualquer operação
      _conhecimentoSelecionadoId = conhecimento['cd_conhecimento'];
      _nivelConhecimentoId = conhecimento['cd_nivel_conhecimento'];

      // ✅ CORREÇÃO: Preencher descrição ANTES de limpar outros campos
      final descricao = conhecimento['descricao_conhecimento'] ?? '';

      // Limpar apenas os campos que precisam ser limpos
      _conhecimentoSelecionado = null;
      _nivelConhecimento = null;

      // Agora preencher a descrição
      _descricaoConhecimentoController.text = descricao;

      // Para os dropdowns, precisamos encontrar as chaves corretas nos maps
      // Buscar o conhecimento correto no map
      if (_conhecimentosMap.isNotEmpty && _conhecimentoSelecionadoId != null) {
        final conhecimentoKey = _conhecimentosMap.entries
            .firstWhere(
              (entry) => entry.value == _conhecimentoSelecionadoId,
              orElse: () => const MapEntry('', 0),
            )
            .key;

        if (conhecimentoKey.isNotEmpty) {
          _conhecimentoSelecionado = conhecimentoKey;
          print('   - Conhecimento selecionado: $_conhecimentoSelecionado');
        } else {
          print('   - ⚠️ Não foi possível encontrar o conhecimento no map');
          // Tentar usar o nome diretamente dos dados
          _conhecimentoSelecionado = conhecimento['nome'];
        }
      }

      // Buscar o nível correto no map
      if (_niveisConhecimentoMap.isNotEmpty && _nivelConhecimentoId != null) {
        final nivelKey = _niveisConhecimentoMap.entries
            .firstWhere(
              (entry) => entry.value == _nivelConhecimentoId,
              orElse: () => const MapEntry('', 0),
            )
            .key;

        if (nivelKey.isNotEmpty) {
          _nivelConhecimento = nivelKey;
          print('   - Nível selecionado: $_nivelConhecimento');
        } else {
          print('   - ⚠️ Não foi possível encontrar o nível no map');
          // Tentar usar o nome diretamente dos dados
          _nivelConhecimento = conhecimento['nivel'];
        }
      }

      print('   - Estado final:');
      print('     - _conhecimentoSelecionado: $_conhecimentoSelecionado');
      print('     - _conhecimentoSelecionadoId: $_conhecimentoSelecionadoId');
      print('     - _nivelConhecimento: $_nivelConhecimento');
      print('     - _nivelConhecimentoId: $_nivelConhecimentoId');
      print(
          '     - _descricaoConhecimentoController.text: ${_descricaoConhecimentoController.text}');
    });
  }

  // Método auxiliar para construir mapas de conhecimento
  void _construirMapasConhecimento() {
    print('🔧 [CONSTRUIR_MAPAS] Construindo mapas de conhecimento...');

    if (_conhecimentosCache != null) {
      final conhecimentos = _conhecimentosCache!['conhecimentos']
              as List<modelConhecimento.Conhecimento>? ??
          [];

      _conhecimentosMap.clear(); // ✅ Limpar antes de reconstruir
      for (var conhecimento in conhecimentos) {
        final chave = conhecimento.nome.isNotEmpty
            ? conhecimento.nome
            : (conhecimento.descricao.isNotEmpty
                ? conhecimento.descricao
                : 'Conhecimento ${conhecimento.id}');
        _conhecimentosMap[chave] = conhecimento.id!;
      }
      print('   - Conhecimentos no mapa: ${_conhecimentosMap.length}');
    }

    if (_niveisConhecimentoCache != null) {
      final niveis = _niveisConhecimentoCache!['niveisConhecimento']
              as List<NivelConhecimento>? ??
          [];

      _niveisConhecimentoMap.clear(); // ✅ Limpar antes de reconstruir
      for (var nivel in niveis) {
        final chave = nivel.nome.isNotEmpty
            ? nivel.nome
            : (nivel.descricao.isNotEmpty
                ? nivel.descricao
                : 'Nível ${nivel.id}');
        _niveisConhecimentoMap[chave] = nivel.id!;
      }
      print('   - Níveis no mapa: ${_niveisConhecimentoMap.length}');
    }
  }

  //Criar método void _excluirConhecimento com base no _excluirIdioma

  void _excluirConhecimento(Map<String, dynamic> conhecimento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Conhecimento'),
        content:
            const Text('Tem certeza que deseja excluir este conhecimento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              final id = conhecimento['cd_conhecimento_candidato'];
              if (id == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ID do conhecimento não encontrado.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              setState(() => _isLoadingConhecimento = true);
              try {
                final response = await http.delete(
                  Uri.parse(
                      'https://cideestagio.com.br/api/candidato/conhecimento/$id'),
                  headers: await _getHeaders(),
                );
                if (response.statusCode == 200 || response.statusCode == 204) {
                  setState(() {
                    _conhecimentos.removeWhere(
                        (i) => i['cd_conhecimento_candidato'] == id);
                    _conhecimentosNeedRefresh = !_conhecimentosNeedRefresh;

                    // Remover do cache também, se existir
                    if (_conhecimentosCarregados != null) {
                      _conhecimentosCarregados!.removeWhere(
                          (i) => i['cd_conhecimento_candidato'] == id);
                    }
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conhecimento excluído com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Erro ao excluir conhecimento: ${response.body}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir conhecimento: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                setState(() => _isLoadingConhecimento = false);
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _cancelarFormularioConhecimento() {
    _limparFormularioConhecimento();
    setState(() {
      _showFormConhecimento = false;
      _conhecimentoEditando = null;
      _limparFormularioConhecimento();
    });
  }

  void _limparFormularioConhecimento() {
    _nomeConhecimentoController.clear();
    _descricaoConhecimentoController.clear();
    _conhecimentoSelecionado = null;
    _conhecimentoSelecionadoId = null;
    _nivelConhecimento = null;
    _nivelConhecimentoId = null;
  }

  Future<void> _salvarConhecimento() async {
    // ✅ Prevenir múltiplos cliques
    if (_isLoadingConhecimento) return;

    print('🏁 [SALVAR_CONHECIMENTO] Iniciando salvamento de conhecimento...');

    if (_conhecimentoSelecionado == null) {
      print(
          '❌ [SALVAR_CONHECIMENTO] Validação falhou: Nome do conhecimento não informado');
      _mostrarErroObrigatorio('Nome do conhecimento');
      return;
    }

    if (_nivelConhecimento == null) {
      print(
          '❌ [SALVAR_CONHECIMENTO] Validação falhou: Nível do conhecimento não selecionado');
      _mostrarErroObrigatorio('Nível do conhecimento');
      return;
    }

    // 🔥 CAPTURE O ID DO USUÁRIO NO INÍCIO, ANTES DE OPERAÇÕES ASSÍNCRONAS
    final usuarioId = mounted
        ? Provider.of<AuthProvider>(context, listen: false).usuario?.id
        : null;

    print('📋 [SALVAR_CONHECIMENTO] Dados coletados:');
    print('   - Nome do conhecimento: ${_nomeConhecimentoController.text}');
    print('   - Nível: $_nivelConhecimento');
    print('   - ID do conhecimento selecionado: $_conhecimentoSelecionadoId');
    print('   - ID do nível: $_nivelConhecimentoId');
    print('   - Descrição: ${_descricaoConhecimentoController.text}');
    print('   - ID do candidato: $_candidatoId');
    print('   - ID do usuário: $usuarioId');
    print(
        '   - Editando: ${_conhecimentoEditando != null ? "SIM (ID: ${_conhecimentoEditando!['cd_conhecimento_candidato']})" : "NÃO"}');

    // ✅ Ativar loading específico do conhecimento
    if (mounted) {
      setState(() => _isLoadingConhecimento = true);
    }

    try {
      final dadosConhecimento = {
        "cd_conhecimento": _conhecimentoSelecionadoId,
        "cd_nivel_conhecimento": _nivelConhecimentoId,
        "cd_candidato":
            _candidatoId != null ? int.tryParse(_candidatoId!) : null,
        "descricao_conhecimento": _descricaoConhecimentoController.text.trim(),
        "criado_por": usuarioId,
      };

      print('📤 [SALVAR_CONHECIMENTO] Dados preparados para envio:');
      print('   - JSON: ${jsonEncode(dadosConhecimento)}');

      bool sucesso = false;
      int? idConhecimentoCandidato;
      String operacao = '';

      if (_conhecimentoEditando != null &&
          _conhecimentoEditando!['cd_conhecimento_candidato'] != null) {
        operacao = 'ATUALIZAÇÃO';
        final idConhecimentoCandidatoExistente =
            _conhecimentoEditando!['cd_conhecimento_candidato'] as int;

        print(
            '🔄 [SALVAR_CONHECIMENTO] Iniciando $operacao do conhecimento...');
        print(
            '   - ID do conhecimento candidato: $idConhecimentoCandidatoExistente');

        try {
          sucesso = await ConhecimentoService.atualizarConhecimentoCandidato(
            dadosConhecimento,
            idConhecimentoCandidato: idConhecimentoCandidatoExistente,
          );

          idConhecimentoCandidato = idConhecimentoCandidatoExistente;

          print('📨 [SALVAR_CONHECIMENTO] Resposta da $operacao:');
          print('   - Sucesso: $sucesso');
          print('   - ID mantido: $idConhecimentoCandidato');
        } catch (serviceError) {
          print('💥 [SALVAR_CONHECIMENTO] Erro no service de $operacao:');
          print('   - Erro: $serviceError');
          print('   - Tipo: ${serviceError.runtimeType}');
          rethrow;
        }
      } else {
        operacao = 'CRIAÇÃO';

        print('➕ [SALVAR_CONHECIMENTO] Iniciando $operacao do conhecimento...');

        try {
          idConhecimentoCandidato =
              await ConhecimentoService.criarConhecimentoCandidato(
                  dadosConhecimento);
          sucesso = idConhecimentoCandidato != null;

          print('📨 [SALVAR_CONHECIMENTO] Resposta da $operacao:');
          print('   - ID retornado: $idConhecimentoCandidato');
          print('   - Sucesso: $sucesso');
        } catch (serviceError) {
          print('💥 [SALVAR_CONHECIMENTO] Erro no service de $operacao:');
          print('   - Erro: $serviceError');
          print('   - Tipo: ${serviceError.runtimeType}');
          rethrow;
        }
      }

      print('🎯 [SALVAR_CONHECIMENTO] Resultado final da operação:');
      print('   - Operação: $operacao');
      print('   - Sucesso: $sucesso');
      print('   - ID final: $idConhecimentoCandidato');

      if (sucesso) {
        print('✅ [SALVAR_CONHECIMENTO] $operacao realizada com sucesso!');

        final novoConhecimentoExibicao = {
          "cd_conhecimento_candidato": idConhecimentoCandidato,
          "cd_conhecimento": _conhecimentoSelecionadoId,
          "nome":
              _conhecimentoSelecionado, // Usar o nome selecionado do dropdown
          "cd_nivel_conhecimento": _nivelConhecimentoId,
          "nivel": _nivelConhecimento,
          "descricao_conhecimento": _descricaoConhecimentoController.text,
          "cd_candidato":
              _candidatoId != null ? int.parse(_candidatoId!) : null,
        };

        print('🔄 [SALVAR_CONHECIMENTO] Atualizando estado da interface...');
        print(
            '   - Objeto para exibição: ${jsonEncode(novoConhecimentoExibicao)}');

        // 🔥 CORREÇÃO: Verificar se ainda está montado antes de setState
        if (mounted) {
          setState(() {
            if (_conhecimentoEditando != null) {
              // Atualizar lista local
              final idx = _conhecimentos.indexWhere((conhecimento) =>
                  conhecimento['cd_conhecimento_candidato'] ==
                  _conhecimentoEditando!['cd_conhecimento_candidato']);

              print('   - Atualizando conhecimento existente no índice: $idx');

              if (idx != -1) {
                _conhecimentos[idx] = novoConhecimentoExibicao;
                print('   - Conhecimento atualizado na lista local');
              } else {
                print('   - ⚠️ Índice não encontrado, adicionando como novo');
                _conhecimentos.add(novoConhecimentoExibicao);
              }

              // Atualizar cache do modo edição também
              if (_conhecimentosCarregados != null) {
                final idxCache = _conhecimentosCarregados!.indexWhere(
                    (conhecimento) =>
                        conhecimento['cd_conhecimento_candidato'] ==
                        _conhecimentoEditando!['cd_conhecimento_candidato']);

                if (idxCache != -1) {
                  _conhecimentosCarregados![idxCache] =
                      novoConhecimentoExibicao;
                  print('   - Conhecimento atualizado no cache');
                } else {
                  _conhecimentosCarregados!.add(novoConhecimentoExibicao);
                  print('   - Conhecimento adicionado ao cache');
                }
              }
            } else {
              print('   - Adicionando novo conhecimento à lista');
              _conhecimentos.add(novoConhecimentoExibicao);

              // Adicionar ao cache também, se existir
              if (_conhecimentosCarregados != null) {
                _conhecimentosCarregados!.add(novoConhecimentoExibicao);
                print('   - Novo conhecimento adicionado ao cache');
              }
            }

            // 🔥 CORREÇÃO: Usar a variável correta para fechar o formulário
            _showFormConhecimento = false;
            _conhecimentoEditando = null;
            _conhecimentosNeedRefresh = !_conhecimentosNeedRefresh;

            print('   - Estado da interface atualizado');
            print(
                '   - Total de conhecimentos na lista: ${_conhecimentos.length}');
            print(
                '   - Total de conhecimentos no cache: ${_conhecimentosCarregados?.length}');
          });
        } else {
          print(
              '⚠️ [SALVAR_CONHECIMENTO] Widget desmontado, não foi possível atualizar o estado');
        }

        _limparFormularioConhecimento();
        print('🧹 [SALVAR_CONHECIMENTO] Formulário limpo');

        // 🔥 CORREÇÃO: Verificar se ainda está montado
        if (mounted) {
          final mensagemSucesso = _conhecimentoEditando != null
              ? 'Conhecimento atualizado com sucesso!'
              : 'Conhecimento adicionado com sucesso!';

          print(
              '🎉 [SALVAR_CONHECIMENTO] Exibindo mensagem de sucesso: $mensagemSucesso');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagemSucesso),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          print(
              '⚠️ [SALVAR_CONHECIMENTO] Widget desmontado, não foi possível exibir mensagem de sucesso');
        }
      } else {
        print('❌ [SALVAR_CONHECIMENTO] $operacao falhou!');
        print('   - Sucesso: $sucesso');
        print('   - ID retornado: $idConhecimentoCandidato');

        if (mounted) {
          final mensagemErro = _conhecimentoEditando != null
              ? 'Erro ao atualizar conhecimento'
              : 'Erro ao adicionar conhecimento';

          print(
              '📢 [SALVAR_CONHECIMENTO] Exibindo mensagem de erro: $mensagemErro');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensagemErro),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('💥 [SALVAR_CONHECIMENTO] Erro inesperado capturado:');
      print('   - Erro: $e');
      print('   - Tipo: ${e.runtimeType}');
      print('   - Stack trace: $stackTrace');

      // 🔥 CORREÇÃO: Verificar se ainda está montado
      if (mounted) {
        final mensagemErroCompleta = 'Erro inesperado: ${e.toString()}';
        print(
            '📢 [SALVAR_CONHECIMENTO] Exibindo mensagem de erro inesperado: $mensagemErroCompleta');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensagemErroCompleta),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        print(
            '⚠️ [SALVAR_CONHECIMENTO] Widget desmontado, não foi possível exibir mensagem de erro');
      }
    } finally {
      print('🏁 [SALVAR_CONHECIMENTO] Finalizando operação...');

      // ✅ Desativar loading específico do conhecimento
      if (mounted) {
        setState(() => _isLoadingConhecimento = false);
        print('   - Loading state do conhecimento removido');
      } else {
        print(
            '   - ⚠️ Widget desmontado, não foi possível remover loading state');
      }

      print('🏁 [SALVAR_CONHECIMENTO] Operação finalizada');
    }
  }

  Widget _buildFormularioCurso() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _conhecimentoEditando != null
                    ? 'Editar Conhecimento'
                    : 'Novo Conhecimento',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              IconButton(
                onPressed: _cancelarFormularioConhecimento,
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // DROPDOWN DE CONHECIMENTOS
          Row(
            children: [
              Expanded(
                child: !_dadosCarregados
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : _buildDropdownConhecimento(),
              ),

              // DROPDOWN DE NÍVEIS
              const SizedBox(width: 16),
              Expanded(
                child: _niveisConhecimentoCache == null && _isLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : _buildDropdownNivelConhecimento(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // CERTIFICAÇÃO
          CustomTextField(
            controller: _descricaoConhecimentoController,
            label: 'Descrição',
          ),
          const SizedBox(height: 24),

          // BOTÕES
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelarFormularioConhecimento,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _salvarConhecimento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                      _conhecimentoEditando != null ? 'Atualizar' : 'Salvar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaConhecimentos() {
    print(
        '🔄 [BUILD_LISTA_CONHECIMENTOS] Sendo chamado - _candidatoId: $_candidatoId, _isEdicaoMode: $_isEdicaoMode, _listasCarregadas: $_listasCarregadas, _conhecimentosCarregados: ${_conhecimentosCarregados?.length}, _conhecimentos: ${_conhecimentos.length}');

    // ✅ CORREÇÃO: Sempre usar cache se disponível, senão usar lista local
    List<Map<String, dynamic>> listaParaExibir;

    if (_conhecimentosCarregados != null) {
      // Modo edição: usar cache carregado
      listaParaExibir = _conhecimentosCarregados!;
      print(
          '📋 [BUILD_LISTA_CONHECIMENTOS] Usando cache carregado: ${listaParaExibir.length} itens');
    } else {
      // Modo novo cadastro ou quando cache não existe: usar lista local
      listaParaExibir = _conhecimentos;
      print(
          '📋 [BUILD_LISTA_CONHECIMENTOS] Usando lista local: ${listaParaExibir.length} itens');
    }

    return Column(
      key: ValueKey(
          'conhecimentos_${listaParaExibir.length}_$_conhecimentosNeedRefresh'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (listaParaExibir.isNotEmpty) ...[
          Text(
            'Conhecimentos Cadastrados (${listaParaExibir.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ...listaParaExibir
              .map((conhecimento) => _buildItemConhecimento(conhecimento)),
        ] else ...[
          // ✅ CORREÇÃO: Só mostrar loading se estiver carregando no modo edição
          if (_carregandoListas && _isEdicaoMode) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'Nenhum conhecimento cadastrado ainda.\nClique em "Incluir" para adicionar o primeiro conhecimento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _buscarConhecimentosCandidato() async {
    try {
      if (_candidatoId == null || _candidatoId!.isEmpty) {
        throw Exception('ID do candidato não está definido');
      }

      final candidatoIdInt = int.tryParse(_candidatoId!);
      if (candidatoIdInt == null) {
        throw Exception(
            'ID do candidato não é um número válido: $_candidatoId');
      }

      final response = await http.get(
        Uri.parse(
            'https://cideestagio.com.br/api/candidato/conhecimento/listar/$candidatoIdInt'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data['dados'] is List) {
          final conhecimentosRaw = data['dados'] as List;
          final List<Map<String, dynamic>> conhecimentosConvertidos = [];

          for (var item in conhecimentosRaw) {
            if (item is Map<String, dynamic>) {
              final conhecimento = {
                'cd_conhecimento_candidato': item['id'],
                'cd_conhecimento': item['cd_conhecimento'],
                'nome': item['conhecimento']?.toString() ?? '',
                'cd_nivel_conhecimento': item['cd_nivel_conhecimento'],
                'nivel': item['nivel_conhecimento']?.toString() ?? '',
                'descricao_conhecimento':
                    item['descricao_conhecimento']?.toString(),
                'ativo': item['ativo'] == true || item['ativo'] == 1,
                'cd_candidato': candidatoIdInt,
              };
              conhecimentosConvertidos.add(conhecimento);
            }
          }

          return conhecimentosConvertidos;
        } else {
          return [];
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildCampoBuscaCurso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curso *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Autocomplete<modelCurso.Curso>(
          displayStringForOption: (curso) => curso.nome,
          optionsBuilder: (textEditingValue) async {
            final query = textEditingValue.text.trim();

            if (query.length < 3) {
              return const Iterable<modelCurso.Curso>.empty();
            }

            try {
              // CORRIGIDO: Usar buscarCurso
              final result = await CursoService.buscarCurso(query);
              // CORRIGIDO: buscarCurso retorna List<Curso>? diretamente
              return result ?? [];
            } catch (e) {
              print('Erro ao buscar cursos: $e');
              return const Iterable<modelCurso.Curso>.empty();
            }
          },
          onSelected: (curso) {
            setState(() {
              _cursoSelecionado = curso.nome;
              _cursoId = curso.id;
              _cursoNaoListadoController.clear();
            });
          },
          fieldViewBuilder:
              (context, controller, focusNode, onEditingComplete) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _cursoSelecionado != null &&
                  controller.text.isEmpty) {
                controller.text = _cursoSelecionado!;
              }
            });
            // Se já tem um curso selecionado, mostrar no campo
            if (_cursoSelecionado != null && controller.text.isEmpty) {
              controller.text = _cursoSelecionado!;
            }

            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              onEditingComplete: onEditingComplete,
              decoration: InputDecoration(
                hintText:
                    'Digite o nome do curso (informe pelo menos 3 caracteres)',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          final state = context.findAncestorStateOfType<
                              _CadastroCandidatoScreenState>();
                          if (state != null) {
                            state.setState(() {
                              state._cursoSelecionado = null;
                              state._cursoId = null;
                            });
                          }
                        },
                      )
                    : null,
              ),
              validator: (value) {
                if ((_cursoSelecionado == null || _cursoSelecionado!.isEmpty) &&
                    _cursoNaoListadoController.text.trim().isEmpty) {
                  return 'Selecione um curso ou preencha "Curso Não Listado"';
                }
                return null;
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return _buildOptionsView(options, onSelected, Icons.school);
          },
        ),
      ],
    );
  }

  Future<void> _selecionarComprovanteMatricula() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: kIsWeb, // Importante: carrega bytes apenas para web
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        const maxSize = 10 * 1024 * 1024; // 10MB

        // Validação de tamanho
        if (file.size > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('O arquivo deve ter no máximo 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Validação de tipo de arquivo
        final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
        final fileExtension = file.extension?.toLowerCase();

        if (fileExtension == null ||
            !allowedExtensions.contains(fileExtension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Tipo de arquivo não permitido. Use PDF, JPG, JPEG ou PNG'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _nomeComprovanteMatricula = file.name;

          if (kIsWeb) {
            // Para web: usar bytes
            _comprovanteMatriculaBytes = file.bytes;
            _comprovanteMatricula = null;
          } else {
            // Para mobile/desktop: usar path
            if (file.path != null) {
              _comprovanteMatricula = File(file.path!);
              _comprovanteMatriculaBytes = null;
            } else {
              throw Exception('Caminho do arquivo não disponível');
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comprovante selecionado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Erro detalhado ao selecionar arquivo: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erro ao selecionar arquivo. Tente novamente.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Detalhes',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Erro Detalhado'),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  bool get _temComprovanteMatricula2 {
    return (kIsWeb && _comprovanteMatriculaBytes != null) ||
        (!kIsWeb && _comprovanteMatricula != null);
  }

  // Método para limpar o comprovante selecionado
  void _removerComprovanteMatricula2() {
    setState(() {
      _comprovanteMatricula = null;
      _comprovanteMatriculaBytes = null;
      _nomeComprovanteMatricula = null;
    });
  }

  Widget _buildItemConhecimento(Map<String, dynamic> conhecimento) {
    final isAtivo = conhecimento['ativo'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: isAtivo ? Colors.white : Colors.grey[50],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conhecimento['nome'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nível: ${conhecimento['nivel'] ?? ''}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    if (conhecimento['versao'] != null &&
                        conhecimento['versao'].toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Versão: ${conhecimento['versao']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (conhecimento['certificacao'] != null &&
                        conhecimento['certificacao'].toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Certificação: ${conhecimento['certificacao']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editarConhecimento(conhecimento),
                icon: const Icon(Icons.edit),
                tooltip: 'Editar',
                color: Colors.blue,
              ),
              IconButton(
                onPressed: () => _excluirConhecimento(conhecimento),
                icon: const Icon(Icons.delete),
                tooltip: 'Excluir',
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Controllers existentes
    _nomeController.dispose();
    _nomeSocialController.dispose();
    _rgController.dispose();
    _cpfController.dispose();
    _orgaoEmissorController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _confirmarEmailController.dispose();
    _observacaoController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();

    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _complementoController.dispose();

    _nomeContatoRecadoController.dispose();
    _emailContatoRecadoController.dispose();
    _telefoneRecadoController.dispose();
    _celularRecadoController.dispose();
    _whatsappRecadoController.dispose();
    _grauParentescoRecadoController.dispose();

    _cursoNaoListadoController.dispose();
    _instituicaoNaoListadaController.dispose();
    _semestreAnoInicialController.dispose();
    _semestreAnoConclusaoController.dispose();
    _raMatriculaController.dispose();

    _nomeIdiomaController.dispose();
    _certificacaoIdiomaController.dispose();

    _empresaController.dispose();
    _atividadesController.dispose();
    _dataInicioExpController.dispose();
    _dataFimExpController.dispose();

    _softwareController.dispose();
    _versaoController.dispose();
    _descricaoConhecimentoController.dispose();

    // NOVOS: Controllers de cursos
    _nomeCursoController.dispose();
    _instituicaoCursoController.dispose();
    _cargaHorariaCursoController.dispose();
    _dataInicioCursoController.dispose();
    _dataFimCursoController.dispose();
    _certificacaoCursoController.dispose();

    _pisController.dispose();
    _numeroMembrosController.dispose();
    _rendaDomiciliarController.dispose();
    _qualAuxilioController.dispose();
    _dataInicioCursoController.dispose();

    _limparDadosComprovante();

    _pageController.dispose();
    super.dispose();
  }

  void _limparDadosComprovante() {
    setState(() {
      _comprovanteMatricula = null;
      _comprovanteMatriculaBytes = null;
      _nomeComprovanteMatricula = null;
      _exibirComprovanteObrigatorio = false;
    });
  }
}

// Widget reutilizável para exibir opções
Widget _buildOptionsView<T>(
  Iterable<T> options,
  void Function(T) onSelected,
  IconData icon,
) {
  return Align(
    alignment: Alignment.topLeft,
    child: Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 200),
        child: options.isEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Necessário pelo menos 3 caracteres para iniciar a pesquisa!',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final item = options.elementAt(index);
                  final isLast = index == options.length - 1;

                  String displayText;
                  if (item is modelCurso.Curso) {
                    displayText = item.nome;
                  } else if (item is InstituicaoEnsino) {
                    displayText = item.razaoSocial;
                  } else {
                    displayText = item.toString();
                  }

                  return InkWell(
                    onTap: () => onSelected(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey[200]!,
                            width: isLast ? 0 : 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              displayText,
                              style: const TextStyle(fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    ),
  );
}
