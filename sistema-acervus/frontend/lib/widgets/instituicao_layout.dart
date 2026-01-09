// lib/widgets/instituicao_layout.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sistema_estagio/providers/auth_provider.dart';
import 'package:sistema_estagio/routes/app_router.dart';

const Color _instituicaoPrimary = Color(0xFF82265C);
const Color _instituicaoAccent = Color.fromARGB(255, 163, 73, 126);

class InstituicaoLayout extends StatefulWidget {
  final Widget body;
  final String currentRoute;

  const InstituicaoLayout({
    super.key,
    required this.body,
    required this.currentRoute,
  });

  @override
  State<InstituicaoLayout> createState() => _InstituicaoLayoutState();
}

class _InstituicaoLayoutState extends State<InstituicaoLayout> {
  bool _isCollapsed = false;
  String? _nomeInstituicao;
  String? _emailInstituicao;

  @override
  void initState() {
    super.initState();
    _loadInstituicaoInfo();
  }

  Future<void> _loadInstituicaoInfo() async {
    // TODO: Buscar informações da instituição logada
    // final authProvider = context.read<AuthProvider>();
    // final user = authProvider.user;

    setState(() {
      _nomeInstituicao = 'Instituição de Ensino'; // Mock
      _emailInstituicao = 'contato@instituicao.edu.br'; // Mock
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Menu lateral
          _buildSidebar(),

          // Conteúdo principal
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: widget.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      width: _isCollapsed ? 72 : 260,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/instituicao/dashboard',
                ),
                const Divider(color: Color(0xFFE0E0E0)),
                _buildMenuItem(
                  icon: Icons.business,
                  title: 'Meus Dados',
                  route: '/instituicao/perfil',
                ),
              ],
            ),
          ),
          _buildSidebarFooter(collapsed: _isCollapsed),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth <= 120;

        return Container(
          height: 70,
          decoration: const BoxDecoration(
            color: _instituicaoPrimary,
            border: Border(
              bottom: BorderSide(color: _instituicaoAccent),
            ),
          ),
          child: isCompact
              ? Center(
                  child: IconButton(
                    onPressed: () =>
                        setState(() => _isCollapsed = !_isCollapsed),
                    icon: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: _isCollapsed ? 'Expandir menu' : 'Recolher menu',
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Text(
                        'CIDE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          setState(() => _isCollapsed = !_isCollapsed),
                      icon: const Icon(
                        Icons.menu_open,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Recolher menu',
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            route: '/instituicao/dashboard',
          ),
          const Divider(color: Color(0xFFE0E0E0)),
          _buildMenuItem(
            icon: Icons.business,
            title: 'Meus Dados',
            route: '/instituicao/perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
  }) {
    final bool isActive = route == '/instituicao/perfil'
        ? widget.currentRoute.startsWith('/instituicao/perfil/editar')
        : widget.currentRoute == route;

    if (_isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Tooltip(
          message: title,
          waitDuration: const Duration(milliseconds: 400),
          child: InkWell(
            onTap: () => _handleNavigation(route),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 44,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isActive
                    ? _instituicaoPrimary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: isActive ? _instituicaoPrimary : const Color(0xFF666666),
                size: 22,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? _instituicaoPrimary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? _instituicaoPrimary : const Color(0xFF666666),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? _instituicaoPrimary : const Color(0xFF666666),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () => _handleNavigation(route),
      )      
    );
  }

  Widget _buildUserInfo() {
    if (_isCollapsed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
        child: const Icon(
          Icons.school,
          color: Color(0xFF2E7D32),
          size: 32,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _instituicaoPrimary,
                radius: 20,
                child: Text(
                  (_nomeInstituicao ?? 'I').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nomeInstituicao ?? 'Carregando...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _emailInstituicao ?? '',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _instituicaoPrimary.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _getPageTitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _instituicaoPrimary,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // TODO: Implementar notificações
                },
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notificações',
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle, size: 32),
                onSelected: (value) async {
                  if (value == 'perfil') {
                    _handleNavigation('/instituicao/perfil');
                  } else if (value == 'logout') {
                    final authProvider = context.read<AuthProvider>();
                    AppRouter.resetTokenVerification();
                    await authProvider.logout();
                    if (mounted) {
                      context.go('/');
                    }
                  }
                },
                itemBuilder: (context) => [                  
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Sair', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    switch (widget.currentRoute) {
      case '/instituicao/dashboard':
        return 'Dashboard';
      case '/instituicao/vagas':
        return 'Vagas';
      default:
        // Para rotas dinâmicas como /instituicao/perfil/editar/:id
        if (widget.currentRoute.startsWith('/instituicao/perfil/editar')) {
          return 'Meus Dados';
        }
        return 'CIDE - Instituição';
    }
  }

  void _handleNavigation(String route) {
    if (route == '/instituicao/perfil') {
      // Não use SnackBar aqui para evitar acessar context após navegação
      final auth = context.read<AuthProvider>();

      // Primeiro tenta direto do model
      String? instituicaoId = auth.usuario?.cdInstituicaoEnsino?.toString();

      // Fallbacks seguros
      instituicaoId ??= _resolveInstituicaoIdSafe(auth);

      if (instituicaoId != null && instituicaoId.isNotEmpty) {
        // Agenda a navegação para o próximo frame (evita usar context em transição)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.go('/instituicao/perfil/editar/$instituicaoId');
          // Se você preferir usar nome da rota:
          // context.goNamed('instituicao_perfil_editar', pathParameters: {'id': instituicaoId});
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID da instituição não encontrado.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Outras rotas
    context.go(route);
  }

  // Fallbacks sem acessar propriedades dinâmicas inexistentes
  String? _resolveInstituicaoIdSafe(AuthProvider auth) {
    final u = auth.usuario;
    if (u == null) return null;

    // 1) Campo do model
    final fromModel = u.cdInstituicaoEnsino?.toString();
    if (fromModel != null && fromModel.isNotEmpty) return fromModel;

    // 2) Tenta via toJson do model
    try {
      final json = u.toJson();
      final v = json['cd_instituicao_ensino'] ??
          json['instituicao_id'] ??
          json['id'];
      if (v != null && v.toString().isNotEmpty) return v.toString();
    } catch (_) {}

    // 3) Sem acesso ao cache interno aqui; se precisar, exponha um getter no AuthProvider
    return null;
  }

  Widget _buildSidebarFooter({required bool collapsed}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xFFEDEDED), width: 1),
        ),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user ?? authProvider.usuario;

          if (collapsed) {
            return Center(
              child: PopupMenuButton<String>(
                tooltip: 'Conta',
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFC32E6D),
                  child: Text(
                    _getInitials(user?.nome ?? 'A'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                onSelected: (value) {
                  if (value == 'perfil') context.go('/perfil');
                  if (value == 'logout') _logout();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'perfil', child: Text('Perfil')),
                  PopupMenuItem(value: 'logout', child: Text('Sair')),
                ],
              ),
            );
          }

          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFC32E6D),
                child: Text(
                  _getInitials(user?.nome ?? 'A'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.nome ?? 'Administrador',
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.perfil ?? 'Admin',
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Opções',
                icon: const Icon(Icons.more_vert,
                    color: Color(0xFF555555), size: 18),
                onSelected: (value) {                  
                  if (value == 'logout') _logout();
                },
                itemBuilder: (context) => const [                  
                  PopupMenuItem(value: 'logout', child: Text('Sair')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _getInitials(String name) {
    final words = name.trim().split(' ');
    if (words.isEmpty) return 'A';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) context.go('/login');
  }
}
