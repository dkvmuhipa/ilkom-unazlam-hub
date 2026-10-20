// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void clearAuthCallbackUrl() {
  final uri = Uri.base;
  html.window.history.replaceState(null, '', '${uri.origin}${uri.path}');
}
