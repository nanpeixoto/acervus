import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_overlay.dart';

/// 🎨 Paleta ACERVUS (baseada no logo)
const Color _primaryColor = Color(0xFF1F3A5F); // Azul institucional
const Color _primaryAccent = Color(0xFF2E6DA4); // Azul secundário
const Color _highlightColor = Color(0xFFF28C28); // Laranja marcador

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      body: Stack(
        children: [
          /// 🌈 Fundo institucional
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryAccent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// Círculos decorativos
          Positioned(
            top: -120,
            right: -120,
            child: _decorativeCircle(320, 0.08),
          ),
          Positioned(
            bottom: -180,
            left: -180,
            child: _decorativeCircle(420, 0.05),
          ),

          LoadingOverlay(
            isLoading: _isLoading,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 460),
                      padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            /// 🏛️ Logo Acervus
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _primaryAccent.withOpacity(0.08),
                              ),
                              child: Image.asset(
                                'assets/images/logo_acervus.png',
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 24),

                            /// Título
                            const Text(
                              'Acessar o Acervus',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),

                            /// Subtítulo
                            Text(
                              'Sistema de Controle de Obras, Livros e Acervo Pessoal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),

                            /// Mensagem de erro
                            if (_errorMessage != null) _errorBox(),

                            /// Login
                            CustomTextField(
                              controller: _loginController,
                              label: 'Login',
                              prefixIcon: const Icon(Icons.person_outline),
                              validator: (v) =>
                                  Validators.validateRequired(v, 'Login'),
                              onChanged: (_) =>
                                  setState(() => _errorMessage = null),
                            ),
                            const SizedBox(height: 16),

                            /// Senha
                            CustomTextField(
                              controller: _senhaController,
                              label: 'Senha',
                              obscureText: _obscurePassword,
                              validator: Validators.validatePassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            const SizedBox(height: 24),

                            /// Botão Entrar
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: _highlightColor,
                                        ),
                                      )
                                    : const Text(
                                        'Entrar',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            /// Esqueci senha
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _showForgotPasswordDialog(context),
                              child: const Text(
                                'Esqueci minha senha',
                                style: TextStyle(
                                  color: _primaryAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔐 LOGIN
  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Preencha os campos corretamente';
      });
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      final ok = await auth.login(
        _loginController.text.trim(),
        _senhaController.text,
      );

      if (!ok && mounted) {
        setState(() {
          _errorMessage = auth.lastError ?? 'Login ou senha inválidos';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao autenticar. Tente novamente.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 📩 Reset de senha
  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Redefinir senha',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'E-mail cadastrado',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.trim().isEmpty) return;
                      final auth = context.read<AuthProvider>();
                      await auth.requestReset(emailController.text.trim());
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                    ),
                    child: const Text('Enviar código'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _errorBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decorativeCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loginController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
}
