import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

// Para salvar/compartilhar no mobile/desktop
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Para Web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Excel (Syncfusion)
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

// CSV
import 'package:csv/csv.dart';

class ExportHelper {
  static String _fileStamp() {
    final now = DateTime.now();
    return DateFormat('yyyyMMdd_HHmmss').format(now);
  }

  /// Cria a planilha Excel em memória e retorna os bytes
  static List<int> _gerarExcelBytes(List<Map<String, dynamic>> contratos) {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];

    // Cabeçalhos
    sheet.getRangeByName('A1').setText('Empresa');
    sheet.getRangeByName('B1').setText('Estagiário');
    sheet.getRangeByName('C1').setText('Vencimento');

    // Estilo cabeçalho
    final headerStyle = workbook.styles.add('headerStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#D9E1F2';
    headerStyle.hAlign = xlsio.HAlignType.center;

    sheet.getRangeByName('A1:C1').cellStyle = headerStyle;

    // Linhas
    int rowIndex = 2;
    for (final contrato in contratos) {
      final empresa = (contrato['empresa'] ?? '').toString();
      final estagiario = (contrato['estagiario'] ?? '').toString();

      String vencFmt = '';
      final raw = contrato['vencimento'];
      if (raw is String && raw.isNotEmpty) {
        final dt = DateTime.tryParse(raw);
        if (dt != null) {
          vencFmt = DateFormat('dd/MM/yyyy').format(dt);
        }
      }

      sheet.getRangeByIndex(rowIndex, 1).setText(empresa);
      sheet.getRangeByIndex(rowIndex, 2).setText(estagiario);
      sheet.getRangeByIndex(rowIndex, 3).setText(vencFmt);

      rowIndex++;
    }

    // Auto-ajustar colunas
    sheet.autoFitColumn(1);
    sheet.autoFitColumn(2);
    sheet.autoFitColumn(3);

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return bytes;
  }

  /// Exporta para Excel (.xlsx)
  static Future<void> exportXlsxContratosVencidos(
      List<Map<String, dynamic>> contratos) async {
    final bytes = _gerarExcelBytes(contratos);
    final filename = 'contratos_${_fileStamp()}.xlsx';

    if (kIsWeb) {
      // 👉 Web: download direto
      final blob = html.Blob([bytes],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // 👉 Mobile/Desktop: salva e compartilha
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(file.path)],
          text: 'Exportação de contratos a vencer');
    }
  }

  /// Exporta para CSV simples
  static Future<void> exportCsv(List<Map<String, dynamic>> contratos) async {
    final header = ['Empresa', 'Estagiário', 'Vencimento'];
    final rows = [header];

    for (final contrato in contratos) {
      final empresa = (contrato['empresa'] ?? '').toString();
      final estagiario = (contrato['estagiario'] ?? '').toString();

      String vencFmt = '';
      final raw = contrato['vencimento'];
      if (raw is String && raw.isNotEmpty) {
        final dt = DateTime.tryParse(raw);
        if (dt != null) {
          vencFmt = DateFormat('dd/MM/yyyy').format(dt);
        }
      }

      rows.add([empresa, estagiario, vencFmt]);
    }

    final csv = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csv);
    final filename = 'contratos_${_fileStamp()}.csv';

    if (kIsWeb) {
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([XFile(file.path)],
          text: 'Exportação de contratos a vencer');
    }
  }
}
