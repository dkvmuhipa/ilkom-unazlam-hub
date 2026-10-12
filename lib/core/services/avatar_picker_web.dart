// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List?> pickImageBytesWeb() {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;
  final completer = Completer<Uint8List?>();
  input.onChange.first.then((_) async {
    final files = input.files;
    final file = files == null || files.isEmpty ? null : files.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final result = reader.result;
    if (result is ByteBuffer) {
      completer.complete(Uint8List.view(result));
    } else {
      completer.complete(null);
    }
  });
  input.click();
  return completer.future;
}
