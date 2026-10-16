import 'csv_file_reader_stub.dart'
    if (dart.library.html) 'csv_file_reader_web.dart';

class CsvFileReader {
  /// Membuka file picker untuk memilih berkas .csv dan membaca isinya sebagai string teks
  static Future<String?> pickAndReadCsv() => pickAndReadCsvPlatform();
}
