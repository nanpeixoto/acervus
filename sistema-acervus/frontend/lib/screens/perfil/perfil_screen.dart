// lib/screens/perfil_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import 'dart:io';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';
import '../../services/_core/user_service.dart';
import '../../utils/validators.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  //final _telefoneController = TextEditingController();
  final _senhaAtualController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _editMode = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      _nomeController.text = user.nome ?? '';
      // _emailController.text = user.email;
      //_telefoneController.text = user.//telefone ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Meu Perfil',
        actions: [
          if (!_editMode)
            IconButton(
              onPressed: () => setState(() => _editMode = true),
              icon: const Icon(Icons.edit),
              tooltip: 'Editar perfil',
            ),
          if (_editMode) ...[
            TextButton(
              onPressed: _cancelEdit,
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Salvar',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading || _isSaving,
        child: Column(
          children: [
            // Header com foto e info básica
            _buildProfileHeader(),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2E7D32),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2E7D32),
              tabs: const [
                Tab(icon: Icon(Icons.person), text: 'Dados'),
                Tab(icon: Icon(Icons.lock), text: 'Segurança'),
                Tab(icon: Icon(Icons.settings), text: 'Configurações'),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDadosTab(),
                  _buildSegurancaTab(),
                  _buildConfiguracaoTab(themeProvider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF2E7D32),
                const Color(0xFF2E7D32).withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              // Foto do perfil
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : user?.avatarUrl != null
                            ? NetworkImage(user!.avatarUrl!)
                                as ImageProvider<Object>
                            : null,
                    child: _selectedImage == null && user?.avatarUrl == null
                        ? Text(
                            AppUtils.getInitials(user?.nome ?? 'U'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          )
                        : null,
                  ),
                  if (_editMode)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _pickImage,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Nome e email
              Text(
                user?.nome ?? 'Nome não informado',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'Email não informado',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),

              // Badge do tipo de usuário
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getUserTypeDisplay(user?.type as String?),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDadosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 24),

                // Nome
                CustomTextField(
                  controller: _nomeController,
                  label: 'Nome Completo',
                  readOnly: !_editMode,
                  validator: (value) =>
                      Validators.validateRequired(value, 'Nome'),
                  prefixIcon: const Icon(Icons.person),
                ),
                const SizedBox(height: 16),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'E-mail',
                  readOnly: _editMode,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  prefixIcon: const Icon(Icons.email),
                ),
                const SizedBox(height: 16),

                /*// //telefone
                CustomTextField(
                  controller: _//telefoneController,
                  label: '//telefone',
                  readOnly: !_editMode,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  prefixIcon: const Icon(Icons.phone),
                ),*/
                const SizedBox(height: 24),

                // Informações de auditoria
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final user = authProvider.user;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                'Informações da Conta',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegurancaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Alterar senha
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alterar Senha',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _senhaAtualController,
                    label: 'Senha Atual',
                    obscureText: true,
                    validator: (value) =>
                        Validators.validateRequired(value, 'Senha atual'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _novaSenhaController,
                    label: 'Nova Senha',
                    obscureText: true,
                    validator: Validators.validatePassword,
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmarSenhaController,
                    label: 'Confirmar Nova Senha',
                    obscureText: true,
                    validator: (value) {
                      if (value != _novaSenhaController.text) {
                        return 'Senhas não conferem';
                      }
                      return null;
                    },
                    prefixIcon: const Icon(Icons.lock_reset),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Alterar Senha'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Configurações de segurança
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configurações de Segurança',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading:
                        const Icon(Icons.fingerprint, color: Color(0xFF2E7D32)),
                    title: const Text('Autenticação Biométrica'),
                    subtitle:
                        const Text('Use sua digital ou face para acessar'),
                    trailing: Switch(
                      value: false, // TODO: Implementar
                      onChanged: (value) {
                        // TODO: Implementar toggle biometria
                      },
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notifications,
                        color: Color(0xFF2E7D32)),
                    title: const Text('Notificações de Login'),
                    subtitle: const Text('Receba alertas de novos acessos'),
                    trailing: Switch(
                      value: true, // TODO: Implementar
                      onChanged: (value) {
                        // TODO: Implementar toggle notificações
                      },
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.devices, color: Color(0xFF2E7D32)),
                    title: const Text('Sessões Ativas'),
                    subtitle:
                        const Text('Gerencie seus dispositivos conectados'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navegar para tela de sessões
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracaoTab(ThemeProvider themeProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Aparência
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aparência',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: const Color(0xFF2E7D32),
                    ),
                    title: const Text('Tema Escuro'),
                    subtitle:
                        const Text('Ative o modo escuro para reduzir o brilho'),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) => themeProvider.toggleTheme(),
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.contrast, color: Color(0xFF2E7D32)),
                    title: const Text('Alto Contraste'),
                    subtitle: const Text('Melhore a visibilidade das cores'),
                    trailing: Switch(
                      value: themeProvider.isHighContrast,
                      onChanged: (value) =>
                          themeProvider.setHighContrast(value),
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.format_size, color: Color(0xFF2E7D32)),
                    title: const Text('Tamanho da Fonte'),
                    subtitle: Slider(
                      value: themeProvider.fontSize,
                      min: 0.8,
                      max: 1.5,
                      divisions: 7,
                      label: '${(themeProvider.fontSize * 100).round()}%',
                      onChanged: (value) => themeProvider.setFontSize(value),
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notificações
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notificações',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.email, color: Color(0xFF2E7D32)),
                    title: const Text('Notificações por Email'),
                    subtitle: const Text('Receba atualizações por email'),
                    trailing: Switch(
                      value: true, // TODO: Implementar
                      onChanged: (value) {
                        // TODO: Implementar toggle email
                      },
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.push_pin, color: Color(0xFF2E7D32)),
                    title: const Text('Notificações Push'),
                    subtitle: const Text('Receba alertas no dispositivo'),
                    trailing: Switch(
                      value: true, // TODO: Implementar
                      onChanged: (value) {
                        // TODO: Implementar toggle push
                      },
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ações da conta
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Conta',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading:
                        const Icon(Icons.download, color: Color(0xFF2E7D32)),
                    title: const Text('Exportar Dados'),
                    subtitle: const Text('Baixe uma cópia dos seus dados'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _exportData,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help, color: Color(0xFF2E7D32)),
                    title: const Text('Ajuda e Suporte'),
                    subtitle: const Text('Central de ajuda e contato'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showHelp,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Sair da Conta',
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: const Text('Encerrar sessão atual'),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  String _getUserTypeDisplay(String? type) {
    switch (type) {
      case 'admin':
        return 'Administrador';
      case 'empresa':
        return 'Empresa';
      case 'estagiario':
        return 'Estagiário';
      case 'jovem_aprendiz':
        return 'Jovem Aprendiz';
      case 'instituicao':
        return 'Instituição';
      default:
        return 'Usuário';
    }
  }

  // Ações
  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Foto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Câmera'),
              onTap: () => context.pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => context.pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    }
  }

  void _cancelEdit() {
    setState(() {
      _editMode = false;
      _selectedImage = null;
    });
    _loadUserData();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      AppUtils.showErrorSnackBar(
          context, 'Por favor, corrija os campos em vermelho');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final updateData = {
        'nome': _nomeController.text,
        'email': _emailController.text,
        //'telefone': _//telefoneController.text,
      };

      final success = await UserService.updateProfile(
        updateData as String,
        _selectedImage as Map<String, dynamic>, // ou null se não tiver imagem
      );

      setState(() => _isSaving = false);

      if (success) {
        setState(() => _editMode = false);
        AppUtils.showSuccessSnackBar(context, 'Perfil atualizado com sucesso!');
        await authProvider.reloadUser();
      } else {
        AppUtils.showErrorSnackBar(context, 'Erro ao atualizar perfil');
      }
    } catch (e) {
      setState(() => _isSaving = false);
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  Future<void> _changePassword() async {
    if (_senhaAtualController.text.isEmpty ||
        _novaSenhaController.text.isEmpty ||
        _confirmarSenhaController.text.isEmpty) {
      AppUtils.showErrorSnackBar(context, 'Preencha todos os campos de senha');
      return;
    }

    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      AppUtils.showErrorSnackBar(context, 'Senhas não conferem');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await UserService.redefinirSenha(
        _novaSenhaController.text,
      );

      setState(() => _isLoading = false);

      if (success) {
        _senhaAtualController.clear();
        _novaSenhaController.clear();
        _confirmarSenhaController.clear();
        AppUtils.showSuccessSnackBar(context, 'Senha alterada com sucesso!');
      } else {
        AppUtils.showErrorSnackBar(context, 'Erro ao alterar senha');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      AppUtils.showErrorSnackBar(context, 'Erro: $e');
    }
  }

  void _exportData() {
    // TODO: Implementar exportação de dados
    AppUtils.showSuccessSnackBar(
        context, 'Exportação iniciada. Você receberá um email.');
  }

  void _showHelp() {
    context.go('/help');
  }

  Future<void> _logout() async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Sair da Conta',
      content: 'Tem certeza que deseja sair da sua conta?',
      confirmText: 'Sair',
    );

    if (confirm) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomeController.dispose();
    _emailController.dispose();
    //_telefoneController.dispose();
    _senhaAtualController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }
}
