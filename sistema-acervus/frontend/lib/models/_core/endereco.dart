// lib/models/endereco.dart
class Endereco {
  final int?  id; // ID opcional, pode ser usado para identificar o endereço em um banco de dados
  final String? cep;
  final String? logradouro;
  final String? complemento;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  // final String? complemento; // se existir

  Endereco({

    this.id,
    this.cep,
    this.complemento,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    // this.complemento,
  });

  // Factory para criar a partir de JSON geral
  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      id: json['cd_endereco'] != null ? int.tryParse(json['cd_endereco'].toString()) : null,
      cep: json['cep'],
      complemento: json['complemento'],
      logradouro: json['logradouro'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
      //complemento: json['complemento'],
    );
  }

  // Factory específico para dados de estagiário (campos podem estar no nível raiz)
  factory Endereco.fromEstagiarioJson(Map<String, dynamic> json) {
    return Endereco(
      id: json['cd_endereco'] != null ? int.tryParse(json['cd_endereco'].toString()) : null,
      cep: json['cep'],
      complemento: json['complemento'],
      logradouro: json['logradouro'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
      //complemento: json['complemento'],
    );
  }

  // Factory específico para dados de empresa (campos podem estar no nível raiz)
  factory Endereco.fromEmpresaJson(Map<String, dynamic> json) {
    return Endereco(
      id: json['cd_endereco'] != null ? int.tryParse(json['cd_endereco'].toString()) : null,
      cep: json['cep'],
      complemento: json['complemento'],
      logradouro: json['logradouro'],
      numero: json['numero'],
      bairro: json['bairro'],
      cidade: json['cidade'],
      estado: json['estado'],
      //complemento: json['complemento'],
    );
  }

  // Factory específico para dados de instituição
  factory Endereco.fromInstituicaoJson(Map<String, dynamic> json) {
    return Endereco(
      id: json['cd_endereco'] != null ? int.tryParse(json['cd_endereco'].toString()) : null,
      cep: json['cep']?.toString(),
      complemento: json['complemento']?.toString(),
      logradouro: json['logradouro']?.toString(),
      numero: json['numero']?.toString(),
      bairro: json['bairro']?.toString(),
      cidade: json['cidade']?.toString(),
      estado: json['estado']?.toString(),
      // complemento: json['complemento']?.toString(),
    );
  }

  // Factory para criar a partir de dados da API ViaCEP
  factory Endereco.fromViaCep(Map<String, dynamic> json) {
    return Endereco(
      id: null, // ID não é usado com ViaCEP
      cep: json['cep']?.replaceAll('-', '') ?? '',
      logradouro: json['logradouro'] ?? '',
      complemento: json['complemento'] ?? '',
      numero: '', // Deve ser preenchido pelo usuário
      bairro: json['bairro'] ?? '',
      cidade: json['localidade'] ?? '',
      estado: json['estado'] ?? '',
      //complemento: json['complemento']?.isEmpty == true ? null : json['complemento'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cd_endereco': id,
      'cep': cep,
      'complemento': complemento,
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      // 'complemento': complemento,
    };
  }

  String get enderecoCompleto {
    final partes = [      
      logradouro,
      complemento,
      numero,
      bairro,
      cidade,
      estado,
      cep,
    ].where((e) => e != null && e.isNotEmpty).toList();
    return partes.join(', ');
  }

  String get enderecoUmaLinha {
    String endereco = '$logradouro, $numero';
    // if (complemento != null && complemento!.isNotEmpty) {
    //   endereco += ' - $complemento';
    // }
    endereco += ', $bairro, $cidade/$estado - ${EnderecoUtils.formatCEP(cep ?? '')}';
    return endereco;
  }

  String get enderecoResumo {
    return '$logradouro, $numero - $bairro, $cidade/$estado';
  }

  // Validações
  bool get isValid {
    return (cep?.isNotEmpty ?? false) &&
           (logradouro?.isNotEmpty ?? false) &&
           (numero?.isNotEmpty ?? false) &&
           (bairro?.isNotEmpty ?? false) &&
           (cidade?.isNotEmpty ?? false) &&
           (estado?.isNotEmpty ?? false) &&
           (estado?.length == 2);
  }

  bool get isCepValid {
  final cepNumbers = (cep ?? '').replaceAll(RegExp(r'\D'), '');
  return cepNumbers.length == 8;
  }

  bool get isEstadoValid {
    return (estado?.length == 2) && _estadosValidos.contains(estado?.toUpperCase() ?? '');
  }

  // Lista de estados válidos
  static const List<String> _estadosValidos = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO',
    'MA', 'MT', 'MS', 'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
    'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO'
  ];

  // Método para obter nome completo do estado
  String get estadoNome {
    return _getEstadoNome(estado ?? '');
  }

  static String _getEstadoNome(String uf) {
    const Map<String, String> estados = {
      'AC': 'Acre',
      'AL': 'Alagoas',
      'AP': 'Amapá',
      'AM': 'Amazonas',
      'BA': 'Bahia',
      'CE': 'Ceará',
      'DF': 'Distrito Federal',
      'ES': 'Espírito Santo',
      'GO': 'Goiás',
      'MA': 'Maranhão',
      'MT': 'Mato Grosso',
      'MS': 'Mato Grosso do Sul',
      'MG': 'Minas Gerais',
      'PA': 'Pará',
      'PB': 'Paraíba',
      'PR': 'Paraná',
      'PE': 'Pernambuco',
      'PI': 'Piauí',
      'RJ': 'Rio de Janeiro',
      'RN': 'Rio Grande do Norte',
      'RS': 'Rio Grande do Sul',
      'RO': 'Rondônia',
      'RR': 'Roraima',
      'SC': 'Santa Catarina',
      'SP': 'São Paulo',
      'SE': 'Sergipe',
      'TO': 'Tocantins',
    };
    return estados[uf.toUpperCase()] ?? uf;
  }

  // Lista de todos os estados para dropdowns
  static List<Map<String, String>> get estadosList {
    return [
      {'codigo': 'AC', 'nome': 'Acre'},
      {'codigo': 'AL', 'nome': 'Alagoas'},
      {'codigo': 'AP', 'nome': 'Amapá'},
      {'codigo': 'AM', 'nome': 'Amazonas'},
      {'codigo': 'BA', 'nome': 'Bahia'},
      {'codigo': 'CE', 'nome': 'Ceará'},
      {'codigo': 'DF', 'nome': 'Distrito Federal'},
      {'codigo': 'ES', 'nome': 'Espírito Santo'},
      {'codigo': 'GO', 'nome': 'Goiás'},
      {'codigo': 'MA', 'nome': 'Maranhão'},
      {'codigo': 'MT', 'nome': 'Mato Grosso'},
      {'codigo': 'MS', 'nome': 'Mato Grosso do Sul'},
      {'codigo': 'MG', 'nome': 'Minas Gerais'},
      {'codigo': 'PA', 'nome': 'Pará'},
      {'codigo': 'PB', 'nome': 'Paraíba'},
      {'codigo': 'PR', 'nome': 'Paraná'},
      {'codigo': 'PE', 'nome': 'Pernambuco'},
      {'codigo': 'PI', 'nome': 'Piauí'},
      {'codigo': 'RJ', 'nome': 'Rio de Janeiro'},
      {'codigo': 'RN', 'nome': 'Rio Grande do Norte'},
      {'codigo': 'RS', 'nome': 'Rio Grande do Sul'},
      {'codigo': 'RO', 'nome': 'Rondônia'},
      {'codigo': 'RR', 'nome': 'Roraima'},
      {'codigo': 'SC', 'nome': 'Santa Catarina'},
      {'codigo': 'SP', 'nome': 'São Paulo'},
      {'codigo': 'SE', 'nome': 'Sergipe'},
      {'codigo': 'TO', 'nome': 'Tocantins'},
    ];
  }

  // Método para cópia com modificações
  Endereco copyWith({
    int? id,
    String? cep,
    String? logradouro,
    String? numero,
    String? bairro,
    String? cidade,
    String? estado,
    String? complemento,
  }) {
    return Endereco(
      id: id ?? this.id,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      //complemento: complemento ?? this.complemento,
    );
  }

  // Método para criar endereço vazio
  static Endereco empty() {
    return Endereco(
      cep: '',
      logradouro: '',
      numero: '',
      bairro: '',
      cidade: '',
      estado: '',
    );
  }

  // Método para verificar se o endereço está vazio
  bool get isEmpty {
    return (cep?.isEmpty ?? true) &&
           (logradouro?.isEmpty ?? true) &&
           (numero?.isEmpty ?? true) &&
           (bairro?.isEmpty ?? true) &&
           (cidade?.isEmpty ?? true) &&
           (estado?.isEmpty ?? true);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Endereco &&
           other.cep == cep &&
           other.logradouro == logradouro &&
           other.numero == numero &&
           other.bairro == bairro &&
           other.cidade == cidade &&
           other.estado == estado ;
           //other.complemento == complemento;
  }

  @override
  int get hashCode {
    return Object.hash(
      cep,
      logradouro,
      numero,
      bairro,
      cidade,
      estado,
      //complemento,
    );
  }

  @override
  String toString() {
    return enderecoUmaLinha;
  }
}

// Classe para validações de endereço
class EnderecoValidator {
  static String? validateCEP(String? cep) {
    if (cep == null || cep.isEmpty) {
      return 'CEP é obrigatório';
    }
    
    final cepNumbers = cep.replaceAll(RegExp(r'\D'), '');
    
    if (cepNumbers.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }
    
    return null;
  }

  static String? validateLogradouro(String? logradouro) {
    if (logradouro == null || logradouro.trim().isEmpty) {
      return 'Logradouro é obrigatório';
    }
    if (logradouro.trim().length < 3) {
      return 'Logradouro deve ter pelo menos 3 caracteres';
    }
    return null;
  }

  static String? validateNumero(String? numero) {
    if (numero == null || numero.trim().isEmpty) {
      return 'Número é obrigatório';
    }
    // Permitir "S/N" para sem número
    if (numero.trim().toUpperCase() == 'S/N') {
      return null;
    }
    return null;
  }

  static String? validateBairro(String? bairro) {
    if (bairro == null || bairro.trim().isEmpty) {
      return 'Bairro é obrigatório';
    }
    if (bairro.trim().length < 2) {
      return 'Bairro deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  static String? validateCidade(String? cidade) {
    if (cidade == null || cidade.trim().isEmpty) {
      return 'Cidade é obrigatória';
    }
    if (cidade.trim().length < 2) {
      return 'Cidade deve ter pelo menos 2 caracteres';
    }
    return null;
  }

  static String? validateEstado(String? estado) {
    if (estado == null || estado.trim().isEmpty) {
      return 'Estado é obrigatório';
    }
    if (estado.length != 2) {
      return 'Estado deve ter 2 caracteres';
    }
    if (!Endereco._estadosValidos.contains(estado.toUpperCase())) {
      return 'Estado inválido';
    }
    return null;
  }

  static String? validateComplemento(String? complemento) {
    // Complemento é opcional, então não há validação obrigatória
    if (complemento != null && complemento.trim().isNotEmpty && complemento.length > 100) {
      return 'Complemento deve ter no máximo 100 caracteres';
    }
    return null;
  }

  // Validação completa do endereço
  static Map<String, String> validateEndereco(Endereco endereco) {
    Map<String, String> errors = {};

    final cepError = validateCEP(endereco.cep);
    if (cepError != null) errors['cep'] = cepError;

    final logradouroError = validateLogradouro(endereco.logradouro);
    if (logradouroError != null) errors['logradouro'] = logradouroError;

    final numeroError = validateNumero(endereco.numero);
    if (numeroError != null) errors['numero'] = numeroError;

    final bairroError = validateBairro(endereco.bairro);
    if (bairroError != null) errors['bairro'] = bairroError;

    final cidadeError = validateCidade(endereco.cidade);
    if (cidadeError != null) errors['cidade'] = cidadeError;

    final estadoError = validateEstado(endereco.estado);
    if (estadoError != null) errors['estado'] = estadoError;

    // final complementoError = validateComplemento(endereco.complemento);
    // if (complementoError != null) errors['complemento'] = complementoError;

    return errors;
  }
}

// Classe para utilitários de endereço
class EnderecoUtils {
  // Formatar CEP automaticamente
  static String formatCEP(String cep) {
    final numbers = cep.replaceAll(RegExp(r'\D'), '');
    if (numbers.length == 8) {
      return '${numbers.substring(0, 5)}-${numbers.substring(5)}';
    }
    return cep;
  }

  // Limpar CEP (apenas números)
  static String cleanCEP(String cep) {
    return cep.replaceAll(RegExp(r'\D'), '');
  }

  // Capitalizar nome de cidade/bairro
  static String capitalizeName(String name) {
    if (name.isEmpty) return name;
    
    return name.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      
      // Palavras que não devem ser capitalizadas (preposições, artigos)
      const exceptions = ['da', 'de', 'do', 'das', 'dos', 'e', 'em', 'na', 'no'];
      
      if (exceptions.contains(word.toLowerCase())) {
        return word.toLowerCase();
      }
      
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // Verificar se CEP é de uma região específica
  static String getRegiaoFromCEP(String cep) {
    final cepNumber = int.tryParse(cep.replaceAll(RegExp(r'\D'), ''));
    if (cepNumber == null) return 'Desconhecida';

    if (cepNumber >= 01000000 && cepNumber <= 19999999) {
      return 'São Paulo';
    } else if (cepNumber >= 20000000 && cepNumber <= 28999999) {
      return 'Rio de Janeiro';
    } else if (cepNumber >= 30000000 && cepNumber <= 39999999) {
      return 'Minas Gerais';
    } else if (cepNumber >= 40000000 && cepNumber <= 48999999) {
      return 'Bahia';
    } else if (cepNumber >= 50000000 && cepNumber <= 56999999) {
      return 'Pernambuco';
    } else if (cepNumber >= 60000000 && cepNumber <= 63999999) {
      return 'Ceará';
    } else if (cepNumber >= 70000000 && cepNumber <= 72799999) {
      return 'Distrito Federal';
    } else if (cepNumber >= 80000000 && cepNumber <= 87999999) {
      return 'Paraná';
    } else if (cepNumber >= 90000000 && cepNumber <= 99999999) {
      return 'Rio Grande do Sul';
    }
    
    return 'Outra Região';
  }

  // Calcular distância aproximada entre dois CEPs (simulação básica)
  static double calcularDistanciaAproximada(String cep1, String cep2) {
    // Esta é uma implementação muito básica
    // Para implementação real, use APIs como Google Maps ou outras
    final num1 = int.tryParse(cep1.replaceAll(RegExp(r'\D'), '')) ?? 0;
    final num2 = int.tryParse(cep2.replaceAll(RegExp(r'\D'), '')) ?? 0;
    
    final diferenca = (num1 - num2).abs();
    
    // Estimativa muito básica: cada 10000 de diferença = ~100km
    return diferenca / 100000 * 100;
  }
}