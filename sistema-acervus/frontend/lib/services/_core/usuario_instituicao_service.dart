// lib/services/usuario_instituicao_service.dart
import 'package:http/http.dart' as http;
import '../../models/_core/auth/usuario_instituicao.dart';
import '../../utils/app_config.dart';

class UsuarioInstituicaoService {
  static String baseUrl = AppConfig.baseUrl;

  // ==========================================
  // MÉTODOS AUXILIARES
  // ==========================================

  /// Retorna headers básicos
  static Map<String, String> _getBasicHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Processa resposta HTTP
  static Map<String, dynamic> _processResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return body;
      } else {
        final errorMessage = body['mensagem'] ??
            body['message'] ??
            body['erro'] ??
            'Erro no servidor';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Resposta inválida do servidor');
      }
      rethrow;
    }
  }

  // ==========================================
  // MÉTODOS PRINCIPAIS
  // ==========================================

  /// Cadastra novo usuário da instituição
  /// POST /usuarioInstituicao/cadastrar
  static Future<Map<String, dynamic>> cadastrarUsuario(
      UsuarioInstituicao usuario) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarioInstituicao/cadastrar'),
        headers: _getBasicHeaders(),
        body: jsonEncode(usuario.toCreateJson()),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Erro ao cadastrar usuário: $e');
    }
  }

  /// Lista usuários vinculados a uma instituição com paginação
  /// GET /usuarioInstituicao/instituicao/listar/{cd_instituicao_ensino}
  static Future<Map<String, dynamic>> listarUsuarios({
    required int cdInstituicaoEnsino,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final uri = Uri.parse(
              '$baseUrl/usuarioInstituicao/instituicao/listar/$cdInstituicaoEnsino')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(
        uri,
        headers: _getBasicHeaders(),
      );

      final result = _processResponse(response);

      // Processar lista de usuários
      final List<UsuarioInstituicao> usuarios = [];
      if (result['data'] != null && result['data'] is List) {
        for (var item in result['data']) {
          try {
            usuarios.add(UsuarioInstituicao.fromJson(item));
          } catch (e) {
            print('Erro ao processar usuário: $e');
          }
        }
      } else if (result['usuarios'] != null && result['usuarios'] is List) {
        for (var item in result['usuarios']) {
          try {
            usuarios.add(UsuarioInstituicao.fromJson(item));
          } catch (e) {
            print('Erro ao processar usuário: $e');
          }
        }
      }

      return {
        'usuarios': usuarios,
        'paginacao': {
          'pagina_atual':
              result['current_page'] ?? result['pagina_atual'] ?? page,
          'total_paginas':
              result['total_pages'] ?? result['total_paginas'] ?? 1,
          'total_registros':
              result['total'] ?? result['total_registros'] ?? usuarios.length,
          'por_pagina': result['per_page'] ?? result['por_pagina'] ?? limit,
          'tem_proxima':
              result['has_next_page'] ?? result['tem_proxima'] ?? false,
          'tem_anterior':
              result['has_prev_page'] ?? result['tem_anterior'] ?? false,
        },
        'sucesso': true,
      };
    } catch (e) {
      throw Exception('Erro ao listar usuários: $e');
    }
  }

  /// Altera vínculo e dados do usuário
  /// PUT /usuarioInstituicao/alterar/{id_usuario_instituicao}
  static Future<Map<String, dynamic>> alterarUsuario({
    required int idUsuarioInstituicao,
    required UsuarioInstituicao usuario,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/usuarioInstituicao/alterar/$idUsuarioInstituicao'),
        headers: _getBasicHeaders(),
        body: jsonEncode(usuario.toUpdateJson()),
      );

      return _processResponse(response);
    } catch (e) {
      throw Exception('Erro ao alterar usuário: $e');
    }
  }

  // ==========================================
  // MÉTODOS UTILITÁRIOS
  // ==========================================

  /// Busca usuários por nome ou email
  static Future<List<UsuarioInstituicao>> buscarUsuarios({
    required int cdInstituicaoEnsino,
    String? termo,
    bool? apenasAtivos,
  }) async {
    try {
      var page = 1;
      final List<UsuarioInstituicao> todosUsuarios = [];
      bool temMais = true;

      while (temMais) {
        final result = await listarUsuarios(
          cdInstituicaoEnsino: cdInstituicaoEnsino,
          page: page,
          limit: 50, // Buscar mais por página
        );

        final usuarios = result['usuarios'] as List<UsuarioInstituicao>;
        todosUsuarios.addAll(usuarios);

        temMais = result['paginacao']['tem_proxima'] ?? false;
        page++;
      }

      // Filtrar por termo se fornecido
      List<UsuarioInstituicao> usuariosFiltrados = todosUsuarios;

      if (termo != null && termo.isNotEmpty) {
        final termoLower = termo.toLowerCase();
        usuariosFiltrados = todosUsuarios.where((usuario) {
          return usuario.nome.toLowerCase().contains(termoLower) ||
              usuario.email.toLowerCase().contains(termoLower);
        }).toList();
      }

      // Filtrar apenas ativos se solicitado
      if (apenasAtivos == true) {
        usuariosFiltrados =
            usuariosFiltrados.where((usuario) => !usuario.bloqueado).toList();
      }

      return usuariosFiltrados;
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  /// Valida se email já está em uso na instituição
  static Future<bool> emailJaExiste({
    required int cdInstituicaoEnsino,
    required String email,
    int? idUsuarioAtual,
  }) async {
    try {
      final usuarios = await buscarUsuarios(
        cdInstituicaoEnsino: cdInstituicaoEnsino,
        termo: email,
      );

      return usuarios.any((usuario) =>
          usuario.email.toLowerCase() == email.toLowerCase() &&
          usuario.id != idUsuarioAtual);
    } catch (e) {
      return false; // Em caso de erro, assume que não existe
    }
  }

  /// Obter estatísticas dos usuários da instituição
  static Future<Map<String, int>> obterEstatisticas(
      int cdInstituicaoEnsino) async {
    try {
      final usuarios =
          await buscarUsuarios(cdInstituicaoEnsino: cdInstituicaoEnsino);

      return {
        'total': usuarios.length,
        'ativos': usuarios.where((u) => !u.bloqueado).length,
        'bloqueados': usuarios.where((u) => u.bloqueado).length,
        'recebem_email': usuarios.where((u) => u.recebeEmail).length,
      };
    } catch (e) {
      return {
        'total': 0,
        'ativos': 0,
        'bloqueados': 0,
        'recebem_email': 0,
      };
    }
  }

  /// Ativar/desativar usuário (toggle do status bloqueado)
  static Future<Map<String, dynamic>> toggleStatusUsuario({
    required int idUsuarioInstituicao,
    required UsuarioInstituicao usuario,
  }) async {
    try {
      final usuarioAtualizado = usuario.copyWith(
        bloqueado: !usuario.bloqueado,
      );

      return await alterarUsuario(
        idUsuarioInstituicao: idUsuarioInstituicao,
        usuario: usuarioAtualizado,
      );
    } catch (e) {
      throw Exception('Erro ao alterar status: $e');
    }
  }

  /// Validar dados antes de enviar
  static String? validarUsuario(UsuarioInstituicao usuario,
      {bool isCreating = false}) {
    if (usuario.nome.trim().isEmpty) {
      return 'Nome é obrigatório';
    }

    if (usuario.nome.trim().length < 2) {
      return 'Nome deve ter pelo menos 2 caracteres';
    }

    if (usuario.email.trim().isEmpty) {
      return 'Email é obrigatório';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(usuario.email)) {
      return 'Email inválido';
    }

    if (isCreating &&
        (usuario.senha == null || usuario.senha!.trim().isEmpty)) {
      return 'Senha é obrigatória para novos usuários';
    }

    if (isCreating && usuario.senha != null && usuario.senha!.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }

    return null; // Válido
  }
}
