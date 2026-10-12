import 'dart:typed_data';
import 'avatar_picker_stub.dart'
    if (dart.library.html) 'avatar_picker_web.dart'
    as platform;

Future<Uint8List?> pickImageBytesWeb() => platform.pickImageBytesWeb();
