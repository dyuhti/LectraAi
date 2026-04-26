import 'dart:async';
import 'dart:html' as html;

class WebPickedFile {
  final String name;
  final int sizeBytes;

  const WebPickedFile({
    required this.name,
    required this.sizeBytes,
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

  return files
      .map(
        (file) => WebPickedFile(
          name: file.name,
          sizeBytes: file.size,
        ),
      )
      .toList();
}
