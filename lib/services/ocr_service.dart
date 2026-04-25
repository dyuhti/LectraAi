import 'dart:io';
import 'dart:convert';

import 'package:image_picker/image_picker.dart';

class OcrScanResult {
  const OcrScanResult({
    required this.imagePath,
    required this.imageBase64,
    required this.extractedText,
  });

  final String imagePath;
  final String imageBase64;
  final String extractedText;
}

class OcrService {
  OcrService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<OcrScanResult?> captureAndExtractTextFromCamera() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
    );

    if (image == null) {
      print('[OCR] Capture cancelled by user.');
      return null;
    }

    try {
      final sourceFile = File(image.path);
      final bytes = await sourceFile.readAsBytes();
      final imageBase64 = base64Encode(bytes);

      return OcrScanResult(
        imagePath: image.path,
        imageBase64: imageBase64,
        extractedText: '',
      );
    } catch (e) {
      print('[OCR] Failed to encode image: $e');
      return null;
    }
  }

  void dispose() {
    // No resources to release currently.
  }
}
