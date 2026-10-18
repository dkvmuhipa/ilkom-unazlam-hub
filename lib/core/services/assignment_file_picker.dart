import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'picked_assignment_file.dart';

const _assignmentExtensions = [
  'pdf',
  'doc',
  'docx',
  'ppt',
  'pptx',
  'xls',
  'xlsx',
  'zip',
  'png',
  'jpg',
  'jpeg',
];

const maxAssignmentFileBytes = 20 * 1024 * 1024;

class AssignmentFileTooLarge implements Exception {
  const AssignmentFileTooLarge();
}

Future<PickedAssignmentFile?> pickAssignmentFile() async {
  final file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: _assignmentExtensions,
  );
  if (file == null) return null;

  final size = file.lengthSync() ?? await file.length();
  if (size != null && size > maxAssignmentFileBytes) {
    throw const AssignmentFileTooLarge();
  }
  // Bound memory use even when a provider cannot report a file's size.
  final builder = BytesBuilder(copy: false);
  await for (final chunk in file.readAsByteStream()) {
    if (builder.length + chunk.length > maxAssignmentFileBytes) {
      throw const AssignmentFileTooLarge();
    }
    builder.add(chunk);
  }

  return PickedAssignmentFile(
    name: file.name,
    contentType: _contentTypeFor(file.extension),
    bytes: builder.takeBytes(),
  );
}

String _contentTypeFor(String? extension) => switch (extension?.toLowerCase()) {
  'pdf' => 'application/pdf',
  'doc' => 'application/msword',
  'docx' =>
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'ppt' => 'application/vnd.ms-powerpoint',
  'pptx' =>
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'xls' => 'application/vnd.ms-excel',
  'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'zip' => 'application/zip',
  'png' => 'image/png',
  'jpg' || 'jpeg' => 'image/jpeg',
  _ => 'application/octet-stream',
};
