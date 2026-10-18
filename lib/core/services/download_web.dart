// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// Web implementation for browser downloads and print dialogs.
bool downloadFilePlatform(String fileName, String content) {
  try {
    final extension = fileName.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'csv' => 'text/csv;charset=utf-8',
      'json' => 'application/json;charset=utf-8',
      'ics' => 'text/calendar;charset=utf-8',
      'html' => 'text/html;charset=utf-8',
      _ => 'text/plain;charset=utf-8',
    };
    final bytes = extension == 'csv'
        ? <int>[0xEF, 0xBB, 0xBF, ...utf8.encode(content)]
        : utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    // Give the browser time to begin reading the object URL before revoking it.
    Timer(const Duration(minutes: 1), () => html.Url.revokeObjectUrl(url));
    return true;
  } catch (_) {
    return false;
  }
}

bool printHtmlPlatform(String content) {
  try {
    final printable = content.replaceFirst(
      '</body>',
      '<script>window.onload=function(){window.focus();window.print();};</script></body>',
    );
    final blob = html.Blob([utf8.encode(printable)], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Timer(const Duration(minutes: 5), () => html.Url.revokeObjectUrl(url));
    return true;
  } catch (_) {
    return false;
  }
}
