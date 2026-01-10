// lib/routes/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sistema_estagio/models/_auxiliares/assunto.dart';
import 'package:sistema_estagio/screens/admin/autores/assunto_form_screen.dart';
import 'package:sistema_estagio/screens/admin/autores/editora_screen.dart';
import 'package:sistema_estagio/screens/admin/autores/estado_conservacao_screen.dart';
import 'package:sistema_estagio/screens/admin/autores/subtipo_obra_screen.dart';
import 'package:sistema_estagio/screens/admin/autores/tipo_obra_screen.dart';
import 'package:sistema_estagio/screens/admin/cadastros/_auxiliares/idiomas/idiomas_list_screen.dart';
import 'package:sistema_estagio/screens/admin/cadastros/_auxiliares/material_screen.dart';
import 'package:sistema_estagio/screens/admin/cadastros/obras_list_screen.dart';
import 'package:sistema_estagio/screens/candidato/components/obra_cadastro_screen.dart';

import '../providers/auth_provider.dart';
import '../screens/public/login_screen.dart';
import '../screens/admin/dashboard/dashboard_screen.dart';
import '../widgets/admin_layout.dart';

import '../screens/admin/autores/autor_form_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  // Mantido por compatibilidade com o CIDE
  static bool _tokenVerifiedThisSession = false;
  static String? _lastVerifiedRoute;

  AppRouter(this.authProvider);

  /// Mantém compatibilidade com AuthProvider / código legado
  /// Deve ser chamado no logout
  static void resetTokenVerification() {
    _tokenVerifiedThisSession = false;
    _lastVerifiedRoute = null;
  }

  GoRouter get router => GoRouter(
        initialLocation: '/login',
        refreshListenable: authProvider,
        redirect: (context, state) {
          final isLoggedIn = authProvider.isAuthenticated;
          final isOnLogin = state.matchedLocation == '/login';

          if (!isLoggedIn && !isOnLogin) {
            return '/login';
          }

          if (isLoggedIn && isOnLogin) {
            return '/admin/dashboard';
          }

          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginScreen(),
          ),
          ShellRoute(
            builder: (context, state, child) {
              return AdminLayout(
                currentRoute: state.uri.toString(),
                child: child,
              );
            },
            routes: [
              GoRoute(
                path: '/admin/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
              GoRoute(
                path: '/admin/autores',
                builder: (context, state) => const AutoresScreen(),
              ),
              GoRoute(
                path: '/admin/assuntos',
                builder: (context, state) => const AssuntosScreen(),
              ),
              GoRoute(
                path: '/admin/estado-conservacao',
                builder: (context, state) => const EstadoConservacaoScreen(),
              ),
              GoRoute(
                path: '/admin/idiomas',
                builder: (context, state) => const IdiomasScreen(),
              ),
              GoRoute(
                path: '/admin/materiais',
                builder: (context, state) => const MateriaisScreen(),
              ),
              GoRoute(
                path: '/admin/tipos-obra',
                builder: (context, state) => const TipoObraScreen(),
              ),
              GoRoute(
                path: '/admin/subtipos-obra',
                builder: (context, state) => const SubtipoObraScreen(),
              ),
              GoRoute(
                path: '/admin/obras',
                builder: (context, state) => const ObrasListScreen(),
              ),
              GoRoute(
                path: '/admin/obras/nova',
                builder: (context, state) => const ObraCadastroScreen(),
              ),
              GoRoute(
                path: '/admin/obras/editar/:id',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return ObraCadastroScreen(obraId: id);
                },
              ),
              GoRoute(
                path: '/admin/editoras',
                builder: (context, state) => const EditoraScreen(),
              ),
            ],
          ),
        ],
      );
}
