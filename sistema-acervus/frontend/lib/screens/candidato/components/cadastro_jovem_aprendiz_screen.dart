import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../providers/auth_provider.dart';
import '../../../utils/validators.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/loading_overlay.dart';

class CadastroJovemAprendizScreen extends StatefulWidget {
  const CadastroJovemAprendizScreen({super.key});

  @override
  State<CadastroJovemAprendizScreen> createState() =>
      _CadastroJovemAprendizScreenState();
}

class _CadastroJovemAprendizScreenState
    extends State<CadastroJovemAprendizScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Formatters
  final _cpfFormatter = MaskTextInputFormatter(mask: '###.###.###-##');
  final _cepFormatter = MaskTextInputFormatter(mask: '#####-###');
  final _telefoneFormatter = MaskTextInputFormatter(mask: '(##) #####-####');

  // Controllers - Dados Pessoais
  final _nomeController = TextEditingController();
  final _nomeSocialController = TextEditingController();
  final _rgController = TextEditingController();
  final _cpfController = TextEditingController();
  final _orgaoEmissorController = TextEditingController();
  final _naturalidadeController = TextEditingController();
  final _carteiraTrabalhoController = TextEditingController();

  // Controllers - Contatos
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _celularController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  // Controllers - Endereço
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _complementoController = TextEditingController();

  // Controllers - Responsável (se menor)
  final _nomeResponsavelController = TextEditingController();
  final _telefoneResponsavelController = TextEditingController();
  final _emailResponsavelController = TextEditingController();

  // Controllers - Dados Acadêmicos/Profissionais
  final _instituicaoController = TextEditingController();
  final _cursoController = TextEditingController();
  final _experienciasController = TextEditingController();

  // Dropdowns
  String? _uf;
  String? _sexo;
  String? _genero;
  String? _raca;
  String? _estadoCivil;
  String? _estado;
  String? _tipoCarteiraTrabalho;
  DateTime? _dataNascimento;
  bool _isLoading = false;
  bool _isMenorIdade = false;

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

  final List<String> _sexos = ['Masculino', 'Feminino'];
  final List<String> _generos = [
    'Cisgênero',
    'Transgênero',
    'Não-binário',
    'Prefiro não informar'
  ];
  final List<String> _racas = [
    'Branca',
    'Preta',
    'Parda',
    'Amarela',
    'Indígena',
    'Prefiro não informar'
  ];
  final List<String> _estadosCivis = [
    'Solteiro(a)',
    'Casado(a)',
    'Divorciado(a)',
    'Viúvo(a)',
    'União Estável'
  ];
  final List<String> _tiposCarteira = ['Física', 'Digital'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Jovem Aprendiz'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
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
                        _buildStepIndicator(0, 'Dados\nPessoais'),
                        _buildStepConnector(),
                        _buildStepIndicator(1, 'Endereço'),
                        _buildStepConnector(),
                        _buildStepIndicator(2, 'Contato\ne Acesso'),
                        _buildStepConnector(),
                        _buildStepIndicator(3, 'Finalizar'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: (_currentPage + 1) / 4,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Etapa ${_currentPage + 1} de 4',
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
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildDadosPessoaisPage(),
                    _buildEnderecoPage(),
                    _buildContatoSenhaPage(),
                    _buildDadosFinaisPage(),
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
                            foregroundColor: const Color(0xFF2E7D32),
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
                            : (_currentPage == 3 ? _submitForm : _nextPage),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
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
                            : Text(_currentPage == 3
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
              color: isActive ? const Color(0xFF2E7D32) : Colors.grey[300],
              border: isCurrent
                  ? Border.all(color: const Color(0xFF2E7D32), width: 3)
                  : null,
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
              color: isActive ? const Color(0xFF2E7D32) : Colors.grey[600],
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

  Widget _buildDadosPessoaisPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dados Pessoais',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 24),

              // Nome e Nome Social
              CustomTextField(
                controller: _nomeController,
                label: 'Nome Completo *',
                validator: (value) =>
                    Validators.validateRequired(value, 'Nome'),
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _nomeSocialController,
                label: 'Nome Social',
                hintText: 'Opcional',
              ),
              const SizedBox(height: 16),

              // RG e CPF
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _rgController,
                      label: 'RG *',
                      validator: (value) =>
                          Validators.validateRequired(value, 'RG'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _cpfController,
                      label: 'CPF *',
                      inputFormatters: [_cpfFormatter],
                      validator: Validators.validateCPF,
                      onChanged: _verificarIdade,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Órgão Emissor e UF
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _orgaoEmissorController,
                      label: 'Órgão Emissor *',
                      validator: (value) =>
                          Validators.validateRequired(value, 'Órgão Emissor'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      value: _uf,
                      label: 'UF de Expedição *',
                      items: _ufs
                          .map((uf) => DropdownMenuItem(
                                value: uf,
                                child: Text(uf),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _uf = value),
                      validator: (value) =>
                          value == null ? 'UF é obrigatória' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Carteira de Trabalho
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _carteiraTrabalhoController,
                      label: 'Carteira de Trabalho *',
                      hintText: 'Número da carteira',
                      validator: (value) => Validators.validateRequired(
                          value, 'Carteira de Trabalho'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      value: _tipoCarteiraTrabalho,
                      label: 'Tipo *',
                      items: _tiposCarteira
                          .map((tipo) => DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _tipoCarteiraTrabalho = value),
                      validator: (value) =>
                          value == null ? 'Tipo é obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sexo e Gênero
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown<String>(
                      value: _sexo,
                      label: 'Sexo *',
                      items: _sexos
                          .map((sexo) => DropdownMenuItem(
                                value: sexo,
                                child: Text(sexo),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _sexo = value),
                      validator: (value) =>
                          value == null ? 'Sexo é obrigatório' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      value: _genero,
                      label: 'Gênero *',
                      items: _generos
                          .map((genero) => DropdownMenuItem(
                                value: genero,
                                child: Text(genero),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _genero = value),
                      validator: (value) =>
                          value == null ? 'Gênero é obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Raça e Estado Civil
              Row(
                children: [
                  Expanded(
                    child: CustomDropdown<String>(
                      value: _raca,
                      label: 'Raça *',
                      items: _racas
                          .map((raca) => DropdownMenuItem(
                                value: raca,
                                child: Text(raca),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _raca = value),
                      validator: (value) =>
                          value == null ? 'Raça é obrigatória' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      value: _estadoCivil,
                      label: 'Estado Civil *',
                      items: _estadosCivis
                          .map((estado) => DropdownMenuItem(
                                value: estado,
                                child: Text(estado),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _estadoCivil = value),
                      validator: (value) =>
                          value == null ? 'Estado civil é obrigatório' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Data de Nascimento e Naturalidade
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: Color(0xFF2E7D32)),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Data de Nascimento *',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  _dataNascimento != null
                                      ? '${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}'
                                      : 'Selecione a data',
                                  style: TextStyle(
                                    color: _dataNascimento != null
                                        ? Colors.black
                                        : Colors.grey[500],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _naturalidadeController,
                      label: 'Naturalidade *',
                      validator: (value) =>
                          Validators.validateRequired(value, 'Naturalidade'),
                    ),
                  ),
                ],
              ),

              // Indicador de menor de idade
              if (_isMenorIdade) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Menor de idade identificado. Será necessário informar dados do responsável.',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnderecoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Endereço Completo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 24),

              // CEP
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _cepController,
                      label: 'CEP *',
                      inputFormatters: [_cepFormatter],
                      validator: Validators.validateCEP,
                      onChanged: _buscarCEP,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _buscarCEP(_cepController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Buscar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Logradouro
              CustomTextField(
                controller: _logradouroController,
                label: 'Logradouro *',
                validator: (value) =>
                    Validators.validateRequired(value, 'Logradouro'),
              ),
              const SizedBox(height: 16),

              // Número e Bairro
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: CustomTextField(
                      controller: _numeroController,
                      label: 'Número *',
                      validator: (value) =>
                          Validators.validateRequired(value, 'Número'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      controller: _bairroController,
                      label: 'Bairro *',
                      validator: (value) =>
                          Validators.validateRequired(value, 'Bairro'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Cidade e Estado
              Row(
                children: [
                  Expanded(
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
              const SizedBox(height: 16),

              // Complemento
              CustomTextField(
                controller: _complementoController,
                label: 'Complemento',
                hintText: 'Apartamento, bloco, casa, etc.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContatoSenhaPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contato e Acesso',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 24),

              // Email
              CustomTextField(
                controller: _emailController,
                label: 'E-mail *',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),

              // Telefones
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _telefoneController,
                      label: 'Telefone *',
                      inputFormatters: [_telefoneFormatter],
                      validator: Validators.validatePhone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _celularController,
                      label: 'Celular *',
                      inputFormatters: [_telefoneFormatter],
                      validator: Validators.validatePhone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'Dados de Acesso',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 16),

              // Senhas
              CustomTextField(
                controller: _senhaController,
                label: 'Senha *',
                obscureText: true,
                validator: Validators.validatePassword,
                hintText: 'Mínimo 8 caracteres',
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _confirmarSenhaController,
                label: 'Confirmar Senha *',
                obscureText: true,
                validator: (value) {
                  if (value != _senhaController.text) {
                    return 'Senhas não conferem';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sua senha deve ter pelo menos 8 caracteres e conter letras e números.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
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
  }

  Widget _buildDadosFinaisPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Responsável (se menor de idade)
          if (_isMenorIdade) ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados do Responsável',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Como você é menor de idade, é necessário informar os dados do responsável.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _nomeResponsavelController,
                      label: 'Nome do Responsável *',
                      validator: _isMenorIdade
                          ? (value) => Validators.validateRequired(
                              value, 'Nome do Responsável')
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _telefoneResponsavelController,
                            label: 'Telefone do Responsável *',
                            inputFormatters: [_telefoneFormatter],
                            validator:
                                _isMenorIdade ? Validators.validatePhone : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            controller: _emailResponsavelController,
                            label: 'E-mail do Responsável',
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                return Validators.validateEmail(value);
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Dados Acadêmicos/Profissionais
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dados Acadêmicos e Profissionais',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Instituição e Curso
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _instituicaoController,
                          label: 'Instituição de Ensino',
                          hintText: 'Nome da escola/curso técnico',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomTextField(
                          controller: _cursoController,
                          label: 'Curso',
                          hintText: 'Ex: Ensino Médio, Técnico em...',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Experiências Profissionais
                  CustomTextField(
                    controller: _experienciasController,
                    label: 'Experiências Profissionais',
                    hintText:
                        'Descreva suas experiências anteriores, estágios, trabalhos temporários, etc.',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Informações Finais
          Container(
            padding: const EdgeInsets.all(16),
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
                    Icon(Icons.info_outline, color: Colors.green[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Programa Jovem Aprendiz',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Programa destinado a jovens de 14 a 24 anos\n'
                  '• Combina aprendizado teórico e prático\n'
                  '• Oportunidade de primeiro emprego\n'
                  '• Certificado de qualificação profissional',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentPage() {
    switch (_currentPage) {
      case 0:
        return _nomeController.text.isNotEmpty &&
            _rgController.text.isNotEmpty &&
            _cpfController.text.isNotEmpty &&
            _orgaoEmissorController.text.isNotEmpty &&
            _uf != null &&
            _carteiraTrabalhoController.text.isNotEmpty &&
            _tipoCarteiraTrabalho != null &&
            _sexo != null &&
            _genero != null &&
            _raca != null &&
            _estadoCivil != null &&
            _dataNascimento != null &&
            _naturalidadeController.text.isNotEmpty;
      case 1:
        return _cepController.text.isNotEmpty &&
            _logradouroController.text.isNotEmpty &&
            _numeroController.text.isNotEmpty &&
            _bairroController.text.isNotEmpty &&
            _cidadeController.text.isNotEmpty &&
            _estado != null;
      case 2:
        return _emailController.text.isNotEmpty &&
            _telefoneController.text.isNotEmpty &&
            _celularController.text.isNotEmpty &&
            _senhaController.text.isNotEmpty &&
            _confirmarSenhaController.text.isNotEmpty;
      case 3:
        if (_isMenorIdade) {
          return _nomeResponsavelController.text.isNotEmpty &&
              _telefoneResponsavelController.text.isNotEmpty;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 5475)), // 15 anos
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
    );

    if (date != null) {
      setState(() {
        _dataNascimento = date;
        _verificarMenorIdade();
      });
    }
  }

  void _verificarIdade(String? value) {
    if (_dataNascimento != null) {
      _verificarMenorIdade();
    }
  }

  void _verificarMenorIdade() {
    final hoje = DateTime.now();
    final idade = hoje.year - _dataNascimento!.year;
    final fezAniversario = hoje.month > _dataNascimento!.month ||
        (hoje.month == _dataNascimento!.month &&
            hoje.day >= _dataNascimento!.day);

    final idadeAtual = fezAniversario ? idade : idade - 1;

    setState(() {
      _isMenorIdade = idadeAtual < 18;
    });
  }

  void _buscarCEP(String cep) async {
    if (cep.length == 9) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simular busca de CEP via API
        await Future.delayed(const Duration(seconds: 1));

        setState(() {
          _logradouroController.text = "Rua das Palmeiras";
          _bairroController.text = "Jardim América";
          _cidadeController.text = "São Paulo";
          _estado = "SP";
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CEP encontrado!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CEP não encontrado. Verifique e tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        final dados = {
          'nome': _nomeController.text,
          'nomeSocial': _nomeSocialController.text.isEmpty
              ? null
              : _nomeSocialController.text,
          'rg': _rgController.text,
          'cpf': _cpfController.text,
          'orgaoEmissor': _orgaoEmissorController.text,
          'uf': _uf,
          'carteiraTrabalho': _carteiraTrabalhoController.text,
          'tipoCarteiraTrabalho': _tipoCarteiraTrabalho,
          'sexo': _sexo,
          'genero': _genero,
          'raca': _raca,
          'estadoCivil': _estadoCivil,
          'dataNascimento': _dataNascimento?.toIso8601String(),
          'naturalidade': _naturalidadeController.text,
          'email': _emailController.text,
          'telefone': _telefoneController.text,
          'celular': _celularController.text,
          'endereco': {
            'cep': _cepController.text,
            'logradouro': _logradouroController.text,
            'numero': _numeroController.text,
            'bairro': _bairroController.text,
            'cidade': _cidadeController.text,
            'estado': _estado,
            'complemento': _complementoController.text.isEmpty
                ? null
                : _complementoController.text,
          },
          'responsavel': _isMenorIdade
              ? {
                  'nome': _nomeResponsavelController.text,
                  'telefone': _telefoneResponsavelController.text,
                  'email': _emailResponsavelController.text.isEmpty
                      ? null
                      : _emailResponsavelController.text,
                }
              : null,
          'dadosAcademicos': {
            'instituicao': _instituicaoController.text.isEmpty
                ? null
                : _instituicaoController.text,
            'curso':
                _cursoController.text.isEmpty ? null : _cursoController.text,
          },
          'experienciasProfissionais': _experienciasController.text.isEmpty
              ? null
              : _experienciasController.text,
          'senha': _senhaController.text,
          'isMenorIdade': _isMenorIdade,
        };

        // Simular registro na API
        await Future.delayed(const Duration(seconds: 2));
        const success = true; // Simular sucesso

        setState(() {
          _isLoading = false;
        });

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Cadastro de Jovem Aprendiz realizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navegar para a próxima tela
          context.go('/cadastro/jovem-aprendiz'); // Navega usando GoRouter
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao realizar cadastro. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro inesperado. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    // Dados Pessoais
    _nomeController.dispose();
    _nomeSocialController.dispose();
    _rgController.dispose();
    _cpfController.dispose();
    _orgaoEmissorController.dispose();
    _naturalidadeController.dispose();
    _carteiraTrabalhoController.dispose();

    // Contatos
    _emailController.dispose();
    _telefoneController.dispose();
    _celularController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();

    // Endereço
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _complementoController.dispose();

    // Responsável
    _nomeResponsavelController.dispose();
    _telefoneResponsavelController.dispose();
    _emailResponsavelController.dispose();

    // Dados Acadêmicos/Profissionais
    _instituicaoController.dispose();
    _cursoController.dispose();
    _experienciasController.dispose();

    _pageController.dispose();
    super.dispose();
  }
}
