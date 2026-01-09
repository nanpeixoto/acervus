import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:sistema_estagio/providers/auth_provider.dart';
import 'package:sistema_estagio/widgets/candidato_layout.dart';


class CandidatoPerfilScreen extends StatefulWidget {
  const CandidatoPerfilScreen({super.key});

  @override
  State<CandidatoPerfilScreen> createState() => _CandidatoPerfilScreenState();
}

class _CandidatoPerfilScreenState extends State<CandidatoPerfilScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _redirect());
  }

  void _redirect() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final id = _resolverCandidatoIdFallback(auth);
    final regimeId = _resolverRegimeIdFallback(auth);

    if (!mounted) return;

    if (id != null && regimeId != null) {
      context.go('/admin/candidatos/editar/$id/$regimeId');
    } else {
      setState(() {
        _error = 'Candidato ou regime não vinculados ao usuário atual.';
      });
    }
  }

  String? _resolverCandidatoIdFallback(AuthProvider auth) {
    final dynamic user = auth.usuario;
    if (user == null) return null;

    final getters = [
      () => user.cdCandidato,
      () => user.cdEstagiario,
      () => user.cdJovemAprendiz,
      () => user.candidatoId,
      () => user.id,
      () => user.isCandidato,
    ];

    for (final getter in getters) {
      try {
        final value = getter();
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      } catch (_) {}
    }
    return null;
  }

  String? _resolverRegimeIdFallback(AuthProvider auth) {
    final dynamic user = auth.usuario;
    if (user == null) return null;

    final getters = [
      () => user.regimeId,
      () => user.cdRegime,
      () => user.regime?.id,
      () => user.tipoRegime,
    ];

    for (final getter in getters) {
      try {
        final value = getter();
        if (value != null && value.toString().isNotEmpty) {
          return value.toString();
        }
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return CandidatoLayout(
      currentRoute: '/candidato/perfil',
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
      ),
    );
  }
}