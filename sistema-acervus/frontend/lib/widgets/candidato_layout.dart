import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sistema_estagio/providers/auth_provider.dart';
import 'package:sistema_estagio/routes/app_router.dart';

const Color _candPrimary = Color(0xFF82265C);
const Color _candAccent = Color.fromARGB(255, 163, 73, 126);

class CandidatoLayout extends StatefulWidget {
  final Widget body;
  final String currentRoute;

  const CandidatoLayout({
    super.key,
    required this.body,
    required this.currentRoute,
  });

  @override
  State<CandidatoLayout> createState() => _CandidatoLayoutState();
}

class _CandidatoLayoutState extends State<CandidatoLayout> {
  bool _isCollapsed = false;
  bool _isJovemAprendiz = false;
  String? _nomeCandidato;
  String? _emailCandidato;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDados());
  }

  void _carregarDados() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dynamic user = auth.usuario;

    String? nome;
    String? email;

    if (user != null) {
      try {
        nome = user.nome as String?;
      } catch (_) {}
      try {
        email = user.email as String?;
      } catch (_) {}
      try {
        email ??= user.login as String?;
      } catch (_) {}
    }

    setState(() {
      _nomeCandidato = nome ?? 'Candidato';
      _emailCandidato = email ?? '';
      _isJovemAprendiz = isJovemAprendizFromUser(user);
    });
  }

  void _handleNavigation(String route) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final id = auth.candidatoId?.toString();
    final regime = auth.regimeId?.toString();

    print('🔍 [NAVEGACAO_CANDIDATO] Tentando navegar para: $route');
    print('   - candidatoId do auth: ${auth.candidatoId}');
    print('   - regimeId do auth: ${auth.regimeId}');
    print('   - usuario completo: ${auth.usuario}');
    print('   - ID extraído: $id');
    print('   - Regime extraído: $regime');

    if (route == '/candidato/perfil') {
      if (id != null && regime != null) {
        final targetRoute = '/candidato/perfil/editar/$id/$regime';
        print('   - Navegando para: $targetRoute');
        context.go(targetRoute);
      } else {
        print('   - ❌ ERRO: ID ou regime não encontrados');
        print('   - Tentando extrair do usuario diretamente...');

        // Tentar extrair do usuario diretamente de forma mais segura
        final usuario = auth.usuario;
        String? extractedId;
        String? extractedRegime;

        try {
          extractedId = candidatoIdFromUser(usuario);
        } catch (e) {
          print('   - Erro ao extrair ID: $e');
        }

        try {
          extractedRegime = regimeIdFromUser(usuario);
        } catch (e) {
          print('   - Erro ao extrair regime: $e');
        }

        print('   - ID extraído do usuario: $extractedId');
        print('   - Regime extraído do usuario: $extractedRegime');

        if (extractedId != null && extractedRegime != null) {
          final targetRoute =
              '/candidato/perfil/editar/$extractedId/$extractedRegime';
          print('   - ✅ Navegando com dados extraídos: $targetRoute');
          context.go(targetRoute);
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidato ou regime não encontrados.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Tratar rota de candidaturas de forma mais segura
    if (route == '/candidato/candidaturas') {
      final usuario = auth.usuario;
      String? extractedId;

      try {
        extractedId = candidatoIdFromUser(usuario);
      } catch (e) {
        print('   - Erro ao extrair ID para candidaturas: $e');
      }

      if (extractedId != null) {
        final targetRoute = '/candidato/candidaturas/$extractedId';
        print('   - ✅ Navegando para candidaturas: $targetRoute');
        context.go(targetRoute);
      } else {
        print('   - ❌ ERRO: ID do candidato não encontrado para candidaturas');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID do candidato não encontrado.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

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
                    route: _isJovemAprendiz
                        ? '/aprendiz/dashboard'
                        : '/estagiario/dashboard',
                  ),
                  const Divider(color: Color(0xFFE0E0E0)),
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Meus Dados',
                    route: '/candidato/perfil',
                  ),
                  const Divider(color: Color(0xFFE0E0E0)),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Minhas Candidaturas',
                    route: '/candidato/candidaturas',
                  ),
                  /*
                  const Divider(color: Color(0xFFE0E0E0)),
                  _buildMenuItem(
                    icon: Icons.work_outline,
                    title: 'Vagas Salvas',
                    route: '/candidato/vagas/{cdCandidato}',
                  ),*/
                ]),
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
            color: _candPrimary,
            border: Border(
              bottom: BorderSide(color: _candAccent),
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
    // Considera subrotas como ativas (ex.: /candidato/perfil/editar/315/1)
    final bool isActive =
        widget.currentRoute == route || widget.currentRoute.startsWith(route);

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
                    ? _candPrimary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isActive ? _candPrimary : const Color(0xFF666666),
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
          color: isActive ? _candPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isActive ? _candPrimary : const Color(0xFF666666),
            size: 22,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? _candPrimary : const Color(0xFF666666),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () => _handleNavigation(route),
        ));
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
                      _isJovemAprendiz ? 'APRENDIZ' : 'ESTUDANTE',
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
              _pageTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5B2C6F),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implementar notificações
            },
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notificações',
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Mostrar menu',
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) async {
              if (value == 'perfil') {
                _handleNavigation('/candidato/perfil');
              } else if (value == 'logout') {
                final authProvider = context.read<AuthProvider>();
                AppRouter.resetTokenVerification();
                await authProvider.logout();
                if (mounted) {
                  context.go('/');
                }
              }
            },
            itemBuilder: (context) => const [
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
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFE9E0F2),
              child: Text(
                (_nomeCandidato?.isNotEmpty ?? false)
                    ? _nomeCandidato![0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: Color(0xFF5B2C6F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _pageTitle() {
    // Garante título correto mesmo em subrotas
    if (widget.currentRoute.startsWith('/candidato/perfil')) {
      return 'Meus Dados';
    }
    if (widget.currentRoute.startsWith('/candidato/candidaturas')) {
      return 'Minhas Candidaturas';
    }
    switch (widget.currentRoute) {
      case '/candidato/contrato':
        return 'Contrato Ativo';
      case '/candidato/servico-social':
        return 'Serviço Social';
      case '/candidato/vagas':
        return 'Vagas Disponíveis';      
      default:
        return 'Dashboard';
    }
  }
}

bool isJovemAprendizFromUser(dynamic user) {
  if (user == null) return false;

  // 1) Perfil explícito no model
  try {
    final perfil = (user.perfil ?? '').toString().toUpperCase();
    if (perfil == 'JOVEM_APRENDIZ' || perfil.contains('APREND')) return true;
    if (perfil == 'ESTAGIARIO' || perfil.contains('ESTAG')) return false;
  } catch (_) {}

  // 2) Perfil no mapa (quando user é Map)
  if (user is Map) {
    final perfilMap = (user['perfil'] ?? '').toString().toUpperCase();
    if (perfilMap.isNotEmpty) {
      if (perfilMap == 'JOVEM_APRENDIZ' || perfilMap.contains('APREND')) {
        return true;
      }
      if (perfilMap == 'ESTAGIARIO' || perfilMap.contains('ESTAG')) {
        return false;
      }
    }

    // Regime no mapa (1 = Aprendiz, 2 = Estagiário)
    final regimeRaw = user['regime'] ??
        user['regime_id'] ??
        user['regimeId'] ??
        user['cd_regime'];
    final regimeInt =
        regimeRaw is int ? regimeRaw : int.tryParse('${regimeRaw ?? ''}');
    if (regimeInt != null) return regimeInt == 1;
  }

  // 3) Regime no model (1 = Aprendiz, 2 = Estagiário)
  try {
    final regimeRaw =
        user.regimeId ?? user.regime_id ?? user.regime ?? user.cdRegime;
    final regimeInt =
        regimeRaw is int ? regimeRaw : int.tryParse('${regimeRaw ?? ''}');
    if (regimeInt != null) return regimeInt == 1;
  } catch (_) {}

  return false;
}

String? candidatoIdFromUser(dynamic user) {
  if (user == null) return null;

  // Suporte direto quando usuario já é um Map
  if (user is Map) {
    for (final key in ['cd_usuario', 'cd_candidato', 'id']) {
      final value = user[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
  }

  // Lista de propriedades possíveis usando reflection segura
  final propertyNames = [
    'cdUsuario', // camelCase de cd_usuario
    'cd_usuario', // snake_case
    'cdCandidato',
    'cd_candidato',
    'cdCandidatoEstagio',
    'cdCandidatoAprendiz',
    'cdEstagiario',
    'cdJovemAprendiz',
    'candidatoId',
    'id',
  ];

  // Tentar acessar propriedades de forma segura
  for (final propName in propertyNames) {
    try {
      // Use reflection mirror se disponível, caso contrário use toString
      final userString = user.toString();
      if (userString.contains(propName)) {
        // Tente extrair usando runtimeType e mirror se necessário
        // Por ora, vamos usar uma abordagem mais simples
      }
    } catch (_) {}
  }

  // Tentar converter para JSON se possível
  try {
    final json = user.toJson();
    if (json is Map) {
      for (final key in ['cd_usuario', 'cd_candidato', 'id']) {
        final value = json[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }
  } catch (_) {}

  // Como último recurso, tentar acessar propriedades conhecidas do modelo Usuario
  try {
    // Assumindo que o modelo Usuario tem uma propriedade id
    if (user.id != null) return user.id.toString();
  } catch (_) {}

  return null;
}

String? regimeIdFromUser(dynamic user) {
  if (user == null) return null;

  // Suporte direto quando usuario já é um Map
  if (user is Map) {
    for (final key in ['regime', 'regime_id', 'regimeId', 'cd_regime']) {
      final value = user[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
  }

  // Tentar converter para JSON se possível
  try {
    final json = user.toJson();
    if (json is Map) {
      for (final key in ['regime', 'regime_id', 'regimeId', 'cd_regime']) {
        final value = json[key];
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      }
    }
  } catch (_) {}

  // Acessar propriedades conhecidas do modelo Usuario
  try {
    // Assumindo que o modelo Usuario tem uma propriedade regime
    if (user.regime != null) return user.regime.toString();
  } catch (_) {}

  return null;
}
