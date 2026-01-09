// lib/utils/app_config.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../utils/app_config.dart';
// Imports condicionais (NÃO mude a ordem dos ifs)
import '../utils/csv_downloader_stub.dart'
    if (dart.library.html) '../utils/csv_downloader_web.dart'
    if (dart.library.io) '../utils/csv_downloader_io.dart';

export 'dart:convert';
export 'dart:typed_data';
export 'package:http/http.dart';
export '../utils/app_config.dart';
export '../utils/csv_downloader_stub.dart'
    if (dart.library.html) '../utils/csv_downloader_web.dart'
    if (dart.library.io) '../utils/csv_downloader_io.dart';

class AppConfig {
  // Versão do app
  static const String appVersion = '1.0.0';
  static const String appName = 'Acervus - Portal WEB';

  // URLs base para diferentes ambientes
  static const String prodBaseUrl = 'http://127.0.0.1:5001';
  static const String devBaseUrl = 'http://127.0.0.1:5001';
  static const String apiURLPRD = 'http://127.0.0.1:5001';
  static const String apiURL = 'http://127.0.0.1';
  static const String apiPORT = '5001';
  static const String stagingBaseUrl = 'https://staging-api.cideestagio.com.br';

  // Configurações de API
  static const int apiTimeout = 30; // segundos
  static const int maxRetries = 3;
  static const int cacheTimeout = 10; // minutos

  // Configurações de upload
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = [
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx'
  ];

  // Configurações de paginação
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Configurações de validação
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minIdadeJovemAprendiz = 14;
  static const int maxIdadeJovemAprendiz = 24;

  // URLs externas
  static const String receitaFederalUrl =
      'https://www.receitaws.com.br/v1/cnpj';
  static const String viaCepUrl = 'https://viacep.com.br/ws';

  // Chaves de armazenamento local
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // Configurações de tema
  static const primaryColor = 0xFF2E7D32;
  static const secondaryColor = 0xFF1976D2;

  // Obter URL base baseado no ambiente
  static String get baseUrl {
    const env = String.fromEnvironment('ENV', defaultValue: 'dev');
    switch (env) {
      case 'production':
        return prodBaseUrl;
      case 'staging':
        return stagingBaseUrl;
      default:
        return devBaseUrl;
    }
  }

  // Verificar se está em modo debug
  static bool get isDebug {
    bool debug = false;
    assert(debug = true);
    return debug;
  }

  // Configurações de log
  static bool get enableLogging => isDebug;
  static bool get enableCrashlytics => !isDebug;

  // Configurações de feature flags
  static const Map<String, bool> featureFlags = {
    'enable_notifications': true,
    'enable_dark_mode': true,
    'enable_biometric_login': true,
    'enable_offline_mode': false,
    'enable_analytics': true,
  };

  // Verificar se uma feature está habilitada
  static bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }
}

// lib/utils/constants.dart
class Constants {
  // Status de empresa
  static const String statusAtiva = 'ativa';
  static const String statusInativa = 'inativa';
  static const String statusPendente = 'pendente';

  // Tipos de usuário
  static const String userTypeAdmin = 'admin';
  static const String userTypeEmpresa = 'empresa';
  static const String userTypeEstagiario = 'estagiario';
  static const String userTypeJovemAprendiz = 'jovem_aprendiz';
  static const String userTypeInstituicao = 'instituicao';

  // Status de contrato
  static const String contratoRevisao = 'revisao';
  static const String contratoGerado = 'gerado';
  static const String contratoAtivo = 'ativo';
  static const String contratoCancelado = 'cancelado';
  static const String contratoDesligado = 'desligado';

  // Tipos de vaga
  static const String vagaEstagio = 'estagio';
  static const String vagaJovemAprendiz = 'jovem_aprendiz';

  // Estados brasileiros
  static const List<String> estadosBrasil = [
    'AC',
    'AL',
    'AP',
    'AM',
    'BA',
    'CE',
    'DF',
    'ES',
    'GO',
    'MA',
    'MT',
    'MS',
    'MG',
    'PA',
    'PB',
    'PR',
    'PE',
    'PI',
    'RJ',
    'RN',
    'RS',
    'RO',
    'RR',
    'SC',
    'SP',
    'SE',
    'TO'
  ];

  // Nomes completos dos estados
  static const Map<String, String> nomeEstados = {
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

  // Mensagens de erro comuns
  static const String erroConexao = 'Erro de conexão. Verifique sua internet.';
  static const String erroGenerico =
      'Ocorreu um erro inesperado. Tente novamente.';
  static const String erroValidacao =
      'Por favor, corrija os campos em vermelho.';
  static const String erroPermissao = 'Você não tem permissão para esta ação.';
  static const String erroSessao = 'Sua sessão expirou. Faça login novamente.';

  // Mensagens de sucesso
  static const String sucessoCadastro = 'Cadastro realizado com sucesso!';
  static const String sucessoAtualizacao = 'Dados atualizados com sucesso!';
  static const String sucessoExclusao = 'Item excluído com sucesso!';
  static const String sucessoEnvio = 'Dados enviados com sucesso!';

  // Padrões de validação
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\(\d{2}\)\s\d{4,5}-\d{4}$';
  static const String cpfPattern = r'^\d{3}\.\d{3}\.\d{3}-\d{2}$';
  static const String cnpjPattern = r'^\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}$';
  static const String cepPattern = r'^\d{5}-\d{3}$';
}

// lib/utils/app_utils.dart
class AppUtils {
  // Formatar data para exibição
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  // Formatar data e hora
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} às '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Formatar moeda brasileira
  static String formatCurrency(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // Calcular idade
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Verificar se é menor de idade
  static bool isMinor(DateTime birthDate) {
    return calculateAge(birthDate) < 18;
  }

  // Obter iniciais do nome
  static String getInitials(String name) {
    if (name.isEmpty) return '';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    }

    return '${words[0].substring(0, 1)}${words[words.length - 1].substring(0, 1)}'
        .toUpperCase();
  }

  // Remover acentos de texto
  static String removeAccents(String text) {
    const withAccents = 'àáäâèéëêìíïîòóöôùúüûñç';
    const withoutAccents = 'aaaaeeeeiiiioooouuuunc';

    String result = text.toLowerCase();
    for (int i = 0; i < withAccents.length; i++) {
      result = result.replaceAll(withAccents[i], withoutAccents[i]);
    }
    return result;
  }

  // Validar se string contém apenas números
  static bool isNumeric(String str) {
    return double.tryParse(str) != null;
  }

  // Validar se email é válido
  static bool isValidEmail(String email) {
    return RegExp(Constants.emailPattern).hasMatch(email);
  }

  // Gerar cores baseadas em string
  static Color generateColorFromString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }

    final r = (hash & 0xFF0000) >> 16;
    final g = (hash & 0x00FF00) >> 8;
    final b = hash & 0x0000FF;

    return Color.fromRGBO(r, g, b, 1.0);
  }

  // Truncar texto com reticências
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  // Debounce para buscas
  static Timer? _debounceTimer;
  static void debounce(VoidCallback action,
      {Duration delay = const Duration(milliseconds: 500)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, action);
  }

  // Mostrar snackbar de erro
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Mostrar snackbar de sucesso
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Confirmar ação com dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  // Em algum BaseService ou ServiceUtils

  /// Exporta CSV de qualquer endpoint e devolve:
  ///  - Web: null (o arquivo é baixado pelo navegador)
  ///  - Mobile/Desktop: caminho salvo no disco
  static Future<String?> exportCsv({
    required String endpointPath, // ex.: '/idiomas/exportar/csv'
    Map<String, dynamic>? params, // ex.: {'ativo': true, 'is_default': false}
    String? explicitFilename, // se quiser forçar um nome
    String filenamePrefix = 'export', // prefixo padrão do arquivo
    Map<String, String> headers = const {}, // headers adicionais
  }) async {
    try {
      // Normaliza params (bool -> 'true'/'false', DateTime -> ISO, List -> 'a,b,c')
      final qp = <String, String>{};
      (params ?? {}).forEach((k, v) {
        if (v == null) return;
        if (v is bool) {
          qp[k] = v ? 'true' : 'false';
        } else if (v is DateTime) {
          qp[k] = v.toIso8601String();
        } else if (v is List) {
          qp[k] = v
              .map((e) => e is DateTime ? e.toIso8601String() : e.toString())
              .join(',');
        } else {
          qp[k] = v.toString();
        }
      });

      final uri = Uri.parse('${AppConfig.devBaseUrl}$endpointPath')
          .replace(queryParameters: qp);
      final response = await http.get(uri, headers: headers);

      if (response.statusCode != 200) {
        throw Exception('Erro ao exportar CSV (HTTP ${response.statusCode})');
      }

      final bytes = response.bodyBytes;

      // 1) tenta Content-Disposition -> filename
      final cd = response.headers['content-disposition'];
      final fromHeader = _extrairFilename(cd);

      // 2) se não veio, usa explicitFilename ou gera padrão
      final def =
          '${filenamePrefix}_${DateTime.now().toIso8601String().substring(0, 10)}.csv';
      final filename = explicitFilename ?? fromHeader ?? def;

      final downloader = getCsvDownloader(); // condicional (web/io)
      final savedPath = await downloader.saveCsv(bytes, filename: filename);

      return savedPath;
    } catch (e) {
      throw Exception('Erro ao exportar CSV: $e');
    }
  }

  /// Extrai filename do header Content-Disposition (se existir)
  static String? _extrairFilename(String? contentDisposition) {
    if (contentDisposition == null || contentDisposition.isEmpty) return null;

    // filename="turnos.csv"  |  filename=turnos.csv  |  filename*=UTF-8''turnos.csv
    final regex = RegExp('filename\\*?=(?:UTF-8\'\')?(")?([^";]+)\\1');

    final match = regex.firstMatch(contentDisposition);
    if (match != null) {
      final raw = match.group(2);
      if (raw == null) return null;
      try {
        return Uri.decodeFull(raw); // lida com %C3%B3 etc.
      } catch (_) {
        return raw;
      }
    }
    return null;
  }
}
