import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  Color get activeColor => const Color(0xFFC32E6D); // Magenta institucional
  Color get inactiveColor => const Color(0xFF555555); // Cinza escuro
  Color get dividerColor => const Color(0xFFEDEDED); // Cinza claro
  LinearGradient get sidebarGradient => const LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F3F6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  Widget buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
  }) {
    bool isActive = ModalRoute.of(context)?.settings.name == route;
    return Material(
      color: isActive ? const Color(0xFFFAD6E8) : Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? activeColor : inactiveColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? activeColor : inactiveColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => Navigator.pushReplacementNamed(context, route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(gradient: sidebarGradient),
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFAD6E8), Color(0xFFFFFFFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings, size: 48, color: Color(0xFFC32E6D)),
                  SizedBox(height: 8),
                  Text(
                    'Painel Administrativo',
                    style: TextStyle(
                      color: Color(0xFFC32E6D),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            buildMenuItem(context: context, icon: Icons.dashboard, title: 'Dashboard', route: '/admin/dashboard'),
            const Divider(color: Color(0xFFEDEDED)),

            buildMenuItem(context: context, icon: Icons.person, title: 'Candidatos', route: '/admin/candidatos'),
            buildMenuItem(context: context, icon: Icons.work, title: 'Jovens Aprendizes', route: '/admin/jovens-aprendizes'),
            buildMenuItem(context: context, icon: Icons.business, title: 'Empresas', route: '/admin/empresas'),
            buildMenuItem(context: context, icon: Icons.school, title: 'Instituições', route: '/admin/instituicoes'),

            const Divider(color: Color(0xFFEDEDED)),

            buildMenuItem(context: context, icon: Icons.description, title: 'Modelos', route: '/admin/modelos'),
            buildMenuItem(context: context, icon: Icons.work_outline, title: 'Vagas', route: '/admin/vagas'),
            buildMenuItem(context: context, icon: Icons.people, title: 'Supervisores', route: '/admin/supervisores'),

            const Divider(color: Color(0xFFEDEDED)),

            buildMenuItem(context: context, icon: Icons.bar_chart, title: 'Relatórios', route: '/admin/relatorios'),
            buildMenuItem(context: context, icon: Icons.settings, title: 'Configurações', route: '/admin/configuracoes'),

            const Spacer(),
            const Divider(color: Color(0xFFEDEDED)),

            buildMenuItem(context: context, icon: Icons.logout, title: 'Sair', route: '/logout'),
          ],
        ),
      ),
    );
  }
}
