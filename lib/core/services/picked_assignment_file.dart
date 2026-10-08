import 'dart:typed_data';

class PickedAssignmentFile {
  final String name;
  final String contentType;
  final Uint8List bytes;

  const PickedAssignmentFile({
    required this.name,
    required this.contentType,
    required this.bytes,
  });
}
