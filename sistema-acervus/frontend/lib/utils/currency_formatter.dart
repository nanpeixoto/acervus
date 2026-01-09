// lib/utils/currency_formatter.dart
import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final String currencySymbol;
  final int decimalDigits;

  CurrencyInputFormatter({
    this.currencySymbol = 'R\$ ',
    this.decimalDigits = 2,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove tudo que não é dígito
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Se não há dígitos, retorna vazio
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Converte para inteiro para manipular
    int value = int.parse(newText);

    // Converte para double considerando as casas decimais
    double doubleValue = value / 100.0;

    // Formata o valor
    String formattedValue = _formatCurrency(doubleValue);

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }

  String _formatCurrency(double value) {
    // Formata o número com 2 casas decimais
    String valueStr = value.toStringAsFixed(decimalDigits);

    // Separa parte inteira e decimal
    List<String> parts = valueStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    // Adiciona separadores de milhares
    String formattedInteger = _addThousandsSeparator(integerPart);

    // Retorna o valor formatado
    return '$currencySymbol$formattedInteger,$decimalPart';
  }

  String _addThousandsSeparator(String value) {
    if (value.length <= 3) return value;

    String result = '';
    int count = 0;

    for (int i = value.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = '.$result';
        count = 0;
      }
      result = value[i] + result;
      count++;
    }

    return result;
  }

  /// Método para extrair o valor numérico do texto formatado
  static double getNumericValue(String formattedText) {
    if (formattedText.isEmpty) return 0.0;

    // Remove o símbolo R$ e espaços
    String cleanText = formattedText.replaceAll('R\$ ', '').trim();

    // Se não tem vírgula, é um valor inteiro em centavos
    if (!cleanText.contains(',')) {
      // Apenas dígitos - valor em centavos
      int centavos = int.tryParse(cleanText) ?? 0;
      return centavos / 100.0;
    }

    // Tem vírgula - separar parte inteira e decimal
    List<String> parts = cleanText.split(',');
    if (parts.length != 2) return 0.0;

    // Remover pontos da parte inteira (separadores de milhares)
    String parteInteira = parts[0].replaceAll('.', '');
    String parteDecimal = parts[1];

    // Garantir que parte decimal tenha 2 dígitos
    if (parteDecimal.length == 1) parteDecimal += '0';
    if (parteDecimal.length > 2) parteDecimal = parteDecimal.substring(0, 2);

    // Converter para double
    String valorFinal = '$parteInteira.$parteDecimal';
    return double.tryParse(valorFinal) ?? 0.0;
  }
}
