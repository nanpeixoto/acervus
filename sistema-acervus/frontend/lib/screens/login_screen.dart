import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/acervus_colors.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

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
          /// 🌈 Fundo institucional (gradiente índigo → roxo)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AcervusColors.gradientStart, AcervusColors.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// 🏛️ Marca acima do card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Image.asset(
                              'assets/images/logo_acervus.png',
                              height: 56,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'ACERVUS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sistema de Controle de Obras,\nLivros e Acervo Pessoal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          const SizedBox(height: 28),

                          /// Card de login
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.20),
                                  blurRadius: 32,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Bem-vindo de volta! 👋',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: AcervusColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Faça login para acessar sua conta',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AcervusColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  /// Mensagem de erro
                                  if (_errorMessage != null) _errorBox(),

                                  /// Login
                                  CustomTextField(
                                    controller: _loginController,
                                    label: 'Email ou login',
                                    prefixIcon:
                                        const Icon(Icons.person_outline),
                                    validator: (v) =>
                                        Validators.validateRequired(
                                            v, 'Login'),
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
                                      onPressed: () => setState(() =>
                                          _obscurePassword =
                                              !_obscurePassword),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  /// Esqueci senha
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _showForgotPasswordDialog(
                                              context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                      ),
                                      child: const Text(
                                        'Esqueci minha senha',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  /// Botão Entrar
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              'Entrar',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
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
                    fontWeight: FontWeight.w600,
                    color: AcervusColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail cadastrado',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (emailController.text.trim().isEmpty) return;
                      final auth = context.read<AuthProvider>();
                      await auth.requestReset(emailController.text.trim());
                      if (mounted) Navigator.pop(context);
                    },
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
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AcervusColors.danger, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style:
                  const TextStyle(color: AcervusColors.danger, fontSize: 13),
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
