import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'csv_downloader_stub.dart';

class IoCsvDownloader implements CsvDownloader {
  @override
  Future<String> saveCsv(Uint8List bytes,
      {String filename = 'turnos.csv'}) async {
    late Directory dir;

    try {
      // Tenta salvar em "Downloads" (desktop/Android 33+)
      dir = (await getDownloadsDirectory()) ??
          await getApplicationDocumentsDirectory();
    } catch (_) {
      // Se der erro ou não existir, salva em Documents/app dir
      dir = await getApplicationDocumentsDirectory();
    }

    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
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

CsvDownloader getCsvDownloader() => IoCsvDownloader();
