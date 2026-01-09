class Validators {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email é obrigatório';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Email inválido';
    }
    return null;
  }

  static String? validateCPF(String? cpf) {
    if (cpf == null || cpf.isEmpty) {
      return 'CPF é obrigatório';
    }
    
    cpf = cpf.replaceAll(RegExp(r'\D'), '');
    
    if (cpf.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(cpf)) {
      return 'CPF inválido';
    }

    // Validação básica do algoritmo do CPF
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int remainder = sum % 11;
    int firstDigit = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cpf[9]) != firstDigit) {
      return 'CPF inválido';
    }

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    remainder = sum % 11;
    int secondDigit = remainder < 2 ? 0 : 11 - remainder;

    if (int.parse(cpf[10]) != secondDigit) {
      return 'CPF inválido';
    }

    return null;
  }

  static String? validateCNPJ(String? cnpj) {
    if (cnpj == null || cnpj.isEmpty) {
      return 'CNPJ é obrigatório';
    }
    
    cnpj = cnpj.replaceAll(RegExp(r'\D'), '');
    
    if (cnpj.length != 14) {
      return 'CNPJ deve ter 14 dígitos';
    }

    if (RegExp(r'^(\d)\1+$').hasMatch(cnpj)) {
      return 'CNPJ inválido';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Telefone é obrigatório';
    }
    
    phone = phone.replaceAll(RegExp(r'\D'), '');
    
    if (phone.length < 10 || phone.length > 11) {
      return 'Telefone inválido';
    }
    
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (password.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  static String? validateCEP(String? cep) {
    if (cep == null || cep.isEmpty) {
      return 'CEP é obrigatório';
    }
    
    cep = cep.replaceAll(RegExp(r'\D'), '');
    
    if (cep.length != 8) {
      return 'CEP deve ter 8 dígitos';
    }
    
    return null;
  }
}