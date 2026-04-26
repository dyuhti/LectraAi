import 'dart:typed_data';

class WebPickedFile {
  final String name;
  final int sizeBytes;
  final Uint8List? bytes;

  const WebPickedFile({
    required this.name,
    required this.sizeBytes,
    this.bytes,
  });
}

Future<List<WebPickedFile>> pickFilesForWeb({
  required List<String> allowedExtensions,
  bool allowMultiple = true,
}) async {
  return const <WebPickedFile>[];
}
