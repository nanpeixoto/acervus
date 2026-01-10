// lib/widgets/admin_sidebar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sistema_estagio/utils/app_config.dart';
import '../providers/auth_provider.dart';
import '../models/usuario.dart';
import '../utils/app_utils.dart';

class AdminSidebar extends StatefulWidget {
  final String currentRoute;

  const AdminSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  bool _isCollapsed = false;
  String? _expandedSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _isCollapsed ? 60 : 250,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF82265C),
            Color.fromARGB(255, 163, 73, 126),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildMenu(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (!_isCollapsed) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'CIDE',
                style: TextStyle(
                  color: Color(0xFF8e44ad),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Spacer(),
          ],
          IconButton(
            onPressed: () {
              setState(() {
                _isCollapsed = !_isCollapsed;
                if (_isCollapsed) {
                  _expandedSection = null;
                }
              });
            },
            icon: Icon(
              _isCollapsed ? Icons.menu : Icons.menu_open,
              color: Colors.white,
              size: 20,
            ),
            tooltip: _isCollapsed ? 'Expandir menu' : 'Recolher menu',
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final tipoUsuario =
            authProvider.usuario?.tipo ?? TipoUsuario.COLABORADOR;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: _buildMenuByProfile(tipoUsuario),
          ),
        );
      },
    );
  }

  // ============================================
  // CONSTRUTOR DE MENU BASEADO NO PERFIL
  // ============================================

  List<Widget> _buildMenuByProfile(TipoUsuario tipoUsuario) {
    switch (tipoUsuario) {
      case TipoUsuario.EMPRESA:
        return _buildEmpresaMenu();

      case TipoUsuario.ESTAGIARIO:
        return _buildEstagiarioMenu();

      case TipoUsuario.INSTITUICAO:
        return _buildInstituicaoMenu();

      case TipoUsuario.JOVEM_APRENDIZ:
        return _buildJovemAprendizMenu();

      case TipoUsuario.ADMIN:
      case TipoUsuario.COLABORADOR:
      default:
        return _buildAdminMenu();
    }
  }

  // ============================================
  // MENU PARA EMPRESA/CONCEDENTE
  // ============================================

  List<Widget> _buildEmpresaMenu() {
    return [
      // Dashboard
      _buildMenuItem(
        icon: Icons.dashboard,
        title: 'Dashboard',
        route: '/empresa/dashboard',
        isActive: widget.currentRoute == '/empresa/dashboard',
      ),

      const SizedBox(height: 8),

      // Seção Meus Dados
      _buildMenuSection(
        title: 'Meus Dados',
        sectionKey: 'meus_dados',
        children: [
          _buildMenuItem(
            icon: Icons.business,
            title: 'Perfil da Empresa',
            route: '/empresa/perfil',
            isActive: widget.currentRoute == '/empresa/perfil',
          ),
          _buildMenuItem(
            icon: Icons.supervisor_account,
            title: 'Supervisores',
            route: '/empresa/supervisores',
            isActive: widget.currentRoute == '/empresa/supervisores',
          ),
          _buildMenuItem(
            icon: Icons.apartment,
            title: 'Setores/Órgãos',
            route: '/empresa/setores',
            isActive: widget.currentRoute == '/empresa/setores',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Vagas
      _buildMenuSection(
        title: 'Vagas',
        sectionKey: 'vagas',
        children: [
          _buildMenuItem(
            icon: Icons.work,
            title: 'Minhas Vagas',
            route: '/empresa/vagas',
            isActive: widget.currentRoute == '/empresa/vagas',
          ),
          _buildMenuItem(
            icon: Icons.add_circle,
            title: 'Criar Nova Vaga',
            route: '/empresa/vagas/nova',
            isActive: widget.currentRoute == '/empresa/vagas/nova',
          ),
          _buildMenuItem(
            icon: Icons.people,
            title: 'Candidatos',
            route: '/empresa/candidatos',
            isActive: widget.currentRoute == '/empresa/candidatos',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Estagiários/Aprendizes
      _buildMenuSection(
        title: 'Estagiários/Aprendizes',
        sectionKey: 'estagiarios',
        children: [
          _buildMenuItem(
            icon: Icons.school,
            title: 'Estagiários Ativos',
            route: '/empresa/estagiarios',
            isActive: widget.currentRoute == '/empresa/estagiarios',
          ),
          _buildMenuItem(
            icon: Icons.work_outline,
            title: 'Aprendizes Ativos',
            route: '/empresa/aprendizes',
            isActive: widget.currentRoute == '/empresa/aprendizes',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Contratos
      _buildMenuSection(
        title: 'Contratos',
        sectionKey: 'contratos',
        children: [
          _buildMenuItem(
            icon: Icons.description,
            title: 'Contratos Vigentes',
            route: '/empresa/contratos',
            isActive: widget.currentRoute == '/empresa/contratos',
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Histórico',
            route: '/empresa/contratos/historico',
            isActive: widget.currentRoute == '/empresa/contratos/historico',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Documentos
      _buildMenuSection(
        title: 'Documentos',
        sectionKey: 'documentos',
        children: [
          _buildMenuItem(
            icon: Icons.file_copy,
            title: 'Convênio',
            route: '/empresa/documentos/convenio',
            isActive: widget.currentRoute == '/empresa/documentos/convenio',
          ),
          _buildMenuItem(
            icon: Icons.description,
            title: 'Declarações',
            route: '/empresa/documentos/declaracoes',
            isActive: widget.currentRoute == '/empresa/documentos/declaracoes',
          ),
        ],
      ),
    ];
  }

  // ============================================
  // MENU PARA ESTAGIÁRIO
  // ============================================

  List<Widget> _buildEstagiarioMenu() {
    return [
      // Dashboard
      _buildMenuItem(
        icon: Icons.dashboard,
        title: 'Início',
        route: '/estagiario/dashboard',
        isActive: widget.currentRoute == '/estagiario/dashboard',
      ),

      const SizedBox(height: 8),

      // Seção Meu Perfil
      _buildMenuSection(
        title: 'Meu Perfil',
        sectionKey: 'perfil',
        children: [
          _buildMenuItem(
            icon: Icons.person,
            title: 'Dados Pessoais',
            route: '/estagiario/perfil',
            isActive: widget.currentRoute == '/estagiario/perfil',
          ),
          _buildMenuItem(
            icon: Icons.school,
            title: 'Formação Acadêmica',
            route: '/estagiario/formacao',
            isActive: widget.currentRoute == '/estagiario/formacao',
          ),
          _buildMenuItem(
            icon: Icons.work_history,
            title: 'Experiências',
            route: '/estagiario/experiencias',
            isActive: widget.currentRoute == '/estagiario/experiencias',
          ),
          _buildMenuItem(
            icon: Icons.folder,
            title: 'Documentos',
            route: '/estagiario/documentos',
            isActive: widget.currentRoute == '/estagiario/documentos',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Vagas
      _buildMenuSection(
        title: 'Vagas',
        sectionKey: 'vagas',
        children: [
          _buildMenuItem(
            icon: Icons.search,
            title: 'Buscar Vagas',
            route: '/estagiario/vagas',
            isActive: widget.currentRoute == '/estagiario/vagas',
          ),
          _buildMenuItem(
            icon: Icons.send,
            title: 'Minhas Candidaturas',
            route: '/estagiario/candidaturas',
            isActive: widget.currentRoute == '/estagiario/candidaturas',
          ),
          _buildMenuItem(
            icon: Icons.favorite,
            title: 'Vagas Salvas',
            route: '/estagiario/vagas/salvas',
            isActive: widget.currentRoute == '/estagiario/vagas/salvas',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Meus Contratos
      _buildMenuSection(
        title: 'Meus Contratos',
        sectionKey: 'contratos',
        children: [
          _buildMenuItem(
            icon: Icons.description,
            title: 'Contrato Atual',
            route: '/estagiario/contrato',
            isActive: widget.currentRoute == '/estagiario/contrato',
          ),
          _buildMenuItem(
            icon: Icons.access_time,
            title: 'Registro de Horas',
            route: '/estagiario/horas',
            isActive: widget.currentRoute == '/estagiario/horas',
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Histórico',
            route: '/estagiario/historico',
            isActive: widget.currentRoute == '/estagiario/historico',
          ),
        ],
      ),
    ];
  }

  // ============================================
  // MENU PARA INSTITUIÇÃO DE ENSINO
  // ============================================

  List<Widget> _buildInstituicaoMenu() {
    return [
      // Dashboard
      _buildMenuItem(
        icon: Icons.dashboard,
        title: 'Dashboard',
        route: '/instituicao/dashboard',
        isActive: widget.currentRoute == '/instituicao/dashboard',
      ),

      const SizedBox(height: 8),

      // Seção Meus Dados
      _buildMenuSection(
        title: 'Meus Dados',
        sectionKey: 'dados',
        children: [
          _buildMenuItem(
            icon: Icons.school,
            title: 'Perfil Institucional',
            route: '/instituicao/perfil',
            isActive: widget.currentRoute == '/instituicao/perfil',
          ),
          _buildMenuItem(
            icon: Icons.people,
            title: 'Representantes',
            route: '/instituicao/representantes',
            isActive: widget.currentRoute == '/instituicao/representantes',
          ),
          _buildMenuItem(
            icon: Icons.location_on,
            title: 'Campus',
            route: '/instituicao/campus',
            isActive: widget.currentRoute == '/instituicao/campus',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Estudantes
      _buildMenuSection(
        title: 'Estudantes',
        sectionKey: 'estudantes',
        children: [
          _buildMenuItem(
            icon: Icons.people,
            title: 'Alunos Cadastrados',
            route: '/instituicao/estudantes',
            isActive: widget.currentRoute == '/instituicao/estudantes',
          ),
          _buildMenuItem(
            icon: Icons.person_add,
            title: 'Validar Matrículas',
            route: '/instituicao/validar-matriculas',
            isActive: widget.currentRoute == '/instituicao/validar-matriculas',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Contratos
      _buildMenuSection(
        title: 'Contratos de Estágio',
        sectionKey: 'contratos',
        children: [
          _buildMenuItem(
            icon: Icons.assignment,
            title: 'Contratos Ativos',
            route: '/instituicao/contratos',
            isActive: widget.currentRoute == '/instituicao/contratos',
          ),
          _buildMenuItem(
            icon: Icons.pending_actions,
            title: 'Pendentes Assinatura',
            route: '/instituicao/contratos/pendentes',
            isActive: widget.currentRoute == '/instituicao/contratos/pendentes',
          ),
          _buildMenuItem(
            icon: Icons.history,
            title: 'Histórico',
            route: '/instituicao/contratos/historico',
            isActive: widget.currentRoute == '/instituicao/contratos/historico',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Documentos
      _buildMenuSection(
        title: 'Documentos',
        sectionKey: 'documentos',
        children: [
          _buildMenuItem(
            icon: Icons.description,
            title: 'Convênio',
            route: '/instituicao/convenio',
            isActive: widget.currentRoute == '/instituicao/convenio',
          ),
          _buildMenuItem(
            icon: Icons.file_download,
            title: 'Termos de Compromisso',
            route: '/instituicao/termos',
            isActive: widget.currentRoute == '/instituicao/termos',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Relatórios
      _buildMenuSection(
        title: 'Relatórios',
        sectionKey: 'relatorios',
        children: [
          _buildMenuItem(
            icon: Icons.bar_chart,
            title: 'Estatísticas',
            route: '/instituicao/relatorios',
            isActive: widget.currentRoute == '/instituicao/relatorios',
          ),
        ],
      ),
    ];
  }

  // ============================================
  // MENU PARA JOVEM APRENDIZ
  // ============================================

  List<Widget> _buildJovemAprendizMenu() {
    return [
      // Dashboard
      _buildMenuItem(
        icon: Icons.dashboard,
        title: 'Início',
        route: '/aprendiz/dashboard',
        isActive: widget.currentRoute == '/aprendiz/dashboard',
      ),

      const SizedBox(height: 8),

      // Seção Meu Perfil
      _buildMenuSection(
        title: 'Meu Perfil',
        sectionKey: 'perfil',
        children: [
          _buildMenuItem(
            icon: Icons.person,
            title: 'Dados Pessoais',
            route: '/aprendiz/perfil',
            isActive: widget.currentRoute == '/aprendiz/perfil',
          ),
          _buildMenuItem(
            icon: Icons.school,
            title: 'Formação',
            route: '/aprendiz/formacao',
            isActive: widget.currentRoute == '/aprendiz/formacao',
          ),
          _buildMenuItem(
            icon: Icons.folder,
            title: 'Documentos',
            route: '/aprendiz/documentos',
            isActive: widget.currentRoute == '/aprendiz/documentos',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Vagas
      _buildMenuSection(
        title: 'Vagas',
        sectionKey: 'vagas',
        children: [
          _buildMenuItem(
            icon: Icons.search,
            title: 'Buscar Vagas',
            route: '/aprendiz/vagas',
            isActive: widget.currentRoute == '/aprendiz/vagas',
          ),
          _buildMenuItem(
            icon: Icons.send,
            title: 'Minhas Candidaturas',
            route: '/aprendiz/candidaturas',
            isActive: widget.currentRoute == '/aprendiz/candidaturas',
          ),
          _buildMenuItem(
            icon: Icons.favorite,
            title: 'Vagas Salvas',
            route: '/aprendiz/vagas/salvas',
            isActive: widget.currentRoute == '/aprendiz/vagas/salvas',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Meu Contrato
      _buildMenuSection(
        title: 'Meu Contrato',
        sectionKey: 'contrato',
        children: [
          _buildMenuItem(
            icon: Icons.description,
            title: 'Contrato Atual',
            route: '/aprendiz/contrato',
            isActive: widget.currentRoute == '/aprendiz/contrato',
          ),
          _buildMenuItem(
            icon: Icons.access_time,
            title: 'Registro de Horas',
            route: '/aprendiz/horas',
            isActive: widget.currentRoute == '/aprendiz/horas',
          ),
          _buildMenuItem(
            icon: Icons.assessment,
            title: 'Avaliações',
            route: '/aprendiz/avaliacoes',
            isActive: widget.currentRoute == '/aprendiz/avaliacoes',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Curso
      _buildMenuSection(
        title: 'Curso de Aprendizagem',
        sectionKey: 'curso',
        children: [
          _buildMenuItem(
            icon: Icons.book,
            title: 'Meu Curso',
            route: '/aprendiz/curso',
            isActive: widget.currentRoute == '/aprendiz/curso',
          ),
          _buildMenuItem(
            icon: Icons.grade,
            title: 'Notas e Frequência',
            route: '/aprendiz/notas',
            isActive: widget.currentRoute == '/aprendiz/notas',
          ),
        ],
      ),
    ];
  }

  // ============================================
  // MENU PARA ADMIN/COLABORADOR (MENU COMPLETO EXISTENTE)
  // ============================================

  List<Widget> _buildAdminMenu() {
    return [
      // Dashboard
      _buildMenuItem(
        icon: Icons.dashboard,
        title: 'Dashboard',
        route: '/admin/dashboard',
        isActive: widget.currentRoute == '/admin/dashboard',
      ),

      const SizedBox(height: 8),

      // Seção Cadastros
      _buildMenuSection(
        title: 'Cadastros',
        sectionKey: 'cadastros',
        children: [
          _buildMenuItem(
            icon: Icons.people,
            title: 'Estudantes',
            route: '/admin/candidatos',
            isActive: widget.currentRoute == '/admin/candidatos',
          ),
          _buildMenuItem(
            icon: Icons.group,
            title: 'Jovem Aprendiz',
            route: '/admin/jovem-aprendiz',
            isActive: widget.currentRoute == '/admin/jovem-aprendiz',
          ),
          _buildMenuItem(
            icon: Icons.business,
            title: 'Empresas',
            route: '/admin/empresas',
            isActive: widget.currentRoute == '/admin/empresas',
          ),
          _buildMenuItem(
            icon: Icons.school,
            title: 'Instituições',
            route: '/admin/instituicoes',
            isActive: widget.currentRoute == '/admin/instituicoes',
          ),
          _buildMenuItem(
            icon: Icons.supervisor_account,
            title: 'Supervisores',
            route: '/admin/supervisores',
            isActive: widget.currentRoute == '/admin/supervisores',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Vagas
      _buildMenuSection(
        title: 'Vagas',
        sectionKey: 'vagas',
        children: [
          _buildMenuItem(
            icon: Icons.work,
            title: 'Estágio',
            route: '/admin/vagas-estagio',
            isActive: widget.currentRoute == '/admin/vagas-estagio',
          ),
          _buildMenuItem(
            icon: Icons.work_outline,
            title: 'Aprendizagem',
            route: '/admin/vagas-aprendizagem',
            isActive: widget.currentRoute == '/admin/vagas-aprendizagem',
          ),
          _buildMenuItem(
            icon: Icons.analytics,
            title: 'Processo Seletivo',
            route: '/admin/processo-seletivo',
            isActive: widget.currentRoute == '/admin/processo-seletivo',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Contratos
      _buildMenuSection(
        title: 'Contratos',
        sectionKey: 'contratos',
        children: [
          _buildMenuItem(
            icon: Icons.description,
            title: 'Estágio',
            route: '/admin/contratos-estagio',
            isActive: widget.currentRoute == '/admin/contratos-estagio',
          ),
          _buildMenuItem(
            icon: Icons.assignment,
            title: 'Aprendizagem',
            route: '/admin/contratos-aprendizagem',
            isActive: widget.currentRoute == '/admin/contratos-aprendizagem',
          ),
          _buildMenuItem(
            icon: Icons.add_circle_outline,
            title: 'Termos Aditivos',
            route: '/admin/termos-aditivos',
            isActive: widget.currentRoute == '/admin/termos-aditivos',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Financeiro
      _buildMenuSection(
        title: 'Financeiro',
        sectionKey: 'financeiro',
        children: [
          _buildMenuItem(
            icon: Icons.monetization_on,
            title: 'Faturamento',
            route: '/admin/faturamento',
            isActive: widget.currentRoute == '/admin/faturamento',
          ),
          _buildMenuItem(
            icon: Icons.receipt,
            title: 'Taxas CIDE',
            route: '/admin/taxas',
            isActive: widget.currentRoute == '/admin/taxas',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Cadastros Básicos
      _buildMenuSection(
        title: 'Cadastros Básicos',
        sectionKey: 'cadastros_basicos',
        children: [
          _buildMenuItem(
            icon: Icons.bar_chart,
            title: 'Status do Curso',
            route: '/admin/status-curso',
            isActive: widget.currentRoute == '/admin/status-curso',
          ),
          _buildMenuItem(
            icon: Icons.schedule,
            title: 'Turnos',
            route: '/admin/turnos',
            isActive: widget.currentRoute == '/admin/turnos',
          ),
          _buildMenuItem(
            icon: Icons.style,
            title: 'Modalidades de Ensino',
            route: '/admin/modalidades-ensino',
            isActive: widget.currentRoute == '/admin/modalidades-ensino',
          ),
          _buildMenuItem(
            icon: Icons.emoji_events,
            title: 'Níveis de Formação',
            route: '/admin/niveis-formacao',
            isActive: widget.currentRoute == '/admin/niveis-formacao',
          ),
          _buildMenuItem(
            icon: Icons.menu_book,
            title: 'Cursos',
            route: '/admin/cursos',
            isActive: widget.currentRoute == '/admin/cursos',
          ),
          _buildMenuItem(
            icon: Icons.signal_cellular_alt,
            title: 'Níveis de Conhecimento',
            route: '/admin/niveis-conhecimento',
            isActive: widget.currentRoute == '/admin/niveis-conhecimento',
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: 'Idiomas',
            route: '/admin/idiomas',
            isActive: widget.currentRoute == '/admin/idiomas',
          ),
          _buildMenuItem(
            icon: Icons.lightbulb,
            title: 'Conhecimentos',
            route: '/admin/conhecimentos',
            isActive: widget.currentRoute == '/admin/conhecimentos',
          ),
          _buildMenuItem(
            icon: Icons.account_balance,
            title: 'Bancos',
            route: '/admin/bancos',
            isActive: widget.currentRoute == '/admin/bancos',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Relatórios
      _buildMenuSection(
        title: 'Relatórios',
        sectionKey: 'relatorios',
        children: [
          _buildMenuItem(
            icon: Icons.bar_chart,
            title: 'Estatísticas',
            route: '/admin/estatisticas',
            isActive: widget.currentRoute == '/admin/estatisticas',
          ),
          _buildMenuItem(
            icon: Icons.file_download,
            title: 'Exportações',
            route: '/admin/exportacoes',
            isActive: widget.currentRoute == '/admin/exportacoes',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Admin
      _buildMenuSection(
        title: 'Admin',
        sectionKey: 'admin',
        children: [
          _buildMenuItem(
            icon: Icons.location_city,
            title: 'Cidades',
            route: '/admin/cidades',
            isActive: widget.currentRoute == '/admin/cidades',
          ),
          _buildMenuItem(
            icon: Icons.manage_accounts,
            title: 'Usuários',
            route: '/admin/usuarios',
            isActive: widget.currentRoute == '/admin/usuarios',
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Configurações',
            route: '/admin/configuracoes',
            isActive: widget.currentRoute == '/admin/configuracoes',
          ),
          _buildMenuItem(
            icon: Icons.backup,
            title: 'Backup/Restore',
            route: '/admin/backup',
            isActive: widget.currentRoute == '/admin/backup',
          ),
        ],
      ),

      const SizedBox(height: 8),

      // Seção Segurança
      _buildMenuSection(
        title: 'Segurança',
        sectionKey: 'seguranca',
        children: [
          _buildMenuItem(
            icon: Icons.security,
            title: 'Logs de Auditoria',
            route: '/admin/logs',
            isActive: widget.currentRoute == '/admin/logs',
          ),
          _buildMenuItem(
            icon: Icons.verified_user,
            title: 'Permissões',
            route: '/admin/permissoes',
            isActive: widget.currentRoute == '/admin/permissoes',
          ),
        ],
      ),
    ];
  }

  // ============================================
  // WIDGETS AUXILIARES (SEM ALTERAÇÕES)
  // ============================================

  Widget _buildMenuSection({
    required String title,
    required String sectionKey,
    required List<Widget> children,
  }) {
    if (_isCollapsed) {
      return Column(children: children);
    }

    final isExpanded = _expandedSection == sectionKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedSection = isExpanded ? null : sectionKey;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...children,
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isCollapsed ? 8 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isActive ? Colors.white.withOpacity(0.2) : null,
              borderRadius: BorderRadius.circular(8),
              border: isActive
                  ? const Border(
                      left: BorderSide(
                        color: Colors.white,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      isActive ? Colors.white : Colors.white.withOpacity(0.8),
                  size: 20,
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          final tipoUsuario = authProvider.usuario?.tipo;

          // Define o label do perfil baseado no tipo
          String perfilLabel = 'Usuário';
          switch (tipoUsuario) {
            case TipoUsuario.ADMIN:
              perfilLabel = 'Administrador';
              break;
            case TipoUsuario.COLABORADOR:
              perfilLabel = 'Colaborador';
              break;
            case TipoUsuario.EMPRESA:
              perfilLabel = 'Empresa';
              break;
            case TipoUsuario.ESTAGIARIO:
              perfilLabel = 'Estagiário';
              break;
            case TipoUsuario.INSTITUICAO:
              perfilLabel = 'Instituição';
              break;
            case TipoUsuario.JOVEM_APRENDIZ:
              perfilLabel = 'Jovem Aprendiz';
              break;
            default:
              perfilLabel = 'Usuário';
          }

          if (_isCollapsed) {
            return Center(
              child: PopupMenuButton<String>(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Text(
                    AppUtils.getInitials(user?.nome ?? 'U'),
                    style: const TextStyle(
                      color: Color(0xFF8e44ad),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'perfil':
                      _navigateToProfile(tipoUsuario);
                      break;
                    case 'logout':
                      _logout();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'perfil',
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 18),
                        const SizedBox(width: 8),
                        Text('Perfil ($perfilLabel)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Sair', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Text(
                      AppUtils.getInitials(user?.nome ?? 'U'),
                      style: const TextStyle(
                        color: Color(0xFF8e44ad),
                        fontSize: 12,
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
                          user?.nome ?? 'Usuário',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          perfilLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.white.withOpacity(0.8),
                      size: 18,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'perfil':
                          _navigateToProfile(tipoUsuario);
                          break;
                        case 'logout':
                          _logout();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'perfil',
                        child: Row(
                          children: [
                            Icon(Icons.person, size: 18),
                            SizedBox(width: 8),
                            Text('Meu Perfil'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Sair', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================
  // MÉTODOS AUXILIARES
  // ============================================

  /// Navega para o perfil correto baseado no tipo de usuário
  void _navigateToProfile(TipoUsuario? tipoUsuario) {
    String route = '/perfil'; // rota padrão

    switch (tipoUsuario) {
      case TipoUsuario.EMPRESA:
        route = '/empresa/perfil';
        break;
      case TipoUsuario.ESTAGIARIO:
        route = '/estagiario/perfil';
        break;
      case TipoUsuario.INSTITUICAO:
        route = '/instituicao/perfil';
        break;
      case TipoUsuario.JOVEM_APRENDIZ:
        route = '/aprendiz/perfil';
        break;
      case TipoUsuario.ADMIN:
      case TipoUsuario.COLABORADOR:
        route = '/perfil'; // ou '/admin/perfil' se preferir
        break;
      default:
        route = '/perfil';
    }

    context.go(route);
  }

  Future<void> _logout() async {
    final confirm = await AppUtils.showConfirmDialog(
      context,
      title: 'Sair do Sistema',
      content: 'Tem certeza que deseja sair?',
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
}
