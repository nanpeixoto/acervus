enum TipoUsuario {
  ADMIN,
  COLABORADOR,
  ESTAGIARIO,
  EMPRESA,
  INSTITUICAO,
  SUPERVISOR,
  JOVEM_APRENDIZ,
}

// Extension para facilitar o uso
extension TipoUsuarioExtension on TipoUsuario {
  String get displayName {
    switch (this) {
      case TipoUsuario.ADMIN:
        return 'Administrador';
      case TipoUsuario.COLABORADOR:
        return 'Colaborador';
      case TipoUsuario.ESTAGIARIO:
        return 'Estagiário';
      case TipoUsuario.EMPRESA:
        return 'Empresa';
      case TipoUsuario.INSTITUICAO:
        return 'Instituição de Ensino';
      case TipoUsuario.JOVEM_APRENDIZ:
        return 'Jovem Aprendiz';
      case TipoUsuario.SUPERVISOR:
        return 'Supervisor';
    }
  }

  String get description {
    switch (this) {
      case TipoUsuario.ADMIN:
        return 'Administrador do sistema';
      case TipoUsuario.COLABORADOR:
        return 'Colaborador interno';
      case TipoUsuario.ESTAGIARIO:
        return 'Candidato a estágio';
      case TipoUsuario.EMPRESA:
        return 'Empresa concedente';
      case TipoUsuario.INSTITUICAO:
        return 'Instituição de ensino';
      case TipoUsuario.JOVEM_APRENDIZ:
        return 'Candidato a jovem aprendiz';
      case TipoUsuario.SUPERVISOR:
        return 'Supervisor';
    }
  }

  bool get isCandidato =>
      this == TipoUsuario.ESTAGIARIO || this == TipoUsuario.JOVEM_APRENDIZ;
  bool get isAdministrativo =>
      this == TipoUsuario.ADMIN || this == TipoUsuario.COLABORADOR;
  bool get isExterno =>
      this == TipoUsuario.EMPRESA || this == TipoUsuario.INSTITUICAO;
}

class Usuario {
  // ✅ CAMPOS DA TABELA (conforme banco de dados)
  final int id; // cd_usuario
  final String? nome; // nome
  final String? login; // login
  final String? email; // email
  final String? senha; // senha (apenas para criação/alteração)
  final String? perfil; // perfil (string que será mapeada para TipoUsuario)
  final bool? ativo; // ativo
  final String? observacao; // observacao
  final bool? bloqueado; // bloqueado
  final bool? recebeEmail; // recebe_email
  final DateTime? dataCriacao; // data_criacao
  final String? criadoPor; // criado_por
  final DateTime? dataAlteracao; // data_alteracao
  final String? alteradoPor; // alterado_por
  final int? cdEmpresa; // cd_empresa
  final int? cdInstituicaoEnsino; // cd_instituicao_ensino
  final int? cdSupervisor; // cd_supervisor
  final String? tipoRegime; // tipo_regime
  final int? regimeId; // regime_id

  // ✅ CAMPOS EXISTENTES (mantidos para compatibilidade)
  final TipoUsuario tipo;
  final dynamic token;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLogin;
  final List<String>? permissoes;
  final String? avatarUrl;
  final String? telefone;
  final String? cpf;
  final String? celular;

  int? cdCandidato;

  // ✅ ALIAS/GETTERS para compatibilidade com AuthProvider
  String? get tipoUsuario => perfil; // Compatibilidade com tela

  Usuario({
    required this.id,
    this.nome,
    this.login,
    this.email,
    this.senha,
    this.perfil,
    this.ativo,
    this.observacao,
    this.bloqueado,
    this.recebeEmail,
    this.dataCriacao,
    this.criadoPor,
    this.dataAlteracao,
    this.alteradoPor,
    this.cdEmpresa,
    this.cdInstituicaoEnsino,
    this.tipoRegime,
    this.regimeId,
    this.cdSupervisor,
    // Campos existentes
    required this.tipo,
    this.token,
    this.createdAt,
    this.updatedAt,
    this.lastLogin,
    this.permissoes,
    this.avatarUrl,
    this.telefone,
    this.cpf,
    this.celular,
  });

  // Método estático para mapear perfil do backend para TipoUsuario
  static TipoUsuario _mapPerfilToTipoUsuario(String? perfil) {
    if (perfil == null) return TipoUsuario.ESTAGIARIO;

    switch (perfil.toUpperCase()) {
      case 'ADMIN':
        return TipoUsuario.ADMIN;
      case 'COLABORADOR':
        return TipoUsuario.COLABORADOR;
      case 'EMPRESA':
        return TipoUsuario.EMPRESA;
      case 'ESTAGIARIO':
        return TipoUsuario.ESTAGIARIO;
      case 'IE':
        return TipoUsuario.INSTITUICAO;
      case 'JOVEM_APRENDIZ':
        return TipoUsuario.JOVEM_APRENDIZ;
      case 'SUPERVISOR':
        return TipoUsuario.SUPERVISOR;
      default:
        return TipoUsuario.ESTAGIARIO;
    }
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      // ✅ CAMPOS DA TABELA
      id: json['cd_usuario'] ?? json['id'],
      nome: json['nome'],
      login: json['login'],
      email: json['email'],
      senha: json['senha'], // Normalmente não vem do backend
      perfil: json['perfil'],
      ativo: json['ativo'],
      observacao: json['observacao'],
      bloqueado: json['bloqueado'],
      recebeEmail: json['recebe_email'],
      dataCriacao: json['data_criacao'] != null
          ? DateTime.parse(json['data_criacao'])
          : null,
      criadoPor: json['criado_por'],
      dataAlteracao: json['data_alteracao'] != null
          ? DateTime.parse(json['data_alteracao'])
          : null,
      alteradoPor: json['alterado_por'],
      cdEmpresa: json['cd_empresa'],
      cdInstituicaoEnsino: json['cd_instituicao_ensino'],
      cdSupervisor: json['cd_supervisor'],
      tipoRegime: json['tipo_regime'],
      regimeId: json['regime'] != null
          ? int.tryParse(json['regime'].toString())
          : null,

      // ✅ CAMPOS EXISTENTES (mantidos)
      tipo: _mapPerfilToTipoUsuario(json['perfil']),
      token: json['token'],
      createdAt: json['createdAt'] != null || json['data_criacao'] != null
          ? DateTime.parse(json['createdAt'] ?? json['data_criacao'])
          : null,
      updatedAt: json['updatedAt'] != null || json['data_alteracao'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['data_alteracao'])
          : null,
      lastLogin:
          json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      permissoes: json['permissoes'] != null
          ? List<String>.from(json['permissoes'])
          : null,
      avatarUrl: json['avatarUrl'],
      telefone: json['telefone'],
      cpf: json['cpf'],
      celular: json['celular'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // ✅ CAMPOS DA TABELA
      'cd_usuario': id,
      'nome': nome,
      'login': login,
      'email': email,
      'senha': senha,
      'perfil': perfil,
      'ativo': ativo,
      'observacao': observacao,
      'bloqueado': bloqueado,
      'recebe_email': recebeEmail,
      'data_criacao': dataCriacao?.toIso8601String(),
      'criado_por': criadoPor,
      'data_alteracao': dataAlteracao?.toIso8601String(),
      'alterado_por': alteradoPor,
      'cd_empresa': cdEmpresa,
      'cd_instituicao_ensino': cdInstituicaoEnsino,
      'tipo_regime': tipoRegime,
      'cd_supervisor': cdSupervisor,
      'regime': regimeId,

      // ✅ CAMPOS EXISTENTES (compatibilidade)
      'id': id.toString(),
      'tipo': tipo.name,
      'token': token,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'permissoes': permissoes,
      'avatarUrl': avatarUrl,
      'telefone': telefone,
      'cpf': cpf,
      'celular': celular,
    };
  }

  // ==========================================
  // GETTERS PARA COMPATIBILIDADE COM AUTHPROVIDER
  // ==========================================

  /// Verifica se é administrador
  bool get isAdmin => tipo == TipoUsuario.ADMIN;

  /// Verifica se é empresa
  bool get isEmpresa => tipo == TipoUsuario.EMPRESA;

  /// Verifica se é candidato (estagiário ou jovem aprendiz)
  bool get isCandidato => tipo.isCandidato;

  /// Verifica se é estagiário
  bool get isEstagiario => tipo == TipoUsuario.ESTAGIARIO;

  /// Verifica se é jovem aprendiz
  bool get isJovemAprendiz => tipo == TipoUsuario.JOVEM_APRENDIZ;

  /// Verifica se é instituição
  bool get isInstituicao => tipo == TipoUsuario.INSTITUICAO;

  /// Verifica se é colaborador
  bool get isColaborador => tipo == TipoUsuario.COLABORADOR;

  /// Verifica se é usuário administrativo
  bool get isAdministrativo => tipo.isAdministrativo;

  /// Verifica se é usuário externo
  bool get isExterno => tipo.isExterno;

  // ==========================================
  // GETTERS DE COMPATIBILIDADE ADICIONAL
  // ==========================================

  /// Alias para lastLogin (compatibilidade com lastLoginAt)
  DateTime? get lastLoginAt => lastLogin;

  /// Alias para ativo (compatibilidade com isActive)
  bool get isActive => ativo ?? true;

  /// Alias para tipo (compatibilidade com type)
  TipoUsuario get type => tipo;

  /// Retorna telefone do usuário formatado
  String get telefoneFormatado {
    if (telefone != null && telefone!.isNotEmpty) {
      return _formatarTelefone(telefone!);
    }
    return '';
  }

  /// Retorna celular do usuário formatado
  String get celularFormatado {
    if (celular != null && celular!.isNotEmpty) {
      return _formatarTelefone(celular!);
    }
    return '';
  }

  String _formatarTelefone(String tel) {
    final clean = tel.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 6)}-${clean.substring(6)}';
    } else if (clean.length == 11) {
      return '(${clean.substring(0, 2)}) ${clean.substring(2, 7)}-${clean.substring(7)}';
    }
    return tel;
  }

  /// URL do avatar do usuário
  String? get avatarImage => avatarUrl;

  /// Status formatado para exibição
  String get statusExibicao => (ativo ?? true) ? 'Ativo' : 'Inativo';

  /// Display do tipo de usuário
  String get typeDisplay => tipo.displayName;

  // ==========================================
  // MÉTODOS DE PERMISSÃO
  // ==========================================

  /// Verifica se o usuário tem uma permissão específica
  bool temPermissao(String permissao) {
    // Admin tem todas as permissões
    if (isAdmin) return true;

    // Verifica na lista de permissões
    if (permissoes != null) {
      return permissoes!.contains(permissao);
    }

    // Permissões padrão por tipo
    return _getPermissoesPadrao().contains(permissao);
  }

  /// Verifica se tem múltiplas permissões
  bool temPermissoes(List<String> permissoesRequeridas) {
    return permissoesRequeridas.every((p) => temPermissao(p));
  }

  /// Retorna todas as permissões do usuário
  List<String> get todasPermissoes {
    if (isAdmin) return _getTodasPermissoes();

    final perms = <String>{};
    perms.addAll(_getPermissoesPadrao());
    if (permissoes != null) perms.addAll(permissoes!);

    return perms.toList();
  }

  /// Permissões padrão por tipo de usuário
  List<String> _getPermissoesPadrao() {
    switch (tipo) {
      case TipoUsuario.ADMIN:
        return _getTodasPermissoes();
      case TipoUsuario.COLABORADOR:
        return [
          'visualizar_vagas',
          'criar_vagas',
          'editar_vagas',
          'visualizar_candidatos',
          'gerenciar_candidaturas',
          'visualizar_empresas',
          'visualizar_instituicoes',
          'gerar_relatorios',
        ];
      case TipoUsuario.EMPRESA:
        return [
          'visualizar_proprias_vagas',
          'criar_vagas',
          'editar_proprias_vagas',
          'visualizar_proprios_candidatos',
          'gerenciar_proprias_candidaturas',
          'visualizar_proprio_perfil',
          'editar_proprio_perfil',
        ];
      case TipoUsuario.SUPERVISOR:
        return [
          'visualizar_proprias_vagas',
          'visualizar_proprios_candidatos',
          'visualizar_proprio_perfil',
          'editar_proprio_perfil',
        ];
      case TipoUsuario.INSTITUICAO:
        return [
          'visualizar_vagas',
          'visualizar_proprios_alunos',
          'visualizar_proprio_perfil',
          'editar_proprio_perfil',
          'aprovar_estagios',
        ];
      case TipoUsuario.ESTAGIARIO:
      case TipoUsuario.JOVEM_APRENDIZ:
        return [
          'visualizar_vagas',
          'candidatar_vagas',
          'visualizar_proprias_candidaturas',
          'visualizar_proprio_perfil',
          'editar_proprio_perfil',
        ];
    }
  }

  /// Todas as permissões disponíveis no sistema
  List<String> _getTodasPermissoes() {
    return [
      // Vagas
      'visualizar_vagas',
      'criar_vagas',
      'editar_vagas',
      'excluir_vagas',
      'publicar_vagas',
      'visualizar_proprias_vagas',
      'editar_proprias_vagas',

      // Candidatos
      'visualizar_candidatos',
      'gerenciar_candidaturas',
      'visualizar_proprios_candidatos',
      'gerenciar_proprias_candidaturas',
      'candidatar_vagas',
      'visualizar_proprias_candidaturas',

      // Empresas
      'visualizar_empresas',
      'criar_empresas',
      'editar_empresas',
      'excluir_empresas',

      // Instituições
      'visualizar_instituicoes',
      'criar_instituicoes',
      'editar_instituicoes',
      'excluir_instituicoes',

      // Usuários
      'visualizar_usuarios',
      'criar_usuarios',
      'editar_usuarios',
      'excluir_usuarios',
      'gerenciar_permissoes',

      // Perfil
      'visualizar_proprio_perfil',
      'editar_proprio_perfil',
      'visualizar_proprios_alunos',

      // Estágios
      'aprovar_estagios',
      'criar_contratos',
      'gerenciar_contratos',

      // Relatórios
      'gerar_relatorios',
      'exportar_dados',

      // Administração
      'gerenciar_sistema',
      'visualizar_logs',
    ];
  }

  // ==========================================
  // MÉTODOS DE INFORMAÇÃO
  // ==========================================

  /// Retorna informações do perfil formatadas
  Map<String, dynamic> get perfilFormatado {
    return {
      'tipo': perfil,
      'displayName': tipo.displayName,
      'description': tipo.description,
    };
  }

  /// Nome de exibição do usuário
  String get nomeExibicao {
    final nomeUsuario = nome ?? '';
    if (nomeUsuario.isNotEmpty) {
      return nomeUsuario;
    }
    return (email ?? '').split('@').first; // Usa parte do email como fallback
  }

  /// Status formatado
  String get statusFormatado => (ativo ?? true) ? 'Ativo' : 'Inativo';

  /// Tipo formatado
  String get tipoFormatado => tipo.displayName;

  /// Último login formatado
  String get lastLoginFormatado {
    if (lastLogin == null) return 'Nunca';

    final now = DateTime.now();
    final difference = now.difference(lastLogin!);

    if (difference.inDays > 0) {
      return '${difference.inDays} dia(s) atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hora(s) atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minuto(s) atrás';
    } else {
      return 'Agora';
    }
  }

  /// Tempo desde criação
  String get tempoDesdeCreacao {
    final dataRef = createdAt ?? dataCriacao;
    if (dataRef == null) return 'Data não informada';

    final now = DateTime.now();
    final difference = now.difference(dataRef);

    if (difference.inDays > 365) {
      final anos = difference.inDays ~/ 365;
      return anos == 1 ? '1 ano' : '$anos anos';
    } else if (difference.inDays > 30) {
      final meses = difference.inDays ~/ 30;
      return meses == 1 ? '1 mês' : '$meses meses';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? '1 dia' : '${difference.inDays} dias';
    } else {
      return 'Hoje';
    }
  }

  // ==========================================
  // MÉTODOS AUXILIARES
  // ==========================================

  /// Verifica se pode acessar área administrativa
  bool get podeAcessarAdmin => isAdmin || isColaborador;

  /// Verifica se pode gerenciar vagas
  bool get podeGerenciarVagas =>
      temPermissao('criar_vagas') || temPermissao('editar_vagas');

  /// Verifica se pode visualizar relatórios
  bool get podeVisualizarRelatorios => temPermissao('gerar_relatorios');

  /// Verifica se o usuário está ativo
  bool get isAtivo => ativo ?? true;

  /// Verifica se o usuário está bloqueado
  bool get isBloqueado => bloqueado ?? false;

  /// Cria cópia do usuário com alterações
  Usuario copyWith({
    int? id,
    String? nome,
    String? login,
    String? email,
    String? senha,
    String? perfil,
    bool? ativo,
    String? observacao,
    bool? bloqueado,
    bool? recebeEmail,
    DateTime? dataCriacao,
    String? criadoPor,
    DateTime? dataAlteracao,
    String? alteradoPor,
    int? cdEmpresa,
    int? cdInstituicaoEnsino,
    String? tipoRegime,
    int? cdSupervisor,
    TipoUsuario? tipo,
    dynamic token,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLogin,
    List<String>? permissoes,
    String? avatarUrl,
    String? telefone,
    String? cpf,
    String? celular,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      login: login ?? this.login,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      perfil: perfil ?? this.perfil,
      ativo: ativo ?? this.ativo,
      observacao: observacao ?? this.observacao,
      bloqueado: bloqueado ?? this.bloqueado,
      recebeEmail: recebeEmail ?? this.recebeEmail,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      criadoPor: criadoPor ?? this.criadoPor,
      dataAlteracao: dataAlteracao ?? this.dataAlteracao,
      alteradoPor: alteradoPor ?? this.alteradoPor,
      cdEmpresa: cdEmpresa ?? this.cdEmpresa,
      cdInstituicaoEnsino: cdInstituicaoEnsino ?? this.cdInstituicaoEnsino,
      tipoRegime: tipoRegime ?? this.tipoRegime,
      cdSupervisor: cdSupervisor ?? this.cdSupervisor,
      tipo: tipo ?? this.tipo,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLogin: lastLogin ?? this.lastLogin,
      permissoes: permissoes ?? this.permissoes,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      celular: celular ?? this.celular,
    );
  }

  /// Atualiza o último login
  Usuario updateLastLogin() {
    return copyWith(lastLogin: DateTime.now());
  }

  /// Ativa/desativa usuário
  Usuario toggleAtivo() {
    return copyWith(ativo: !(ativo ?? true));
  }

  /// Adiciona permissão
  Usuario adicionarPermissao(String permissao) {
    final novasPermissoes = List<String>.from(permissoes ?? []);
    if (!novasPermissoes.contains(permissao)) {
      novasPermissoes.add(permissao);
    }
    return copyWith(permissoes: novasPermissoes);
  }

  /// Remove permissão
  Usuario removerPermissao(String permissao) {
    final novasPermissoes = List<String>.from(permissoes ?? []);
    novasPermissoes.remove(permissao);
    return copyWith(permissoes: novasPermissoes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Usuario(id: $id, email: $email, tipo: ${tipo.name}, ativo: $ativo)';
  }
}

// ==========================================
// CLASSE PARA VALIDAÇÕES
// ==========================================

class UsuarioValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'E-mail é obrigatório';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'E-mail inválido';
    }

    return null;
  }

  static String? validateTipo(TipoUsuario? tipo) {
    if (tipo == null) {
      return 'Tipo de usuário é obrigatório';
    }
    return null;
  }

  static Map<String, String> validateUsuario(Usuario usuario) {
    Map<String, String> errors = {};

    final emailError = validateEmail(usuario.email);
    if (emailError != null) errors['email'] = emailError;

    final tipoError = validateTipo(usuario.tipo);
    if (tipoError != null) errors['tipo'] = tipoError;

    return errors;
  }
}

// ==========================================
// UTILITÁRIOS
// ==========================================

class UsuarioUtils {
  /// Filtra usuários por tipo
  static List<Usuario> filtrarPorTipo(
      List<Usuario> usuarios, TipoUsuario tipo) {
    return usuarios.where((u) => u.tipo == tipo).toList();
  }

  /// Filtra usuários ativos
  static List<Usuario> filtrarAtivos(List<Usuario> usuarios) {
    return usuarios.where((u) => u.ativo == true).toList();
  }

  /// Busca usuários por texto
  static List<Usuario> buscarUsuarios(List<Usuario> usuarios, String query) {
    if (query.trim().isEmpty) return usuarios;

    final queryLower = query.toLowerCase();

    return usuarios.where((usuario) {
      return (usuario.email?.toLowerCase().contains(queryLower) ?? false) ||
          (usuario.nome?.toLowerCase().contains(queryLower) ?? false) ||
          (usuario.login?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  /// Ordena usuários
  static List<Usuario> ordenarUsuarios(
      List<Usuario> usuarios, String criterio) {
    switch (criterio.toLowerCase()) {
      case 'nome':
        return usuarios..sort((a, b) => (a.nome ?? '').compareTo(b.nome ?? ''));
      case 'email':
        return usuarios
          ..sort((a, b) => (a.email ?? '').compareTo(b.email ?? ''));
      case 'tipo':
        return usuarios..sort((a, b) => a.tipo.name.compareTo(b.tipo.name));
      case 'criacao':
        return usuarios
          ..sort((a, b) => (b.createdAt ?? b.dataCriacao ?? DateTime(2000))
              .compareTo(a.createdAt ?? a.dataCriacao ?? DateTime(2000)));
      case 'ultimo_login':
        return usuarios
          ..sort((a, b) => (b.lastLogin ?? DateTime(2000))
              .compareTo(a.lastLogin ?? DateTime(2000)));
      default:
        return usuarios;
    }
  }

  /// Calcula estatísticas dos usuários
  static Map<String, dynamic> calcularEstatisticas(List<Usuario> usuarios) {
    final total = usuarios.length;
    final ativos = usuarios.where((u) => u.ativo == true).length;
    final inativos = total - ativos;

    final porTipo = <String, int>{};
    for (final tipo in TipoUsuario.values) {
      porTipo[tipo.displayName] = usuarios.where((u) => u.tipo == tipo).length;
    }

    return {
      'total': total,
      'ativos': ativos,
      'inativos': inativos,
      'porTipo': porTipo,
    };
  }

  /// MÉTODO UTILITÁRIO SOLICITADO: Retorna display do tipo de usuário
  static String getUserTypeDisplay(TipoUsuario? tipo) {
    if (tipo == null) return 'Não definido';
    return tipo.displayName;
  }

  /// Função global para compatibilidade
  static String _getUserTypeDisplay(TipoUsuario? tipo) {
    return getUserTypeDisplay(tipo);
  }

  /// Gera URL de avatar baseado no nome
  static String generateAvatarUrl(String nome) {
    final initials = nome
        .split(' ')
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join('');

    return 'https://ui-avatars.com/api/?name=$initials&size=100&background=2E7D9A&color=fff';
  }
}
