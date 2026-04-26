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
  return const <WebPickedFile>[];
}
