import 'dart:typed_data';

abstract class CsvDownloader {
  /// Retorna o caminho salvo (quando aplicável). Na Web retorna null.
  Future<String?> saveCsv(Uint8List bytes, {String filename = 'turnos.csv'});
  Future<String?> extractFilename(String? contentDisposition);
}

// Fallback (não deve ser usado em runtime, só para o analyzer)
CsvDownloader getCsvDownloader() =>
    throw UnsupportedError('No CSV downloader implementation found.');
