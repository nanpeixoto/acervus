// lib/screens/admin/seguradoras_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_dropdown.dart';
import 'package:sistema_estagio/widgets/custom_app_bar.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/models/_organizacoes/empresa/seguradora.dart'
    as seguradora;
import 'package:sistema_estagio/services/_organizacoes/empresa/seguradora_service.dart'
    as seguradoraService;
import 'package:sistema_estagio/services/_organizacoes/instituicao/instituicao_service.dart';
import 'package:sistema_estagio/utils/app_utils.dart';
import 'package:sistema_estagio/utils/validators.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class SeguradorasScreen extends StatefulWidget {
  const SeguradorasScreen({super.key});

  @override
  State<SeguradorasScreen> createState() => _SeguradorasScreenState();
}

class _SeguradorasScreenState extends State<SeguradorasScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  // ✅ ADICIONADO: Formatters para máscaras
  final _cnpjFormatter = MaskTextInputFormatter(mask: '##.###.###/####-##');
  final _cepFormatter = MaskTextInputFormatter(mask: '#####-###');
  final _telefoneFormatter = MaskTextInputFormatter(mask: '(##) ####-####');
  final _celularFormatter = MaskTextInputFormatter(mask: '(##) #####-####');
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##');

  // ✅ ADICIONADO: Variáveis para validação de CNPJ
  bool _cnpjValidado = false;
  bool _consultandoCNPJ = false;
  Map<String, dynamic>? _dadosReceitaFederal;

  // Informações Gerais
  final TextEditingController _razaoSocialController = TextEditingController();
  final TextEditingController _nomeFantasiaController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();

// Informações da Apólice
  final TextEditingController _valorApoliceController = TextEditingController();
  final TextEditingController _apoliceController = TextEditingController();
  final TextEditingController _porcentagemDHMOController =
      TextEditingController();

// Endereço
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _logradouroController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _ufController = TextEditingController();

// Outros
  final TextEditingController _observacaoController = TextEditingController();

// Variável de estado para o checkbox
  bool _ativo = true;

  List<seguradora.Seguradora> _seguradoras = [];
  Map<String, dynamic> _estatisticas = {};
  bool _isLoading = false;

  // Filtros
  bool? _filtroAtivo;
  bool? _filtroDefault;

  // Paginação
  late TabController _tabController;
  int _currentPage = 1;
  int _pageSize = 10;
  Map<String, dynamic>? _pagination;
  String _currentSearch = '';
  bool _isLoadingPage = false;

  // Opções de página
  final List<int> _pageSizeOptions = [5, 10, 20, 50, 100];

  // Formulário
  bool _showForm = false;
  seguradora.Seguradora? _statusEditando;
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _ordemController = TextEditingController();
  String? _corSelecionada;
  bool _isDefault = false;

  // ✅ ADICIONADO: Lista de UFs
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

  // Cores disponíveis
  final List<String> _coresDisponiveis = [
    '#4CAF50', // Verde
    '#FF9800', // Laranja
    '#F44336', // Vermelho
    '#2196F3', // Azul
    '#9C27B0', // Roxo
    '#FF5722', // Laranja escuro
    '#795548', // Marrom
    '#607D8B', // Azul acinzentado
    '#9E9E9E', // Cinza
    '#E91E63', // Rosa
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSeguradoras();
    //_loadEstatisticas();
  }

  // ✅ ADICIONADO: Métodos para busca de CNPJ
  Future<void> _buscarCNPJ() async {
    final cnpj = _cnpjController.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (cnpj.length != 14) {
      _mostrarErro('CNPJ deve ter 14 dígitos');
      return;
    }

    setState(() {
      _consultandoCNPJ = true;
      _cnpjValidado = false;
    });

    try {
      final resultado = await InstituicaoService.buscarDadosCNPJ(cnpj);

      if (resultado['sucesso'] == true) {
        final dados = resultado['dadosFormatados'];
        _dadosReceitaFederal = resultado['dadosCompletos'];

        await _preencherDadosAutomaticamente(dados);

        setState(() {
          _cnpjValidado = true;
        });

        _mostrarSucesso('CNPJ validado e dados carregados automaticamente!');
      } else {
        _mostrarAviso('CNPJ válido, mas ${resultado['erro']}');
        setState(() {
          _cnpjValidado = true; // CNPJ é válido mesmo sem dados da Receita
        });
      }
    } catch (e) {
      _mostrarErro('Erro ao consultar CNPJ: $e');
    } finally {
      setState(() {
        _consultandoCNPJ = false;
      });
    }
  }

  // ✅ ADICIONADO: Preencher dados automaticamente
  Future<void> _preencherDadosAutomaticamente(
      Map<String, dynamic> dados) async {
    setState(() {
      // Dados básicos
      _razaoSocialController.text = dados['razaoSocial'] ?? '';
      _nomeFantasiaController.text = dados['nomeFantasia']?.isNotEmpty == true
          ? dados['nomeFantasia']
          : dados['razaoSocial'] ?? '';

      // Endereço (se ainda não preenchido)
      if (_cepController.text.isEmpty) {
        final endereco = dados['endereco'];
        _cepController.text = endereco['cep'] ?? '';
        _logradouroController.text = endereco['logradouro'] ?? '';
        _numeroController.text = endereco['numero'] ?? '';
        _bairroController.text = endereco['bairro'] ?? '';
        _cidadeController.text = endereco['cidade'] ?? '';
        _complementoController.text = endereco['complemento'] ?? '';
        _ufController.text = endereco['uf'] ?? '';
      }

      // Contatos (se ainda não preenchidos)
      if (_telefoneController.text.isEmpty) {
        final contatos = dados['contatos'];
        _telefoneController.text =
            _formatarTelefone(contatos['telefone'] ?? '');
      }
    });
  }

  // ✅ ADICIONADO: Formatar telefone
  String _formatarTelefone(String telefone) {
    final numeros = telefone.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length == 10) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 6)}-${numeros.substring(6)}';
    } else if (numeros.length == 11) {
      return '(${numeros.substring(0, 2)}) ${numeros.substring(2, 7)}-${numeros.substring(7)}';
    }
    return telefone;
  }

  // ✅ ADICIONADO: Validação de CNPJ
  String? _validateCNPJ(String? value) {
    if (value?.isEmpty ?? true) {
      return 'CNPJ é obrigatório';
    }

    final cnpj = value!.replaceAll(RegExp(r'[^0-9]'), '');
    if (cnpj.length != 14) {
      return 'CNPJ deve ter 14 dígitos';
    }

    final validacao = InstituicaoService.validarCNPJLocal(cnpj);
    if (!validacao) {
      return 'CNPJ inválido';
    }

    return null;
  }

  // ✅ ADICIONADO: Buscar CEP
  Future<void> _buscarCEP(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepLimpo.length == 8) {
      setState(() {
        _isLoading = true;
      });

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
            _ufController.text = data['uf'] ?? '';
            _isLoading = false;
          });

          _mostrarSucesso('CEP encontrado!');
        } else {
          throw Exception('Erro ao buscar CEP');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _mostrarErro('CEP não encontrado. Verifique e tente novamente.');
      }
    }
  }

  // ✅ ADICIONADO: Métodos para mostrar mensagens
  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarAviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _loadSeguradoras({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingPage = true);
    }

    try {
      final result =
          await seguradoraService.SeguradoraService.listarSeguradoras(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
        isDefault: _filtroDefault,
      );

      if (mounted) {
        setState(() {
          _seguradoras = result['seguradoras'];
          _pagination = result['pagination'];

          if (_pagination == null || _pagination!.isEmpty) {
            final totalItems = _seguradoras.length;
            final totalPages = (totalItems / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt();

            _pagination = {
              'currentPage': _currentPage,
              'totalPages': totalPages,
              'total': totalItems,
              'hasNextPage': _currentPage < totalPages,
              'hasPrevPage': _currentPage > 1,
            };
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar Items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingPage = false;
        });
      }
    }
  }

  Future<void> _loadEstatisticas() async {
    try {
      final stats = await seguradoraService.SeguradoraService
          .getCachedEstatisticasGerais();
      setState(() {
        _estatisticas = stats;
      });
    } catch (e) {
      // Ignorar erro de estatísticas
    }
  }

  void _performSearch() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _currentSearch = _searchController.text.trim();
    });

    try {
      if (_currentSearch.isEmpty) {
        await _loadSeguradoras();
        return;
      }

      final result = await seguradoraService.SeguradoraService.buscarSeguradora(
          _currentSearch);

      if (mounted) {
        setState(() {
          _seguradoras = result ?? <seguradora.Seguradora>[];
          _pagination = {
            'currentPage': 1,
            'totalPages': 1,
            'total': _seguradoras.length,
            'hasNextPage': false,
            'hasPrevPage': false,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar Items: $e'),
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentSearch = '';
      _currentPage = 1;
    });
    _loadSeguradoras();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguradoras'),
        actions: [
          IconButton(
            onPressed: _showFiltrosDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtros',
          ),
          IconButton(
            onPressed: _exportarDados,
            icon: const Icon(Icons.download),
            tooltip: 'Exportar',
          ),
          IconButton(
            onPressed: _showNovoStatusForm,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Seguradora',
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildListaTab(),
            _buildEstatisticasTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildListaTab() {
    return Column(
      children: [
        _buildHeader(),
        if (_showForm) _buildFormulario(),
        Expanded(child: buscarSeguradorasList()),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildEstatisticasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildEstatisticasGerais(),
          const SizedBox(height: 16),
          _buildGraficos(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Estatísticas rápidas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total de Status',
                  (_pagination?['total'] ?? _seguradoras.length).toString(),
                  Icons.description,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Ativos',
                  (_seguradoras.where((s) => s.ativo).length).toString(),
                  Icons.check_circle,
                  const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Padrão',
                  (_seguradoras.where((s) => s.isDefault).length).toString(),
                  Icons.star,
                  const Color(0xFFED6C02),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de busca
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _searchController,
                  label: 'Buscar por nome ou descrição',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: _clearSearch,
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _performSearch,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          // Configurações de paginação
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Itens por página: ', style: TextStyle(fontSize: 14)),
              DropdownButton<int>(
                value: _pageSize,
                items: _pageSizeOptions.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(size.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _pageSize = value;
                      _currentPage = 1;
                    });
                    _loadSeguradoras();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadSeguradoras();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Atualizar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),

          // Filtros ativos
          if (_temFiltrosAtivos()) ...[
            const SizedBox(height: 8),
            _buildFiltrosAtivos(),
          ],
        ],
      ),
    );
  }

  // ✅ FORMULÁRIO ATUALIZADO COM VALIDAÇÕES E MÁSCARAS
  Widget _buildFormulario() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho fixo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _statusEditando == null
                      ? 'Nova Seguradora'
                      : 'Editar Seguradora',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                IconButton(
                  onPressed: _cancelarForm,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Conteúdo scrollável
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seção: Informações Gerais
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Informações Gerais',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ✅ CNPJ com busca automática
                    CustomTextField(
                      controller: _cnpjController,
                      label: 'CNPJ *',
                      maxLines: 1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cnpjFormatter],
                      validator: _validateCNPJ,
                      suffixIcon: _consultandoCNPJ
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : _cnpjValidado
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: _buscarCNPJ,
                                  tooltip: 'Consultar CNPJ na Receita Federal',
                                ),
                      onChanged: (value) {
                        setState(() {
                          _cnpjValidado = false;
                          _dadosReceitaFederal = null;
                        });

                        if (value.length == 18) {
                          _buscarCNPJ();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // ✅ Feedback do CNPJ validado
                    if (_cnpjValidado && _dadosReceitaFederal != null)
                      _buildFeedbackReceitaFederal(),

                    // Primeira linha: Razão Social e Nome Fantasia
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _razaoSocialController,
                            label: 'Razão Social *',
                            maxLines: 1,
                            validator: (value) => Validators.validateRequired(
                                value, 'Razão Social'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _nomeFantasiaController,
                            label: 'Nome Fantasia',
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Segunda linha: Telefone e Celular com máscaras
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _telefoneController,
                            label: 'Telefone',
                            maxLines: 1,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [_telefoneFormatter],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                return Validators.validatePhone(value);
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _celularController,
                            label: 'Celular',
                            maxLines: 1,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [_celularFormatter],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                return Validators.validatePhone(value);
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Terceira linha: Valor Apólice, Apólice e Porcentagem DHMO
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _valorApoliceController,
                            label: 'Valor Apólice',
                            maxLines: 1,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            prefixIcon: const Icon(Icons.attach_money),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final valor = double.tryParse(value);
                                if (valor == null || valor <= 0) {
                                  return 'Valor deve ser maior que zero';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _apoliceController,
                            label: 'Apólice',
                            maxLines: 1,
                            validator: (value) =>
                                Validators.validateRequired(value, 'Apólice'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _porcentagemDHMOController,
                            label: 'Porcentagem DHMO',
                            maxLines: 1,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            suffixIcon: const Icon(Icons.percent),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final porcentagem = double.tryParse(value);
                                if (porcentagem == null ||
                                    porcentagem < 0 ||
                                    porcentagem > 100) {
                                  return 'Porcentagem deve estar entre 0 e 100';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quarta linha: CEP e Logradouro
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomTextField(
                            controller: _cepController,
                            label: 'CEP *',
                            maxLines: 1,
                            keyboardType: TextInputType.number,
                            inputFormatters: [_cepFormatter],
                            validator: Validators.validateCEP,
                            onChanged: (value) => _buscarCEP(value),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () => _buscarCEP(_cepController.text),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: CustomTextField(
                            controller: _logradouroController,
                            label: 'Logradouro *',
                            maxLines: 1,
                            validator: (value) => Validators.validateRequired(
                                value, 'Logradouro'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quinta linha: Número e Complemento
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomTextField(
                            controller: _numeroController,
                            label: 'Número',
                            maxLines: 1,
                            hintText: 'S/N',
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            controller: _complementoController,
                            label: 'Complemento',
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sexta linha: Bairro, Cidade, UF
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            controller: _bairroController,
                            label: 'Bairro *',
                            maxLines: 1,
                            validator: (value) =>
                                Validators.validateRequired(value, 'Bairro'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            controller: _cidadeController,
                            label: 'Cidade *',
                            maxLines: 1,
                            validator: (value) =>
                                Validators.validateRequired(value, 'Cidade'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: CustomDropdown<String>(
                            value: _ufController.text.isEmpty
                                ? null
                                : _ufController.text,
                            label: 'UF *',
                            items: _ufs
                                .map((uf) => DropdownMenuItem(
                                    value: uf, child: Text(uf)))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _ufController.text = value ?? '';
                              });
                            },
                            validator: (value) =>
                                Validators.validateRequired(value, 'UF'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Checkbox Ativo
                    CheckboxListTile(
                      title: const Text('Ativo?'),
                      value: _ativo,
                      onChanged: (value) =>
                          setState(() => _ativo = value ?? true),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 12),

                    // Campo Observação
                    CustomTextField(
                      controller: _observacaoController,
                      label: 'Observação',
                      maxLines: 3,
                      hintText: 'Informações adicionais sobre a seguradora...',
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Botões fixos na parte inferior
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _cancelarForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _salvarStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: Text(_statusEditando == null ? 'Salvar' : 'Atualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ ADICIONADO: Widget de feedback da Receita Federal
  Widget _buildFeedbackReceitaFederal() {
    if (!_cnpjValidado || _dadosReceitaFederal == null) {
      return const SizedBox.shrink();
    }

    final dados = _dadosReceitaFederal!;
    final situacao = dados['situacao'] ?? '';
    final abertura = dados['abertura'] ?? '';
    final porte = dados['porte'] ?? '';

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CNPJ Validado na Receita Federal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (situacao.isNotEmpty) _buildInfoRow('Situação:', situacao),
              if (abertura.isNotEmpty) _buildInfoRow('Abertura:', abertura),
              if (porte.isNotEmpty) _buildInfoRow('Porte:', porte),
              const SizedBox(height: 4),
              Text(
                'Dados carregados automaticamente da Receita Federal.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.green[600],
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget buscarSeguradorasList() {
    if (_isLoadingPage) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando página...'),
          ],
        ),
      );
    }

    if (_seguradoras.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _currentSearch.isNotEmpty
                  ? 'Nenhum Item encontrado para a busca "$_currentSearch"'
                  : 'Nenhum Item cadastrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            if (_currentSearch.isNotEmpty)
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Limpar Busca'),
              )
            else
              ElevatedButton(
                onPressed: _showNovoStatusForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar Primeiro Ítem'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _seguradoras.length,
      itemBuilder: (context, index) {
        final seguradora = _seguradoras[index];
        return _buildSeguradoraCard(seguradora, index);
      },
    );
  }

  Widget _buildSeguradoraCard(seguradora.Seguradora seguradora, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: Center(
                    child: Text(
                      seguradora.id?.toString() ?? '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            seguradora.nomeFantasia.isNotEmpty
                                ? seguradora.nomeFantasia
                                : seguradora.razaoSocial,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (seguradora.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: const Text(
                                'PADRÃO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (seguradora.observacao?.isNotEmpty == true)
                        Text(
                          seguradora.observacao ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, seguradora),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: seguradora.ativo ? 'desativar' : 'ativar',
                      child: Row(
                        children: [
                          Icon(
                            seguradora.ativo
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                            color:
                                seguradora.ativo ? Colors.orange : Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            seguradora.ativo ? 'Desativar' : 'Ativar',
                            style: TextStyle(
                              color: seguradora.ativo
                                  ? Colors.orange
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Status
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: seguradora.ativo
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: seguradora.ativo ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Text(
                    seguradora.ativo ? 'ATIVO' : 'INATIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: seguradora.ativo ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${seguradora.id}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls() {
    if (_seguradoras.isEmpty && !_isLoading && !_isLoadingPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['totalPages'] ??
        ((_seguradoras.isNotEmpty)
            ? ((_seguradoras.length / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt())
            : 1);
    final currentPage = _pagination?['currentPage'] ?? _currentPage;
    final total = _pagination?['total'] ?? _seguradoras.length;
    final hasNextPage =
        _pagination?['hasNextPage'] ?? (_currentPage < totalPages);
    final hasPrevPage = _pagination?['hasPrevPage'] ?? (_currentPage > 1);

    final startItem = ((currentPage - 1) * _pageSize) + 1;
    final endItem =
        (currentPage * _pageSize) > total ? total : (currentPage * _pageSize);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mostrando $startItem-$endItem de $total registros',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Página $currentPage de $totalPages',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: currentPage > 1 ? () => _goToPage(1) : null,
                icon: const Icon(Icons.first_page),
                tooltip: 'Primeira página',
                style: IconButton.styleFrom(
                  backgroundColor: currentPage > 1
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              IconButton(
                onPressed:
                    hasPrevPage ? () => _goToPage(currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Página anterior',
                style: IconButton.styleFrom(
                  backgroundColor: hasPrevPage
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              const SizedBox(width: 16),
              ..._buildPageNumbers(currentPage, totalPages),
              const SizedBox(width: 16),
              IconButton(
                onPressed:
                    hasNextPage ? () => _goToPage(currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Próxima página',
                style: IconButton.styleFrom(
                  backgroundColor: hasNextPage
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
              IconButton(
                onPressed: currentPage < totalPages
                    ? () => _goToPage(totalPages)
                    : null,
                icon: const Icon(Icons.last_page),
                tooltip: 'Última página',
                style: IconButton.styleFrom(
                  backgroundColor: currentPage < totalPages
                      ? const Color(0xFF2E7D32).withOpacity(0.1)
                      : Colors.grey[200],
                ),
              ),
            ],
          ),
          if (totalPages > 5) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Ir para página: '),
                SizedBox(
                  width: 60,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page >= 1 && page <= totalPages) {
                        _goToPage(page);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers(int currentPage, int totalPages) {
    List<Widget> pages = [];

    int start = (currentPage - 2).clamp(1, totalPages);
    int end = (currentPage + 2).clamp(1, totalPages);

    if (end - start < 4) {
      if (start == 1) {
        end = (start + 4).clamp(1, totalPages);
      } else if (end == totalPages) {
        start = (end - 4).clamp(1, totalPages);
      }
    }

    for (int i = start; i <= end; i++) {
      pages.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: ElevatedButton(
            onPressed: i == currentPage ? null : () => _goToPage(i),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  i == currentPage ? const Color(0xFF2E7D32) : Colors.white,
              foregroundColor:
                  i == currentPage ? Colors.white : const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              i.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    return pages;
  }

  void _goToPage(int page) {
    if (page != _currentPage && page >= 1) {
      setState(() => _currentPage = page);
      _loadSeguradoras(showLoading: false);
    }
  }

  Widget _buildEstatisticasGerais() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estatísticas Gerais',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Total de Status',
              (_estatisticas['total'] ?? 0).toString(),
              Icons.flag,
              const Color(0xFF2E7D32),
            ),
            _buildStatCard(
              'Status Ativos',
              (_estatisticas['ativos'] ?? 0).toString(),
              Icons.check_circle,
              const Color(0xFF1976D2),
            ),
            _buildStatCard(
              'Status Padrão',
              (_estatisticas['padrao'] ?? 0).toString(),
              Icons.star,
              const Color(0xFFED6C02),
            ),
            _buildStatCard(
              'Criados Este Mês',
              (_estatisticas['criadosEsteMes'] ?? 0).toString(),
              Icons.trending_up,
              const Color(0xFF9C27B0),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGraficos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Distribuição por Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Gráfico de distribuição de status\n(Implementar com charts)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, seguradora.Seguradora seguradora) {
    switch (action) {
      case 'editar':
        _editarSeguradora(seguradora);
        break;
      case 'ativar':
        _ativarSeguradora(seguradora);
        break;
      case 'desativar':
        _desativarSeguradora(seguradora);
        break;
      case 'excluir':
        _confirmarExclusao(seguradora);
        break;
    }
  }

  void _editarSeguradora(seguradora.Seguradora seguradora) {
    setState(() {
      _statusEditando = seguradora;

      // ✅ DADOS BÁSICOS
      _razaoSocialController.text = seguradora.razaoSocial;
      _nomeFantasiaController.text = seguradora.nomeFantasia;
      _cnpjController.text = seguradora.cnpj;
      _telefoneController.text = seguradora.telefone;
      _celularController.text = seguradora.celular ?? '';

      // ✅ DADOS DA APÓLICE - CORRIGIDO
      _valorApoliceController.text = seguradora.valorApolice.toString();
      _apoliceController.text = seguradora.apolice;
      _porcentagemDHMOController.text = seguradora.porcentagemDhmo.toString();

      // ✅ DADOS DE ENDEREÇO - CORRIGIDO
      _cepController.text = seguradora.cep;
      _logradouroController.text = seguradora.logradouro;
      _numeroController.text = seguradora.numero ?? '';
      _complementoController.text = seguradora.complemento ?? '';
      _bairroController.text = seguradora.bairro;
      _cidadeController.text = seguradora.cidade;
      _ufController.text = seguradora.uf;

      // ✅ OUTROS CAMPOS
      _observacaoController.text = seguradora.observacao ?? '';
      _ativo = seguradora.ativo;
      _isDefault = seguradora.isDefault;

      // ✅ VALIDAÇÃO - O CNPJ já foi validado anteriormente
      _cnpjValidado = true;

      _showForm = true;
    });
  }

  Future<void> _ativarSeguradora(seguradora.Seguradora seguradora) async {
    try {
      final success =
          await seguradoraService.SeguradoraService.desativarSeguradora(
              seguradora.id!,
              ativo: true);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Item ativado com sucesso!');
        _loadSeguradoras(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _desativarSeguradora(seguradora.Seguradora seguradora) async {
    try {
      final success =
          await seguradoraService.SeguradoraService.desativarSeguradora(
              seguradora.id!,
              ativo: false);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Item desativado com sucesso!');
        _loadSeguradoras(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _confirmarExclusao(seguradora.Seguradora seguradora) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Excluir Item',
      content:
          'Tem certeza que deseja excluir "${seguradora.nomeFantasia}"?\n\nEsta ação não pode ser desfeita e pode afetar seguradoras que utilizam este status.',
      confirmText: 'Excluir',
    );

    if (confirm) {
      try {
        final success =
            await seguradoraService.SeguradoraService.deletarSeguradora(
                seguradora.id!);
        if (success) {
          AppUtils.showSuccessSnackBar(context, 'Item excluído com sucesso!');
          _loadSeguradoras();
        }
      } catch (e) {
        AppUtils.showErrorSnackBar(context, 'Erro: $e');
      }
    }
  }

  void _showNovoStatusForm() {
    _limparFormulario();
    setState(() => _showForm = true);
  }

  void _cancelarForm() {
    _limparFormulario();
    setState(() => _showForm = false);
  }

  void _limparFormulario() {
    // ✅ Limpar TODOS os campos corretamente
    _razaoSocialController.clear();
    _nomeFantasiaController.clear();
    _cnpjController.clear();
    _telefoneController.clear();
    _celularController.clear();
    _valorApoliceController.clear();
    _apoliceController.clear();
    _porcentagemDHMOController.clear();
    _cepController.clear();
    _logradouroController.clear();
    _numeroController.clear();
    _complementoController.clear();
    _bairroController.clear();
    _cidadeController.clear();
    _ufController.clear();
    _observacaoController.clear();

    // Campos originais que também devem ser limpos
    _nomeController.clear();
    _descricaoController.clear();
    _ordemController.clear();
    _corSelecionada = null;
    _ativo = true;
    _isDefault = false;
    _statusEditando = null;
    _cnpjValidado = false;
    _dadosReceitaFederal = null;
  }

  Future<void> _salvarStatus() async {
    if (!_formKey.currentState!.validate()) return;

    // Debug prints
    print('DEBUG: id_endereco: ${_statusEditando?.idEndereco}');
    print('DEBUG: id_seguradora: ${_statusEditando?.id}');

    // ✅ Dados completos da seguradora
    final dados = {
      'razao_social': _razaoSocialController.text.trim(),
      'nome_fantasia': _nomeFantasiaController.text.trim(),
      'cnpj': _cnpjController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'celular': _celularController.text.trim() ?? '',
      'valor_apolice':
          double.tryParse(_valorApoliceController.text.trim()) ?? 0.0,
      'numero_apolice': _apoliceController.text.trim(),
      'porcentagem_dhmo':
          double.tryParse(_porcentagemDHMOController.text.trim()) ?? 0.0,
      'observacao': _observacaoController.text.trim() ?? '',
      'ativo': _ativo,
      'endereco': {
        if (_statusEditando?.idEndereco != null)
          'id_endereco': _statusEditando!.idEndereco,
        'cd_seguradora': _statusEditando?.id,
        'cep': _cepController.text.trim(),
        'logradouro': _logradouroController.text.trim(),
        'numero': _numeroController.text.trim(),
        'bairro': _bairroController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'complemento': _complementoController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'uf': _ufController.text.trim(),
        'ativo': true,
        'principal': true,
      }
    };

    try {
      setState(() => _isLoading = true);

      bool success;
      if (_statusEditando == null) {
        success =
            await seguradoraService.SeguradoraService.criarSeguradora(dados);
      } else {
        success = await seguradoraService.SeguradoraService.atualizarSeguradora(
            _statusEditando!.id!, dados);
      }

      if (success) {
        AppUtils.showSuccessSnackBar(
          context,
          _statusEditando == null
              ? 'Seguradora criada com sucesso!'
              : 'Seguradora atualizada com sucesso!',
        );
        _cancelarForm();
        _loadSeguradoras();
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFiltrosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<bool>(
                value: _filtroAtivo,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: true, child: Text('Ativos')),
                  DropdownMenuItem(value: false, child: Text('Inativos')),
                ],
                onChanged: (value) => setState(() => _filtroAtivo = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<bool>(
                value: _filtroDefault,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: true, child: Text('Status Padrão')),
                  DropdownMenuItem(value: false, child: Text('Personalizados')),
                ],
                onChanged: (value) => setState(() => _filtroDefault = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtroAtivo = null;
                _filtroDefault = null;
                _currentPage = 1;
              });
              Navigator.of(context).pop();
              _loadSeguradoras();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _currentPage = 1);
              _loadSeguradoras();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  bool _temFiltrosAtivos() {
    return _filtroAtivo != null ||
        _filtroDefault != null ||
        _currentSearch.isNotEmpty;
  }

  Widget _buildFiltrosAtivos() {
    final filtros = <Widget>[];

    if (_currentSearch.isNotEmpty) {
      filtros.add(_buildFiltroChip('Busca: "$_currentSearch"', _clearSearch));
    }

    if (_filtroAtivo != null) {
      filtros.add(_buildFiltroChip(
          'Status: ${_filtroAtivo! ? "Ativos" : "Inativos"}', () {
        setState(() => _filtroAtivo = null);
        _loadSeguradoras();
      }));
    }

    if (_filtroDefault != null) {
      filtros.add(_buildFiltroChip(
          'Tipo: ${_filtroDefault! ? "Padrão" : "Personalizados"}', () {
        setState(() => _filtroDefault = null);
        _loadSeguradoras();
      }));
    }

    return Wrap(spacing: 8, children: filtros);
  }

  Widget _buildFiltroChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
    );
  }

  Future<void> _exportarDados() async {
    try {
      await seguradoraService.SeguradoraService.exportarCSV(
        ativo: _filtroAtivo,
        isDefault: _filtroDefault,
      );
      AppUtils.showSuccessSnackBar(context, 'Dados exportados com sucesso!');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao exportar: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _nomeController.dispose();
    _descricaoController.dispose();
    _ordemController.dispose();
    _razaoSocialController.dispose();
    _nomeFantasiaController.dispose();
    _cnpjController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();
    _valorApoliceController.dispose();
    _apoliceController.dispose();
    _porcentagemDHMOController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }
}
