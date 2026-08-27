import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../theme/acervus_colors.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const AdminLayout({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  bool _isCollapsed = false;
  bool _hoverExpand = false;

  final double _sidebarExpandedW = 260.0;
  final double _sidebarCollapsedW = 64.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 🎨 Paleta Acervus (design system)
  static const Color primary = AcervusColors.primary;
  static const Color primarySoft = AcervusColors.primarySoft;
  static const Color textPrimary = AcervusColors.textPrimary;
  static const Color textSecondary = AcervusColors.textSecondary;
  static const Color divider = AcervusColors.border;
  static const Color background = AcervusColors.background;

  @override
  void initState() {
    super.initState();
    _loadCollapsePref();
  }

  Future<void> _loadCollapsePref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isCollapsed = prefs.getBool('sidebarCollapsed') ?? false);
  }

  Future<void> _toggleCollapse() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isCollapsed = !_isCollapsed);
    await prefs.setBool('sidebarCollapsed', _isCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    if (isMobile) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          width: 280,
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: divider)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'ACERVUS',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildMenu(false)),
                _buildFooter(false),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          backgroundColor: primary,
          tooltip: 'Menu',
          child: const Icon(Icons.menu, color: Colors.white),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: Container(color: background, child: widget.child),
      );
    }

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
            const ActivateIntent(),
      },
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction(onInvoke: (_) {
            _toggleCollapse();
            return null;
          }),
        },
        child: Scaffold(
          body: Row(
            children: [
              _buildSidebar(),
              Expanded(
                child: Container(
                  color: background,
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    final isNarrow = MediaQuery.of(context).size.width < 1000;
    final collapsed = isNarrow ? true : _isCollapsed;

    final width = (_hoverExpand && _isCollapsed && !isNarrow)
        ? _sidebarExpandedW
        : (collapsed ? _sidebarCollapsedW : _sidebarExpandedW);

    return MouseRegion(
      onEnter: (_) {
        if (_isCollapsed && !isNarrow) setState(() => _hoverExpand = true);
      },
      onExit: (_) {
        if (_isCollapsed && !isNarrow) setState(() => _hoverExpand = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(collapsed),
            Expanded(child: _buildMenu(collapsed)),
            _buildFooter(collapsed),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool collapsed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: divider)),
      ),
      child: Row(
        children: [
          if (!collapsed) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                color: primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'ACERVUS',
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 17,
              ),
            ),
            const Spacer(),
          ],
          IconButton(
            onPressed: _toggleCollapse,
            icon: Icon(
              collapsed ? Icons.menu : Icons.menu_open,
              color: textSecondary,
            ),
            tooltip: 'Expandir / Colapsar',
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(bool collapsed) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _menuItem(Icons.space_dashboard_rounded, 'Dashboard',
              '/admin/dashboard', collapsed),
          _section('OBRAS', collapsed),
          _menuItem(
              Icons.menu_book_rounded, 'Livros', '/admin/obras', collapsed),
          _section('CADASTROS', collapsed),
          _menuItem(
            Icons.person_outline_rounded,
            'Autores',
            '/admin/autores',
            collapsed,
          ),
          _menuItem(Icons.label_outline_rounded, 'Assuntos', '/admin/assuntos',
              collapsed),
          _menuItem(Icons.business_outlined, 'Editoras', '/admin/editoras',
              collapsed),
          _menuItem(Icons.health_and_safety_outlined, 'Estado de Conservação',
              '/admin/estado-conservacao', collapsed),
          _menuItem(
              Icons.translate_rounded, 'Idiomas', '/admin/idiomas', collapsed),
          _menuItem(Icons.category_outlined, 'Material', '/admin/materiais',
              collapsed),
          //_menuItem(Icons.people_outline_rounded, 'Pessoas', '/admin/pessoas',         collapsed),
          _menuItem(Icons.layers_outlined, 'Subtipo de Obra',
              '/admin/subtipos-obra', collapsed),
          _menuItem(Icons.collections_bookmark_outlined, 'Tipo de Obra',
              '/admin/tipos-obra', collapsed),
          //_menuItem(Icons.badge_outlined, 'Tipo de Prestador',         '/admin/tipos-prestador', collapsed),
          _section('LOCALIZAÇÃO', collapsed),
          _menuItem(
              Icons.meeting_room_outlined, 'Sala', '/admin/salas', collapsed),
          _menuItem(Icons.view_column_outlined, 'Estante', '/admin/estantes',
              collapsed),
          _section('RELATÓRIOS', collapsed),
          _menuItem(Icons.view_column_outlined, 'Resumo de Obras',
              '/relatorios/lista/resumida', collapsed),
          // _menuItem(Icons.view_agenda_outlined, 'Prateleira',              '/admin/prateleiras', collapsed),
          // _section('CONFIGURAÇÕES', collapsed),          _menuItem(Icons.manage_accounts_outlined, 'Usuários',              '/admin/usuarios', collapsed),
          //  _section('RELATÓRIOS', collapsed),          _menuItem(Icons.bar_chart_rounded, 'Relatórios', '/admin/relatorios',              collapsed),
        ],
      ),
    );
  }

  Widget _section(String title, bool collapsed) {
    if (collapsed) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String route, bool collapsed) {
    final isActive = widget.currentRoute == route;

    final content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 14, vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? primarySoft : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isActive ? primary : textSecondary),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? primary : textPrimary,
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return collapsed ? Tooltip(message: title, child: content) : content;
  }

  Widget _buildFooter(bool collapsed) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: divider)),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.usuario;
          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: primarySoft,
                child: Text(
                  user?.nome?.substring(0, 1).toUpperCase() ?? 'A',
                  style: const TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.nome ?? 'Administrador',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const Text(
                        'Administrador',
                        style: TextStyle(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 20, color: textSecondary),
                  tooltip: 'Sair',
                  onPressed: _logout,
                )
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) context.go('/login');
  }
}
