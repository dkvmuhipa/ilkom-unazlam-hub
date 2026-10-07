/// Web implementation for file download
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadFilePlatform(String fileName, String content) {
  try {
    final bytes = [0xEF, 0xBB, 0xBF, ...content.codeUnits]; // UTF-8 BOM
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  } catch (_) {}
}
