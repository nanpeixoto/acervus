// lib/screens/admin/usuario_screen.dart
import 'package:flutter/material.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'package:sistema_estagio/widgets/custom_dropdown.dart';
import 'package:sistema_estagio/widgets/loading_overlay.dart';
import 'package:sistema_estagio/widgets/custom_text_field.dart';
import 'package:sistema_estagio/models/_core/usuario.dart';
import 'package:sistema_estagio/services/_core/usuario_service.dart'
    as usuarioService;
import 'package:sistema_estagio/utils/validators.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class UsuarioScreen extends StatefulWidget {
  const UsuarioScreen({super.key});

  @override
  State<UsuarioScreen> createState() => UsuariosScreen();
}

class UsuariosScreen extends State<UsuarioScreen>
    with TickerProviderStateMixin {
  final _searchController = TextEditingController();

  // ✅ Formatters para máscaras
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##');
  final _telefoneFormatter = MaskTextInputFormatter(mask: '(##) ####-####');
  final _celularFormatter = MaskTextInputFormatter(mask: '(##) #####-####');

  // Controladores do formulário
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final TextEditingController _confirmarSenhaController =
      TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _observacaoController = TextEditingController();

  // Variáveis de estado
  bool _ativo = true;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;
  String? _tipoUsuarioSelecionado;

  List<Usuario> _usuarios = [];
  Map<String, dynamic> _estatisticas = {};
  bool _isLoading = false;

  // Filtros
  bool? _filtroAtivo;
  String? _filtroTipoUsuario;

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
  Usuario? _usuarioEditando;
  final _formKey = GlobalKey<FormState>();

  // ✅ Tipos de usuário
  final List<Map<String, dynamic>> _tiposUsuario = [
    {
      'value': 'ADMIN',
      'label': 'Administrador',
      'description': 'Acesso total ao sistema'
    },
    {
      'value': 'COLABORADOR',
      'label': 'Colaborador',
      'description': 'Colaborador interno'
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUsuarios();
    _loadEstatisticas();
  }

  // ✅ Validação de CPF
  String? _validateCPF(String? value) {
    if (value?.isEmpty ?? true) {
      return 'CPF é obrigatório';
    }

    final cpf = value!.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    // Validação básica de CPF
    if (!_validarCPFLocal(cpf)) {
      return 'CPF inválido';
    }

    return null;
  }

  bool _validarCPFLocal(String cpf) {
    if (cpf.length != 11) return false;

    // CPFs conhecidos como inválidos
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    // Cálculo do primeiro dígito verificador
    int soma = 0;
    for (int i = 0; i < 9; i++) {
      soma += int.parse(cpf[i]) * (10 - i);
    }
    int primeiroDigito = (soma * 10) % 11;
    if (primeiroDigito == 10) primeiroDigito = 0;

    // Cálculo do segundo dígito verificador
    soma = 0;
    for (int i = 0; i < 10; i++) {
      soma += int.parse(cpf[i]) * (11 - i);
    }
    int segundoDigito = (soma * 10) % 11;
    if (segundoDigito == 10) segundoDigito = 0;

    return primeiroDigito == int.parse(cpf[9]) &&
        segundoDigito == int.parse(cpf[10]);
  }

  // ✅ Validação de senha
  String? _validatePassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Senha é obrigatória';
    }

    if (value!.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Confirmação de senha é obrigatória';
    }

    if (value != _senhaController.text) {
      return 'Senhas não conferem';
    }

    return null;
  }

  // ✅ Métodos para mostrar mensagens
  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
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

  Future<void> _loadUsuarios({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingPage = true);
    }

    try {
      final result = await usuarioService.UsuarioService.listarUsuarios(
        page: _currentPage,
        limit: _pageSize,
        search: _currentSearch.isEmpty ? null : _currentSearch,
        ativo: _filtroAtivo,
      );

      if (mounted) {
        setState(() {
          _usuarios = result['usuarios'] as List<Usuario>;
          _pagination = result['pagination'];

          if (_pagination == null || _pagination!.isEmpty) {
            final totalItems = _usuarios.length;
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
            content: Text('Erro ao carregar usuários: $e'),
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
      final stats = await usuarioService.UsuarioService.getEstatisticas();
      setState(() {
        _estatisticas = stats;
      });
    } catch (e) {
      // Ignorar erro de estatísticas e criar estatísticas básicas
      setState(() {
        _estatisticas = {
          'total': _usuarios.length,
          'ativos': _usuarios.where((u) => u.ativo == true).length,
          'inativos': _usuarios.where((u) => u.ativo == false).length,
          'criadosEsteMes': 0,
        };
      });
    }
  }

  void _performSearch() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _currentSearch = _searchController.text.trim();
    });

    await _loadUsuarios();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentSearch = '';
      _currentPage = 1;
    });
    _loadUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuários'),
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
            onPressed: _showNovoUsuarioForm,
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar Usuário',
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
        if (_showForm)
          Expanded(
            child: _buildFormulario(),
          )
        else
          Expanded(
            child: _buildUsuariosList(),
          ),
        if (!_showForm) _buildPaginationControls(),
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
                  'Total de Usuários',
                  (_pagination?['total'] ?? _usuarios.length).toString(),
                  Icons.people,
                  const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Ativos',
                  (_usuarios.where((u) => u.ativo == true).length).toString(),
                  Icons.check_circle,
                  const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Inativos',
                  (_usuarios.where((u) => u.ativo == false).length).toString(),
                  Icons.block,
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
                  label: 'Buscar por nome, login ou email',
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
                    _loadUsuarios();
                  }
                },
                underline: Container(),
                isDense: true,
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _currentPage = 1);
                  _loadUsuarios();
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

  // ✅ FORMULÁRIO COMPLETO DE USUÁRIO
  Widget _buildFormulario() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      // Remove the fixed height: height: 600,
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
                  _usuarioEditando == null ? 'Novo Usuário' : 'Editar Usuário',
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
                    // ... rest of your form content remains the same
                    // Seção: Dados Pessoais
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Dados Pessoais',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nome
                    CustomTextField(
                      controller: _nomeController,
                      label: 'Nome Completo *',
                      maxLines: 1,
                      validator: (value) =>
                          Validators.validateRequired(value, 'Nome'),
                    ),
                    const SizedBox(height: 12),

                    // CPF
                    CustomTextField(
                      controller: _cpfController,
                      label: 'CPF *',
                      maxLines: 1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_cpfFormatter],
                      validator: _validateCPF,
                    ),
                    const SizedBox(height: 12),

                    // Telefone e Celular
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
                    const SizedBox(height: 16),

                    // Seção: Dados de Acesso
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Dados de Acesso',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Login e Email
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _loginController,
                            label: 'Login *',
                            maxLines: 1,
                            validator: (value) =>
                                Validators.validateRequired(value, 'Login'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            controller: _emailController,
                            label: 'E-mail *',
                            maxLines: 1,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Senhas (apenas para novo usuário ou se estiver alterando)
                    if (_usuarioEditando == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _senhaController,
                              label: 'Senha *',
                              maxLines: 1,
                              obscureText: !_senhaVisivel,
                              validator: _validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(_senhaVisivel
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _senhaVisivel = !_senhaVisivel;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _confirmarSenhaController,
                              label: 'Confirmar Senha *',
                              maxLines: 1,
                              obscureText: !_confirmarSenhaVisivel,
                              validator: _validateConfirmPassword,
                              suffixIcon: IconButton(
                                icon: Icon(_confirmarSenhaVisivel
                                    ? Icons.visibility
                                    : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _confirmarSenhaVisivel =
                                        !_confirmarSenhaVisivel;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Tipo de Usuário/Perfil
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // TIPO DE USUÁRIO (METADE ESQUERDA)
                          Expanded(
                            child: CustomDropdown<String>(
                              label: 'Perfil/Tipo de Usuário *',
                              value: _tipoUsuarioSelecionado,
                              hintText: 'Selecione o perfil do usuário',
                              items: _tiposUsuario
                                  .map((tipo) => DropdownMenuItem<String>(
                                        value: tipo['value'],
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              tipo['label'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              tipo['description'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _tipoUsuarioSelecionado = value;
                                });
                              },
                              validator: (value) => Validators.validateRequired(
                                  value, 'Perfil/Tipo de Usuário'),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // STATUS (METADE DIREITA) - Mover o checkbox para cá
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  const Text(
                                    'Status: ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: _ativo,
                                    onChanged: (value) =>
                                        setState(() => _ativo = value),
                                    activeColor: const Color(0xFF2E7D32),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _ativo ? 'Ativo' : 'Inativo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _ativo
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Observação
                    CustomTextField(
                      controller: _observacaoController,
                      label: 'Observação',
                      maxLines: 3,
                      hintText: 'Informações adicionais sobre o usuário...',
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
                  onPressed: _salvarUsuario,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child:
                      Text(_usuarioEditando == null ? 'Salvar' : 'Atualizar'),
                ),
              ],
            ),
          ],
        ),
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

  Widget _buildUsuariosList() {
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

    if (_usuarios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _currentSearch.isNotEmpty
                  ? 'Nenhum usuário encontrado para a busca "$_currentSearch"'
                  : 'Nenhum usuário cadastrado',
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
                onPressed: _showNovoUsuarioForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Adicionar Primeiro Usuário'),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _usuarios.length,
      itemBuilder: (context, index) {
        final usuario = _usuarios[index];
        return _buildUsuarioCard(usuario, index);
      },
    );
  }

  Widget _buildUsuarioCard(Usuario usuario, int index) {
    final idStr = (usuario.id ?? '').toString();
    final nome = usuario.nome ?? 'Nome não informado';
    final login = usuario.login ?? '';
    final email = usuario.email ?? '';
    final cpf = usuario.cpf ?? '';
    final telefone = (usuario.celular?.trim().isNotEmpty == true)
        ? usuario.celular!.trim()
        : (usuario.telefone ?? '');
    final perfilLabel = _getTipoUsuarioLabel(usuario.tipoUsuario);
    final perfilColor = _getPerfilColor(usuario.tipoUsuario);
    final ativo = usuario.ativo == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E6DE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ID em formato "pill"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2E7D32)),
            ),
            child: Text(
              'ID $idStr',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32),
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nome
          _infoItemRow(
            icon: Icons.person,
            text: nome,
            flex: 3,
            bold: true,
          ),

          _vDivider(),

          // Login
          _infoItemRow(
            icon: Icons.account_circle_outlined,
            text: login,
            flex: 2,
          ),

          _vDivider(),

          // Email
          _infoItemRow(
            icon: Icons.email_outlined,
            text: email,
            flex: 3,
          ),
          _vDivider(),

          // Perfil + Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // Chip de Perfil
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: perfilColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: perfilColor),
                  ),
                  child: Text(
                    perfilLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: perfilColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _statusChip(ativo: ativo),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Ações
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, usuario),
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
                value: ativo ? 'desativar' : 'ativar',
                child: Row(
                  children: [
                    Icon(
                      ativo ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: ativo ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ativo ? 'Desativar' : 'Ativar',
                      style: TextStyle(
                        color: ativo ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'resetar_senha',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Resetar Senha', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0xFFE3E7E1),
    );
  }

  Widget _infoItemRow({
    required IconData icon,
    required String text,
    required int flex,
    bool bold = false,
  }) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Expanded(
            child: Tooltip(
              message: text,
              waitDuration: const Duration(milliseconds: 400),
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                  color: Colors.grey[900],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip({required bool ativo}) {
    final bg = ativo ? Colors.green[100] : Colors.grey[200];
    final fg = ativo ? Colors.green[800] : Colors.grey[700];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ativo ? Colors.green : Colors.grey),
      ),
      child: Text(
        ativo ? 'ATIVO' : 'INATIVO',
        style: TextStyle(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ✅ Métodos auxiliares para cores e ícones por perfil
  Color _getPerfilColor(String? perfil) {
    switch (perfil?.toUpperCase()) {
      case 'ADMIN':
        return const Color(0xFFD32F2F); // Vermelho
      case 'COLABORADOR':
        return const Color(0xFF1976D2); // Azul
      case 'EMPRESA':
        return const Color(0xFF2E7D32); // Verde
      case 'IE':
        return const Color(0xFF9C27B0); // Roxo
      default:
        return Colors.grey;
    }
  }

  IconData _getPerfilIcon(String? perfil) {
    switch (perfil?.toUpperCase()) {
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'COLABORADOR':
        return Icons.badge;
      case 'EMPRESA':
        return Icons.business;
      case 'IE':
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  String _getTipoUsuarioLabel(String? tipo) {
    final tipoEncontrado = _tiposUsuario.firstWhere(
      (t) => t['value'] == tipo,
      orElse: () => {'label': tipo ?? 'Não definido'},
    );
    return tipoEncontrado['label'];
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
    if (_usuarios.isEmpty && !_isLoading && !_isLoadingPage) {
      return const SizedBox.shrink();
    }

    final totalPages = _pagination?['totalPages'] ??
        ((_usuarios.isNotEmpty)
            ? ((_usuarios.length / _pageSize)
                .ceil()
                .clamp(1, double.infinity)
                .toInt())
            : 1);
    final currentPage = _pagination?['currentPage'] ?? _currentPage;
    final total = _pagination?['total'] ?? _usuarios.length;
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
      _loadUsuarios(showLoading: false);
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
              'Total de Usuários',
              (_estatisticas['total'] ?? 0).toString(),
              Icons.people,
              const Color(0xFF2E7D32),
            ),
            _buildStatCard(
              'Usuários Ativos',
              (_estatisticas['ativos'] ?? 0).toString(),
              Icons.check_circle,
              const Color(0xFF1976D2),
            ),
            _buildStatCard(
              'Usuários Inativos',
              (_estatisticas['inativos'] ?? 0).toString(),
              Icons.block,
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
          'Distribuição por Tipo',
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
              'Gráfico de distribuição por tipo de usuário\n(Implementar com charts)',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(String action, Usuario usuario) {
    switch (action) {
      case 'editar':
        _editarUsuario(usuario);
        break;
      case 'ativar':
        _ativarUsuario(usuario);
        break;
      case 'desativar':
        _desativarUsuario(usuario);
        break;
      case 'resetar_senha':
        _resetarSenhaUsuario(usuario);
        break;
    }
  }

  void _editarUsuario(Usuario usuario) {
    setState(() {
      _usuarioEditando = usuario;
      _nomeController.text = usuario.nome ?? '';
      _loginController.text = usuario.login ?? '';
      _emailController.text = usuario.email ?? '';
      _cpfController.text = usuario.cpf ?? '';
      _telefoneController.text = usuario.telefone ?? '';
      _celularController.text = usuario.celular ?? '';
      _observacaoController.text = usuario.observacao ?? '';
      _ativo = usuario.ativo ?? true;
      _tipoUsuarioSelecionado = usuario.tipoUsuario;

      // Limpar campos de senha na edição
      _senhaController.clear();
      _confirmarSenhaController.clear();

      _showForm = true;
    });
  }

  Future<void> _ativarUsuario(Usuario usuario) async {
    try {
      final success = await usuarioService.UsuarioService.ativarUsuario(
          usuario.id.toString(),
          ativo: true);
      if (success) {
        AppUtils.showSuccessSnackBar(context, 'Usuário ativado com sucesso!');
        _loadUsuarios(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _desativarUsuario(Usuario usuario) async {
    try {
      final success = await usuarioService.UsuarioService.desativarUsuario(
          usuario.id.toString());
      if (success) {
        AppUtils.showSuccessSnackBar(
            context, 'Usuário desativado com sucesso!');
        _loadUsuarios(showLoading: false);
      }
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _resetarSenhaUsuario(Usuario usuario) async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Resetar Senha',
      content:
          'Tem certeza que deseja resetar a senha do usuário "${usuario.nome}"?\n\nEsta funcionalidade ainda não foi implementada no backend.',
      confirmText: 'OK',
    );

    if (confirm) {
      // TODO: Implementar quando o endpoint estiver disponível
      AppUtils.showErrorSnackBar(
          context, 'Funcionalidade ainda não implementada no backend.');
    }
  }

  void _showNovoUsuarioForm() {
    _limparFormulario();
    setState(() => _showForm = true);
  }

  void _cancelarForm() {
    _limparFormulario();
    setState(() => _showForm = false);
  }

  void _limparFormulario() {
    _nomeController.clear();
    _loginController.clear();
    _emailController.clear();
    _senhaController.clear();
    _confirmarSenhaController.clear();
    _cpfController.clear();
    _telefoneController.clear();
    _celularController.clear();
    _observacaoController.clear();
    _ativo = true;
    _tipoUsuarioSelecionado = null;
    _usuarioEditando = null;
    _senhaVisivel = false;
    _confirmarSenhaVisivel = false;
  }

  Future<void> _salvarUsuario() async {
    if (!_formKey.currentState!.validate()) return;

    final dados = {
      'nome': _nomeController.text.trim(),
      'login': _loginController.text.trim(),
      'email': _emailController.text.trim(),
      'cpf': _cpfController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'celular': _celularController.text.trim(),
      'observacao': _observacaoController.text.trim(),
      'ativo': _ativo,
      'perfil': _tipoUsuarioSelecionado,
    };

    // Incluir senha apenas para novos usuários
    if (_usuarioEditando == null) {
      dados['senha'] = _senhaController.text.trim();
    }

    try {
      setState(() => _isLoading = true);

      bool success;
      if (_usuarioEditando == null) {
        success = await usuarioService.UsuarioService.criarUsuario(dados);
      } else {
        success = await usuarioService.UsuarioService.atualizarUsuario(
            _usuarioEditando!.id.toString(), dados);
      }

      if (success) {
        AppUtils.showSuccessSnackBar(
          context,
          _usuarioEditando == null
              ? 'Usuário criado com sucesso!'
              : 'Usuário atualizado com sucesso!',
        );
        _cancelarForm();
        _loadUsuarios();
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
              DropdownButtonFormField<String>(
                value: _filtroTipoUsuario,
                decoration: const InputDecoration(labelText: 'Tipo de Usuário'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todos')),
                  ..._tiposUsuario.map((tipo) => DropdownMenuItem(
                      value: tipo['value'], child: Text(tipo['label']))),
                ],
                onChanged: (value) =>
                    setState(() => _filtroTipoUsuario = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filtroAtivo = null;
                _filtroTipoUsuario = null;
                _currentPage = 1;
              });
              Navigator.of(context).pop();
              _loadUsuarios();
            },
            child: const Text('Limpar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _currentPage = 1);
              _loadUsuarios();
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  bool _temFiltrosAtivos() {
    return _filtroAtivo != null ||
        _filtroTipoUsuario != null ||
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
        _loadUsuarios();
      }));
    }

    if (_filtroTipoUsuario != null) {
      final tipoLabel = _getTipoUsuarioLabel(_filtroTipoUsuario);
      filtros.add(_buildFiltroChip('Tipo: $tipoLabel', () {
        setState(() => _filtroTipoUsuario = null);
        _loadUsuarios();
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
      // TODO: Implementar quando o método estiver disponível no service
      AppUtils.showErrorSnackBar(context,
          'Funcionalidade de exportação ainda não implementada no service.');
    } catch (e) {
      AppUtils.showErrorSnackBar(context, 'Erro ao exportar: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _nomeController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _cpfController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }
}
