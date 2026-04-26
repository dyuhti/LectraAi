import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

class WebPickedFile {
  final String name;
  final int sizeBytes;
  final Uint8List bytes;

  const WebPickedFile({
    required this.name,
    required this.sizeBytes,
    required this.bytes,
  });
}

Future<List<WebPickedFile>> pickFilesForWeb({
  required List<String> allowedExtensions,
  bool allowMultiple = true,
}) async {
  final input = html.FileUploadInputElement();
  input.multiple = allowMultiple;
  input.accept = allowedExtensions.map((e) => '.${e.toLowerCase()}').join(',');
  input.click();

  try {
    await input.onChange.first.timeout(const Duration(seconds: 30));
  } on TimeoutException {
    return const <WebPickedFile>[];
  }

  final files = input.files;
  if (files == null || files.isEmpty) {
    return const <WebPickedFile>[];
  }

  final result = <WebPickedFile>[];
  for (final file in files) {
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;
    final buffer = reader.result as ByteBuffer;
    result.add(
      WebPickedFile(
        name: file.name,
        sizeBytes: file.size,
        bytes: buffer.asUint8List(),
      ),
    );
  }

  return result;
}
