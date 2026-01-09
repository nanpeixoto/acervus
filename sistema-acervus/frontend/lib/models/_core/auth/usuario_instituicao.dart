// lib/models/usuario_instituicao.dart
class UsuarioInstituicao {
  final int? id;
  final int? cdUsuario;
  final String nome;
  final String email;
  final String? senha;
  final int cdInstituicaoEnsino;
  final bool bloqueado;
  final bool recebeEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UsuarioInstituicao({
    this.id,
    this.cdUsuario,
    required this.nome,
    required this.email,
    this.senha,
    required this.cdInstituicaoEnsino,
    this.bloqueado = false,
    this.recebeEmail = true,
    this.createdAt,
    this.updatedAt,
  });

  factory UsuarioInstituicao.fromJson(Map<String, dynamic> json) {
    return UsuarioInstituicao(
      id: json['id_usuario_instituicao'] ?? json['id'],
      cdUsuario: json['cd_usuario'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      senha: json['senha'],
      cdInstituicaoEnsino: json['cd_instituicao_ensino'] ?? 0,
      bloqueado: json['bloqueado'] ?? false,
      recebeEmail: json['recebe_email'] ?? true,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id_usuario_instituicao': id,
      if (cdUsuario != null) 'cd_usuario': cdUsuario,
      'nome': nome,
      'email': email,
      if (senha != null) 'senha': senha,
      'cd_instituicao_ensino': cdInstituicaoEnsino,
      'bloqueado': bloqueado,
      'recebe_email': recebeEmail,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      if (cdUsuario != null) 'cd_usuario': cdUsuario,
      'nome': nome,
      'email': email,
      if (senha != null) 'senha': senha,
      'cd_instituicao_ensino': cdInstituicaoEnsino,
      'bloqueado': bloqueado,
      'recebe_email': recebeEmail,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'nome': nome,
      'email': email,
      'bloqueado': bloqueado,
      'recebe_email': recebeEmail,
    };
  }

  UsuarioInstituicao copyWith({
    int? id,
    int? cdUsuario,
    String? nome,
    String? email,
    String? senha,
    int? cdInstituicaoEnsino,
    bool? bloqueado,
    bool? recebeEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UsuarioInstituicao(
      id: id ?? this.id,
      cdUsuario: cdUsuario ?? this.cdUsuario,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      cdInstituicaoEnsino: cdInstituicaoEnsino ?? this.cdInstituicaoEnsino,
      bloqueado: bloqueado ?? this.bloqueado,
      recebeEmail: recebeEmail ?? this.recebeEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UsuarioInstituicao(id: $id, nome: $nome, email: $email, bloqueado: $bloqueado)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsuarioInstituicao &&
        other.id == id &&
        other.nome == nome &&
        other.email == email;
  }

  @override
  int get hashCode {
    return Object.hash(id, nome, email);
  }

  // Getters úteis
  String get status => bloqueado ? 'Bloqueado' : 'Ativo';
  String get recebeEmailDisplay => recebeEmail ? 'Sim' : 'Não';
  String get iniciais {
    if (nome.isEmpty) return '';
    final words = nome.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }
    return '${words[0].substring(0, 1)}${words[words.length - 1].substring(0, 1)}'
        .toUpperCase();
  }
}