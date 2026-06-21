import 'dart:typed_data';

import 'download_bytes_stub.dart'
    if (dart.library.html) 'download_bytes_web.dart' as impl;

bool downloadBytes({
  required String fileName,
  required Uint8List bytes,
  String mimeType = 'application/octet-stream',
}) {
  return impl.downloadBytes(
    fileName: fileName,
    bytes: bytes,
    mimeType: mimeType,
  );
}
