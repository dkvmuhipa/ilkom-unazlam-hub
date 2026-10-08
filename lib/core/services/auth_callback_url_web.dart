import 'dart:html' as html;

void clearAuthCallbackUrl() {
  final uri = Uri.base;
  html.window.history.replaceState(null, '', '${uri.origin}${uri.path}');
}
