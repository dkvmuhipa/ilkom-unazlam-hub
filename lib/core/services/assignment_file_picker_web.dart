import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'picked_assignment_file.dart';

Future<PickedAssignmentFile?> pickAssignmentFile() {
  final input = html.FileUploadInputElement()
    ..accept = '.pdf,.doc,.docx,.ppt,.pptx,.xls,.xlsx,.zip,.png,.jpg,.jpeg'
    ..multiple = false;
  final completer = Completer<PickedAssignmentFile?>();
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
      completer.complete(
        PickedAssignmentFile(
          name: file.name,
          contentType: file.type.isEmpty
              ? 'application/octet-stream'
              : file.type,
          bytes: Uint8List.view(result),
        ),
      );
    } else {
      completer.completeError(StateError('Berkas gagal dibaca oleh browser.'));
    }
  });
  input.click();
  return completer.future;
}
