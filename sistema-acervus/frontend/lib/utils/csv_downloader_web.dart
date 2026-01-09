import 'dart:typed_data';
import 'dart:html' as html;
import 'csv_downloader_stub.dart';

class WebCsvDownloader implements CsvDownloader {
  @override
  Future<String?> saveCsv(Uint8List bytes,
      {String filename = 'turnos.csv'}) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..click();
    html.Url.revokeObjectUrl(url);
    return null; // na Web não há "caminho" local
  }

  @override
  Future<String?> extractFilename(String? contentDisposition) {
    return Future.value(_extrairFilename(contentDisposition));
  }
}

/// Extrai o filename do header Content-Disposition, se presente
String? _extrairFilename(String? contentDisposition) {
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

CsvDownloader getCsvDownloader() => WebCsvDownloader();
