import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sistema_estagio/providers/auth_provider.dart';
import 'package:sistema_estagio/routes/app_router.dart';

const Color _empresaPrimary = Color(0xFF82265C);
const Color _empresaAccent = Color.fromARGB(255, 163, 73, 126);

class EmpresaLayout extends StatefulWidget {
  final Widget body;
  final String currentRoute;

  const EmpresaLayout({
    super.key,
    required this.body,
    required this.currentRoute,
  });

  @override
  State<EmpresaLayout> createState() => _EmpresaLayoutState();
}

class _EmpresaLayoutState extends State<EmpresaLayout> {
  bool _isCollapsed = false;
  String? _nomeEmpresa;
  String? _emailEmpresa;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  void _carregarDados() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final usuario = auth.usuario;

    setState(() {
      _nomeEmpresa = usuario?.nome ?? 'Empresa';
      _emailEmpresa = usuario?.email ?? usuario?.login ?? '';
    });
  }

  void _handleNavigation(String route) {
    if (widget.currentRoute == route) return;
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3F9),
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24),
                      child: widget.body,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
                  route: '/empresa/dashboard',
                ),
                const Divider(color: Color(0xFFE0E0E0)),
                _buildMenuItem(
                  icon: Icons.badge_outlined,
                  title: 'Meus Dados',
                  route: '/empresa/perfil',
                ),
                const Divider(color: Color(0xFFE0E0E0)),
                _buildMenuItem(
                  icon: Icons.group_outlined,
                  title: 'Supervisores',
                  route: '/empresa/supervisores',
                ),
                _buildMenuItem(
                  icon: Icons.fact_check_outlined,
                  title: 'Ateste de Frequência',
                  route: '/empresa/ateste',
                ),
                _buildMenuItem(
                  icon: Icons.work_outline,
                  title: 'Solicitar Vagas',
                  route: '/empresa/vagas',
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
            color: _empresaPrimary,
            border: Border(
              bottom: BorderSide(color: _empresaAccent),
            ),
          ),
          child: isCompact
              ? Center(
                  child: IconButton(
                    onPressed: () =>
                        setState(() => _isCollapsed = !_isCollapsed),
                    icon: const Icon(Icons.menu, color: Colors.white, size: 20),
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
                      icon: const Icon(Icons.menu_open,
                          color: Colors.white, size: 20),
                      tooltip: 'Recolher menu',
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
  }) {
    final bool isActive = widget.currentRoute == route ||
        (route == '/empresa/perfil' &&
            widget.currentRoute.startsWith('/empresa/perfil'));

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
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive
                    ? _empresaPrimary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isActive ? _empresaPrimary : const Color(0xFF666666),
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
        color: isActive ? _empresaPrimary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? _empresaPrimary : const Color(0xFF666666),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? _empresaPrimary : const Color(0xFF666666),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () => _handleNavigation(route),
      ),
    );
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

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getPageTitle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _empresaPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            color: const Color(0xFF5B2C6F),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Mostrar menu',
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              switch (value) {
                case 'perfil':
                  context.go('/empresa/perfil');
                  break;
                case 'logout':
                  AppRouter.resetTokenVerification();
                  await context.read<AuthProvider>().logout();
                  if (!mounted) return;
                  context.go('/login');
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 12),
                    Text('Meus Dados'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
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
            child: const CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE9E0F2),
              child: Icon(Icons.person, color: Color(0xFF5B2C6F)),
            ),
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    if (widget.currentRoute.startsWith('/empresa/perfil')) {
      return 'Meus Dados';
    }
    switch (widget.currentRoute) {
      case '/empresa/supervisores':
        return 'Supervisores';
      case '/empresa/ateste':
        return 'Ateste de Frequência';
      case '/empresa/vagas':
        return 'Solicitação de Vagas';
      default:
        return 'Dashboard';
    }
  }
}
