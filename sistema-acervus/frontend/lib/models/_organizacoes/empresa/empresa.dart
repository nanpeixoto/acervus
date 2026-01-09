// lib/models/empresa.dart
import '../../_core/endereco.dart';

class Empresa {
  final String? id;
  final int? idModelo;
  final String? idSeguradora;
  final String? nomeSeguradora; // NOVO CAMPO
  final String? taxaAprendiz;
  final String? taxaEstagiario; // Mantendo o campo original
  final String? taxaPrograma; // NOVO CAMPO (taxa_pagamento_programa)
  final String cnpj;
  final String? razaoSocial;
  final String? nomeFantasia;
  final String? enderecoCompleto; // NOVO CAMPO
  final String? site; // NOVO CAMPO
  final String? tipoInscricao; // NOVO CAMPO
  final String? numeroInscricao; // NOVO CAMPO
  final String? telefone;
  final String? celular;
  final String? email;
  final String? observacao; // NOVO CAMPO
  final Endereco? endereco;
  final bool ativo;
  final int? criadoPor; // NOVO CAMPO
  final DateTime? createdAt;
  final int? alteradoPor; // NOVO CAMPO
  final DateTime? updatedAt;
  final String? senha;

  Empresa({
    this.id,
    this.idModelo,
    this.idSeguradora,
    this.nomeSeguradora,
    this.taxaAprendiz = '0.00',
    this.taxaEstagiario = '0.00',
    this.taxaPrograma = '0.00',
    required this.cnpj,
    this.razaoSocial,
    this.nomeFantasia,
    this.enderecoCompleto,
    this.site,
    this.tipoInscricao,
    this.numeroInscricao,
    this.telefone = '',
    this.celular,
    this.email,
    this.observacao,
    required this.endereco,
    this.ativo = true,
    this.criadoPor,
    this.createdAt,
    this.alteradoPor,
    this.updatedAt,
    this.senha,
  });

  factory Empresa.fromJson(Map<String, dynamic> json) {
    try {
      return Empresa(
        id: (() {
          try {
            return json['cd_empresa']?.toString();
          } catch (e) {
            print('Erro em id: $e');
            return null;
          }
        })(),
        idModelo: (() {
          try {
            return json['cd_template_modelo'];
          } catch (e) {
            print('Erro em idModelo: $e');
            return null;
          }
        })(),
        cnpj: (() {
          try {
            // Remove formatação do CNPJ se existir
            String cnpjRaw = json['cnpj']?.toString() ?? '';
            return cnpjRaw.replaceAll(RegExp(r'[^\d]'), '');
          } catch (e) {
            print('Erro em cnpj: $e');
            return '';
          }
        })(),
        razaoSocial: (() {
          try {
            return json['razao_social'] ?? '';
          } catch (e) {
            print('Erro em razaoSocial: $e');
            return '';
          }
        })(),
        nomeFantasia: (() {
          try {
            return json['nome_fantasia'] ?? '';
          } catch (e) {
            print('Erro em nomeFantasia: $e');
            return '';
          }
        })(),
        site: json['site']?.toString(),
        tipoInscricao: json['tipo_inscricao']?.toString(),
        numeroInscricao: json['numero_inscricao']?.toString(),
        telefone: (() {
          try {
            return json['telefone']?.toString() ?? '';
          } catch (e) {
            print('Erro em telefone: $e');
            return '';
          }
        })(),
        celular: json['celular']?.toString(),
        email: json['email']?.toString(),
        senha: json['senha']?.toString(),
        observacao: json['observacao']?.toString(),
        taxaAprendiz: json['taxa_pagamento_aprendiz']?.toString() ?? '0.00',
        taxaEstagiario: json['taxa_pagamento_estagiario']?.toString() ?? '0.00',
        taxaPrograma: json['taxa_pagamento_programa']?.toString() ?? '0.00',
        idSeguradora: json['cd_seguradora']?.toString(),
        nomeSeguradora: json['nome_seguradora']?.toString(),
        ativo: !(json['bloqueado'] ?? false), // Inverte o valor do bloqueado
        criadoPor: json['criado_por'] != null
            ? int.tryParse(json['criado_por'].toString())
            : null,
        alteradoPor: json['alterado_por'] != null
            ? int.tryParse(json['alterado_por'].toString())
            : null,
        createdAt: (() {
          try {
            return json['data_criacao'] != null
                ? DateTime.parse(json['data_criacao'])
                : null;
          } catch (e) {
            print('Erro em data_criacao: $e');
            return null;
          }
        })(),
        updatedAt: (() {
          try {
            return json['data_alteracao'] != null
                ? DateTime.parse(json['data_alteracao'])
                : null;
          } catch (e) {
            print('Erro em data_alteracao: $e');
            return null;
          }
        })(),
        endereco: (() {
          try {
            return Endereco.fromJson(json['endereco_completo'] ?? {});
          } catch (e) {
            print('Erro em endereco: $e');
            // Retorna endereco vazio em caso de erro
            return Endereco(
              cep: '',
              logradouro: '',
              numero: '',
              bairro: '',
              cidade: '',
              estado: '',
            );
          }
        })(),
        enderecoCompleto: (() {
          try {
            return json['endereco_completo']?.toString() ?? '';
          } catch (e) {
            print('Erro em endereco_completo: $e');
            return '';
          }
        })(),
      );
    } catch (e, stack) {
      print('Erro geral em Empresa.fromJson: $e\n$stack');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'cd_empresa': id,
      'idModelo': idModelo,
      'cnpj': cnpjFormatted, // Retorna formatado para exibição
      'razao_social': razaoSocial,
      'nome_fantasia': nomeFantasia,
      'site': site,
      'tipo_inscricao': tipoInscricao,
      'numero_inscricao': numeroInscricao,
      'telefone': telefone,
      'celular': celular,
      'email': email,
      'senha': senha,
      'observacao': observacao,
      'taxa_pagamento_aprendiz': taxaAprendiz,
      'taxa_pagamento_estagiario': taxaEstagiario,
      'taxa_pagamento_programa': taxaPrograma,
      'cd_seguradora': idSeguradora,
      'nome_seguradora': nomeSeguradora,
      'bloqueado': !ativo, // Inverte para salvar
      'criado_por': criadoPor,
      'data_criacao': createdAt?.toIso8601String(),
      'alterado_por': alteradoPor,
      'data_alteracao': updatedAt?.toIso8601String(),
      'endereco': endereco?.toJson(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'cnpj': cnpj, // Sem formatação para criação
      'razao_social': razaoSocial,
      'nome_fantasia': nomeFantasia,
      'site': site,
      'tipo_inscricao': tipoInscricao,
      'numero_inscricao': numeroInscricao,
      'telefone': telefone,
      'celular': celular,
      'email': email,
      'observacao': observacao,
      'taxa_pagamento_aprendiz': taxaAprendiz,
      'taxa_pagamento_programa': taxaPrograma,
      'cd_seguradora': idSeguradora,
      'endereco': endereco?.toJson(),
    };
  }

  // Métodos utilitários
  String get cnpjFormatted {
    if (cnpj.length == 14) {
      return '${cnpj.substring(0, 2)}.${cnpj.substring(2, 5)}.${cnpj.substring(5, 8)}/${cnpj.substring(8, 12)}-${cnpj.substring(12, 14)}';
    }
    return cnpj;
  }

  String? get telefoneFormatted {
    if (telefone == null || telefone!.isEmpty) return null;
    final numbers = telefone!.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return telefone;
  }

  String? get celularFormatted {
    if (celular == null || celular!.isEmpty) return null;
    final numbers = celular!.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 11) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 7)}-${numbers.substring(7)}';
    } else if (numbers.length == 10) {
      return '(${numbers.substring(0, 2)}) ${numbers.substring(2, 6)}-${numbers.substring(6)}';
    }
    return celular;
  }

  String get enderecoCompletoValue {
    return endereco?.enderecoCompleto ?? '';
  }

  String get nomeExibicao {
    return nomeFantasia?.isNotEmpty == true ? nomeFantasia! : razaoSocial ?? '';
  }

  String get statusTexto {
    return ativo ? 'Ativo' : 'Bloqueado';
  }

  // Métodos de validação
  bool get isValidCNPJ {
    if (cnpj.length != 14) return false;
    return EmpresaValidator.validateCNPJ(cnpj) == null;
  }

  bool get hasValidEmail {
    if (email == null || email!.isEmpty) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email!);
  }

  bool get hasValidTelefone {
    if (telefone == null || telefone!.isEmpty) {
      return true; // Telefone é opcional
    }
    final numbers = telefone!.replaceAll(RegExp(r'\D'), '');
    return numbers.length >= 10 && numbers.length <= 11;
  }

  // Método de cópia
  Empresa copyWith({
    String? id,
    String? idModelo,
    String? idSeguradora,
    String? nomeSeguradora,
    String? taxaAprendiz,
    String? taxaEstagiario,
    String? taxaPrograma,
    String? cnpj,
    String? razaoSocial,
    String? nomeFantasia,
    String? site,
    String? tipoInscricao,
    String? numeroInscricao,
    String? telefone,
    String? celular,
    String? email,
    String? observacao,
    Endereco? endereco,
    bool? ativo,
    int? criadoPor,
    DateTime? createdAt,
    int? alteradoPor,
    DateTime? updatedAt,
  }) {
    return Empresa(
      id: id ?? this.id,
      idModelo: this.idModelo,
      idSeguradora: idSeguradora ?? this.idSeguradora,
      nomeSeguradora: nomeSeguradora ?? this.nomeSeguradora,
      taxaAprendiz: taxaAprendiz ?? this.taxaAprendiz,
      taxaEstagiario: taxaEstagiario ?? this.taxaEstagiario,
      taxaPrograma: taxaPrograma ?? this.taxaPrograma,
      cnpj: cnpj ?? this.cnpj,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      site: site ?? this.site,
      tipoInscricao: tipoInscricao ?? this.tipoInscricao,
      numeroInscricao: numeroInscricao ?? this.numeroInscricao,
      telefone: telefone ?? this.telefone,
      celular: celular ?? this.celular,
      email: email ?? this.email,
      observacao: observacao ?? this.observacao,
      endereco: endereco ?? this.endereco,
      ativo: ativo ?? this.ativo,
      criadoPor: criadoPor ?? this.criadoPor,
      createdAt: createdAt ?? this.createdAt,
      alteradoPor: alteradoPor ?? this.alteradoPor,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Empresa && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Empresa(id: $id, nomeFantasia: $nomeExibicao, cnpj: $cnpjFormatted)';
  }
}

// Classe para validações específicas da Empresa
class EmpresaValidator {
  static String? validateCNPJ(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) {
      return 'CNPJ é obrigatório';
    }

    final numbers = cnpj.replaceAll(RegExp(r'\D'), '');

    if (numbers.length != 14) {
      return 'CNPJ deve ter 14 dígitos';
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(numbers)) {
      return 'CNPJ inválido';
    }

    return _validateCNPJAlgorithm(numbers) ? null : 'CNPJ inválido';
  }

  static bool _validateCNPJAlgorithm(String cnpj) {
    List<int> weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    List<int> weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += int.parse(cnpj[i]) * weights1[i];
    }
    int remainder = sum % 11;
    int digit1 = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cnpj[12]) != digit1) return false;

    sum = 0;
    for (int i = 0; i < 13; i++) {
      sum += int.parse(cnpj[i]) * weights2[i];
    }
    remainder = sum % 11;
    int digit2 = remainder < 2 ? 0 : 11 - remainder;

    return int.parse(cnpj[13]) == digit2;
  }

  static String? validateRazaoSocial(String? razaoSocial) {
    if (razaoSocial == null || razaoSocial.trim().isEmpty) {
      return 'Razão social é obrigatória';
    }
    if (razaoSocial.trim().length < 2) {
      return 'Razão social deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  static String? validateNomeFantasia(String? nomeFantasia) {
    if (nomeFantasia == null || nomeFantasia.trim().isEmpty) {
      return 'Nome fantasia é obrigatório';
    }
    if (nomeFantasia.trim().length < 2) {
      return 'Nome fantasia deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'E-mail é obrigatório';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'E-mail inválido';
    }
    return null;
  }

  static String? validateTelefone(String? telefone,
      {bool obrigatorio = false}) {
    if (telefone == null || telefone.trim().isEmpty) {
      return obrigatorio ? 'Telefone é obrigatório' : null;
    }
    final numbers = telefone.replaceAll(RegExp(r'\D'), '');
    if (numbers.length < 10 || numbers.length > 11) {
      return 'Telefone deve ter 10 ou 11 dígitos';
    }
    return null;
  }

  static String? validateTaxa(String? taxa) {
    if (taxa == null || taxa.trim().isEmpty) {
      return null; // Taxa é opcional
    }
    final double? value = double.tryParse(taxa.replaceAll(',', '.'));
    if (value == null) {
      return 'Taxa deve ser um número válido';
    }
    if (value < 0) {
      return 'Taxa não pode ser negativa';
    }
    if (value > 100) {
      return 'Taxa não pode ser maior que 100%';
    }
    return null;
  }
}

// Enum para tipos de inscrição
enum TipoInscricao {
  CNPJ,
  CEI,
  CAEPF,
  CNO,
}

extension TipoInscricaoExtension on TipoInscricao {
  String get displayName {
    switch (this) {
      case TipoInscricao.CNPJ:
        return 'CNPJ';
      case TipoInscricao.CEI:
        return 'CEI';
      case TipoInscricao.CAEPF:
        return 'CAEPF';
      case TipoInscricao.CNO:
        return 'CNO';
    }
  }
}
