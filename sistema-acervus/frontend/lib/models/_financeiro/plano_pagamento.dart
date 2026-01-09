// TODO Implement this library.// TODO Implement this library.// lib/models/turnos.dart
class PlanoPagamento {
  final int? id;
  final String nome;
  final String descricao;
  final double? valor; // Valor do PlanoPagamento de Pagamento
  final bool ativo;
  final bool isMatricula; // Indica se o plano é para matrícula
  final int totalUsos;

  PlanoPagamento({
    this.id,
    required this.nome,
    required this.descricao,
    required this.valor,
    this.ativo = true,
    this.isMatricula = false,
    this.totalUsos = 0,
  });

  factory PlanoPagamento.fromJson(Map<String, dynamic> json) {
    return PlanoPagamento(
      id: json['cd_plano_pagamento'],
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      isMatricula: json['ismatricula'] ?? false,
      valor: json['valor'] != null
          ? (json['valor'] is double
              ? json['valor']
              : double.tryParse(json['valor'].toString()) ?? 0.0)
          : 0.0,
      ativo: json['ativo'] ?? true,
      totalUsos: json['total_usos'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'valor': valor,
      'ativo': ativo,
      'isMatricula': isMatricula,
      'total_usos': totalUsos,
    };
  }

  PlanoPagamento copyWith({
    int? id,
    String? nome,
    String? descricao,
    String? cor,
    int? ordem,
    bool? isDefault,
    bool? ativo,
    bool? isMatricula,
    int? totalUsos,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    int? updatedBy,
  }) {
    return PlanoPagamento(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      valor: valor, // Valor não é alterável via copyWith
      ativo: ativo ?? this.ativo,
      isMatricula: isMatricula ?? this.isMatricula,
      totalUsos: totalUsos ?? this.totalUsos,
    );
  }

  @override
  String toString() {
    return 'PlanoPagamento{id: $id, nome: $nome, ativo: $ativo, descricao: $descricao}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanoPagamento &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Status padrão do sistema
  static List<PlanoPagamento> getStatusPadrao() {
    return [
      PlanoPagamento(
        id: 1,
        nome: 'Ativo',
        descricao: 'PlanoPagamento ativo e disponível para matrícula',
        valor: 0.0, // Valor padrão para PlanoPagamentos de status
        ativo: true,
      ),
      PlanoPagamento(
        id: 2,
        nome: 'Inativo',
        descricao: 'PlanoPagamento temporariamente inativo',
        valor: 0.0, // Valor padrão para PlanoPagamentos de status
        ativo: true,
      ),
      PlanoPagamento(
        id: 3,
        nome: 'Suspenso',
        descricao: 'PlanoPagamento suspenso por determinação administrativa',
        valor: 0.0, // Valor padrão para PlanoPagamentos de status
        ativo: true,
      ),
      PlanoPagamento(
        id: 4,
        nome: 'Em Análise',
        descricao: 'PlanoPagamento em processo de análise/aprovação',
        valor: 0.0, // Valor padrão para PlanoPagamentos de status
        ativo: true,
      ),
      PlanoPagamento(
        id: 5,
        nome: 'Encerrado',
        descricao: 'PlanoPagamento encerrado definitivamente',
        valor: 0.0, // Valor padrão para PlanoPagamentos de status
        ativo: true,
      ),
    ];
  }
}
