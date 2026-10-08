import 'picked_assignment_file.dart';
import 'assignment_file_picker_stub.dart'
    if (dart.library.html) 'assignment_file_picker_web.dart'
    as platform;

Future<PickedAssignmentFile?> pickAssignmentFile() =>
    platform.pickAssignmentFile();
